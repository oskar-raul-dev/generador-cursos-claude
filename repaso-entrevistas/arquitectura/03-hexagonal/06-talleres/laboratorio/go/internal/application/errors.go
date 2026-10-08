package application

import "errors"

// Errores de aplicación: existencia, permisos, credenciales, idempotencia.

var (
	ErrAccessDenied         = errors.New("actor lacks the required capability")
	ErrInvalidCredentials   = errors.New("invalid credentials")
	ErrIdempotencyKeyReused = errors.New("Idempotency-Key reused with a different payload")
)

// NotFound: "no existe" y "no es tuyo" se expresan igual; el borde responde 404 sin revelar existencia.
type NotFound struct {
	Kind string // "PRODUCT" | "ORDER"
	ID   string
}

func (e NotFound) Error() string { return e.Kind + " not found: " + e.ID }

type ProductAlreadyExists struct{ SKU string }

func (e ProductAlreadyExists) Error() string { return e.SKU + " already exists" }
