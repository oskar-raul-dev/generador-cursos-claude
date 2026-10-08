package domain

import (
	"fmt"
	"regexp"
)

var skuPattern = regexp.MustCompile(`^SKU-[0-9]{3,}$`)

// Product es el catálogo: qué se vende y a qué precio. El stock vive en el inventario, que es
// otra unidad de consistencia (y, en la parte 3, otra base).
type Product struct {
	SKU       string
	Name      string
	UnitPrice Money
}

func NewProduct(sku, name string, unitPrice Money) (Product, error) {
	if !skuPattern.MatchString(sku) {
		return Product{}, fmt.Errorf("invalid sku: %q", sku)
	}
	if name == "" {
		return Product{}, fmt.Errorf("empty product name")
	}
	return Product{SKU: sku, Name: name, UnitPrice: unitPrice}, nil
}
