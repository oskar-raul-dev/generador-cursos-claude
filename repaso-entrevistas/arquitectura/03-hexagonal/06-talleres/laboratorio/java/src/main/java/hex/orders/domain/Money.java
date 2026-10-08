package hex.orders.domain;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Objects;

// Value object: dinero con dos cifras, sin double en ninguna parte. El contrato lo serializa como
// texto ("49.90") y este tipo es el único que hace aritmética con él.
public record Money(BigDecimal amount, String currency) {

    public Money {
        Objects.requireNonNull(amount, "amount");
        Objects.requireNonNull(currency, "currency");
        amount = amount.setScale(2, RoundingMode.HALF_UP);
    }

    public static Money of(String amount, String currency) {
        return new Money(new BigDecimal(amount), currency);
    }

    public static Money usd(String amount) {
        return of(amount, "USD");
    }

    public Money times(int quantity) {
        return new Money(amount.multiply(BigDecimal.valueOf(quantity)), currency);
    }

    public Money plus(Money other) {
        if (!currency.equals(other.currency)) {
            throw new IllegalArgumentException("currency mismatch: " + currency + " vs " + other.currency);
        }
        return new Money(amount.add(other.amount), currency);
    }

    public boolean isGreaterThan(Money other) {
        return amount.compareTo(other.amount) > 0;
    }

    public boolean hasAmount(String literal) {
        return amount.compareTo(new BigDecimal(literal)) == 0;
    }

    // "49.90", nunca "49.9" ni notación científica
    public String amountAsText() {
        return amount.toPlainString();
    }
}
