// Las pruebas del almacén de pricing (G3, B-12). Las mismas pruebas corren contra los dos motores:
//
//	go test ./...                         contra SQLite, en una carpeta temporal
//	TEST_DATABASE=postgres go test ./...  contra un Postgres de verdad, con Testcontainers
//
// Testcontainers necesita el socket del motor; la tarea `task test:pricing` lo monta (Fase 12).
package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
)

// postgres:18.6, la misma imagen del cluster.
const postgresImage = "postgres@sha256:5a5a84b19854a9ffaa54082c166ff4ec27473a361e496e5ea167f298f2da9722"

var testDB *sql.DB

// TestMain abre el motor una vez para todas las pruebas: un contenedor por corrida, no por prueba.
func TestMain(m *testing.M) {
	ctx := context.Background()
	if os.Getenv("TEST_DATABASE") == "postgres" {
		container, err := postgres.Run(ctx, postgresImage,
			postgres.WithDatabase("pricing"), postgres.WithUsername("pricing"), postgres.WithPassword("pricing"),
			postgres.BasicWaitStrategies())
		if err != nil {
			log.Fatalf("no arrancó Postgres: %v", err)
		}
		defer func() { _ = testcontainers.TerminateContainer(container) }()
		url, err := container.ConnectionString(ctx, "sslmode=disable")
		if err != nil {
			log.Fatal(err)
		}
		os.Setenv("DATABASE_URL", url)
	} else {
		dir, err := os.MkdirTemp("", "pricing-test")
		if err != nil {
			log.Fatal(err)
		}
		defer os.RemoveAll(dir)
		os.Setenv("DATA_DIR", dir)
	}
	db, engine, err := openStore()
	if err != nil {
		log.Fatal(err)
	}
	if err := migrate(db); err != nil {
		log.Fatal(err)
	}
	log.Printf("pruebas contra %s", engine)
	testDB = db
	code := m.Run()
	db.Close()
	os.Exit(code)
}

// newServer limpia la tabla y arma el servidor con los topes que pida la prueba.
func newServer(t *testing.T, caps map[string]int) http.Handler {
	t.Helper()
	if _, err := testDB.Exec(`DELETE FROM prices`); err != nil {
		t.Fatal(err)
	}
	s := &server{db: testDB, caps: caps}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /prices", s.listPrices)
	mux.HandleFunc("GET /prices/{sku}", s.getPrice)
	mux.HandleFunc("PUT /prices/{sku}", s.putPrice)
	return mux
}

func call(t *testing.T, h http.Handler, method, path, body string) (int, map[string]any) {
	t.Helper()
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(method, path, strings.NewReader(body)))
	var out map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &out)
	return rec.Code, out
}

func TestPutThenGet(t *testing.T) {
	h := newServer(t, nil)
	if code, _ := call(t, h, "PUT", "/prices/SKU-0003", `{"store":"DRO-007","price":21900}`); code != 200 {
		t.Fatalf("PUT: %d", code)
	}
	code, body := call(t, h, "GET", "/prices/SKU-0003?store=DRO-007", "")
	if code != 200 || body["price"] != float64(21900) {
		t.Fatalf("GET: %d %v", code, body)
	}
}

func TestPutTwiceUpdates(t *testing.T) {
	h := newServer(t, nil)
	call(t, h, "PUT", "/prices/SKU-0003", `{"store":"DRO-007","price":21900}`)
	call(t, h, "PUT", "/prices/SKU-0003", `{"store":"DRO-007","price":19900}`)
	if _, body := call(t, h, "GET", "/prices/SKU-0003?store=DRO-007", ""); body["price"] != float64(19900) {
		t.Fatalf("se esperaba 19900: %v", body)
	}
}

func TestMissingPriceIs404(t *testing.T) {
	h := newServer(t, nil)
	if code, _ := call(t, h, "GET", "/prices/SKU-9999?store=DRO-007", ""); code != 404 {
		t.Fatalf("se esperaba 404: %d", code)
	}
}

func TestNegativePriceIs400(t *testing.T) {
	h := newServer(t, nil)
	if code, _ := call(t, h, "PUT", "/prices/SKU-0003", `{"store":"DRO-007","price":-1}`); code != 400 {
		t.Fatalf("se esperaba 400: %d", code)
	}
}

func TestListIsSortedBySku(t *testing.T) {
	h := newServer(t, nil)
	call(t, h, "PUT", "/prices/SKU-0003", `{"store":"DRO-007","price":21900}`)
	call(t, h, "PUT", "/prices/SKU-0001", `{"store":"DRO-007","price":3500}`)
	call(t, h, "PUT", "/prices/SKU-0002", `{"store":"DRO-008","price":9000}`)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest("GET", "/prices?store=DRO-007", nil))
	var list []price
	_ = json.Unmarshal(rec.Body.Bytes(), &list)
	if len(list) != 2 || list[0].Sku != "SKU-0001" || list[1].Sku != "SKU-0003" {
		t.Fatalf("lista: %+v", list)
	}
}

func TestRegulatedCap(t *testing.T) {
	h := newServer(t, map[string]int{"SKU-0003": 20000})
	_, body := call(t, h, "PUT", "/prices/SKU-0003", `{"store":"DRO-007","price":21900}`)
	if body["price"] != float64(20000) || body["capped"] != true {
		t.Fatalf("tope: %v", body)
	}
}

// El contrato no le pone techo al precio: un lote hospitalario, o un cero de más al digitar, pasa de
// 2.147.483.647, el máximo de un entero de 32 bits.
func TestLargePrice(t *testing.T) {
	h := newServer(t, nil)
	code, body := call(t, h, "PUT", "/prices/SKU-0040", `{"store":"DRO-007","price":3000000000}`)
	if code != 200 {
		t.Fatalf("PUT de un precio grande: %d %v", code, body)
	}
	if _, body := call(t, h, "GET", "/prices/SKU-0040?store=DRO-007", ""); body["price"] != float64(3000000000) {
		t.Fatalf("GET: %v", body)
	}
}
