package postgres

import (
	"encoding/base64"
	"strings"
	"time"
)

// Cursores opacos: el cliente los devuelve tal cual; solo el adaptador sabe qué llevan dentro.
// Un cursor ilegible se trata como "primera página".

func encodeCursor(raw string) *string {
	s := base64.RawURLEncoding.EncodeToString([]byte(raw))
	return &s
}

func decodeCursor(cursor string) string {
	if cursor == "" {
		return ""
	}
	raw, err := base64.RawURLEncoding.DecodeString(cursor)
	if err != nil {
		return ""
	}
	return string(raw)
}

func encodeTimeCursor(ts time.Time, id string) *string {
	return encodeCursor(ts.UTC().Format(time.RFC3339Nano) + "|" + id)
}

func decodeTimeCursor(cursor string) (time.Time, string, bool) {
	raw := decodeCursor(cursor)
	sep := strings.IndexByte(raw, '|')
	if sep < 0 {
		return time.Time{}, "", false
	}
	ts, err := time.Parse(time.RFC3339Nano, raw[:sep])
	if err != nil {
		return time.Time{}, "", false
	}
	return ts, raw[sep+1:], true
}
