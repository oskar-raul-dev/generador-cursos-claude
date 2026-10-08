package httpin

import (
	"crypto/sha256"
	"encoding/hex"
	"net/http"
)

// Regla del borde HTTP: la operación exige la cabecera del contrato, con longitud acotada.
func requireIdempotencyKey(r *http.Request) (string, error) {
	key := r.Header.Get("Idempotency-Key")
	if key == "" {
		return "", errMissingIdempotencyKey
	}
	if len(key) < 8 || len(key) > 128 {
		return "", validationFailed{[]fieldError{{Field: "Idempotency-Key", Message: "must be between 8 and 128 characters"}}}
	}
	return key, nil
}

func requestHash(canonical string) string {
	sum := sha256.Sum256([]byte(canonical))
	return hex.EncodeToString(sum[:])
}
