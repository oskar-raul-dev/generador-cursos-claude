package application

import (
	"context"
	"time"
)

// Login: usuario + contraseña → token. La comparación y el formato del token son puertos.
type Login struct {
	Users  Users
	Hasher PasswordHasher
	Tokens TokenIssuer
}

func (uc Login) Execute(ctx context.Context, email, password string) (IssuedToken, error) {
	// Mismo error exista o no el correo: no se revela quién tiene cuenta.
	user, err := uc.Users.FindByEmail(ctx, email)
	if err != nil {
		return IssuedToken{}, err
	}
	if user == nil || !uc.Hasher.Matches(password, user.PasswordHash) {
		return IssuedToken{}, ErrInvalidCredentials
	}
	return uc.Tokens.Issue(*user)
}

// Logout revoca el token presentado hasta que expire por sí solo.
type Logout struct {
	Revocations TokenRevocationStore
	Clock       Clock
}

func (uc Logout) Execute(ctx context.Context, tokenID string, expiresAt time.Time) error {
	remaining := expiresAt.Sub(uc.Clock.Now())
	if remaining <= 0 {
		return nil // ya expiró: no hay nada que recordar
	}
	return uc.Revocations.Revoke(ctx, tokenID, remaining)
}
