<?php

declare(strict_types=1);

namespace Hex\Application;

final readonly class PageRequest
{
    public const int MAX_LIMIT = 100;

    public const int DEFAULT_LIMIT = 20;

    public function __construct(public ?string $cursor, public int $limit) {}

    /** El servidor acota el tamaño aunque el cliente pida más (decisión del contrato). */
    public static function of(?string $cursor, ?int $limit): self
    {
        $bounded = ($limit === null || $limit < 1) ? self::DEFAULT_LIMIT : min($limit, self::MAX_LIMIT);

        return new self($cursor === '' ? null : $cursor, $bounded);
    }
}
