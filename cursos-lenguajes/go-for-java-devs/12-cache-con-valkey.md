# ⚡ Fase 12 — Caché con Valkey

> Go para desarrolladores Java senior · Fase 12 de 17 · **6 horas**
> Época: **Go moderno (1.25)**
> Depende de: Fase 11 · Habilita: Fase 13
> Proyectos que avanzan: **AtlasSync** (caché de lectura) · **EventRelay** (límite de tasa, idempotencia distribuida)
> Mini proyectos: `cache-aside-lab`, `stampede-lab`, `ratelimit-lab`

---

## 🎯 1. Propósito

Poner una caché es fácil. Invalidarla es el problema difícil de verdad, y es del
que va esta fase.

AtlasSync es un servicio de lectura intensiva: pocas escrituras al día, muchísimas
lecturas, y una dependencia externa que puede estar caída. Es el caso de libro
para una caché. Y sin embargo, la fase se cierra con un experimento que puede
doler: **medir cuánto gana realmente la caché aquí**. La línea base no es "sin
caché": es la caché en memoria con TTL que escribiste en la Fase 10, que funciona
sorprendentemente bien.

A veces la respuesta es *"poco, y acabas de añadir un servicio al `compose.yaml`"*,
y esa es una lección mejor que la contraria.

De paso, descubres que la mitad de lo que se hace con Valkey **no es caché**:
limitación de tasa, idempotencia distribuida y bloqueos — este último con una
advertencia grande sobre corrección que hay que decir con todas las letras.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Valkey corre en el `compose.yaml` y AtlasSync cachea países y tipos de
      cambio con *cache-aside*.
- [ ] Las claves siguen un esquema documentado, versionado, y sabes justificarlo.
- [ ] El TTL lleva *jitter* y sabes demostrar qué pasa sin él.
- [ ] La estampida está resuelta con `singleflight` local **más** bloqueo
      distribuido, y sabes explicar por qué hacen falta los dos.
- [ ] La invalidación por etiqueta funciona: refrescar los tipos de cambio
      invalida lo que dependía de ellos.
- [ ] EventRelay limita la tasa por socio con un *token bucket* en Valkey,
      compartido entre instancias.
- [ ] `SET NX` con TTL resuelve la idempotencia del `POST /events` entre
      instancias (la deuda del ejercicio 25 de la Fase 05).
- [ ] Hay métricas de aciertos y fallos, y las has medido (B-17, B-18).
- [ ] **Tienes escrito si la caché compensó**, con números, aunque la respuesta sea
      que no.

---

## 🚫 3. Qué NO entra todavía

- Valkey como base de datos primaria → **nunca en este curso**. Se nombra en el ⚖️
  y se queda fuera.
- Streams de Valkey como bus de eventos → se nombran en el ⚖️. El outbox de la Fase
  13 es la respuesta del curso.
- Pub/Sub para invalidación entre instancias → se evalúa en §6.7 y se **rechaza**
  con motivo.
- Métricas de caché exportadas a Prometheus → Fase 14. Hoy los contadores existen y
  se consultan por un endpoint de depuración.
- Clúster de Valkey y particionado de claves → fuera del curso.
- Caché de segundo nivel de un ORM → no aplica: en Go no hay ORM con caché (Fase
  09).

---

## 🧠 4. Concepto mínimo

### Valkey, en una frase

Es el fork de Redis, nacido en 2024 cuando Redis cambió su licencia, mantenido bajo
la Linux Foundation y con los mismos comandos y el mismo protocolo. Si sabes Redis,
sabes Valkey: la compatibilidad es el punto.

```go
// El cliente del curso es valkey-go. La alternativa es redis/go-redis, que
// también habla con Valkey sin problema y tiene más años de rodaje.
//
// Diferencias que importan:
//  - valkey-go hace "pipelining" automático: agrupa comandos concurrentes de
//    distintas goroutines en un solo viaje. Con mucha concurrencia, eso es una
//    diferencia real de rendimiento, no cosmética.
//  - go-redis tiene una API más familiar para quien viene de otros clientes, y
//    muchísimo más material escrito.
//
// El curso usa valkey-go y la comparación se mide en el ejercicio 19.
client, err := valkey.NewClient(valkey.ClientOption{
	InitAddress: []string{cfg.Addr},
	// El pool, con la misma lógica que en las Fases 09 y 11.
	PipelineMultiplex: 2,
})
```

### Los tres patrones, y sus grietas

**Cache-aside (o *lazy loading*).** El que usa el 95% de los sistemas, y el que
AtlasSync usa:

```mermaid
flowchart TD
    subgraph LE["leer"]
        direction LR
        L1{"mirar caché"} -- "acierto" --> L4["devolver"]
        L1 -- "falla" --> L2["leer origen"] --> L3["guardar en caché"] --> L4
    end
    subgraph ES["escribir"]
        direction LR
        E1["escribir origen"] --> E2["INVALIDAR la clave<br/>(no actualizarla)"]
    end
    LE ~~~ ES
```

```go
func (s *Service) Country(ctx context.Context, code string) (Country, error) {
	key := s.keys.Country(code)

	if c, ok := s.cache.Get(ctx, key); ok {
		s.metrics.Hit()
		return c, nil
	}
	s.metrics.Miss()

	c, err := s.store.FindByCode(ctx, code)
	if err != nil {
		return Country{}, err
	}

	// El Set es "best effort": si la caché falla, la petición SIGUE. Una caché
	// caída degrada el rendimiento; nunca debe romper el servicio.
	if err := s.cache.Set(ctx, key, c, s.ttl()); err != nil {
		s.logger.Warn("no se pudo cachear", slog.String("key", key), slog.String("err", err.Error()))
	}
	return c, nil
}
```

**Y su condición de carrera**, que casi nadie menciona:

```mermaid
sequenceDiagram
    participant A as Goroutine A
    participant K as Caché
    participant M as Mongo
    participant B as Goroutine B
    Note over A,B: t0
    A->>K: Get: falla la caché
    A->>M: lee de Mongo
    M-->>A: población 52.000.000
    Note over A,B: t1
    B->>M: escribe población 53.000.000
    B->>K: invalida la clave
    Note over A,B: t2
    A->>K: guarda el valor VIEJO (52.000.000)
    Note over K: La caché queda con un dato obsoleto,<br/>y el TTL es lo único que lo arregla.
```

La ventana es pequeña y **existe**. Las defensas reales:

1. **TTL corto**, que acota el daño en el tiempo. Es lo que hace AtlasSync.
2. **Invalidar después de escribir, con retraso** (invalidación diferida doble):
   invalidar, escribir, y volver a invalidar unos cientos de milisegundos después.
   Feo y efectivo.
3. **Versionar la clave** con la revisión del documento, de modo que el valor viejo
   se escriba bajo una clave que ya nadie lee.

> 🧭 **Regla del proyecto.** Al escribir, se **invalida**, no se actualiza. Un
> `Set` tras la escritura parece más eficiente y amplía la ventana de carrera:
> ahora dos escritores concurrentes pueden dejar el valor del perdedor. Invalidar
> es idempotente y seguro.

**Write-through y write-behind**, brevemente y con sus riesgos:

```text
write-through: escribir caché y origen a la vez, síncrono.
   ✅ la caché nunca está obsoleta
   ❌ toda escritura paga la latencia de los dos
   ❌ y si el origen falla después de la caché, quedan desincronizados

write-behind:  escribir caché, y el origen en diferido.
   ✅ escrituras rapidísimas
   ❌ SI SE CAE EL PROCESO, SE PIERDEN DATOS. No es un matiz: es el riesgo.
   → solo es aceptable para datos que se pueden perder: contadores de vistas,
     últimos accesos, telemetría.
```

**AtlasSync no usa ninguno de los dos**, y el motivo está escrito: sus escrituras
son una ingesta diaria masiva, no escrituras interactivas. Para ese patrón, lo
correcto es invalidar en bloque al terminar la ingesta.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"pongo `@Cacheable` en el método y ya está cacheado"*. En Spring
es una anotación, la abstracción es del framework, el `CacheManager` decide el
backend, y `@CacheEvict` invalida. Funciona y se escribe en una línea.

**Qué pasa si lo aplicas aquí.** Buscas el equivalente, no lo hay, y escribes la
caché a mano. Y entonces te encuentras de frente con las cuatro decisiones que
`@Cacheable` tomaba por ti **sin que te enteraras**:

**1. La clave.** `@Cacheable("countries")` deriva la clave de los parámetros del
método con un `KeyGenerator` por defecto. ¿Sabes cuál es esa clave? ¿Incluye el
nombre de la clase? ¿Qué pasa si añades un parámetro al método? (Respuesta: la
clave cambia, la caché entera queda huérfana, y nadie lo nota.)

**2. La serialización.** ¿En qué formato se guarda? Con el `RedisTemplate` por
defecto, **serialización de Java**, que es lenta, enorme, y **acopla la caché a la
versión exacta de tus clases**: añade un campo y todo lo cacheado deja de
deserializar.

**3. El TTL.** `@Cacheable` no tiene TTL: se configura en el `CacheManager`, para
todas las cachés o por nombre. ¿Cuál tiene la tuya? ¿Lleva *jitter*? (Respuesta:
no.)

**4. Qué pasa si Redis está caído.** Por defecto, `@Cacheable` **propaga la
excepción** y tu petición falla. Hay un `CacheErrorHandler` para cambiarlo, y casi
nadie lo configura.

**Qué pensar en su lugar.** No es que `@Cacheable` esté mal: es que **esconde
cuatro decisiones de diseño que hay que tomar conscientemente**. Escribir la caché
a mano cuesta unas cien líneas y te obliga a responderlas:

```go
// La caché del curso: un tipo con las cuatro decisiones explícitas.
type Cache[T any] struct {
	client     valkey.Client
	keys       KeyBuilder      // 1. esquema de claves, versionado
	codec      Codec[T]        // 2. serialización explícita
	ttl        time.Duration   // 3. TTL con jitter
	jitter     float64
	failOpen   bool            // 4. qué pasa si Valkey está caído
	metrics    *Metrics
}
```

> 🧭 **Regla del proyecto: la caché falla abierta (*fail open*).** Si Valkey no
> responde, se lee del origen y la petición tiene éxito. Una caché es una
> optimización; convertirla en una dependencia dura significa que **has añadido un
> punto único de fallo para ganar latencia**, que es un mal negocio.
>
> La excepción son los límites de tasa y los bloqueos: ahí, fallar abierto
> significa no limitar nada. Ese caso se decide aparte y se dice en §6.6.

### El diseño de las claves: el 80% de la calidad

Y casi nunca se discute. Una clave mal diseñada hace imposible invalidar, imposible
depurar, e imposible migrar.

```go
// services/atlassync/internal/cache/keys.go

// KeyBuilder construye las claves de la caché.
//
// El esquema es:   meridian:{servicio}:{versión}:{entidad}:{identificador}
//
// Cada parte tiene su razón:
//
//  - "meridian"  → prefijo global. Permite compartir una instancia de Valkey
//                  entre varios sistemas sin colisionar, y hace que un
//                  `SCAN meridian:*` encuentre lo nuestro.
//
//  - servicio    → aísla AtlasSync de EventRelay. Sin esto, un despliegue de uno
//                  puede invalidar claves del otro por error.
//
//  - versión     → LA PARTE QUE MÁS SE OLVIDA Y MÁS SALVA. Cuando cambia la
//                  forma del valor cacheado —un campo nuevo, otro formato—, se
//                  sube la versión y TODO lo viejo queda huérfano y expira solo.
//                  Sin versión, hay que borrar a mano en producción, o peor:
//                  deserializar un valor viejo con el struct nuevo.
//
//  - entidad     → agrupa. Permite el SCAN por prefijo y da legibilidad.
//
//  - id          → normalizado: siempre en mayúsculas para los códigos ISO.
//                  "co", "CO" y "Co" TIENEN que producir la misma clave, o
//                  tienes tres entradas del mismo dato y una invalidación que
//                  solo borra una.
type KeyBuilder struct {
	service string
	version int
}

func (k KeyBuilder) Country(code string) string {
	return fmt.Sprintf("meridian:%s:v%d:country:%s",
		k.service, k.version, strings.ToUpper(code))
}

func (k KeyBuilder) RatesLatest(base string) string {
	return fmt.Sprintf("meridian:%s:v%d:rates:latest:%s",
		k.service, k.version, strings.ToUpper(base))
}

// La clave de una consulta con filtros necesita que TODOS los parámetros que
// cambian el resultado estén dentro, y en orden determinista.
//
// Si `region` y `limit` no estuvieran, dos consultas distintas compartirían
// entrada y una devolvería el resultado de la otra. Es un bug de corrección, no
// de rendimiento, y es sorprendentemente común.
func (k KeyBuilder) CountryList(region string, limit int) string {
	return fmt.Sprintf("meridian:%s:v%d:countries:region=%s:limit=%d",
		k.service, k.version, strings.ToLower(region), limit)
}
```

> ⚠️ **`KEYS` no se usa nunca en producción.** Es O(n) sobre todo el espacio de
> claves y **bloquea el servidor** mientras corre. Con un millón de claves, eso son
> cientos de milisegundos en los que Valkey no atiende a nadie. La alternativa es
> `SCAN`, que es incremental y no bloquea — y aun así, **si tu diseño necesita
> escanear para invalidar, el diseño está mal**. Por eso existe la invalidación por
> etiqueta de §6.7.

### 🩻 Esto sí funciona igual

- **El concepto de caché no cambia.** Aciertos, fallos, TTL, invalidación,
  estampida — todo tu criterio se traslada.
- **El *token bucket*** es el mismo algoritmo que implementa Bucket4j, con la misma
  matemática.
- **El cálculo de si la caché compensa** es el mismo: coste de la lectura al
  origen × tasa de fallo, frente a coste de la caché × total.
- **La invalidación sigue siendo el problema difícil**, y sigue sin tener solución
  general en ningún lenguaje.
- **Y la advertencia sobre los bloqueos distribuidos** es la misma que se le hace a
  Redisson: un bloqueo con TTL no garantiza exclusión mutua. No es un problema de
  la librería ni del lenguaje.

---

## 🛠️ 5. CLI de la fase

```bash
make up
docker compose exec valkey valkey-cli

# Los comandos que más se usan, con lo que hace cada bandera.
docker compose exec valkey valkey-cli PING
docker compose exec valkey valkey-cli GET 'meridian:atlassync:v1:country:COL'
docker compose exec valkey valkey-cli TTL 'meridian:atlassync:v1:country:COL'
#   TTL devuelve:  -2 = la clave no existe
#                  -1 = existe y NO tiene expiración  ← casi siempre un bug
#                  N  = segundos que le quedan

# SCAN, no KEYS. Es incremental: devuelve un cursor y un lote, y no bloquea.
docker compose exec valkey valkey-cli --scan --pattern 'meridian:atlassync:v1:*' | head -20

# Contar claves por prefijo sin bloquear el servidor.
docker compose exec valkey valkey-cli --scan --pattern 'meridian:*' | wc -l

# Las estadísticas que importan: aciertos y fallos acumulados del servidor.
docker compose exec valkey valkey-cli INFO stats | grep -E 'keyspace_(hits|misses)'
docker compose exec valkey valkey-cli INFO memory | grep -E 'used_memory_human|maxmemory'

# La tasa de acierto global, de un vistazo:
docker compose exec valkey valkey-cli INFO stats | \
  awk -F: '/keyspace_hits/{h=$2} /keyspace_misses/{m=$2} END{printf "acierto: %.1f%%\n", 100*h/(h+m)}'

# MONITOR muestra CADA comando que llega, en vivo. Es la herramienta de
# diagnóstico definitiva y ⚠️ degrada el servidor: solo en desarrollo, y poco rato.
docker compose exec valkey valkey-cli MONITOR

# Los comandos lentos. Por defecto registra los que superan 10 ms.
docker compose exec valkey valkey-cli SLOWLOG GET 10
docker compose exec valkey valkey-cli SLOWLOG RESET

# La política de expulsión cuando se llena la memoria. POR DEFECTO es 'noeviction',
# que significa que las ESCRITURAS EMPIEZAN A FALLAR al llenarse.
# Para una caché pura, allkeys-lru es lo correcto.
docker compose exec valkey valkey-cli CONFIG GET maxmemory-policy
docker compose exec valkey valkey-cli CONFIG SET maxmemory-policy allkeys-lru
docker compose exec valkey valkey-cli CONFIG SET maxmemory 256mb

# Borrar TODO (solo en desarrollo). FLUSHALL es síncrono y bloquea; ASYNC no.
docker compose exec valkey valkey-cli FLUSHALL ASYNC

# El banco de pruebas incluido, para tener una línea base de tu máquina.
docker compose exec valkey valkey-benchmark -t get,set -n 100000 -q

# Latencia del servidor, para distinguir "Valkey es lento" de "la red es lenta".
docker compose exec valkey valkey-cli --latency
docker compose exec valkey valkey-cli --latency-history

# Las claves que más memoria ocupan.
docker compose exec valkey valkey-cli --bigkeys

# Y los benchmarks de la fase.
go test -run '^$' -bench . -benchmem -count=10 ./internal/cache
go test -tags=integration ./internal/cache -v
```

> 💡 **`TTL` devolviendo `-1` es una señal de alarma.** Significa que la clave
> existe y **no expira nunca**. En una caché, eso es casi siempre un `SET` sin
> expiración que alguien escribió por descuido, y esas claves se acumulan hasta
> llenar la memoria. Un `SCAN` periódico buscando claves sin TTL es un buen chivato.

---

## 💻 6. Construcción guiada

### 6.1 Mini proyecto: `cache-aside-lab`

La caché tipada, con las cuatro decisiones explícitas.

```go
// labs/cache-aside-lab/cache.go
package cache

// Codec serializa y deserializa el valor cacheado.
//
// Se declara como interfaz —y no se usa JSON directamente— porque la
// serialización es una decisión con consecuencias medibles, y en §6.4 la vamos a
// cambiar por una más rápida. Tenerla aislada permite comparar.
type Codec[T any] interface {
	Encode(T) ([]byte, error)
	Decode([]byte) (T, error)
}

// JSONCodec es la opción por defecto: legible en valkey-cli, estable entre
// versiones del lenguaje, e independiente del layout de los structs de Go.
//
// 📖 Contrasta con la serialización nativa de Java que el RedisTemplate usa por
// defecto: aquella es más compacta y ACOPLA la caché a la versión exacta de tus
// clases. Añadir un campo invalida todo lo cacheado con un
// InvalidClassException. Aquí, un campo nuevo simplemente llega vacío — y por
// eso la clave lleva versión.
type JSONCodec[T any] struct{}

func (JSONCodec[T]) Encode(v T) ([]byte, error) { return json.Marshal(v) }

func (JSONCodec[T]) Decode(b []byte) (T, error) {
	var v T
	err := json.Unmarshal(b, &v)
	return v, err
}

type Cache[T any] struct {
	client  valkey.Client
	codec   Codec[T]
	ttl     time.Duration
	jitter  float64          // fracción del TTL, 0.2 = ±20%
	rand    *rand.Rand
	metrics *Metrics
	logger  *slog.Logger
}

// Get devuelve el valor si está. Un fallo de Valkey se trata como fallo de
// caché, NO como error: la caché falla abierta.
func (c *Cache[T]) Get(ctx context.Context, key string) (T, bool) {
	var zero T

	// Un plazo CORTO y propio para la caché. Si Valkey tarda más que la base de
	// datos, la caché está haciendo daño en vez de bien, y hay que saltársela.
	ctx, cancel := context.WithTimeout(ctx, 100*time.Millisecond)
	defer cancel()

	raw, err := c.client.Do(ctx, c.client.B().Get().Key(key).Build()).AsBytes()
	if err != nil {
		if valkey.IsValkeyNil(err) {
			c.metrics.Miss()
			return zero, false
		}
		// Error real: se registra y se sigue como si fuera un fallo de caché.
		c.metrics.Error()
		c.logger.Warn("error leyendo de la caché",
			slog.String("key", key), slog.String("err", err.Error()))
		return zero, false
	}

	v, err := c.codec.Decode(raw)
	if err != nil {
		// Un valor que no deserializa es un valor de otra versión del struct.
		// Se borra y se trata como fallo: así la caché se auto-repara en vez de
		// fallar indefinidamente.
		c.metrics.Corrupt()
		c.logger.Warn("valor de caché corrupto; borrando", slog.String("key", key))
		_ = c.Delete(context.WithoutCancel(ctx), key)
		return zero, false
	}

	c.metrics.Hit()
	return v, true
}

// Set guarda con TTL y jitter.
func (c *Cache[T]) Set(ctx context.Context, key string, v T) error {
	raw, err := c.codec.Encode(v)
	if err != nil {
		return fmt.Errorf("codificando el valor de %s: %w", key, err)
	}

	ctx, cancel := context.WithTimeout(ctx, 100*time.Millisecond)
	defer cancel()

	return c.client.Do(ctx,
		c.client.B().Set().Key(key).Value(string(raw)).
			Ex(c.ttlWithJitter()).
			Build()).Error()
}

// ttlWithJitter reparte los vencimientos.
//
// SIN JITTER: si el servicio arranca y cachea 250 países en el mismo segundo,
// los 250 expiran en el mismo segundo una hora después. En ese instante llegan
// 250 fallos de caché simultáneos contra MongoDB, y el pico que la caché existía
// para evitar ocurre igual, solo que cada hora en punto.
//
// El fenómeno tiene nombre —expiración sincronizada— y el jitter es su única
// defensa. Está medido en el ejercicio 8.
func (c *Cache[T]) ttlWithJitter() time.Duration {
	if c.jitter <= 0 {
		return c.ttl
	}
	span := float64(c.ttl) * c.jitter
	// Uniforme en [ttl-span, ttl+span]
	delta := (c.rand.Float64()*2 - 1) * span
	return time.Duration(float64(c.ttl) + delta)
}
```

> 🧪 **Prueba de fuego.** Cachea 250 países sin jitter y mira los TTL:
> ```bash
> docker compose exec valkey valkey-cli --scan --pattern 'meridian:*:country:*' | \
>   while read k; do docker compose exec -T valkey valkey-cli TTL "$k"; done | sort | uniq -c
> ```
> Sin jitter: `250  3600`. Con jitter: una distribución repartida entre 2880 y
> 4320.
>
> **La mentira de la pantalla:** la tasa de acierto media es idéntica en los dos
> casos, así que un panel de métricas no distingue la diferencia. Lo que cambia es
> la **distribución temporal de los fallos**, y eso solo se ve mirando el pico, no
> la media. Es el mismo error que medir latencia con la media en vez del p99.

### 6.2 Mini proyecto: `stampede-lab`

La estampida de caché, y por qué hacen falta **dos** defensas.

**El problema.** La clave del catálogo de países expira. En ese instante hay
cuarenta peticiones en vuelo en cada una de las tres instancias del servicio.
Ciento veinte peticiones fallan la caché **a la vez** y ciento veinte consultas
idénticas salen hacia MongoDB.

**Defensa 1: `singleflight` local** (que ya conoces de la Fase 10):

```go
// singleflight deduplica DENTRO DE UN PROCESO. De cuarenta peticiones
// concurrentes en esta instancia, sale UNA consulta.
//
// De 120 consultas pasamos a 3: una por instancia.
func (s *Service) Country(ctx context.Context, code string) (Country, error) {
	key := s.keys.Country(code)

	if c, ok := s.cache.Get(ctx, key); ok {
		return c, nil
	}

	v, err, _ := s.group.Do(key, func() (any, error) {
		// Volver a mirar la caché DENTRO del singleflight: mientras esperábamos
		// el turno, el ganador pudo haberla llenado ya.
		if c, ok := s.cache.Get(ctx, key); ok {
			return c, nil
		}

		c, err := s.store.FindByCode(context.WithoutCancel(ctx), code)
		if err != nil {
			return nil, err
		}
		_ = s.cache.Set(context.WithoutCancel(ctx), key, c)
		return c, nil
	})
	if err != nil {
		return Country{}, err
	}
	return v.(Country), nil
}
```

**Defensa 2: bloqueo distribuido**, para las tres que quedan:

```go
// labs/stampede-lab/lock.go

// TryLock intenta adquirir un bloqueo. Es SET con NX (solo si no existe) y EX
// (con expiración), en una sola operación atómica.
//
// El valor es un token aleatorio, y no es decorativo: es lo que permite que solo
// quien adquirió el bloqueo pueda liberarlo. Sin él, un proceso lento cuyo
// bloqueo expiró liberaría el bloqueo de OTRO proceso al terminar.
func (l *Locker) TryLock(ctx context.Context, key string, ttl time.Duration) (token string, ok bool, err error) {
	token = randomToken()
	lockKey := "lock:" + key

	res := l.client.Do(ctx, l.client.B().Set().
		Key(lockKey).Value(token).
		Nx().           // solo si no existe
		Ex(ttl).        // con expiración obligatoria
		Build())

	if err := res.Error(); err != nil {
		if valkey.IsValkeyNil(err) {
			return "", false, nil   // otro lo tiene
		}
		return "", false, fmt.Errorf("adquiriendo el bloqueo %s: %w", key, err)
	}
	return token, true, nil
}

// unlockScript libera el bloqueo SOLO si el token coincide.
//
// Tiene que ser un script Lua porque la comprobación y el borrado deben ser
// ATÓMICOS. Con GET seguido de DEL hay una ventana: el bloqueo puede expirar
// entre las dos operaciones, otro proceso adquirirlo, y nuestro DEL borrar el
// suyo.
var unlockScript = valkey.NewLuaScript(`
if redis.call("GET", KEYS[1]) == ARGV[1] then
    return redis.call("DEL", KEYS[1])
else
    return 0
end`)

func (l *Locker) Unlock(ctx context.Context, key, token string) error {
	return unlockScript.Exec(ctx, l.client, []string{"lock:" + key}, []string{token}).Error()
}
```

> ⚠️ **LA ADVERTENCIA GRANDE, y hay que decirla con todas las letras.**
>
> **Un bloqueo con TTL en Valkey NO garantiza exclusión mutua.** Nunca. El
> escenario:
>
> ```text
> t0   El proceso A adquiere el bloqueo, TTL = 10 s
> t1   A empieza a trabajar
> t2   A sufre una pausa: recolección de basura, el hipervisor lo suspende,
>      la red se corta 12 segundos
> t10  El bloqueo EXPIRA en Valkey
> t11  B adquiere el bloqueo y empieza a trabajar
> t13  A vuelve de su pausa, CREE que tiene el bloqueo, y sigue trabajando
>
> → A y B en la sección crítica a la vez.
> ```
>
> Esto no es un fallo de Valkey ni de la implementación: es una consecuencia
> inevitable de un bloqueo basado en tiempo en un sistema distribuido asíncrono.
> Redlock —el algoritmo con varias instancias— **tampoco lo resuelve**, y la
> discusión entre Martin Kleppmann y Salvatore Sanfilippo sobre esto es lectura
> obligatoria de esta fase.
>
> **La regla del curso, que es la única postura defendible:**
>
> **Los bloqueos distribuidos sirven para EFICIENCIA, nunca para CORRECCIÓN.**
>
> - ✅ *Eficiencia*: "que no consulten a MongoDB doscientas veces a la vez". Si el
>   bloqueo falla, se consulta de más. Coste: unos milisegundos. **Aceptable.**
> - ❌ *Corrección*: "que no se cobre dos veces la misma factura". Si el bloqueo
>   falla, se cobra dos veces. **Inaceptable**, y la solución no es un bloqueo
>   mejor: es una restricción única en la base de datos, o un `UPDATE`
>   condicional, o una transacción. **Corrección se resuelve donde están los
>   datos.**

Y los dos juntos:

```go
func (s *Service) countryWithStampedeProtection(ctx context.Context, code string) (Country, error) {
	key := s.keys.Country(code)

	if c, ok := s.cache.Get(ctx, key); ok {
		return c, nil
	}

	// Defensa 1: singleflight. 40 goroutines de esta instancia → 1.
	v, err, _ := s.group.Do(key, func() (any, error) {
		if c, ok := s.cache.Get(ctx, key); ok {
			return c, nil
		}

		// Defensa 2: bloqueo distribuido. 3 instancias → 1.
		token, acquired, err := s.locker.TryLock(ctx, key, 5*time.Second)
		if err != nil {
			// Valkey falló: seguimos sin bloqueo. Fallar abierto, otra vez.
			s.logger.Warn("no se pudo adquirir el bloqueo; sigo sin él")
		}

		if !acquired {
			// Otra instancia está cargando. Esperar un poco y volver a mirar la
			// caché es MEJOR que cargar también: la espera es de milisegundos y
			// evita la consulta duplicada.
			//
			// ⚠️ Y si tras esperar sigue sin estar, SE CARGA IGUAL. Nunca se
			// devuelve un error por no conseguir un bloqueo de eficiencia: eso
			// convertiría una optimización en un punto de fallo.
			if c, ok := s.waitForCache(ctx, key, 200*time.Millisecond); ok {
				return c, nil
			}
			s.metrics.LockMiss()
		} else {
			defer func() { _ = s.locker.Unlock(context.WithoutCancel(ctx), key, token) }()
		}

		c, err := s.store.FindByCode(context.WithoutCancel(ctx), code)
		if err != nil {
			return nil, err
		}
		_ = s.cache.Set(context.WithoutCancel(ctx), key, c)
		return c, nil
	})
	if err != nil {
		return Country{}, err
	}
	return v.(Country), nil
}
```

**Y la tercera defensa, que es la más elegante y casi nadie usa: refresco
anticipado.**

```go
// El valor cacheado lleva su propia marca de "refrescar a partir de".
//
// Cuando una lectura llega en la ventana entre refreshAt y expiresAt, devuelve
// el valor cacheado INMEDIATAMENTE y lanza un refresco en segundo plano. El
// usuario nunca espera por el origen, y la clave nunca llega a expirar bajo
// carga.
//
// Es lo que hace @Cacheable con refreshAfterWrite de Caffeine 🩻, y aquí se
// escribe en veinte líneas.
type entry[T any] struct {
	Value     T         `json:"v"`
	RefreshAt time.Time `json:"r"`
	ExpiresAt time.Time `json:"e"`
}

func (s *Service) getWithEarlyRefresh(ctx context.Context, key string, load func(context.Context) (Country, error)) (Country, error) {
	e, ok := s.cache.GetEntry(ctx, key)
	if !ok {
		return s.loadAndCache(ctx, key, load)
	}

	if time.Now().After(e.RefreshAt) {
		// Refresco en segundo plano, sin bloquear al usuario.
		// El singleflight impide que cuarenta lecturas lancen cuarenta
		// refrescos.
		go func() {
			bgCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 10*time.Second)
			defer cancel()
			_, _, _ = s.group.Do("refresh:"+key, func() (any, error) {
				return s.loadAndCache(bgCtx, key, load)
			})
		}()
	}
	return e.Value, nil
}
```

### 6.3 AtlasSync: la caché en su sitio

```go
// services/atlassync/internal/atlassync/service.go

// La caché se compone POR DELANTE del almacén, implementando la misma interfaz.
//
// Es el patrón decorador, y tiene una propiedad valiosa: el servicio no sabe que
// hay caché. Los tests del servicio siguen pasando sin tocarlos, y quitar la
// caché es cambiar una línea en main — que es justo lo que vamos a necesitar
// para medir B-17.
type CachedCountryStore struct {
	inner  CountryStore          // el de MongoDB, Fase 11
	cache  *cache.Cache[Country]
	group  singleflight.Group
	keys   cache.KeyBuilder
	logger *slog.Logger
}

// Compilación verificada: satisface la misma interfaz que el almacén real.
var _ CountryStore = (*CachedCountryStore)(nil)

func (s *CachedCountryStore) FindByCode(ctx context.Context, code string) (Country, error) {
	// ... cache-aside con las tres defensas de §6.2 ...
}

// InvalidateAll se llama al terminar una ingesta.
//
// Con 250 países, borrar las claves una a una es aceptable. Con un millón, no, y
// entonces la respuesta NO es escanear: es la invalidación por versión de §6.7.
func (s *CachedCountryStore) InvalidateAll(ctx context.Context) error {
	// ...
}
```

Y el cableado, que hace la caché **opcional**:

```go
// services/atlassync/cmd/atlassync/main.go

var countryStore atlassync.CountryStore = mongoStore

if cfg.CacheEnabled {
	countryStore = cache.NewCachedCountryStore(mongoStore, valkeyCache, keys, logger)
}

svc := atlassync.New(countryStore, ratesStore, logger)
```

> 🧭 **Regla del proyecto: la caché tiene que poder apagarse con una bandera.**
> No es por elegancia: es lo que hace posible **medir si compensa** (B-17) y lo que
> permite apagarla en producción cuando Valkey se convierta en el problema en vez
> de en la solución. Un sistema que no puede funcionar sin su caché no tiene una
> caché: tiene una base de datos frágil.

### 6.4 La serialización, medida

```go
// Tres codecs para el mismo valor, para medir B-18.

// 1. JSON. Legible en valkey-cli, estable, y el más lento.
type JSONCodec[T any] struct{}

// 2. JSON precodificado. La idea: si el valor se sirve tal cual por la API, se
//    puede guardar YA SERIALIZADO y devolverlo sin decodificar y volver a
//    codificar.
//
//    Es la optimización más rentable de una caché de lectura y casi nadie la
//    hace: elimina DOS pasos de serialización por acierto.
type RawJSONCodec struct{}

func (RawJSONCodec) Encode(raw json.RawMessage) ([]byte, error) { return raw, nil }
func (RawJSONCodec) Decode(b []byte) (json.RawMessage, error)   { return b, nil }

// Y el handler escribe los bytes directamente:
func (h *Handler) getCountry(w http.ResponseWriter, r *http.Request) {
	if raw, ok := h.cache.GetRaw(r.Context(), key); ok {
		w.Header().Set("Content-Type", "application/json")
		w.Write(raw)   // ← cero decodificación, cero recodificación
		return
	}
	// ...
}

// 3. Compresión. Para valores grandes, gzip o s2 reduce memoria en Valkey y
//    tráfico de red, a cambio de CPU en los dos extremos.
//
//    El umbral importa: comprimir 200 bytes cuesta más de lo que ahorra.
//    AtlasSync comprime a partir de 1 KB, y ese número sale de medirlo.
type CompressedCodec[T any] struct {
	inner     Codec[T]
	threshold int
}
```

> 📐 **Cómo se mide.** Entrada **B-18**: *bytes precodificados frente a codificar
> por petición*. Se miden las tres variantes con el documento de un país (unos 2
> KB) y con el listado de una región (unos 60 KB), reportando `ns/op`, `B/op`,
> `allocs/op` y **el tamaño en Valkey**.
>
> La hipótesis: *"servir bytes precodificados elimina más del 60% del tiempo de
> proceso por acierto de caché frente a decodificar y recodificar"*. Y el veredicto
> tiene que decir **qué se pierde**: con bytes precodificados, la caché guarda la
> **representación de la API**, no el dominio, así que un cambio en el formato de
> salida obliga a invalidar todo — otra razón para versionar las claves.

### 6.5 Mini proyecto: `ratelimit-lab`

Y aquí empieza **lo que no es caché**.

EventRelay tiene treinta socios, cada uno con su límite acordado. El problema: con
tres instancias del servicio, el `golang.org/x/time/rate` de la Fase 10 limita
**por proceso**, así que el socio recibe el triple de lo pactado.

```go
// services/eventrelay/internal/ratelimit/valkey.go

// tokenBucketScript implementa un token bucket en Lua, ejecutado atómicamente
// en el servidor.
//
// POR QUÉ LUA Y NO VARIOS COMANDOS: leer el estado, calcular y escribir desde Go
// tiene una carrera entre instancias. Valkey ejecuta cada script de forma atómica
// y sin interrupción, así que el cálculo completo es una sola operación.
//
// Es el mismo algoritmo de Bucket4j 🩻: un depósito con capacidad, que se rellena
// a un ritmo constante, y del que cada petición saca un token.
var tokenBucketScript = valkey.NewLuaScript(`
local key      = KEYS[1]
local rate     = tonumber(ARGV[1])   -- tokens por segundo
local capacity = tonumber(ARGV[2])   -- tamaño del depósito (permite ráfagas)
local now      = tonumber(ARGV[3])   -- marca de tiempo del cliente, en segundos
local requested= tonumber(ARGV[4])

local bucket = redis.call("HMGET", key, "tokens", "ts")
local tokens = tonumber(bucket[1])
local ts     = tonumber(bucket[2])

if tokens == nil then
    tokens = capacity
    ts = now
end

-- Rellenar en proporción al tiempo transcurrido, sin pasar de la capacidad.
local delta = math.max(0, now - ts)
tokens = math.min(capacity, tokens + delta * rate)

local allowed = 0
local wait = 0

if tokens >= requested then
    tokens = tokens - requested
    allowed = 1
else
    -- Cuánto falta para tener suficientes. Se devuelve para poder responder con
    -- un Retry-After honesto en vez de un número inventado.
    wait = (requested - tokens) / rate
end

redis.call("HSET", key, "tokens", tokens, "ts", now)
-- El TTL evita que los depósitos de socios inactivos se acumulen para siempre.
redis.call("EXPIRE", key, math.ceil(capacity / rate) * 2)

return {allowed, tostring(wait)}
`)
```

> ⚠️ **La marca de tiempo la pone el cliente, y eso tiene una consecuencia.** Si
> los relojes de las tres instancias divergen, el cálculo de relleno es
> inconsistente. La alternativa es usar `TIME` de Valkey dentro del script, que da
> un reloj único — a cambio de que el script deje de ser determinista, lo que
> complica la replicación. **Para un límite de tasa, la deriva de milisegundos
> entre instancias con NTP es irrelevante y el reloj del cliente está bien.** Para
> algo donde el orden importe, no.

```go
// Allow decide si la petición pasa.
//
// ⚠️ Y AQUÍ LA DECISIÓN CONTRARIA A LA DE LA CACHÉ: si Valkey está caído, el
// limitador falla CERRADO o ABIERTO, y hay que elegir conscientemente.
//
//  - Fallar abierto: dejar pasar todo. El socio recibe una avalancha si Valkey
//    cae. Protege nuestra disponibilidad, arriesga la del socio.
//  - Fallar cerrado: rechazar todo. Protege al socio, para nuestras entregas.
//
// EventRelay falla abierto pero con un limitador LOCAL de respaldo, calibrado al
// límite dividido entre el número de instancias. Es lo menos malo: degrada a un
// límite aproximado en vez de a ninguno.
func (l *Limiter) Allow(ctx context.Context, endpointID string, rps float64, burst int) (bool, time.Duration, error) {
	res, err := tokenBucketScript.Exec(ctx, l.client,
		[]string{"meridian:eventrelay:v1:ratelimit:" + endpointID},
		[]string{
			strconv.FormatFloat(rps, 'f', -1, 64),
			strconv.Itoa(burst),
			strconv.FormatInt(time.Now().Unix(), 10),
			"1",
		}).ToArray()

	if err != nil {
		l.metrics.Degraded()
		l.logger.Warn("limitador distribuido no disponible; usando el local",
			slog.String("endpoint", endpointID))
		// Respaldo local, con el límite dividido entre las instancias.
		return l.local.For(endpointID, rps/float64(l.instances)).Allow(), 0, nil
	}
	// ...
}
```

### 6.6 Idempotencia distribuida con `SET NX`

La deuda del ejercicio 25 de la Fase 05: dos peticiones con la misma
`Idempotency-Key` deben producir un solo evento, **entre todas las instancias**.

```go
// services/eventrelay/internal/idempotency/store.go

// Begin reserva la clave de idempotencia. Devuelve:
//   - (nil, true, nil)          → la reserva es nuestra, hay que procesar
//   - (respuesta, false, nil)   → ya se procesó; devuelve lo de la primera vez
//   - (nil, false, ErrInFlight) → otra instancia la está procesando ahora mismo
func (s *Store) Begin(ctx context.Context, key string, bodyHash string) (*StoredResponse, bool, error) {
	k := "meridian:eventrelay:v1:idem:" + key

	// SET NX con TTL: reservar es atómico. El valor inicial guarda el hash del
	// cuerpo para detectar el caso "misma clave, cuerpo distinto".
	reserved := s.client.Do(ctx, s.client.B().Set().
		Key(k).
		Value(`{"state":"in_flight","body_hash":"`+bodyHash+`"}`).
		Nx().
		Ex(s.inFlightTTL).   // corto: si morimos, otro puede reintentar pronto
		Build())

	if err := reserved.Error(); err == nil {
		return nil, true, nil   // la reserva es nuestra
	} else if !valkey.IsValkeyNil(err) {
		return nil, false, fmt.Errorf("reservando la clave de idempotencia: %w", err)
	}

	// Ya existe: leer en qué estado está.
	raw, err := s.client.Do(ctx, s.client.B().Get().Key(k).Build()).AsBytes()
	if err != nil {
		return nil, false, fmt.Errorf("leyendo la clave de idempotencia: %w", err)
	}

	var rec record
	if err := json.Unmarshal(raw, &rec); err != nil {
		return nil, false, fmt.Errorf("registro de idempotencia corrupto: %w", err)
	}

	// MISMA CLAVE, CUERPO DISTINTO: es un error del cliente, y responder la
	// respuesta anterior sería incorrecto. 409, y con un mensaje que lo explique.
	if rec.BodyHash != bodyHash {
		return nil, false, ErrKeyReused
	}

	if rec.State == "in_flight" {
		// Otra instancia la está procesando. 409 con Retry-After, para que el
		// cliente vuelva en un momento — es mejor que esperar bloqueados.
		return nil, false, ErrInFlight
	}

	return &rec.Response, false, nil
}

// Complete guarda la respuesta y alarga el TTL a la ventana de idempotencia
// acordada con el productor: 24 horas.
func (s *Store) Complete(ctx context.Context, key string, bodyHash string, resp StoredResponse) error {
	// ...
}
```

> 🧭 **Regla del proyecto.** La idempotencia en Valkey es una **optimización de
> latencia**, no la garantía. La garantía está en el índice único
> `events_idempotency_key_uniq` de PostgreSQL, creado en la Fase 09. Si Valkey
> falla y dos peticiones llegan a la base de datos, **la restricción única rechaza
> la segunda** y el servicio responde con la primera.
>
> Es exactamente la distinción del ⚠️ de §6.2: **corrección en la base de datos,
> eficiencia en Valkey.**

### 6.7 Invalidación: por clave, por etiqueta y por versión

**Por clave** es trivial y cubre el 90%. Los otros dos casos son los interesantes.

**El problema.** El listado `countries:region=americas:limit=50` depende de todos
los países de América. Si cambia Colombia, ese listado queda obsoleto. ¿Cómo se
invalida sin conocer todas las claves derivadas?

**Opción A: escanear.** `SCAN` con patrón y borrar. Funciona, es O(n) sobre el
espacio de claves, y **no escala**. Descartada salvo para operaciones de
mantenimiento.

**Opción B: etiquetas.** Un conjunto por etiqueta que apunta a las claves que la
usan:

```go
// SetWithTags guarda el valor Y registra la clave en cada etiqueta.
//
// La etiqueta es un SET de Valkey. Invalidar una etiqueta es leer su conjunto y
// borrar todas las claves de golpe.
func (c *Cache[T]) SetWithTags(ctx context.Context, key string, v T, tags ...string) error {
	raw, err := c.codec.Encode(v)
	if err != nil {
		return err
	}

	// Todo en un pipeline: un viaje, no N+1.
	cmds := make(valkey.Commands, 0, len(tags)*2+1)
	cmds = append(cmds, c.client.B().Set().Key(key).Value(string(raw)).Ex(c.ttlWithJitter()).Build())

	for _, tag := range tags {
		tagKey := "tag:" + tag
		cmds = append(cmds, c.client.B().Sadd().Key(tagKey).Member(key).Build())
		// ⚠️ El TTL del conjunto de etiquetas tiene que ser MAYOR que el de las
		// claves que contiene, o la etiqueta desaparece antes que ellas y se
		// vuelven ininvalidables.
		cmds = append(cmds, c.client.B().Expire().Key(tagKey).Seconds(int64(c.ttl.Seconds()*3)).Build())
	}

	for _, res := range c.client.DoMulti(ctx, cmds...) {
		if err := res.Error(); err != nil {
			return fmt.Errorf("guardando con etiquetas: %w", err)
		}
	}
	return nil
}

// InvalidateTag borra todas las claves de una etiqueta.
//
// ⚠️ El conjunto de etiquetas acumula claves ya expiradas: un SMEMBERS de una
// etiqueta vieja puede devolver miles de claves que ya no existen. El DEL sobre
// claves inexistentes es barato, pero el conjunto crece sin límite.
//
// La defensa es el TTL del conjunto y, si el volumen lo justifica, una limpieza
// periódica. Es el coste real de este patrón y hay que conocerlo antes de
// adoptarlo.
func (c *Cache[T]) InvalidateTag(ctx context.Context, tag string) error {
	tagKey := "tag:" + tag

	keys, err := c.client.Do(ctx, c.client.B().Smembers().Key(tagKey).Build()).AsStrSlice()
	if err != nil {
		return fmt.Errorf("leyendo la etiqueta %s: %w", tag, err)
	}
	if len(keys) == 0 {
		return nil
	}

	cmds := []valkey.Completed{
		c.client.B().Del().Key(keys...).Build(),
		c.client.B().Del().Key(tagKey).Build(),
	}
	for _, res := range c.client.DoMulti(ctx, cmds...) {
		if err := res.Error(); err != nil {
			return fmt.Errorf("invalidando la etiqueta %s: %w", tag, err)
		}
	}
	c.logger.Info("etiqueta invalidada",
		slog.String("tag", tag), slog.Int("claves", len(keys)))
	return nil
}
```

**Opción C: versión en la clave.** La más simple y la mejor cuando encaja:

```go
// Un contador en Valkey forma parte de la clave. Incrementarlo deja TODA la
// generación anterior huérfana, y expira sola por TTL.
//
// Coste de invalidar: UN comando, O(1), sin importar cuántas claves haya.
// Coste: las claves viejas ocupan memoria hasta expirar.
//
// Es la técnica que usa Rails con sus "cache key versioning", y para una
// invalidación masiva —el final de una ingesta— es claramente la mejor.
func (k *VersionedKeyBuilder) Country(ctx context.Context, code string) (string, error) {
	gen, err := k.generation(ctx)   // cacheado en memoria unos segundos
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("meridian:atlassync:v%d:g%d:country:%s",
		k.version, gen, strings.ToUpper(code)), nil
}

func (k *VersionedKeyBuilder) InvalidateAll(ctx context.Context) error {
	return k.client.Do(ctx, k.client.B().Incr().Key(k.genKey).Build()).Error()
}
```

> 🧭 **Decisión del curso.** AtlasSync usa **versión de generación** para la
> invalidación masiva tras una ingesta —un comando, O(1)— y **etiquetas** para la
> invalidación selectiva de listados cuando cambia un país concreto. `SCAN` no se
> usa para invalidar nunca.

**Y la opción D, evaluada y rechazada: Pub/Sub para invalidación entre
instancias.**

Valkey tiene Pub/Sub, y la idea es tentadora: publicar "se invalidó COL" y que
cada instancia borre su caché local. **Rechazada**, con motivo:

- El Pub/Sub de Valkey es **de entrega como máximo una vez**: si una instancia
  está desconectada en ese instante, **se pierde el mensaje y su caché queda
  obsoleta indefinidamente**.
- Añade una segunda capa de caché (local) con su propia coherencia que gestionar.
- Y no resuelve nada que el TTL corto no resuelva ya en AtlasSync.

La entrada va a `docs/rechazos.md`, con su condición de revisión: *"se reconsidera
si aparece una caché local de primer nivel con TTL largo y el coste de la
obsolescencia se vuelve inaceptable"*.

### 6.8 El experimento que cierra la fase

**Y ahora la pregunta incómoda: ¿compensó?**

```go
// La caché se apaga con una bandera (§6.3). Eso permite medir el MISMO servicio
// con y sin ella, bajo la misma carga.
```

```bash
# Sin caché
MERIDIAN_CACHE_ENABLED=false ./bin/atlassync &
vegeta attack -targets=targets.txt -rate=500 -duration=60s | vegeta report

# Con caché en memoria (la de la Fase 10)
MERIDIAN_CACHE_ENABLED=true MERIDIAN_CACHE_BACKEND=memory ./bin/atlassync &
vegeta attack -targets=targets.txt -rate=500 -duration=60s | vegeta report

# Con Valkey
MERIDIAN_CACHE_ENABLED=true MERIDIAN_CACHE_BACKEND=valkey ./bin/atlassync &
vegeta attack -targets=targets.txt -rate=500 -duration=60s | vegeta report
```

> 📐 **Cómo se mide.** Entrada **B-17**: *AtlasSync, tasa de acierto y latencia con
> y sin caché*. **Tres variantes, no dos**: sin caché, con mapa en memoria y TTL, y
> con Valkey. Con la distribución de acceso declarada —uniforme y sesgada, porque
> el resultado depende enteramente de eso— y midiendo p50, p95, p99, rendimiento y
> memoria.
>
> **La hipótesis honesta, y hay que escribirla antes de medir:**
>
> *"Frente a no cachear, las dos cachés reducen la latencia p99 de forma
> significativa. Frente a la caché en memoria, Valkey **no mejora la latencia** —la
> empeora, porque añade un viaje de red— y su ventaja está en otra parte: la caché
> se comparte entre instancias, sobrevive a los reinicios, y no multiplica la
> memoria por el número de réplicas."*
>
> **Si tu medición dice que Valkey es más rápido que un mapa en memoria, revisa el
> experimento.** Un acceso a un mapa son nanosegundos; un viaje a Valkey, cientos
> de microsegundos como mínimo. La caché distribuida **nunca** gana a la local en
> latencia pura, y entender eso es el punto de la medición.

**Lo que la medición tiene que responder, y que es lo que de verdad decide:**

1. ¿Cuál es la tasa de acierto real con la distribución de acceso real? Con 250
   países y acceso uniforme, un mapa en memoria de 250 entradas tiene **100% de
   acierto** y no necesita expulsión.
2. ¿Cuánta memoria por instancia? Con 250 países a 2 KB son 500 KB. Irrelevante.
3. ¿Cuánto tarda el arranque en frío? Con caché local, cada reinicio empieza vacío
   y golpea MongoDB. Con Valkey, el arranque encuentra la caché caliente.
4. ¿Cuántas instancias hay? Con tres, la caché local multiplica la carga de
   llenado por tres. Con treinta, por treinta.

⚖️ **Y el veredicto que el curso sostiene, adelantado para que lo verifiques en vez
de descubrirlo:**

> **Para AtlasSync tal como está —250 países, 2 KB cada uno, tres instancias— un
> mapa en memoria con TTL resuelve el problema, y Valkey no aporta lo suficiente
> para justificar un servicio más en el `compose.yaml`.**
>
> Lo que sí justifica Valkey en Meridian es **lo que no es caché**: el límite de
> tasa por socio, que debe ser compartido entre instancias por definición, y la
> idempotencia distribuida. **Esos dos casos no tienen alternativa local.**
>
> Y cuándo cambiaría el veredicto para la caché: si el conjunto de datos no
> cupiera en memoria, si las instancias fueran muchas, si el coste de llenar la
> caché fuera alto (una consulta de diez segundos en vez de una lectura de
> MongoDB), o si la coherencia entre instancias importara.

**Esa es la lección de la fase**, y es mejor que "pon una caché".

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: la caché que se convirtió en base de datos

**El cadáver.** Empezó bien. AtlasSync cacheaba países con TTL de una hora, la tasa
de acierto era del 97%, y todo el mundo contento.

Después vinieron, en este orden:

1. *"El TTL de una hora hace que cada hora haya un pico contra Mongo. Subámoslo a
   24 horas."* → 24 h.
2. *"Los países no cambian casi nunca. ¿Por qué expirar?"* → sin TTL.
3. *"Si no expira, la ingesta tiene que escribir en la caché también."* →
   write-through.
4. *"Si la caché siempre está actualizada, leer de Mongo es redundante."* → la
   lectura ya no va nunca a Mongo.
5. *"Mongo solo se usa para el arranque en frío."* → …

Y un martes Valkey se reinició.

```go
// ☕ — el estado final, y cada paso parecía razonable
func (s *Service) Country(ctx context.Context, code string) (Country, error) {
	c, ok := s.cache.Get(ctx, s.keys.Country(code))
	if !ok {
		// "Esto no debería pasar nunca."
		return Country{}, ErrNotFound
	}
	return c, nil
}
```

**Lo que pasó a las 14:07 de ese martes:**

```text
14:07:12  Valkey se reinicia (mantenimiento de la imagen). Memoria vacía.
14:07:13  AtlasSync devuelve 404 en TODAS las consultas de país.
14:07:13  Los cuatro servicios que dependen de AtlasSync empiezan a fallar.
14:07:20  ClearingHouse no puede convertir monedas → el cierre nocturno queda
          en riesgo.
14:21:00  Alguien se da cuenta y dispara la ingesta a mano.
14:23:40  Servicio restaurado. 16 minutos de caída total.
```

**El informe forense:**

| | Caché correcta | La de la autopsia |
|---|---|---|
| ¿Qué pasa si Valkey se reinicia? | latencia peor unos minutos | **caída total** |
| ¿El dato está en algún sitio duradero? | sí, MongoDB | sí, **pero nadie lo lee** |
| ¿Se puede apagar la caché con una bandera? | sí | **no, el servicio no funciona sin ella** |
| ¿Un fallo de caché degrada o rompe? | degrada | **rompe** |
| Tiempo de recuperación tras reinicio de Valkey | 0 | **16 minutos, manual** |
| Persistencia de Valkey configurada | irrelevante | **no**, y ahí estaba la última esperanza |

**La causa de la muerte: ninguna decisión individual fue absurda.** Subir el TTL
era razonable. Quitarlo, defendible para datos que cambian una vez al día.
Write-through, coherente con lo anterior. Y dejar de leer de Mongo era la
consecuencia lógica de todo lo demás.

**La suma de cinco decisiones razonables convirtió una optimización en un punto
único de fallo sin persistencia.**

**Y la señal de alarma que estaba ahí desde el paso 2, visible para cualquiera que
supiera mirarla:** `TTL` devolviendo `-1`. Una clave de caché que no expira nunca
es una clave que dejó de ser caché.

**El fix, y las tres reglas que se llevan:**

> 🧭 **Regla 1.** **Toda clave de caché tiene TTL.** Sin excepción. Si un dato no
> debe expirar, no es caché: es estado, y el estado va a una base de datos.
>
> 🧭 **Regla 2.** **La caché tiene que poder apagarse con una bandera y el servicio
> seguir funcionando.** Si no puede, no tienes una caché: tienes una base de datos
> en memoria sin garantías de durabilidad. Y esto se **prueba**: hay un test que
> corre la suite completa con la caché desactivada.
>
> 🧭 **Regla 3.** **Un fallo de caché degrada, nunca rompe.** El `Get` que falla
> devuelve "no está", no un error. Eso es *fail open*, y es la diferencia entre una
> tarde con latencia alta y una caída de dieciséis minutos.

Y la corrección mínima frente a la refactorización correcta: **el parche del
viernes** es restaurar la lectura a Mongo cuando la caché falla —cuatro líneas—.
**La refactorización del lunes** es el test que corre toda la suite con
`CACHE_ENABLED=false`, para que este camino no vuelva a atrofiarse.

### Errores comunes

**1. Claves sin TTL.**
*Síntoma:* la memoria de Valkey crece hasta el límite; con `noeviction`, las
escrituras empiezan a fallar.
*Causa:* un `SET` sin `EX`.
*Fix mínimo:* que el tipo `Cache` sea el único que hace `SET`, y que siempre ponga
TTL. Y un chivato que escanee claves con `TTL == -1`.

**2. TTL sin jitter.**
*Síntoma:* picos periódicos de carga contra el origen, sincronizados.
*Causa:* todo se cacheó a la vez y expira a la vez.
*Fix mínimo:* ±20% de jitter.

**3. La caché que rompe el servicio al fallar.**
*Síntoma:* Valkey cae y el servicio devuelve 500.
*Causa:* el error de caché se propaga.
*Fix mínimo:* *fail open*, y el test con la caché desactivada.

**4. Clave incompleta.**
*Síntoma:* una consulta devuelve el resultado de otra.
*Causa:* un parámetro que cambia el resultado no está en la clave.
*Fix mínimo:* todos los parámetros, en orden determinista, y normalizados.

**5. Clave sin versión.**
*Síntoma:* tras desplegar un cambio de formato, se deserializan valores viejos con
el struct nuevo.
*Causa:* la clave no distingue formatos.
*Fix mínimo:* versión en la clave, y subirla al cambiar el formato.

**6. `KEYS` en producción.**
*Síntoma:* Valkey deja de responder durante cientos de milisegundos.
*Causa:* `KEYS` es O(n) y bloquea.
*Fix mínimo:* `SCAN`. Y replantear el diseño si necesitas escanear para invalidar.

**7. Actualizar la caché al escribir en vez de invalidar.**
*Síntoma:* valores obsoletos bajo escrituras concurrentes.
*Causa:* dos escritores pueden dejar el valor del perdedor.
*Fix mínimo:* invalidar.

**8. Bloqueo distribuido usado para corrección.**
*Síntoma:* dos procesos en la sección crítica pese al bloqueo.
*Causa:* una pausa de recolección de basura o de red mayor que el TTL.
*Fix mínimo:* mover la garantía a la base de datos. **El bloqueo no se arregla: se
reemplaza.**

**9. Liberar un bloqueo sin comprobar el token.**
*Síntoma:* un proceso libera el bloqueo de otro.
*Causa:* `DEL` sin verificar propiedad.
*Fix mínimo:* el script Lua de comparación y borrado atómico.

**10. Etiquetas que crecen sin límite.**
*Síntoma:* conjuntos con decenas de miles de claves inexistentes.
*Causa:* las claves expiran y no se quitan del conjunto.
*Fix mínimo:* TTL en el conjunto, mayor que el de sus claves; o versión de
generación, que no tiene este problema.

**11. `maxmemory-policy` en `noeviction`.**
*Síntoma:* `OOM command not allowed when used memory > 'maxmemory'`.
*Causa:* es el valor **por defecto**, y para una caché es el equivocado.
*Fix mínimo:* `allkeys-lru`.

**12. No distinguir "no está en caché" de "está y vale nil".**
*Síntoma:* consultas repetidas al origen para algo que no existe (envenenamiento
por fallos).
*Causa:* no se cachean los negativos.
*Fix mínimo:* cachear el negativo con TTL **más corto**. Es lo que evita que un
atacante pida un millón de códigos inexistentes y cada uno golpee MongoDB.

**13. `singleflight` sin bloqueo distribuido, o al revés.**
*Síntoma:* la estampida se reduce pero no desaparece.
*Causa:* `singleflight` dedupe dentro del proceso; el bloqueo, entre procesos.
*Fix mínimo:* los dos.

**14. El plazo de la caché igual o mayor que el del origen.**
*Síntoma:* cuando Valkey está lento, las peticiones tardan **más** que sin caché.
*Causa:* el `Get` de caché espera tanto como esperaría la consulta.
*Fix mínimo:* plazo corto y propio para la caché (100 ms), mucho menor que el del
origen.

### 🧨 Rompe a propósito

**Provoca la expiración sincronizada y mírala en el panel.**

```go
func TestSynchronizedExpiry(t *testing.T) {
	for _, jitter := range []float64{0, 0.2} {
		t.Run(fmt.Sprintf("jitter=%.0f%%", jitter*100), func(t *testing.T) {
			c := newCache(t, 10*time.Second, jitter)

			// Llenar 250 claves en el mismo instante, como haría un arranque.
			for i := 0; i < 250; i++ {
				_ = c.Set(ctx, fmt.Sprintf("k%d", i), value)
			}

			// Contar cuántas expiran en cada segundo.
			buckets := make([]int, 15)
			for i := 0; i < 250; i++ {
				ttl := c.TTL(ctx, fmt.Sprintf("k%d", i))
				if s := int(ttl.Seconds()); s >= 0 && s < len(buckets) {
					buckets[s]++
				}
			}
			t.Logf("expiraciones por segundo: %v", buckets)
		})
	}
}
```

```text
jitter=0%   → [0 0 0 0 0 0 0 0 0 0 250 0 0 0 0]
jitter=20%  → [0 0 0 0 0 0 0 0 21 32 29 34 31 28 25 ...]
```

**250 fallos de caché en un solo segundo frente a unos 30 repartidos.** Ahora
conecta eso a MongoDB con `vegeta` corriendo y mira el p99: el pico es visible, y
la media **no cambia**.

Y el segundo experimento, que es el de la autopsia:

```bash
# Llena la caché, comprueba que el servicio va bien, y entonces:
docker compose restart valkey

# Con fail open: latencia peor unos segundos, cero errores.
# Con la caché como única fuente: 404 en todo.
vegeta attack -targets=targets.txt -rate=100 -duration=30s | vegeta report
```

---

## 🧪 8. Ejercicios (22)

**🟢 Fácil (1–5)**

1. Conecta a Valkey y haz `SET`, `GET`, `TTL` y `DEL` desde Go. *Criterio:*
   distingues "la clave no existe" de "error de conexión" con `IsValkeyNil`.
2. Diseña el esquema de claves de AtlasSync y documéntalo. *Criterio:* justificas
   las cinco partes; explicas qué pasa si falta la versión y qué si falta el
   servicio.
3. Comprueba con `TTL` que todas tus claves expiran. *Criterio:* escribes el
   comando que encuentra claves con `TTL == -1` y explicas por qué es un chivato
   útil.
4. Configura `maxmemory` y `maxmemory-policy`, y provoca el
   `OOM command not allowed`. *Criterio:* lo reproduces con `noeviction` y lo
   arreglas con `allkeys-lru`.
5. Usa `INFO stats` para calcular la tasa de acierto de tu servicio bajo carga.
   *Criterio:* comparas ese número con el de tus propias métricas y explicas por
   qué pueden diferir.

**🟡 Intermedio (6–14)**

6. Implementa el `Cache[T]` genérico con las cuatro decisiones explícitas.
   *Criterio:* un test demuestra que un fallo de Valkey **no** rompe la lectura.
7. Implementa el *cache-aside* en `CachedCountryStore` como decorador. *Criterio:*
   los tests del servicio de la Fase 11 pasan **sin tocarlos**, y la caché se
   apaga con una bandera.
8. Reproduce el 🧨 de la expiración sincronizada. *Criterio:* el histograma de los
   dos casos, y conectas el pico con el p99 medido bajo carga.
9. Implementa el cacheado de negativos con TTL más corto. *Criterio:* mil
   peticiones a códigos inexistentes producen una consulta a Mongo, no mil; y
   explicas por qué el TTL es más corto.
10. Implementa `singleflight` y mide cuántas consultas salen con 40 goroutines
    concurrentes tras una expiración. *Criterio:* una, y lo demuestras con un
    contador en el almacén falso.
11. Implementa el bloqueo distribuido con `SET NX` y el script Lua de liberación.
    *Criterio:* un test demuestra que un proceso no puede liberar el bloqueo de
    otro.
12. Implementa la invalidación por etiqueta. *Criterio:* cambiar un país invalida
    los listados de su región y **no** los de otras; y mides cuánto crece el
    conjunto de la etiqueta tras mil ciclos.
13. Implementa la invalidación por versión de generación. *Criterio:* invalidar
    todo es **un** comando, y explicas el intercambio frente a las etiquetas.
14. **Línea de comandos.** Usa `MONITOR` para ver los comandos de una petición
    completa. *Criterio:* cuentas cuántos comandos por petición y detectas si hay
    alguno de más.

**🟠 Difícil (15–19)**

15. Implementa el *token bucket* distribuido en Lua. *Criterio:* (a) tres
    instancias comparten el límite y el socio recibe lo pactado, no el triple; (b)
    el `Retry-After` sale del cálculo real, no de una constante; (c) los depósitos
    de socios inactivos expiran.
16. Implementa el respaldo local del limitador para cuando Valkey falla.
    *Criterio:* apagas Valkey bajo carga y el servicio sigue limitando de forma
    aproximada, sin errores; y explicas por qué aquí no vale el mismo *fail open*
    que en la caché.
17. Implementa la idempotencia distribuida con los tres casos: reserva nueva, ya
    procesada, y en vuelo. *Criterio:* (a) diez peticiones simultáneas con la misma
    clave producen **un** evento, verificado en PostgreSQL; (b) misma clave con
    cuerpo distinto devuelve 409; (c) apagas Valkey y **la restricción única de la
    Fase 09 sigue garantizando la unicidad** — demuéstralo.
18. Implementa el refresco anticipado. *Criterio:* bajo carga sostenida, la clave
    **nunca** llega a expirar y ninguna petición espera por el origen; lo
    demuestras midiendo el p99 en la ventana de refresco.
19. Mide B-18: las tres estrategias de serialización. *Criterio:* (a) JSON, JSON
    precodificado y comprimido, con dos tamaños de valor; (b) reportas tiempo,
    asignaciones y **tamaño en Valkey**; (c) encuentras el umbral a partir del cual
    comprimir compensa; (d) tu veredicto dice qué se pierde con los bytes
    precodificados.

**🔴 Muy difícil (20–22)**

20. **Mide B-17 y responde la pregunta incómoda.** *Rúbrica:* (a) las tres
    variantes —sin caché, mapa en memoria, Valkey— bajo la misma carga, con la
    distribución de acceso declarada (uniforme y sesgada); (b) p50, p95, p99,
    rendimiento, memoria por instancia y tasa de acierto; (c) declaras la hipótesis
    antes y dices si te equivocaste; (d) **el veredicto responde si Valkey compensa
    para la caché de AtlasSync**, con números, y nombra las cuatro condiciones que
    cambiarían la respuesta; (e) si tu conclusión es que no compensa, **la escribes
    igual** — es la regla 5 de honestidad de `prompts/formato-de-benchmarks.md`.
21. **La caché que sobrevive al desastre.** Somete AtlasSync a cuatro fallos de
    Valkey mientras corre una prueba de carga. *Rúbrica:* (a) reinicio limpio,
    reinicio con pérdida de datos, latencia de 2 s inyectada, y desconexión total
    de 60 s; (b) en los cuatro, **ninguna petición devuelve 5xx** y lo demuestras;
    (c) mides la degradación de latencia en cada caso; (d) el caso de la latencia
    alta es el más difícil —una caché lenta es peor que ninguna— y explicas cómo lo
    resolviste; (e) escribes el *runbook* de qué hacer cuando Valkey falla en
    producción.
22. **La guía de caché de Meridian.** Escribe `docs/cache.md`: la política que los
    cuatro servicios seguirán. *Rúbrica:* (a) el esquema de claves con su gramática,
    y qué hacer al cambiar el formato de un valor; (b) las tres reglas de la
    autopsia, con el incidente resumido como justificación; (c) la política de TTL
    y jitter por tipo de dato, con números y su porqué; (d) la distinción
    eficiencia/corrección para bloqueos, con la lista de qué **no** se resuelve con
    Valkey; (e) el árbol de decisión *"¿necesito Valkey o me basta un mapa en
    memoria?"* con las cuatro condiciones de B-17; (f) qué se monitoriza y qué
    alerta se define; (g) es utilizable por alguien que no ha hecho este curso.

**🔥 Opcionales**

- Implementa la caché con `valkey-go` y con `redis/go-redis`, y mide las dos con
  500 goroutines concurrentes. La diferencia debería estar en el *pipelining*
  automático; comprueba si se nota de verdad a tu escala.
- Investiga la invalidación del lado cliente de Redis 6+ (`CLIENT TRACKING`), que
  Valkey también soporta: el servidor avisa al cliente cuando una clave que cacheó
  localmente cambia. Es la solución correcta al problema que el Pub/Sub resolvía
  mal, y evalúa si cambiaría el rechazo de §6.7.
- Explora las estructuras de datos de Valkey que no hemos usado: `HyperLogLog`
  para cardinalidad aproximada, `Bitmap` para conjuntos de flags, `Sorted Set` para
  rankings. Cada una resuelve un problema que la gente resuelve mal en la base de
  datos.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — La caché de dos niveles con invalidación del servidor.**
Monta caché local **más** Valkey, con `CLIENT TRACKING` para que el servidor avise
cuando una clave cacheada localmente cambia.
*Rúbrica:* (a) el primer nivel es un mapa en memoria con TTL corto; el segundo,
Valkey; (b) `CLIENT TRACKING` invalida el nivel local sin sondeo; (c) demuestras que
resuelve el problema por el que el curso **rechazó** el Pub/Sub —la pérdida de
mensajes con un cliente desconectado— y explicas cómo; (d) mides la latencia de los
tres niveles: local, Valkey, origen; (e) **actualizas la entrada de
`docs/rechazos.md`** con tu conclusión, que era la condición de revisión declarada.

**D2 — La estampida con N instancias, reproducida.**
Levanta cinco instancias de AtlasSync y provoca una expiración simultánea real.
*Rúbrica:* (a) mides las consultas que llegan a MongoDB en las tres
configuraciones: sin defensa, con `singleflight`, y con `singleflight` más bloqueo
distribuido; (b) demuestras que la primera sola reduce de 5N a 5, y la segunda a 1;
(c) mides también la **latencia del perdedor** —el que espera al bloqueo— y decides
si compensa; (d) provocas el caso patológico: la instancia que tiene el bloqueo
muere a mitad, y mides cuánto tardan las demás en recuperarse; (e) escribes cuál de
las tres configuraciones desplegarías **para este caso concreto** y por qué.

**D3 — El presupuesto de memoria de Valkey.**
Calcula cuánta memoria necesita tu caché, verifica el cálculo, y configura la
expulsión.
*Rúbrica:* (a) estimas el tamaño de una entrada —con `MEMORY USAGE`, no a ojo— y lo
multiplicas por las claves esperadas, añadiendo la sobrecarga de los conjuntos de
etiquetas; (b) configuras `maxmemory` al resultado y provocas la expulsión de
verdad; (c) comparas `allkeys-lru`, `allkeys-lfu` y `volatile-ttl` **midiendo la
tasa de acierto de cada una** con tu distribución de acceso real; (d) encuentras el
caso donde `noeviction` sería correcto y explicas por qué; (e) defines la alerta que
avisaría antes de llegar al límite.

---

## 📚 9. Referencias

### Documentación oficial

- **Valkey** — https://valkey.io/docs/ — comandos, configuración y guía de
  operación. La compatibilidad con Redis es total, así que casi toda la
  documentación de Redis aplica.
- **Referencia de comandos** — https://valkey.io/commands/ — la usarás mucho;
  fíjate en la complejidad de cada comando, que está documentada.
- **`valkey-go`** — https://github.com/valkey-io/valkey-go — y su README explica el
  *pipelining* automático.
- **`redis/go-redis`** — https://redis.uptrace.dev — la alternativa.
- **Redis: Key eviction** — https://redis.io/docs/latest/develop/reference/eviction/
  — las políticas de expulsión y cuándo usar cada una.
- **Redis: Distributed locks** — https://redis.io/docs/latest/develop/use-cases/distributed-locks/
  — incluye Redlock y, honestamente, sus críticas.
- **`golang.org/x/sync/singleflight`** —
  https://pkg.go.dev/golang.org/x/sync/singleflight

### Libros

- **Designing Data-Intensive Applications** — Kleppmann. El capítulo 8
  (*The Trouble with Distributed Systems*) es **lo que sostiene la advertencia de
  §6.2** sobre bloqueos: pausas de proceso, relojes poco fiables, y por qué un
  bloqueo con TTL no garantiza exclusión mutua.
- **Redis in Action** — Josiah Carlson. Antiguo y sigue siendo la mejor
  introducción a los patrones: límite de tasa, bloqueos, colas.
- **Site Reliability Engineering** (Google) — el capítulo sobre *cascading
  failures* describe exactamente la estampida y la expiración sincronizada.

### Artículos y charlas

- **How to do distributed locking** — Martin Kleppmann,
  https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html —
  **la lectura obligatoria de esta fase.** La crítica a Redlock y la distinción
  entre eficiencia y corrección salen de aquí.
- **Is Redlock safe?** — Salvatore Sanfilippo (antirez),
  http://antirez.com/news/101 — la respuesta del autor de Redis. **Lee las dos**:
  el intercambio entre los dos es la mejor clase de sistemas distribuidos que hay
  en internet, y las dos partes tienen razón en algo.
- **Caching at Netflix / Facebook's memcache paper** — busca *"Scaling Memcache at
  Facebook"* (NSDI 2013): la estampida, el *leasing* y la invalidación a escala,
  con datos reales.
- **Cache stampede** — https://en.wikipedia.org/wiki/Cache_stampede — corto, y
  cubre el refresco anticipado probabilístico (XFetch), que es más elegante que el
  de §6.2.
- **The Valkey fork: what happened and why** — busca el anuncio de la Linux
  Foundation de 2024, para tener el contexto.
- **Caching Strategies** — busca el material de AWS sobre *cache-aside*,
  *write-through* y *write-behind*; está bien explicado y es agnóstico.

### Video

- **Redis Deep Dive** — las charlas de antirez sobre el diseño interno.
- **GopherCon: Caching in Go** — busca las posteriores a 2020.
- **Distributed systems lectures** — Martin Kleppmann tiene su curso de Cambridge
  en YouTube; la clase sobre relojes y pausas es la base del ⚠️ de §6.2.

> ⚠️ Casi todo el material dice "Redis" y aplica tal cual a Valkey: mismo
> protocolo, mismos comandos, mismo comportamiento. Lo único que cambia es la
> licencia y el gobierno del proyecto. Y ojo con el material anterior a 2020 sobre
> clientes de Go: `redigo` era el estándar y hoy está en mantenimiento.

### Orden de lectura sugerido

**Antes de escribir código:** el artículo de Kleppmann sobre bloqueos
distribuidos. Media hora, y es lo que impide que uses Valkey para corrección.
**Durante:** la referencia de comandos cuando dudes de la complejidad de uno, y la
página de políticas de expulsión antes de configurar `maxmemory`.
**Después:** la respuesta de antirez, y después vuelve a leer a Kleppmann. Los dos
juntos son la mejor lección de sistemas distribuidos del curso, y no van de caché:
van de qué se puede garantizar y qué no.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

**El veredicto principal, y es el que el curso sostiene con números:**

> **Un mapa en memoria con TTL resuelve más casos de los que la gente cree, y no
> necesita un servicio más en el `compose.yaml`.**

Las cuatro preguntas que deciden, en orden:

1. **¿Cabe el conjunto de datos en la memoria de una instancia?** 250 países a 2 KB
   son 500 KB. Sí. Con un catálogo de diez millones de productos, no.
2. **¿Cuántas instancias hay?** Con tres, la caché local multiplica la carga de
   llenado por tres y nadie lo nota. Con cincuenta, sí.
3. **¿Cuánto cuesta llenar la caché?** Una lectura de MongoDB son milisegundos:
   irrelevante. Una consulta agregada de diez segundos: muy relevante, y ahí
   compartirla entre instancias vale mucho.
4. **¿Importa la coherencia entre instancias?** Si dos usuarios pueden recibir
   respuestas distintas del mismo dato porque dieron en instancias distintas, y eso
   es un problema, necesitas caché compartida.

**Y los casos donde Valkey no es la respuesta, aunque parezca:**

- **Como base de datos primaria.** Tiene persistencia (RDB y AOF) y **no es una
  base de datos duradera**: AOF con `everysec` puede perder un segundo de
  escrituras, y un reinicio con la configuración por defecto puede perderlo todo.
  La autopsia de §7 va de esto.
- **Como bus de eventos, con Streams.** Los Streams existen, tienen grupos de
  consumidores y confirmación, y para muchos casos bastan. **Este curso usa el
  patrón outbox en PostgreSQL** (Fase 13), y el motivo es que el evento y el cambio
  de estado que lo produce tienen que escribirse **atómicamente**, y eso solo lo da
  una transacción en la misma base de datos. Si el evento va a otro sistema, se
  pierde la atomicidad. Con Kafka pasa igual, y por eso el outbox existe.
- **Como Pub/Sub para invalidación.** Entrega **como máximo una vez**: una
  instancia desconectada pierde el mensaje y su caché queda obsoleta
  indefinidamente. Rechazado en §6.7 con su condición de revisión.
- **Para bloqueos que garanticen corrección.** El ⚠️ de §6.2, y no es negociable.
- **Y para límites de tasa con precisión estricta.** El *token bucket* distribuido
  es aproximado: hay deriva de relojes y ventanas de carrera. Para un límite
  comercial ("mil peticiones por hora"), perfecto. Para un límite contractual con
  penalización económica, la contabilidad va en la base de datos.

**Y una reflexión final sobre el ecosistema**, que es la diferencia real con
Spring: `@Cacheable` te da en una anotación lo que aquí son cien líneas, y **para
el 80% de los casos esa anotación es suficiente y correcta**. Lo que ganas
escribiéndolo es que las cuatro decisiones —clave, serialización, TTL, qué pasa si
falla— son tuyas y las tomaste a conciencia. Lo que pierdes es tiempo. **Si tu
equipo va a cachear veinte métodos con criterios estándar, la anotación gana; si
vas a cachear tres cosas con criterios que importan, escribirlo gana.**

### 📖 Diccionario Java ⇄ Go de esta fase

| Java / Spring | Go | Dónde se rompe la equivalencia |
|---|---|---|
| `@Cacheable("x")` | un decorador que implementa la misma interfaz | Sin anotación. **Las cuatro decisiones que `@Cacheable` esconde —clave, serialización, TTL, fallo— se toman explícitamente** |
| `@CacheEvict` | `Delete` explícito, o invalidación por etiqueta/generación | Igual de explícito; sin `allEntries=true` mágico |
| `@CachePut` | *(no se usa)* | El curso invalida en vez de actualizar: menos ventana de carrera |
| `CacheManager` | el tipo `Cache[T]` construido en `main` | Sin abstracción de proveedor. Cambiar de backend es cambiar el constructor |
| `KeyGenerator` por defecto | `KeyBuilder` escrito | ⚠️ La clave por defecto de Spring **cambia si añades un parámetro al método**, y la caché queda huérfana sin aviso |
| `RedisTemplate` con serialización Java | `Codec[T]` explícito, JSON por defecto | La serialización de Java **acopla la caché a la versión de tus clases**; añadir un campo invalida todo |
| `Caffeine` (caché local) | un mapa con TTL (Fase 10) | Caffeine hace más: expulsión por tamaño, `refreshAfterWrite`, estadísticas. En Go se escribe o se importa |
| `refreshAfterWrite` | refresco anticipado escrito (§6.2) | Mismo patrón, veinte líneas |
| `@Cacheable(sync=true)` | `singleflight.Group` | Idéntico en propósito |
| `CacheErrorHandler` | *fail open* por diseño | ⚠️ Por defecto Spring **propaga la excepción** y la petición falla; casi nadie lo cambia |
| Bucket4j | *token bucket* en Lua sobre Valkey | Mismo algoritmo. En Go se escribe el script |
| `@RateLimiter` de Resilience4j | el limitador escrito | Resilience4j es local; el distribuido se monta igual en los dos |
| Redisson `RLock` | `SET NX EX` + script Lua de liberación | **Misma limitación de fondo**: no garantiza exclusión mutua. No es un problema del lenguaje |
| Redisson `RLock` con *watchdog* | *(no implementado)* | El *watchdog* de Redisson renueva el TTL mientras el proceso vive. Mitiga y **no elimina** el problema |
| Spring Session con Redis | *(fuera del curso)* | Meridian vive tras un gateway que gestiona sesiones |
| Caché de 2º nivel de Hibernate | *(no existe)* | No hay ORM con caché (Fase 09). Se cachea en la capa de servicio, explícitamente |
| `@Transactional` + caché | invalidar **después** del commit | En Go es una línea de código; en Spring hace falta `TransactionSynchronization` para hacerlo bien |
| Micrometer con métricas de caché | contadores propios (Fase 14) | Se escriben; a cambio mides lo que quieres |

### Qué sigue

La Fase 13 es donde **los cuatro servicios se conectan entre sí**, y es el
territorio donde Java es fuerte: **lotes, scheduling y trabajo asíncrono**.

El cierre nocturno de ClearingHouse es el caso: leer millones de movimientos,
conciliarlos, producir asientos y cerrar el periodo, de forma **reanudable** y sin
cargar nada entero en memoria. Con fragmentación y punto de control en la misma
transacción, idempotencia del lote, reanudación tras caída, y las cinco propiedades
probadas: reanudable, idempotente, acotado en memoria, observable y cancelable.

Y el **patrón outbox implementado completo**, que es donde OpsReport y EventRelay
se encuentran de verdad.

Con el 🧨 más memorable del curso: escribir primero la versión ingenua del cierre
que carga todo en memoria, medirla, y **mirar subir la memoria residente hasta que
el proceso muere**. Después, la versión con fragmentos.

Y la comparación con Spring Batch con el código de los dos delante, incluida la
parte honesta: **Spring Batch resuelve reanudación, reintento por ítem,
particionado y métricas de job que aquí hay que escribir.** Si tu proceso por lotes
es complejo de verdad, eso es un argumento real a favor de Java.

### La señal de que quedó bien

> *"Apago Valkey en producción y lo que pasa es que la latencia sube. Nada más."*

Si apagar la caché rompe algo, vuelve a la autopsia: lo que tienes no es una caché.
Y si nunca lo has probado, **pruébalo hoy** — es un test de una línea y te va a
decir más que cualquier panel.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go test -race ./...` y `go test -tags=integration ./...` en verde, la
> suite pasando **con la caché desactivada**, `golangci-lint run` limpio y
> `git status` sin cambios pendientes:
>
> ```bash
> git tag -a fase-12 -m "F12 cerrada: caché de AtlasSync con cache-aside, TTL con jitter y fail open; claves versionadas; estampida resuelta con singleflight y bloqueo distribuido; invalidación por etiqueta y por generación; token bucket distribuido para EventRelay; idempotencia con SET NX respaldada por la restricción única; B-17 y B-18 medidos"
> git tag -a atlassync/v0.3 -m "AtlasSync: caché de lectura con invalidación pensada"
> git tag -a eventrelay/v0.10 -m "EventRelay: límite de tasa distribuido e idempotencia"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 12: …`) y los de ejercicio su
> número (`fase 12 ej20: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **La caché en memoria con TTL de la Fase 10** es la línea base declarada de B-17.
  **Cadena verificada en las dos direcciones** (la Fase 10 lo anotó, esta fase lo
  usa).
- **`CLIENT TRACKING` (invalidación del lado cliente)** — ejercicio 🔥 que pide
  reevaluar el rechazo del Pub/Sub. Es la solución correcta al problema y el curso
  no la usa. **Si se quisiera formalizar, su sitio sería aquí, no otra fase.**
  Decisión: queda como 🔥.
- **Streams de Valkey frente al outbox** — se rechaza aquí en el ⚖️ y la **Fase 13**
  implementa el outbox. **Verificar que la Fase 13 recoge esta comparación en su ⚖️
  veredicto**, junto a la de Kafka: son la misma discusión.
- **Métricas de caché a Prometheus** — los contadores existen aquí y la **Fase 14
  §6.3 los exporta tal cual**, con un ⚠️ explícito sobre no inventar nombres nuevos
  y con la decisión de calcular la tasa de acierto en Prometheus en vez de
  exportarla como gauge (un porcentaje por réplica no promedia). Cadena verificada
  en las dos direcciones.
- **Test con `CACHE_ENABLED=false`** — es la regla 2 de la autopsia y **tiene que
  estar en el objetivo de `make test`**, no solo escrito. Comprobar que el Makefile
  de la Fase 14 lo recoge cuando se endurezca.
- **`valkey-go` frente a `redis/go-redis`** — ejercicio 🔥 con medición. Si se mide
  de verdad, es candidata a entrada de `BENCHMARKS.md`; si no, retirar la
  afirmación sobre el *pipelining* de §4 o marcarla como característica declarada
  por el proyecto y no medida por el curso. **`prompts/formato-de-benchmarks.md` §3 exige
  una de las dos.**

## ☕ Reflejos para `INSTINTOS.md`

- **"`@Cacheable` y ya está cacheado"** — el reflejo raíz de la fase. Esconde
  cuatro decisiones: clave, serialización, TTL y qué pasa si el backend falla. En
  Spring, la última por defecto **propaga la excepción**.
- **"La caché se puede quedar sin TTL, total el dato no cambia"** — el paso 2 de la
  autopsia. Coste: 16 minutos de caída total cuando Valkey se reinició. Antídoto:
  **toda clave de caché tiene TTL**; si no debe expirar, no es caché.
- **"Si la caché siempre está actualizada, ¿para qué leer del origen?"** — el paso
  4. Convierte una optimización en un punto único de fallo sin durabilidad.
- **"Un bloqueo distribuido garantiza exclusión mutua"** — no lo hace, y no es
  arreglable con un algoritmo mejor. Eficiencia sí; corrección, a la base de datos.
- **"Actualizo la caché al escribir, así está siempre fresca"** — amplía la ventana
  de carrera; dos escritores pueden dejar el valor del perdedor.
- **"El TTL de una hora está bien"** — sin jitter, todo expira a la vez y el pico
  ocurre igual, cada hora en punto.
- **"Poner caché siempre mejora"** — B-17 puede decir que un mapa en memoria ya lo
  resolvía y que Valkey solo añadió un servicio que mantener.

## 📐 Mediciones para `BENCHMARKS.md`

- **B-17 — AtlasSync: tasa de acierto y latencia con y sin Valkey.** ⚠️ **Tres
  variantes obligatorias**, no dos: sin caché, mapa en memoria con TTL, y Valkey.
  Medir solo "con y sin caché" produciría el titular fácil y **ocultaría el
  hallazgo real**, que es que la caché local ya resolvía el problema. La hipótesis
  está escrita en §6.8 y es deliberadamente incómoda. **Esta es la entrada donde la
  regla 5 de honestidad más filo tiene en todo el curso.**
- **B-18 — Bytes precodificados frente a codificar por petición.** Tres codecs ×
  dos tamaños de valor. Reportar también el **tamaño ocupado en Valkey**, no solo
  el tiempo. El veredicto debe decir qué se pierde: la caché pasa a guardar la
  representación de la API, no el dominio.
- Propuesta nueva, sin ID: **coste del jitter sobre el pico de fallos de caché**.
  Sale del 🧨 y del ejercicio 8. No es un benchmark de rendimiento sino de
  **distribución**, y por eso no encaja bien en el formato actual de
  `BENCHMARKS.md` (que pide p50/p95/p99 y ops/s). **Sugerencia: encajarlo como
  sección "distribución temporal de fallos" dentro de B-17**, en vez de como
  entrada propia.
