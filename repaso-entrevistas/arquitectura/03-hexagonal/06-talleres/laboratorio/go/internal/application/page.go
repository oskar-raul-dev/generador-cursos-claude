package application

const (
	MaxLimit     = 100
	DefaultLimit = 20
)

// Page es una página con cursor opaco (nil en la última). El cursor lo fabrica y lo lee el adaptador.
type Page[T any] struct {
	Items      []T
	NextCursor *string
}

func MapPage[T, R any](p Page[T], fn func(T) R) Page[R] {
	items := make([]R, 0, len(p.Items))
	for _, it := range p.Items {
		items = append(items, fn(it))
	}
	return Page[R]{Items: items, NextCursor: p.NextCursor}
}

type PageRequest struct {
	Cursor string
	Limit  int
}

// NewPageRequest acota el tamaño aunque el cliente pida más (decisión del contrato).
func NewPageRequest(cursor string, limit int) PageRequest {
	if limit < 1 {
		limit = DefaultLimit
	}
	if limit > MaxLimit {
		limit = MaxLimit
	}
	return PageRequest{Cursor: cursor, Limit: limit}
}
