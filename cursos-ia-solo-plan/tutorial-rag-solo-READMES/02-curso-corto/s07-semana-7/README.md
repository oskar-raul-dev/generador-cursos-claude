# Semana 7 — Recuperación híbrida

**5.5 h totales · Objetivo: búsqueda que combine dense + sparse**

## Resumen

Dense retrieval (embeddings) es excelente para semántica pero falla con códigos exactos. Sparse (búsqueda textual) es brutal con exactitud pero falla con semántica.

Híbrido combina ambos usando Reciprocal Rank Fusion (RRF) sin normalizar puntajes.

## Estructura de la semana

### Sesión 1 — Teoría (1.5 h)

Dense: "pedir días libres" y "solicitar vacaciones" están próximos. Sparse: "ISO-27001" se encuentra porque la palabra existe.

Dense falla con "¿cómo obtengo licencia?" (no recupera "solicitar vacaciones"). Sparse falla con códigos diluidos.

RRF: fusionar rankings de dos métodos sin normalizar puntajes.

### Sesión 2 — Laboratorio (1.5 h)

Diseñás consultas que rompen cada método:
- "¿cómo solicito mis días libres?" → Falla con sparse
- "Política ISO-27001 sección 4.2" → Falla con dense

Ejecutás con denso, sparse, híbrido.

### Sesión 3 — Proyecto (2.5 h)

Implementás búsqueda textual (índice simple o PostgreSQL). Implementás RRF. Sistema ahora soporta: `"dense"`, `"sparse"`, `"hybrid"`.

Comparás los tres sobre consultas de prueba.

## Criterio de finalización

Muestrás un caso donde híbrido recupera algo que dense o sparse solos no recuperan.

## Contenidos de cada carpeta

```
s07-semana-7/
├── sesion-01-teoria/
│   └── README.md           # Dense vs sparse, RRF
├── sesion-02-laboratorio/
│   └── README.md           # Consultas que rompen cada método
└── sesion-03-proyecto/
    └── README.md           # Búsqueda textual, RRF, modo híbrido
```

## Siguiente paso

Avanzás a Semana 8 con búsqueda híbrida. Ahora le agregás reranking y conversación.
