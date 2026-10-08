<?php

declare(strict_types=1);

namespace Tests\Unit;

use Hex\Domain\Money;
use InvalidArgumentException;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

/** Sin arrancar Laravel: el dominio se prueba como cualquier clase PHP. */
final class MoneyTest extends TestCase
{
    #[Test]
    public function parses_and_prints_with_two_decimals(): void
    {
        self::assertSame(4990, Money::usd('49.90')->cents);
        self::assertSame('49.90', Money::usd('49.90')->text());
        self::assertSame('0.05', new Money(5, 'USD')->text());
    }

    #[Test]
    public function rejects_amounts_without_two_decimals(): void
    {
        $this->expectException(InvalidArgumentException::class);
        Money::usd('35');
    }

    #[Test]
    public function adds_and_multiplies_in_cents(): void
    {
        self::assertSame('99.80', Money::usd('49.90')->times(2)->text());
        self::assertSame('59.80', Money::usd('49.90')->plus(Money::usd('9.90'))->text());
    }
}
