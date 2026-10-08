<?php

declare(strict_types=1);

namespace App\Persistence\Postgres;

use Hex\Application\Port\Inventory;
use Hex\Domain\Error\InsufficientInventory;
use Illuminate\Database\ConnectionInterface;
use Illuminate\Support\Str;

/**
 * reserve descuenta línea a línea con un UPDATE condicional; al primer 0 lanza, y la transacción
 * del caso de uso revierte lo ya descontado.
 */
final readonly class PgInventory implements Inventory
{
    public function __construct(private ConnectionInterface $db) {}

    public function availableFor(array $skus): array
    {
        if ($skus === []) {
            return [];
        }
        // PDO no enlaza arrays: un marcador posicional por SKU.
        $marks = implode(', ', array_fill(0, count($skus), '?'));
        $out = [];
        foreach ($this->db->select("SELECT sku, available FROM inventory WHERE sku IN ({$marks})", $skus) as $row) {
            $out[$row->sku] = (int) $row->available;
        }

        return $out;
    }

    public function initialize(string $sku, int $quantity): void
    {
        $this->db->insert('INSERT INTO inventory (sku, available) VALUES (:sku, :q)', ['sku' => $sku, 'q' => $quantity]);
    }

    public function reserve(string $orderId, array $lines): void
    {
        foreach ($lines as $index => $line) {
            $updated = $this->db->update(
                'UPDATE inventory SET available = available - :q, version = version + 1, updated_at = now() WHERE sku = :sku AND available >= :q2',
                ['q' => $line->quantity, 'sku' => $line->sku, 'q2' => $line->quantity],   // PDO exige un nombre por ocurrencia
            );
            if ($updated === 0) {
                $row = $this->db->select('SELECT available FROM inventory WHERE sku = :sku', ['sku' => $line->sku]);
                throw new InsufficientInventory($line->sku, $line->quantity, $row === [] ? 0 : (int) $row[0]->available, $index);
            }
            $this->db->insert(
                "INSERT INTO inventory_reservations (id, order_id, sku, quantity, status) VALUES (CAST(:id AS uuid), CAST(:order_id AS uuid), :sku, :q, 'RESERVED')",
                ['id' => (string) Str::uuid(), 'order_id' => $orderId, 'sku' => $line->sku, 'q' => $line->quantity],
            );
        }
    }

    public function release(string $orderId): void
    {
        $rows = $this->db->select(
            "SELECT id::text AS id, sku, quantity FROM inventory_reservations WHERE order_id = CAST(:o AS uuid) AND status = 'RESERVED'",
            ['o' => $orderId],
        );
        foreach ($rows as $r) {
            $this->db->update('UPDATE inventory SET available = available + :q, version = version + 1, updated_at = now() WHERE sku = :sku', ['q' => $r->quantity, 'sku' => $r->sku]);
            $this->db->update("UPDATE inventory_reservations SET status = 'RELEASED', updated_at = now() WHERE id = CAST(:id AS uuid)", ['id' => $r->id]);
        }
    }
}
