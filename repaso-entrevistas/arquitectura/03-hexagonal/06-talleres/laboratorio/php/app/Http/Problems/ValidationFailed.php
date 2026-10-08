<?php

declare(strict_types=1);

namespace App\Http\Problems;

use RuntimeException;

/** Error de forma propio del borde (cabeceras, ids, query), con campos. */
final class ValidationFailed extends RuntimeException
{
    /** @param list<array{field: string, message: string}> $errors */
    public function __construct(public readonly array $errors)
    {
        parent::__construct('validation failed');
    }

    public static function field(string $field, string $message): self
    {
        return new self([['field' => $field, 'message' => $message]]);
    }
}
