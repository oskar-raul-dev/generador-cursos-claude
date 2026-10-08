// Package security emite y verifica JWT HS256 y compara contraseñas bcrypt.
package security

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"hexorders/internal/application"
	"hexorders/internal/infrastructure/inbound/httpin"
)

type claims struct {
	Email string `json:"email"`
	Role  string `json:"role"`
	jwt.RegisteredClaims
}

// JWT implementa el puerto TokenIssuer (para Login) y la interfaz TokenVerifier del borde HTTP.
type JWT struct {
	secret []byte
	ttl    time.Duration
	clock  application.Clock
}

func NewJWT(secret string, ttl time.Duration, clock application.Clock) JWT {
	return JWT{secret: []byte(secret), ttl: ttl, clock: clock}
}

func (j JWT) Issue(user application.User) (application.IssuedToken, error) {
	now := j.clock.Now()
	expiresAt := now.Add(j.ttl)
	buf := make([]byte, 16)
	if _, err := rand.Read(buf); err != nil {
		return application.IssuedToken{}, err
	}
	jti := hex.EncodeToString(buf)
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims{
		Email: user.Email, Role: string(user.Role),
		RegisteredClaims: jwt.RegisteredClaims{
			Subject: user.ID, ID: jti,
			IssuedAt: jwt.NewNumericDate(now), ExpiresAt: jwt.NewNumericDate(expiresAt),
		},
	})
	value, err := token.SignedString(j.secret)
	if err != nil {
		return application.IssuedToken{}, err
	}
	return application.IssuedToken{Value: value, TokenID: jti, ExpiresAt: expiresAt, ExpiresInSeconds: int64(j.ttl.Seconds())}, nil
}

func (j JWT) Verify(token string) (httpin.TokenClaims, error) {
	var c claims
	parsed, err := jwt.ParseWithClaims(token, &c, func(t *jwt.Token) (any, error) { return j.secret, nil },
		jwt.WithValidMethods([]string{"HS256"}), jwt.WithExpirationRequired())
	if err != nil {
		return httpin.TokenClaims{}, err
	}
	if !parsed.Valid || c.Subject == "" || c.ID == "" {
		return httpin.TokenClaims{}, errors.New("invalid token")
	}
	return httpin.TokenClaims{Subject: c.Subject, Email: c.Email, Role: c.Role, TokenID: c.ID, ExpiresAt: c.ExpiresAt.Time}, nil
}
