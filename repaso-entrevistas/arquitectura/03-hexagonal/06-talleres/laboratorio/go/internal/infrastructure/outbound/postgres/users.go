package postgres

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"

	"hexorders/internal/application"
)

type Users struct{ DB *DB }

func (u Users) FindByEmail(ctx context.Context, email string) (*application.User, error) {
	return u.find(ctx, "SELECT id::text, email, password_hash, role FROM users WHERE email = $1", email)
}

func (u Users) FindByID(ctx context.Context, id string) (*application.User, error) {
	return u.find(ctx, "SELECT id::text, email, password_hash, role FROM users WHERE id = $1::uuid", id)
}

func (u Users) find(ctx context.Context, sql string, arg any) (*application.User, error) {
	var user application.User
	var role string
	err := u.DB.Q(ctx).QueryRow(ctx, sql, arg).Scan(&user.ID, &user.Email, &user.PasswordHash, &role)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	user.Role = application.Role(strings.ToUpper(role))
	return &user, nil
}
