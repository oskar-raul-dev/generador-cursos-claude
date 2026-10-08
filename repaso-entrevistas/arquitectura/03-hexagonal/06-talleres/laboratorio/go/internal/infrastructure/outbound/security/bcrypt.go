package security

import "golang.org/x/crypto/bcrypt"

// Bcrypt verifica los hashes $2y$10$… de la semilla.
type Bcrypt struct{}

func (Bcrypt) Matches(rawPassword, hash string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(rawPassword)) == nil
}
