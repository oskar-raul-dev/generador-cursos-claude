package httpin

import (
	"context"
	"net/http"
	"strings"
	"time"

	"hexorders/internal/application"
)

// TokenVerifier lo implementa el adaptador de seguridad: firma y fecha del JWT. Es una interfaz
// del borde de entrada, no un puerto del núcleo: el núcleo nunca ve un token.
type TokenVerifier interface {
	Verify(token string) (TokenClaims, error)
}

type TokenClaims struct {
	Subject   string
	Email     string
	Role      string
	TokenID   string
	ExpiresAt time.Time
}

type ctxKey int

const (
	ctxActor ctxKey = iota
	ctxToken
)

func actorFrom(ctx context.Context) application.Actor {
	a, _ := ctx.Value(ctxActor).(application.Actor)
	return a
}

func tokenFrom(ctx context.Context) TokenClaims {
	t, _ := ctx.Value(ctxToken).(TokenClaims)
	return t
}

func isPublic(r *http.Request) bool {
	if r.Method == http.MethodOptions {
		return true
	}
	if r.Method == http.MethodGet && r.URL.Path == "/health" {
		return true
	}
	return r.Method == http.MethodPost && r.URL.Path == "/api/v1/auth/login"
}

// authenticate verifica el bearer (firma, fecha) y la revocación por jti, y deja en el contexto
// un Actor de aplicación. Ninguna regla de "puede ver este pedido" vive aquí.
func authenticate(verifier TokenVerifier, revocations application.TokenRevocationStore, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if isPublic(r) {
			next.ServeHTTP(w, r)
			return
		}
		header := r.Header.Get("Authorization")
		if !strings.HasPrefix(header, "Bearer ") {
			handleError(w, r, unauthenticated{"UNAUTHENTICATED"})
			return
		}
		claims, err := verifier.Verify(strings.TrimPrefix(header, "Bearer "))
		if err != nil || claims.TokenID == "" {
			handleError(w, r, unauthenticated{"UNAUTHENTICATED"})
			return
		}
		revoked, err := revocations.IsRevoked(r.Context(), claims.TokenID)
		if err != nil {
			handleError(w, r, err)
			return
		}
		if revoked {
			handleError(w, r, unauthenticated{"TOKEN_REVOKED"})
			return
		}
		actor := application.Actor{ID: claims.Subject, Email: claims.Email, Role: application.Role(claims.Role)}
		ctx := context.WithValue(r.Context(), ctxActor, actor)
		ctx = context.WithValue(ctx, ctxToken, claims)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// cors permite al frontend del taller 02 hablar desde otro origen.
func cors(origin string, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("Access-Control-Allow-Origin", origin)
		h.Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		h.Set("Access-Control-Allow-Headers", "Authorization, Content-Type, Idempotency-Key, Accept")
		h.Set("Access-Control-Expose-Headers", "Location, Idempotent-Replay")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}
