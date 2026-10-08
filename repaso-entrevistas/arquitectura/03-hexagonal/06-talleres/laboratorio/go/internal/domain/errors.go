package domain

import (
	"errors"
	"fmt"
)

// Errores de negocio del dominio: rechazos esperados con nombre propio. El borde les pone código
// HTTP con errors.As; aquí no hay números.

var ErrEmptyOrder = errors.New("an order must have at least one line")

type OrderNotPayable struct{ Status OrderStatus }

func (e OrderNotPayable) Error() string { return "order is " + string(e.Status) }

type OrderNotCancellable struct{ Status OrderStatus }

func (e OrderNotCancellable) Error() string { return "order is " + string(e.Status) }

// InsufficientInventory la devuelve el adaptador de inventario al primer faltante; la unidad de
// trabajo revierte el resto.
type InsufficientInventory struct {
	SKU       string
	Requested int
	Available int
	LineIndex int
}

func (e InsufficientInventory) Error() string {
	return fmt.Sprintf("%s: requested %d, available %d", e.SKU, e.Requested, e.Available)
}
