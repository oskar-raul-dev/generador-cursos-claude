<?php

declare(strict_types=1);

namespace App\Persistence\Postgres;

use App\Persistence\Cursors;
use Hex\Application\Page;
use Hex\Application\PageRequest;
use Hex\Application\Port\Orders;
use Hex\Domain\Order;
use Hex\Domain\OrderLine;
use Hex\Domain\OrderStatus;
use Hex\Domain\Payment;
use Hex\Domain\PaymentStatus;
use Illuminate\Database\ConnectionInterface;

/** Traduce entre Order y las filas de orders/order_lines/payments; reconstruye el agregado completo. Sin Eloquent. */
final readonly class PgOrders implements Orders
{
    private const string COLUMNS = 'id::text AS id, customer_id::text AS customer_id, status, total_amount::text AS total, currency, version, created_at::text AS created_at';

    public function __construct(private ConnectionInterface $db) {}

    public function find(string $id): ?Order
    {
        $rows = $this->db->select('SELECT '.self::COLUMNS.' FROM orders WHERE id = CAST(:id AS uuid)', ['id' => $id]);

        return $rows === [] ? null : $this->reconstitute($rows[0]);
    }

    public function save(Order $order): void
    {
        $updated = $this->db->update(
            'UPDATE orders SET status = :status, version = :version, updated_at = now() WHERE id = CAST(:id AS uuid)',
            ['status' => $order->status->value, 'version' => $order->version + 1, 'id' => $order->id],
        );
        if ($updated > 0) {
            return;
        }
        $this->db->insert(
            'INSERT INTO orders (id, customer_id, status, total_amount, currency, version, created_at)
             VALUES (CAST(:id AS uuid), CAST(:customer AS uuid), :status, CAST(:total AS numeric), :currency, 0, CAST(:created AS timestamptz))',
            ['id' => $order->id, 'customer' => $order->customerId, 'status' => $order->status->value, 'total' => $order->total->text(),
                'currency' => $order->total->currency, 'created' => Rows::bindTime($order->createdAt)],
        );
        foreach ($order->lines as $i => $line) {
            $this->db->insert(
                'INSERT INTO order_lines (order_id, line_no, sku, product_name, quantity, unit_price)
                 VALUES (CAST(:o AS uuid), :n, :sku, :name, :q, CAST(:price AS numeric))',
                ['o' => $order->id, 'n' => $i, 'sku' => $line->sku, 'name' => $line->name, 'q' => $line->quantity, 'price' => $line->unitPrice->text()],
            );
        }
    }

    public function list(?string $customerId, PageRequest $page): Page
    {
        $sql = 'SELECT '.self::COLUMNS.' FROM orders WHERE true';
        $params = [];
        if ($customerId !== null) {
            $sql .= ' AND customer_id = CAST(:customer AS uuid)';
            $params['customer'] = $customerId;
        }
        $cursor = Cursors::decodeTime($page->cursor);
        if ($cursor !== null) {  // (created_at, id) descendente: estable aunque se creen pedidos entre páginas
            $sql .= ' AND (created_at, id) < (CAST(:ts AS timestamptz), CAST(:cid AS uuid))';
            [$params['ts'], $params['cid']] = [Rows::bindTime($cursor[0]), $cursor[1]];
        }
        $sql .= ' ORDER BY created_at DESC, id DESC LIMIT :limit';
        $params['limit'] = $page->limit + 1;
        $rows = $this->db->select($sql, $params);
        $more = count($rows) > $page->limit;
        $rows = array_slice($rows, 0, $page->limit);
        $last = end($rows);
        $next = $more && $last !== false ? Cursors::encodeTime(Rows::time($last->created_at), $last->id) : null;

        return new Page(array_map($this->reconstitute(...), $rows), $next);
    }

    private function reconstitute(object $row): Order
    {
        $currency = $row->currency;
        $lines = array_map(
            fn (object $l) => new OrderLine($l->sku, $l->product_name, (int) $l->quantity, Rows::money($l->unit_price, $currency)),
            $this->db->select('SELECT sku, product_name, quantity, unit_price::text AS unit_price FROM order_lines WHERE order_id = CAST(:o AS uuid) ORDER BY line_no', ['o' => $row->id]),
        );
        $last = $this->db->select('SELECT status, operation_id, reference FROM payments WHERE order_id = CAST(:o AS uuid) ORDER BY created_at DESC LIMIT 1', ['o' => $row->id]);
        $payment = $last === [] ? null : new Payment(PaymentStatus::from($last[0]->status), $last[0]->operation_id, $last[0]->reference);

        return Order::reconstitute($row->id, $row->customer_id, $lines, Rows::money($row->total, $currency), Rows::time($row->created_at),
            OrderStatus::from($row->status), $payment, (int) $row->version);
    }
}
