package application

import (
	"context"

	"hexorders/internal/domain"
)

type ProductWithStock struct {
	Product domain.Product
	Stock   int
}

// ListProducts compone catálogo + stock: dos puertos, dos unidades de consistencia (y desde la
// parte 3, dos bases). La composición ocurre aquí, no con un JOIN.
type ListProducts struct {
	Products  Products
	Inventory Inventory
}

func (uc ListProducts) Execute(ctx context.Context, page PageRequest) (Page[ProductWithStock], error) {
	catalog, err := uc.Products.List(ctx, page)
	if err != nil {
		return Page[ProductWithStock]{}, err
	}
	skus := make([]string, 0, len(catalog.Items))
	for _, p := range catalog.Items {
		skus = append(skus, p.SKU)
	}
	stock, err := uc.Inventory.AvailableFor(ctx, skus)
	if err != nil {
		return Page[ProductWithStock]{}, err
	}
	return MapPage(catalog, func(p domain.Product) ProductWithStock {
		return ProductWithStock{Product: p, Stock: stock[p.SKU]}
	}), nil
}

type GetProduct struct {
	Products  Products
	Inventory Inventory
}

func (uc GetProduct) Execute(ctx context.Context, sku string) (ProductWithStock, error) {
	p, err := uc.Products.Find(ctx, sku)
	if err != nil {
		return ProductWithStock{}, err
	}
	if p == nil {
		return ProductWithStock{}, NotFound{Kind: "PRODUCT", ID: sku}
	}
	stock, err := uc.Inventory.AvailableFor(ctx, []string{sku})
	if err != nil {
		return ProductWithStock{}, err
	}
	return ProductWithStock{Product: *p, Stock: stock[sku]}, nil
}

// CreateProduct: alta de catálogo e inventario inicial, solo para operator.
type CreateProduct struct {
	Products   Products
	Inventory  Inventory
	UnitOfWork UnitOfWork
}

func (uc CreateProduct) Execute(ctx context.Context, actor Actor, sku, name string, unitPrice domain.Money, stock int) (ProductWithStock, error) {
	if err := actor.RequireOperator(); err != nil {
		return ProductWithStock{}, err
	}
	product, err := domain.NewProduct(sku, name, unitPrice)
	if err != nil {
		return ProductWithStock{}, err
	}
	err = uc.UnitOfWork.Run(ctx, func(ctx context.Context) error {
		exists, err := uc.Products.Exists(ctx, product.SKU)
		if err != nil {
			return err
		}
		if exists {
			return ProductAlreadyExists{SKU: product.SKU}
		}
		if err := uc.Products.Save(ctx, product); err != nil {
			return err
		}
		return uc.Inventory.Initialize(ctx, product.SKU, stock)
	})
	if err != nil {
		return ProductWithStock{}, err
	}
	return ProductWithStock{Product: product, Stock: stock}, nil
}
