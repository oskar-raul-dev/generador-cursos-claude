// G8 (Fase 19): pricing atiende también por TLS mutuo en el 8443. Quien llegue por ahí presenta un
// certificado de cliente firmado por la CA del laboratorio, o la conexión se corta en el saludo, antes de
// llegar a ningún manejador. El 8080 sigue en HTTP plano: lo usan la puerta, las sondas y Prometheus.
package main

import (
	"crypto/tls"
	"crypto/x509"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"sync"
	"time"
)

// certReloader lee el certificado del servidor de sus archivos y lo vuelve a leer cuando cambian: el
// Secret que escribe cert-manager se renueva, y el kubelet actualiza los archivos montados sin reiniciar
// el pod. Sin esto, pricing serviría el certificado viejo hasta su próximo reinicio.
type certReloader struct {
	certFile, keyFile string
	mu                sync.Mutex
	cert              *tls.Certificate
	modTime           time.Time
}

func (c *certReloader) get(*tls.ClientHelloInfo) (*tls.Certificate, error) {
	info, err := os.Stat(c.certFile)
	if err != nil {
		return nil, err
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.cert == nil || info.ModTime().After(c.modTime) {
		cert, err := tls.LoadX509KeyPair(c.certFile, c.keyFile)
		if err != nil {
			return nil, err
		}
		c.cert, c.modTime = &cert, info.ModTime()
		slog.Info("certificado del servidor cargado", "file", c.certFile)
	}
	return c.cert, nil
}

// mtlsServer arma el servidor del 8443 si están las tres variables; si falta alguna, no hay mTLS (G0–G7).
func mtlsServer(handler http.Handler) (*http.Server, error) {
	certFile, keyFile, caFile := os.Getenv("TLS_CERT_FILE"), os.Getenv("TLS_KEY_FILE"), os.Getenv("TLS_CLIENT_CA_FILE")
	if certFile == "" || keyFile == "" || caFile == "" {
		return nil, nil
	}
	caPEM, err := os.ReadFile(caFile)
	if err != nil {
		return nil, err
	}
	clientCAs := x509.NewCertPool()
	if !clientCAs.AppendCertsFromPEM(caPEM) {
		return nil, errors.New("sin certificados de CA en " + caFile)
	}
	reloader := &certReloader{certFile: certFile, keyFile: keyFile}
	if _, err := reloader.get(nil); err != nil {
		return nil, fmt.Errorf("certificado del servidor: %w", err)
	}
	port := os.Getenv("TLS_PORT")
	if port == "" {
		port = "8443"
	}
	return &http.Server{
		Addr:    ":" + port,
		Handler: handler,
		TLSConfig: &tls.Config{
			MinVersion:     tls.VersionTLS12,
			GetCertificate: reloader.get,
			// El cliente presenta certificado, y tiene que estar firmado por la CA del laboratorio.
			ClientAuth: tls.RequireAndVerifyClientCert,
			ClientCAs:  clientCAs,
		},
		// Los saludos fallidos (sin certificado, CA desconocida) van al log como advertencia, en JSON.
		ErrorLog: slog.NewLogLogger(slog.Default().Handler(), slog.LevelWarn),
	}, nil
}
