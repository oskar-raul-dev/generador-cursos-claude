<?php

declare(strict_types=1);

namespace App\Http;

use Hex\Application\Page;
use Hex\Application\Port\Notification;
use Hex\Application\UseCase\ProductWithStock;
use Hex\Domain\Money;
use Hex\Domain\Order;
use Hex\Domain\OrderLine;
use Hex\Domain\Payment;

/** Las formas de salida del contrato (claves camelCase), a partir de los tipos del núcleo. */
final class Responses
{
    public static function money(Money $m): array
    {
        return ['amount' => $m->text(), 'currency' => $m->currency];
    }

    public static function product(ProductWithStock $p): array
    {
        return ['sku' => $p->product->sku, 'name' => $p->product->name, 'unitPrice' => self::money($p->product->unitPrice), 'stock' => $p->stock];
    }

    public static function order(Order $o): array
    {
        return [
            'id' => $o->id, 'customerId' => $o->customerId, 'status' => $o->status->value,
            'lines' => array_map(self::line(...), $o->lines), 'total' => self::money($o->total),
            'payment' => self::payment($o->payment), 'createdAt' => $o->createdAt->format('Y-m-d\TH:i:s.u\Z'),
        ];
    }

    public static function paymentResult(Order $o, Payment $p): array
    {
        return ['orderId' => $o->id, 'orderStatus' => $o->status->value, 'payment' => self::payment($p)];
    }

    public static function notification(Notification $n): array
    {
        return ['id' => $n->id, 'orderId' => $n->orderId, 'type' => $n->type, 'recipient' => $n->recipient, 'createdAt' => $n->createdAt->format('Y-m-d\TH:i:s.u\Z')];
    }

    /** @param Page<mixed> $page */
    public static function page(Page $page, callable $item): array
    {
        return ['items' => array_map($item, $page->items), 'nextCursor' => $page->nextCursor];
    }

    private static function line(OrderLine $l): array
    {
        return ['sku' => $l->sku, 'name' => $l->name, 'quantity' => $l->quantity, 'unitPrice' => self::money($l->unitPrice), 'lineTotal' => self::money($l->lineTotal())];
    }

    private static function payment(?Payment $p): ?array
    {
        return $p === null ? null : ['status' => $p->status->value, 'operationId' => $p->operationId, 'reference' => $p->reference];
    }
}
