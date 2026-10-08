// Value object: dinero en centavos enteros. Ningún double toca un importe; el contrato lo
// serializa como texto ("49.90") y este tipo es el único que hace aritmética con él.
export class Money {
  private constructor(
    readonly cents: number,
    readonly currency: string,
  ) {}

  static of(amount: string, currency = "USD"): Money {
    if (!/^-?[0-9]+\.[0-9]{2}$/.test(amount)) {
      throw new Error(`invalid amount: ${amount}`);
    }
    const negative = amount.startsWith("-");
    const [whole, fraction] = amount.replace("-", "").split(".") as [string, string];
    const cents = Number(whole) * 100 + Number(fraction);
    return new Money(negative ? -cents : cents, currency);
  }

  static usd(amount: string): Money {
    return Money.of(amount, "USD");
  }

  static fromCents(cents: number, currency: string): Money {
    return new Money(Math.trunc(cents), currency);
  }

  times(quantity: number): Money {
    return new Money(this.cents * quantity, this.currency);
  }

  plus(other: Money): Money {
    if (other.currency !== this.currency) {
      throw new Error(`currency mismatch: ${this.currency} vs ${other.currency}`);
    }
    return new Money(this.cents + other.cents, this.currency);
  }

  isGreaterThan(other: Money): boolean {
    return this.cents > other.cents;
  }

  hasAmount(literal: string): boolean {
    return this.cents === Money.of(literal, this.currency).cents;
  }

  // "49.90", nunca "49.9"
  amountAsText(): string {
    const abs = Math.abs(this.cents);
    const text = `${Math.floor(abs / 100)}.${String(abs % 100).padStart(2, "0")}`;
    return this.cents < 0 ? `-${text}` : text;
  }
}
