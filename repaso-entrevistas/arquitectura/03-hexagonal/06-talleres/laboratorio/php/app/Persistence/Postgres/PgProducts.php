<?php

declare(strict_types=1);

namespace App\Persistence\Postgres;

use App\Persistence\Cursors;
use Hex\Application\Page;
use Hex\Application\PageRequest;
use Hex\Application\Port\Products;
use Hex\Domain\Product;
use Illuminate\Database\ConnectionInterface;

/** Catálogo en PostgreSQL (partes 1 y 2). El provider elige entre este y MongoProducts. */
final readonly class PgProducts implements Products
{
    public function __construct(private ConnectionInterface $db) {}

    public function find(string $sku): ?Product
    {
        $rows = $this->db->select('SELECT sku, name, unit_price::text AS unit_price, currency FROM products WHERE sku = :sku', ['sku' => $sku]);

        return $rows === [] ? null : self::toProduct($rows[0]);
    }

    public function exists(string $sku): bool
    {
        return $this->db->select('SELECT 1 AS x FROM products WHERE sku = :sku', ['sku' => $sku]) !== [];
    }

    public function list(PageRequest $page): Page
    {
        $rows = $this->db->select(
            'SELECT sku, name, unit_price::text AS unit_price, currency FROM products WHERE sku > :after ORDER BY sku LIMIT :limit',
            ['after' => Cursors::decode($page->cursor) ?? '', 'limit' => $page->limit + 1],   // una fila más: ¿hay siguiente?
        );
        $more = count($rows) > $page->limit;
        $rows = array_slice($rows, 0, $page->limit);

        return new Page(array_map(self::toProduct(...), $rows), $more ? Cursors::encode(end($rows)->sku) : null);
    }

    public function save(Product $product): void
    {
        $this->db->statement(
            'INSERT INTO products (sku, name, unit_price, currency) VALUES (:sku, :name, CAST(:price AS numeric), :currency)
             ON CONFLICT (sku) DO UPDATE SET name = EXCLUDED.name, unit_price = EXCLUDED.unit_price,
                 currency = EXCLUDED.currency, updated_at = now()',
            ['sku' => $product->sku, 'name' => $product->name, 'price' => $product->unitPrice->text(), 'currency' => $product->unitPrice->currency],
        );
    }

    private static function toProduct(object $row): Product
    {
        return new Product($row->sku, $row->name, Rows::money($row->unit_price, $row->currency));
    }
}
