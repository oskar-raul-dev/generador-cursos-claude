<?php

declare(strict_types=1);

namespace Hex\Application;

use Hex\Application\Error\AccessDenied;
use Hex\Domain\Order;

/** Quién ejecuta el caso de uso, ya verificado por el borde. Sin JWT, sin claims crudos, sin Laravel. */
final readonly class Actor
{
    public function __construct(public string $id, public string $email, public Role $role) {}

    public function isOperator(): bool
    {
        return $this->role === Role::OPERATOR;
    }

    /**
     * Autorización contextual: dueño u operador. Vive aquí porque un job o un consumidor que use el
     * mismo caso de uso tiene que cumplirla igual.
     */
    public function canSee(Order $order): bool
    {
        return $this->isOperator() || $order->customerId === $this->id;
    }

    public function requireOperator(): void
    {
        if (! $this->isOperator()) {
            throw new AccessDenied();
        }
    }
}
