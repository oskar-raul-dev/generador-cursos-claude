<?php

declare(strict_types=1);

namespace Hex\Domain;

use InvalidArgumentException;

/**
 * Value object: dinero en centavos enteros. Ningún float toca un importe; el contrato lo serializa
 * como texto ("49.90") y este tipo es el único que hace aritmética con él.
 */
final readonly class Money
{
    private const string AMOUNT = '/^-?[0-9]+\.[0-9]{2}$/';

    public function __construct(public int $cents, public string $currency) {}

    public static function parse(string $amount, string $currency = 'USD'): self
    {
        if (preg_match(self::AMOUNT, $amount) !== 1) {
            throw new InvalidArgumentException("invalid amount: {$amount}");
        }
        $negative = str_starts_with($amount, '-');
        [$whole, $fraction] = explode('.', ltrim($amount, '-'));
        $cents = (int) $whole * 100 + (int) $fraction;

        return new self($negative ? -$cents : $cents, $currency);
    }

    public static function usd(string $amount): self
    {
        return self::parse($amount, 'USD');
    }

    public function times(int $quantity): self
    {
        return new self($this->cents * $quantity, $this->currency);
    }

    public function plus(self $other): self
    {
        if ($other->currency !== $this->currency) {
            throw new InvalidArgumentException("currency mismatch: {$this->currency} vs {$other->currency}");
        }

        return new self($this->cents + $other->cents, $this->currency);
    }

    public function isGreaterThan(self $other): bool
    {
        return $this->cents > $other->cents;
    }

    public function hasAmount(string $literal): bool
    {
        return $this->cents === self::parse($literal, $this->currency)->cents;
    }

    /** "49.90", nunca "49.9". */
    public function text(): string
    {
        $sign = $this->cents < 0 ? '-' : '';
        $cents = abs($this->cents);

        return sprintf('%s%d.%02d', $sign, intdiv($cents, 100), $cents % 100);
    }
}
