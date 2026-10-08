<?php

declare(strict_types=1);

namespace Tests\Unit;

use Closure;
use DateTimeImmutable;
use Hex\Application\Actor;
use Hex\Application\Error\IdempotencyKeyReused;
use Hex\Application\Page;
use Hex\Application\PageRequest;
use Hex\Application\Port\Clock;
use Hex\Application\Port\IdempotencyStore;
use Hex\Application\Port\IdGenerator;
use Hex\Application\Port\Inventory;
use Hex\Application\Port\Orders;
use Hex\Application\Port\Products;
use Hex\Application\Port\StoredResponse;
use Hex\Application\Port\UnitOfWork;
use Hex\Application\Role;
use Hex\Application\UseCase\CreateOrder;
use Hex\Application\UseCase\CreateOrderCommand;
use Hex\Application\UseCase\LineRequest;
use Hex\Domain\Error\InsufficientInventory;
use Hex\Domain\Money;
use Hex\Domain\Order;
use Hex\Domain\Product;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

/**
 * El caso de uso con dobles fieles a los puertos y una unidad de trabajo de pruebas que restaura
 * los fakes si el trabajo lanza. Los fakes `implements` la interfaz: en PHP el contrato es nominal
 * y el intérprete lo comprueba al cargar la clase (a diferencia de un Protocol de Python).
 */
final class CreateOrderTest extends TestCase
{
    private const string ANA = '11111111-1111-4111-8111-111111111111';

    private FakeInventory $inventory;

    private FakeOrders $orders;

    private FakeIdempotency $keys;

    private CreateOrder $useCase;

    protected function setUp(): void
    {
        $products = new FakeProducts();
        $products->save(new Product('SKU-001', 'Mechanical keyboard', Money::usd('49.90')));
        $products->save(new Product('SKU-004', 'Webcam', Money::usd('59.00')));
        $this->inventory = new FakeInventory();
        $this->inventory->initialize('SKU-001', 20);
        $this->inventory->initialize('SKU-004', 0);
        $this->orders = new FakeOrders();
        $this->keys = new FakeIdempotency();
        $this->useCase = new CreateOrder($products, $this->inventory, $this->orders, $this->keys, new SeqIds(), new FixedClock(),
            new SnapshotUnitOfWork($this->orders, $this->inventory, $this->keys));
    }

    private static function command(string $key, LineRequest ...$lines): CreateOrderCommand
    {
        $canonical = implode(',', array_map(fn (LineRequest $l) => "{$l->sku}:{$l->quantity}", $lines));

        return new CreateOrderCommand(new Actor(self::ANA, 'ana@hex.local', Role::CUSTOMER), $key, $canonical, array_values($lines));
    }

    #[Test]
    public function reserves_stock_and_remembers_the_key(): void
    {
        $result = $this->useCase->execute(self::command('key-0001', new LineRequest('SKU-001', 2)));
        self::assertFalse($result->replayed);
        self::assertSame('99.80', $result->order->total->text());
        self::assertSame(18, $this->inventory->available['SKU-001']);
        self::assertArrayHasKey($result->order->id, $this->orders->data);
    }

    #[Test]
    public function same_key_same_body_replays(): void
    {
        $first = $this->useCase->execute(self::command('key-0002', new LineRequest('SKU-001', 2)));
        $again = $this->useCase->execute(self::command('key-0002', new LineRequest('SKU-001', 2)));
        self::assertTrue($again->replayed);
        self::assertSame($first->order->id, $again->order->id);
        self::assertSame(18, $this->inventory->available['SKU-001']);
    }

    #[Test]
    public function same_key_different_body_is_rejected(): void
    {
        $this->useCase->execute(self::command('key-0003', new LineRequest('SKU-001', 1)));
        $this->expectException(IdempotencyKeyReused::class);
        $this->useCase->execute(self::command('key-0003', new LineRequest('SKU-001', 3)));
    }

    #[Test]
    public function insufficient_inventory_leaves_nothing_behind(): void
    {
        try {
            $this->useCase->execute(self::command('key-0004', new LineRequest('SKU-001', 1), new LineRequest('SKU-004', 1)));
            self::fail('expected InsufficientInventory');
        } catch (InsufficientInventory) {
        }
        // el pedido se guardó antes de reservar; lo que lo deshace es la unidad de trabajo
        self::assertSame(20, $this->inventory->available['SKU-001']);
        self::assertSame([], $this->orders->data);
        self::assertSame([], $this->keys->data);
    }
}

final class FakeProducts implements Products
{
    /** @var array<string, Product> */
    public array $data = [];

    public function find(string $sku): ?Product
    {
        return $this->data[$sku] ?? null;
    }

    public function exists(string $sku): bool
    {
        return isset($this->data[$sku]);
    }

    public function list(PageRequest $page): Page
    {
        return new Page(array_values($this->data), null);
    }

    public function save(Product $product): void
    {
        $this->data[$product->sku] = $product;
    }
}

final class FakeInventory implements Inventory
{
    /** @var array<string, int> */
    public array $available = [];

    public function availableFor(array $skus): array
    {
        $out = [];
        foreach ($skus as $sku) {
            $out[$sku] = $this->available[$sku] ?? 0;
        }

        return $out;
    }

    public function initialize(string $sku, int $quantity): void
    {
        $this->available[$sku] = $quantity;
    }

    public function reserve(string $orderId, array $lines): void
    {
        // como el adaptador real: descuenta línea a línea y lanza al primer faltante
        foreach ($lines as $i => $line) {
            $have = $this->available[$line->sku] ?? 0;
            if ($have < $line->quantity) {
                throw new InsufficientInventory($line->sku, $line->quantity, $have, $i);
            }
            $this->available[$line->sku] = $have - $line->quantity;
        }
    }

    public function release(string $orderId): void {}
}

final class FakeOrders implements Orders
{
    /** @var array<string, Order> */
    public array $data = [];

    public function find(string $id): ?Order
    {
        return $this->data[$id] ?? null;
    }

    public function save(Order $order): void
    {
        $this->data[$order->id] = $order;
    }

    public function list(?string $customerId, PageRequest $page): Page
    {
        return new Page(array_values($this->data), null);
    }
}

final class FakeIdempotency implements IdempotencyStore
{
    /** @var array<string, StoredResponse> */
    public array $data = [];

    public function find(string $actorId, string $key): ?StoredResponse
    {
        return $this->data["{$actorId}:{$key}"] ?? null;
    }

    public function save(string $actorId, string $key, string $requestHash, int $status, string $body): void
    {
        $this->data["{$actorId}:{$key}"] = new StoredResponse($requestHash, $status, $body);
    }
}

final class SnapshotUnitOfWork implements UnitOfWork
{
    public function __construct(private FakeOrders $orders, private FakeInventory $inventory, private FakeIdempotency $keys) {}

    public function run(Closure $work): mixed
    {
        $snapshot = [$this->orders->data, $this->inventory->available, $this->keys->data];
        try {
            return $work();
        } catch (\Throwable $e) {
            [$this->orders->data, $this->inventory->available, $this->keys->data] = $snapshot;
            throw $e;
        }
    }
}

final class FixedClock implements Clock
{
    public function now(): DateTimeImmutable
    {
        return new DateTimeImmutable('2026-09-27T12:00:00Z');
    }
}

final class SeqIds implements IdGenerator
{
    private int $n = 0;

    public function next(): string
    {
        return 'order-'.(++$this->n);
    }
}
