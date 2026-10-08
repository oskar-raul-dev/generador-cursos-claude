package application

import (
	"context"
	"errors"
	"maps"
	"strconv"
	"strings"
	"testing"
	"time"

	"hexorders/internal/domain"
)

// El caso de uso con dobles fieles a los puertos y una unidad de trabajo de pruebas que restaura
// los fakes si fn devuelve error: lo que DB.Run hace, reducido a lo observable.

type fakeProducts struct{ data map[string]domain.Product }

func (f *fakeProducts) Find(_ context.Context, sku string) (*domain.Product, error) {
	if p, ok := f.data[sku]; ok {
		return &p, nil
	}
	return nil, nil
}
func (f *fakeProducts) Exists(_ context.Context, sku string) (bool, error) { _, ok := f.data[sku]; return ok, nil }
func (f *fakeProducts) List(context.Context, PageRequest) (Page[domain.Product], error) {
	return Page[domain.Product]{}, nil
}
func (f *fakeProducts) Save(_ context.Context, p domain.Product) error { f.data[p.SKU] = p; return nil }

type fakeInventory struct{ available map[string]int }

func (f *fakeInventory) AvailableFor(_ context.Context, skus []string) (map[string]int, error) {
	out := map[string]int{}
	for _, s := range skus {
		out[s] = f.available[s]
	}
	return out, nil
}
func (f *fakeInventory) Initialize(_ context.Context, sku string, q int) error { f.available[sku] = q; return nil }
func (f *fakeInventory) Reserve(_ context.Context, _ string, lines []domain.OrderLine) error {
	// como el adaptador real: descuenta línea a línea y devuelve error al primer faltante
	for i, l := range lines {
		have := f.available[l.SKU]
		if have < l.Quantity {
			return domain.InsufficientInventory{SKU: l.SKU, Requested: l.Quantity, Available: have, LineIndex: i}
		}
		f.available[l.SKU] = have - l.Quantity
	}
	return nil
}
func (f *fakeInventory) Release(context.Context, string) error { return nil }

type fakeOrders struct{ data map[string]*domain.Order }

func (f *fakeOrders) Find(_ context.Context, id string) (*domain.Order, error) { return f.data[id], nil }
func (f *fakeOrders) Save(_ context.Context, o *domain.Order) error        { f.data[o.ID()] = o; return nil }
func (f *fakeOrders) List(context.Context, string, PageRequest) (Page[*domain.Order], error) {
	return Page[*domain.Order]{}, nil
}

type fakeIdempotency struct{ data map[string]StoredResponse }

func (f *fakeIdempotency) Find(_ context.Context, actorID, key string) (*StoredResponse, error) {
	if s, ok := f.data[actorID+":"+key]; ok {
		return &s, nil
	}
	return nil, nil
}
func (f *fakeIdempotency) Save(_ context.Context, actorID, key, hash string, status int, body string) error {
	f.data[actorID+":"+key] = StoredResponse{RequestHash: hash, Status: status, Body: body}
	return nil
}

// snapshotUnitOfWork toma una foto de los fakes y la restaura si fn falla.
type snapshotUnitOfWork struct {
	orders    *fakeOrders
	inventory *fakeInventory
	keys      *fakeIdempotency
}

func (u snapshotUnitOfWork) Run(ctx context.Context, fn func(ctx context.Context) error) error {
	o, i, k := maps.Clone(u.orders.data), maps.Clone(u.inventory.available), maps.Clone(u.keys.data)
	if err := fn(ctx); err != nil {
		u.orders.data, u.inventory.available, u.keys.data = o, i, k
		return err
	}
	return nil
}

type fixedClock struct{}

func (fixedClock) Now() time.Time { return time.Date(2026, 9, 27, 12, 0, 0, 0, time.UTC) }

type seqIDs struct{ n int }

func (s *seqIDs) Next() string { s.n++; return "order-" + strconv.Itoa(s.n) }

var ana = Actor{ID: "11111111-1111-4111-8111-111111111111", Email: "ana@hex.local", Role: RoleCustomer}

func setup() (CreateOrder, *fakeInventory, *fakeOrders, *fakeIdempotency) {
	products := &fakeProducts{data: map[string]domain.Product{
		"SKU-001": {SKU: "SKU-001", Name: "Mechanical keyboard", UnitPrice: domain.MustUSD("49.90")},
		"SKU-004": {SKU: "SKU-004", Name: "Webcam", UnitPrice: domain.MustUSD("59.00")},
	}}
	inventory := &fakeInventory{available: map[string]int{"SKU-001": 20, "SKU-004": 0}}
	orders := &fakeOrders{data: map[string]*domain.Order{}}
	keys := &fakeIdempotency{data: map[string]StoredResponse{}}
	uc := CreateOrder{Products: products, Inventory: inventory, Orders: orders, Idempotency: keys,
		IDs: &seqIDs{}, Clock: fixedClock{}, UnitOfWork: snapshotUnitOfWork{orders, inventory, keys}}
	return uc, inventory, orders, keys
}

func command(key string, lines ...LineRequest) CreateOrderCommand {
	parts := make([]string, 0, len(lines))
	for _, l := range lines {
		parts = append(parts, l.SKU+":"+strconv.Itoa(l.Quantity))
	}
	return CreateOrderCommand{Actor: ana, IdempotencyKey: key, RequestHash: strings.Join(parts, ","), Lines: lines}
}

func TestCreateOrderReservesAndRemembersKey(t *testing.T) {
	uc, inventory, orders, _ := setup()
	res, err := uc.Execute(context.Background(), command("key-0001", LineRequest{"SKU-001", 2}))
	if err != nil {
		t.Fatal(err)
	}
	if res.Replayed || res.Order.Total().Text() != "99.80" || inventory.available["SKU-001"] != 18 || orders.data[res.Order.ID()] == nil {
		t.Fatalf("unexpected result %+v stock=%d", res, inventory.available["SKU-001"])
	}
}

func TestCreateOrderReplaysSameKeySameBody(t *testing.T) {
	uc, inventory, _, _ := setup()
	first, _ := uc.Execute(context.Background(), command("key-0002", LineRequest{"SKU-001", 2}))
	again, err := uc.Execute(context.Background(), command("key-0002", LineRequest{"SKU-001", 2}))
	if err != nil || !again.Replayed || again.Order.ID() != first.Order.ID() || inventory.available["SKU-001"] != 18 {
		t.Fatalf("replay failed: %v %+v", err, again)
	}
}

func TestCreateOrderRejectsSameKeyDifferentBody(t *testing.T) {
	uc, _, _, _ := setup()
	_, _ = uc.Execute(context.Background(), command("key-0003", LineRequest{"SKU-001", 1}))
	if _, err := uc.Execute(context.Background(), command("key-0003", LineRequest{"SKU-001", 3})); !errors.Is(err, ErrIdempotencyKeyReused) {
		t.Fatalf("want ErrIdempotencyKeyReused, got %v", err)
	}
}

func TestInsufficientInventoryLeavesNothingBehind(t *testing.T) {
	uc, inventory, orders, keys := setup()
	_, err := uc.Execute(context.Background(), command("key-0004", LineRequest{"SKU-001", 1}, LineRequest{"SKU-004", 1}))
	var insufficient domain.InsufficientInventory
	if !errors.As(err, &insufficient) {
		t.Fatalf("want InsufficientInventory, got %v", err)
	}
	// el pedido se guardó antes de reservar; lo que lo deshace es la unidad de trabajo
	if inventory.available["SKU-001"] != 20 || len(orders.data) != 0 || len(keys.data) != 0 {
		t.Fatalf("rollback failed: stock=%d orders=%d keys=%d", inventory.available["SKU-001"], len(orders.data), len(keys.data))
	}
}
