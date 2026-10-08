package application

import (
	"context"
	"time"

	"hexorders/internal/domain"
)

// Los puertos de salida: lo que el núcleo necesita, en su vocabulario. En Go la interfaz se
// declara junto a quien la consume y el adaptador la satisface sin declararlo. Todas las
// operaciones con I/O reciben context.Context como primer parámetro: cancelación, deadline y,
// dentro de una unidad de trabajo, la transacción en curso (el adaptador la extrae del contexto).

type User struct {
	ID           string
	Email        string
	PasswordHash string
	Role         Role
}

type Users interface {
	FindByEmail(ctx context.Context, email string) (*User, error)
	FindByID(ctx context.Context, id string) (*User, error)
}

type PasswordHasher interface {
	Matches(rawPassword, hash string) bool
}

type IssuedToken struct {
	Value            string
	TokenID          string
	ExpiresAt        time.Time
	ExpiresInSeconds int64
}

type TokenIssuer interface {
	Issue(user User) (IssuedToken, error)
}

type TokenRevocationStore interface {
	Revoke(ctx context.Context, tokenID string, ttl time.Duration) error
	IsRevoked(ctx context.Context, tokenID string) (bool, error)
}

// Products es el catálogo. Ni pgx ni Mongo asoman: la parte 3 cambia la implementación y nada más.
type Products interface {
	Find(ctx context.Context, sku string) (*domain.Product, error)
	Exists(ctx context.Context, sku string) (bool, error)
	List(ctx context.Context, page PageRequest) (Page[domain.Product], error)
	Save(ctx context.Context, p domain.Product) error
}

// Inventory: Reserve descuenta todas las líneas o devuelve InsufficientInventory; la atomicidad
// la da la unidad de trabajo que rodea al caso de uso.
type Inventory interface {
	AvailableFor(ctx context.Context, skus []string) (map[string]int, error)
	Initialize(ctx context.Context, sku string, quantity int) error
	Reserve(ctx context.Context, orderID string, lines []domain.OrderLine) error
	Release(ctx context.Context, orderID string) error
}

type Orders interface {
	Find(ctx context.Context, id string) (*domain.Order, error)
	Save(ctx context.Context, o *domain.Order) error
	List(ctx context.Context, customerID string, page PageRequest) (Page[*domain.Order], error) // customerID "" = todos
}

type PaymentGateway interface {
	Authorize(ctx context.Context, operationID string, amount domain.Money) (domain.Payment, error)
}

type Payments interface {
	Record(ctx context.Context, orderID string, p domain.Payment, amount domain.Money) error
}

type StoredResponse struct {
	RequestHash string
	Status      int
	Body        string
}

// IdempotencyStore: la clave se persiste con el efecto, en la misma transacción.
type IdempotencyStore interface {
	Find(ctx context.Context, actorID, key string) (*StoredResponse, error)
	Save(ctx context.Context, actorID, key, requestHash string, status int, body string) error
}

type PendingPublications interface {
	Add(ctx context.Context, e domain.Event) error
	NextBatch(ctx context.Context, size int) ([]domain.Event, error)
	MarkPublished(ctx context.Context, eventID string) error
}

type Notifier interface {
	Notify(ctx context.Context, e domain.Event, recipient string) error
}

type Notification struct {
	ID        string
	OrderID   string
	Type      string
	Recipient string
	CreatedAt time.Time
}

type Notifications interface {
	List(ctx context.Context, orderID string, page PageRequest) (Page[Notification], error) // orderID "" = todas
}

// UnitOfWork: "ejecuta esto y confirma todo o nada". El ctx que recibe fn lleva la transacción;
// los adaptadores la extraen de ahí. El caso de uso no la ve.
type UnitOfWork interface {
	Run(ctx context.Context, fn func(ctx context.Context) error) error
}

type IDGenerator interface {
	Next() string
}

type Clock interface {
	Now() time.Time
}
