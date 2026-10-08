<?php

declare(strict_types=1);

namespace Hex\Application\Error;

/** "No existe" y "no es tuyo" se expresan igual: el borde responde 404 sin revelar existencia. */
final class NotFound extends ApplicationError
{
    /** @param 'PRODUCT'|'ORDER' $kind */
    public function __construct(public readonly string $kind, public readonly string $identifier)
    {
        parent::__construct(strtolower($kind)." not found: {$identifier}");
    }
}
