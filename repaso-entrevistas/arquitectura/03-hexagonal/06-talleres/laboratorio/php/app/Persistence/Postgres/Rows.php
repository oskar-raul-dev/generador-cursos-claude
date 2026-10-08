<?php

declare(strict_types=1);

namespace App\Persistence\Postgres;

use DateTimeImmutable;
use DateTimeZone;
use Hex\Domain\Money;

/**
 * Conversión de columnas. pdo_pgsql entrega numeric como texto ("49.90"), timestamptz como texto
 * ("2026-09-27 21:03:11.123456+00") y jsonb como texto. Los importes nunca pasan por float.
 */
final class Rows
{
    public static function money(string $value, string $currency): Money
    {
        return Money::parse(bcadd($value, '0', 2), $currency);   // bcmath fija dos decimales sin float
    }

    public static function time(string $value): DateTimeImmutable
    {
        return (new DateTimeImmutable($value))->setTimezone(new DateTimeZone('UTC'));
    }

    /**
     * Laravel formatearía un DateTime con 'Y-m-d H:i:s' (sin microsegundos ni zona): se pasa texto.
     */
    public static function bindTime(DateTimeImmutable $value): string
    {
        return $value->format('Y-m-d H:i:s.uP');
    }

    /** @return array<string, mixed> */
    public static function json(string $value): array
    {
        return json_decode($value, associative: true, flags: JSON_THROW_ON_ERROR);
    }
}
