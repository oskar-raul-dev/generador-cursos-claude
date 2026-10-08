<?php

declare(strict_types=1);

namespace App\Http;

use App\Http\Problems\MissingIdempotencyKey;
use App\Http\Problems\ValidationFailed;
use Hex\Application\PageRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

/** Lo que en FastAPI hacían las dependencias `Key`, `UUID` y `Query`: cabecera, ids y paginación con forma comprobada. */
final class Query
{
    public static function idempotencyKey(Request $request): string
    {
        $key = $request->header('Idempotency-Key');
        if ($key === null || $key === '') {
            throw new MissingIdempotencyKey();
        }
        $length = strlen($key);
        if ($length < 8 || $length > 128) {
            throw ValidationFailed::field('Idempotency-Key', 'must be between 8 and 128 characters');
        }

        return $key;
    }

    /** Un id que no es UUID es forma (400), no existencia (404). */
    public static function uuid(string $value, string $field): string
    {
        if (! Str::isUuid($value)) {
            throw ValidationFailed::field($field, 'must be a UUID');
        }

        return $value;
    }

    public static function page(Request $request): PageRequest
    {
        $limit = $request->query('limit');
        if ($limit !== null && ! ctype_digit((string) $limit)) {
            throw ValidationFailed::field('limit', 'must be an integer');
        }
        $cursor = $request->query('cursor');

        return PageRequest::of(is_string($cursor) ? $cursor : null, $limit === null ? null : (int) $limit);
    }
}
