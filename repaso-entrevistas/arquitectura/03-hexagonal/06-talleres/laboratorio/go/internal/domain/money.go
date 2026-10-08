// Package domain contiene las reglas del negocio. No importa nada fuera de la biblioteca estándar:
// ni HTTP, ni pgx, ni el driver de Mongo, ni siquiera un generador de UUID.
package domain

import (
	"errors"
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

var amountPattern = regexp.MustCompile(`^-?[0-9]+\.[0-9]{2}$`)

// Money es dinero en centavos enteros. Ningún float64 toca un importe; el contrato lo serializa
// como texto ("49.90") y este tipo es el único que hace aritmética con él.
type Money struct {
	Cents    int64
	Currency string
}

// ParseMoney lee "49.90" → 4990 centavos.
func ParseMoney(amount, currency string) (Money, error) {
	if !amountPattern.MatchString(amount) {
		return Money{}, fmt.Errorf("invalid amount: %q", amount)
	}
	negative := strings.HasPrefix(amount, "-")
	parts := strings.SplitN(strings.TrimPrefix(amount, "-"), ".", 2)
	whole, _ := strconv.ParseInt(parts[0], 10, 64)
	fraction, _ := strconv.ParseInt(parts[1], 10, 64)
	cents := whole*100 + fraction
	if negative {
		cents = -cents
	}
	return Money{Cents: cents, Currency: currency}, nil
}

// MustUSD es para literales del propio código (la regla del gateway, las pruebas).
func MustUSD(amount string) Money {
	m, err := ParseMoney(amount, "USD")
	if err != nil {
		panic(err)
	}
	return m
}

func (m Money) Times(quantity int) Money {
	return Money{Cents: m.Cents * int64(quantity), Currency: m.Currency}
}

func (m Money) Plus(other Money) (Money, error) {
	if m.Currency != other.Currency {
		return Money{}, errors.New("currency mismatch: " + m.Currency + " vs " + other.Currency)
	}
	return Money{Cents: m.Cents + other.Cents, Currency: m.Currency}, nil
}

func (m Money) GreaterThan(other Money) bool { return m.Cents > other.Cents }

func (m Money) HasAmount(literal string) bool {
	other, err := ParseMoney(literal, m.Currency)
	return err == nil && other.Cents == m.Cents
}

// Text devuelve "49.90", nunca "49.9".
func (m Money) Text() string {
	abs := m.Cents
	sign := ""
	if abs < 0 {
		abs, sign = -abs, "-"
	}
	return fmt.Sprintf("%s%d.%02d", sign, abs/100, abs%100)
}
