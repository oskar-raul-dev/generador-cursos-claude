<?php

declare(strict_types=1);

namespace App\Providers;

use App\Http\Auth\TokenVerifier;
use App\Payment\DeterministicPaymentGateway;
use App\Persistence\DbUnitOfWork;
use App\Persistence\Mongo\MongoProducts;
use App\Persistence\Postgres\PgIdempotencyStore;
use App\Persistence\Postgres\PgInventory;
use App\Persistence\Postgres\PgNotifications;
use App\Persistence\Postgres\PgOrders;
use App\Persistence\Postgres\PgPayments;
use App\Persistence\Postgres\PgPendingPublications;
use App\Persistence\Postgres\PgProducts;
use App\Persistence\Postgres\PgUsers;
use App\Persistence\Postgres\TableNotifier;
use App\Redis\PredisRevocationStore;
use App\Security\JwtTokens;
use App\Security\NativePasswordHasher;
use App\Support\RandomIds;
use App\Support\SystemClock;
use Hex\Application\Port\Clock;
use Hex\Application\Port\IdempotencyStore;
use Hex\Application\Port\IdGenerator;
use Hex\Application\Port\Inventory;
use Hex\Application\Port\Notifications;
use Hex\Application\Port\Notifier;
use Hex\Application\Port\Orders;
use Hex\Application\Port\PasswordHasher;
use Hex\Application\Port\PaymentGateway;
use Hex\Application\Port\Payments;
use Hex\Application\Port\PendingPublications;
use Hex\Application\Port\Products;
use Hex\Application\Port\TokenIssuer;
use Hex\Application\Port\TokenRevocationStore;
use Hex\Application\Port\UnitOfWork;
use Hex\Application\Port\Users;
use Illuminate\Contracts\Foundation\Application;
use Illuminate\Database\ConnectionInterface;
use Illuminate\Support\ServiceProvider;
use Predis\Client as PredisClient;
use Predis\ClientInterface;

/**
 * El composition root: un `bind` por puerto. Los casos de uso son clases finales con los puertos
 * en el constructor, así que el contenedor los resuelve solo (autowiring por interfaz); nadie los
 * registra a mano. Es el único archivo que conoce a la vez los puertos y las implementaciones.
 */
final class HexServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Una sola conexión por proceso: todos los adaptadores comparten su transacción.
        $this->app->singleton(ConnectionInterface::class, fn (Application $app) => $app->make('db')->connection());
        $this->app->singleton(UnitOfWork::class, DbUnitOfWork::class);

        $this->app->singleton(Clock::class, SystemClock::class);
        $this->app->singleton(IdGenerator::class, RandomIds::class);
        $this->app->singleton(PasswordHasher::class, NativePasswordHasher::class);
        $this->app->singleton(PaymentGateway::class, DeterministicPaymentGateway::class);

        $this->app->singleton(JwtTokens::class, fn (Application $app) => new JwtTokens(
            config('hex.jwt_secret'), config('hex.jwt_ttl_seconds'), $app->make(Clock::class),
        ));
        $this->app->singleton(TokenIssuer::class, JwtTokens::class);
        $this->app->singleton(TokenVerifier::class, JwtTokens::class);

        $this->app->singleton(ClientInterface::class, fn () => new PredisClient([
            'host' => config('database.redis.default.host'), 'port' => (int) config('database.redis.default.port'),
        ]));
        $this->app->singleton(TokenRevocationStore::class, PredisRevocationStore::class);

        // El catálogo: parte 3. Qué implementación, lo decide la configuración; Mongo solo se abre si se usa.
        $this->app->singleton(Products::class, fn () => config('hex.catalog') === 'mongo'
            ? new MongoProducts(config('hex.mongo_url'))
            : new PgProducts($this->app->make(ConnectionInterface::class)));

        $this->app->singleton(Users::class, PgUsers::class);
        $this->app->singleton(Inventory::class, PgInventory::class);
        $this->app->singleton(Orders::class, PgOrders::class);
        $this->app->singleton(Payments::class, PgPayments::class);
        $this->app->singleton(IdempotencyStore::class, PgIdempotencyStore::class);
        $this->app->singleton(PendingPublications::class, PgPendingPublications::class);   // parte 2
        $this->app->singleton(Notifications::class, PgNotifications::class);               // parte 2
        $this->app->singleton(Notifier::class, TableNotifier::class);                       // parte 2
    }
}
