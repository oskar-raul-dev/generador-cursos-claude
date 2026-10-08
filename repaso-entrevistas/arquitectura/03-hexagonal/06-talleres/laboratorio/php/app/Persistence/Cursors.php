<?php

declare(strict_types=1);

namespace App\Persistence;

use DateTimeImmutable;
use Throwable;

/** Cursores opacos: el cliente los devuelve tal cual; solo el adaptador sabe qué llevan dentro. Un cursor ilegible es "primera página". */
final class Cursors
{
    public static function encode(string $raw): string
    {
        return rtrim(strtr(base64_encode($raw), '+/', '-_'), '=');
    }

    public static function decode(?string $cursor): ?string
    {
        if ($cursor === null || $cursor === '') {
            return null;
        }
        $decoded = base64_decode(strtr($cursor, '-_', '+/'), strict: true);

        return $decoded === false ? null : $decoded;
    }

    public static function encodeTime(DateTimeImmutable $ts, string $id): string
    {
        return self::encode($ts->format('Y-m-d\TH:i:s.uP').'|'.$id);
    }

    /** @return array{0: DateTimeImmutable, 1: string}|null */
    public static function decodeTime(?string $cursor): ?array
    {
        $raw = self::decode($cursor);
        if ($raw === null || ! str_contains($raw, '|')) {
            return null;
        }
        [$ts, $id] = explode('|', $raw, 2);
        try {
            return [new DateTimeImmutable($ts), $id];
        } catch (Throwable) {
            return null;
        }
    }
}
