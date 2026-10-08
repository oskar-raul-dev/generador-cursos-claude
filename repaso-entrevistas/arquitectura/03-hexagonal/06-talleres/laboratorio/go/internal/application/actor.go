// Package application contiene los casos de uso y los puertos. Importa domain y la biblioteca
// estándar; nada de HTTP, pgx ni drivers.
package application

import "hexorders/internal/domain"

type Role string

const (
	RoleCustomer Role = "CUSTOMER"
	RoleOperator Role = "OPERATOR"
)

// Actor es quien ejecuta el caso de uso, ya verificado por el borde. Sin JWT ni claims crudos.
type Actor struct {
	ID    string
	Email string
	Role  Role
}

func (a Actor) IsOperator() bool { return a.Role == RoleOperator }

// CanSee es la autorización contextual: dueño u operador. Vive aquí porque un job o un consumidor
// que use el mismo caso de uso tiene que cumplirla igual.
func (a Actor) CanSee(o *domain.Order) bool { return a.IsOperator() || o.CustomerID() == a.ID }

func (a Actor) RequireOperator() error {
	if !a.IsOperator() {
		return ErrAccessDenied
	}
	return nil
}
