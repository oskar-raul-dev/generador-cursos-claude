# 05 — Lab: IO bloqueante y no bloqueante en cinco lenguajes

> **Documento opcional.** La teoría está en el bloque
> [`08-entrada-salida-y-recursos`](../08-entrada-salida-y-recursos/), sobre todo en su capítulo `03`.
> Aquí solo se teclea y se mide. Nadie necesita este documento para aprobar una entrevista; sirve
> para tener el banco de pruebas montado y poder repetir las medidas en tu máquina.
>
> **Todo lo que aparece aquí se ejecutó** y las versiones están declaradas al final. Las soluciones
> van inline: no hay solucionario aparte.
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El banco de pruebas

Un solo experimento sirve para todo el lab: **un servidor TCP que tarda 100 ms en responder**, y un
generador de carga que abre N conexiones a la vez. Cambiando solo el modelo del servidor se mide qué
cuesta cada forma de esperar.

```python
# carga.py — generador con asyncio: N conexiones simultáneas, baratas en el cliente
import asyncio, sys, time

puerto, n = int(sys.argv[1]), int(sys.argv[2])
lat, err = [], []

async def cliente():
    t0 = time.perf_counter()
    try:
        r, w = await asyncio.wait_for(asyncio.open_connection("127.0.0.1", puerto), 30)
        w.write(b"hola\n"); await w.drain()
        d = await asyncio.wait_for(r.read(1024), 30)
        w.close()
        if not d: raise OSError("respuesta vacia")
        lat.append(time.perf_counter() - t0)
    except Exception as e:
        err.append(repr(e))

async def main():
    t0 = time.perf_counter()
    await asyncio.gather(*(cliente() for _ in range(n)))
    total = time.perf_counter() - t0
    lat.sort()
    p = lambda q: lat[min(int(len(lat)*q), len(lat)-1)]*1000 if lat else float("nan")
    print(f"{n:5d} conexiones · total {total*1000:7.0f} ms · p50 {p(.5):7.0f} · p95 {p(.95):7.0f} · errores {len(err)}")

asyncio.run(main())
```

- **El generador tiene que ser asíncrono.** Con miles de conexiones, un cliente de hilo por conexión
  se convierte en el cuello y estarías midiendo el cliente. Es el error número uno de las pruebas de
  carga caseras.
- **Se miden percentiles, no la media.** La media esconde exactamente lo que interesa: qué le pasa a
  la conexión que peor lo pasa.
- **Se cuentan los errores.** El punto interesante de una prueba de carga no es dónde sube la
  latencia, es dónde empiezan los rechazos.

Cómo se mide el coste, que es lo que de verdad distingue a los modelos:

```bash
ps -M <pid> | tail -n +2 | wc -l      # hilos del sistema operativo del proceso servidor
ps -o rss= -p <pid>                    # memoria residente, en KB
```

---

## 2. 🧱 Los siete servidores

### Secuencial — Python

```python
s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", 9101)); s.listen(256)
while True:
    c, _ = s.accept()          # una conexión...
    c.recv(1024)
    time.sleep(0.1)            # ...100 ms de "trabajo"...
    c.sendall(b"ok\n"); c.close()   # ...y solo entonces la siguiente
```

- `SO_REUSEADDR` evita el "address already in use" al reiniciar mientras quedan conexiones en
  `TIME_WAIT`. Sin él, el lab es incómodo.
- `listen(256)` es la cola de conexiones pendientes: sin ella, con 50 clientes a la vez habría
  rechazos y estarías midiendo otra cosa.

### Hilo por conexión — Python

```python
def atender(c):
    c.recv(1024); time.sleep(0.1); c.sendall(b"ok\n"); c.close()
while True:
    c, _ = s.accept()
    threading.Thread(target=atender, args=(c,), daemon=True).start()
```

- `daemon=True` para que el proceso pueda morir sin esperar a los hilos. En un servidor de verdad se
  usa un pool y un apagado ordenado; aquí interesa la forma mínima.

### Bucle de eventos — Python `asyncio`

```python
async def atender(lector, escritor):
    await lector.read(1024)
    await asyncio.sleep(0.1)          # cede el control en vez de bloquear el hilo
    escritor.write(b"ok\n"); await escritor.drain(); escritor.close()
```

- **`asyncio.sleep` y no `time.sleep`.** Ese es el punto entero: `time.sleep` dentro de una corrutina
  bloquea el bucle y convierte este servidor en el secuencial. Es el error que la documentación de
  `asyncio` pone el primero.

### Bucle de eventos — Node

```javascript
const srv = net.createServer((c) => {
  c.on("data", () => {
    setTimeout(() => { c.write("ok\n"); c.end(); }, 100);   // no bloquea el bucle
  });
});
srv.listen(9105, "127.0.0.1");
```

### Goroutines — Go

```go
func atender(c net.Conn) {
	defer c.Close()
	b := make([]byte, 1024)
	c.Read(b)                       // parece bloqueante...
	time.Sleep(100 * time.Millisecond)
	c.Write([]byte("ok\n"))
}

for {
	c, err := l.Accept()
	if err != nil { return }
	go atender(c)                   // ...pero el runtime lo convierte en no bloqueante
}
```

- **Este es el código que mejor resume el capítulo `03`:** se lee exactamente como el bloqueante de
  Python y se comporta como el bucle de eventos. El `netpoller` aparca la goroutine y libera el hilo.

### Los tres de Java, en un solo programa

```java
ExecutorService ex = switch (modo) {
    case "plataforma" -> Executors.newCachedThreadPool();              // un hilo del SO por conexión
    case "pool"       -> Executors.newFixedThreadPool(8);              // pool acotado
    case "virtuales"  -> Executors.newVirtualThreadPerTaskExecutor();  // Java 21
};
while (true) {
    Socket c = ss.accept();
    ex.submit(() -> atender(c));    // el cuerpo de atender() es IDÉNTICO en los tres
}
```

- **Lo importante es que `atender` no cambia.** El mismo código bloqueante —`read`, `sleep`, `write`—
  se comporta de tres formas distintas según el ejecutor. Eso es exactamente lo que hace baratos los
  hilos virtuales frente a reactivo.

---

## 3. 📊 Las medidas

**50 conexiones simultáneas:**

```text
Python, un solo hilo (secuencial)     5131 ms      ← 50 × 100 ms, en fila india
Java, pool acotado de 8 hilos          727 ms      ← 50/8 × 100 ms + reparto
Java, hilos de plataforma              177 ms
Python, hilos del sistema              133 ms
Node, bucle de eventos                 125 ms
Java, hilos virtuales                  122 ms
Python, asyncio                        121 ms
Go, goroutines                         116 ms
```

**2 000 conexiones simultáneas**, con el coste al lado:

| Servidor | hilos del SO | RSS | total |
|---|---|---|---|
| Python, hilos del sistema | 1 780 | 78 MB | **4 458 ms** |
| Java, hilos de plataforma | **2 014** | **240 MB** | 490 ms |
| Java, hilos virtuales | **35** | 64 MB | 419 ms |
| Python, `asyncio` | 1 | 34 MB | 377 ms |
| Go, goroutines | **12** | **14 MB** | 371 ms |
| Node, bucle de eventos | 8 | 35 MB | 258 ms |

Cómo se leen estas dos tablas:

- **La primera enseña el pool acotado.** 727 ms contra 122 ms del mismo Java con otro ejecutor: la
  única diferencia es acotar. `50/8 × 100 ms = 625 ms` predice el resultado antes de medirlo, y el
  exceso hasta 727 es la sobrecarga de reparto.
- **La segunda enseña que la latencia engaña.** 490 ms contra 419 ms no distingue nada; 2 014 hilos
  contra 35, sí. **El techo se ve en los recursos mucho antes que en el reloj.**
- **Node con ocho hilos** no es un error de medida: es el bucle de eventos más el pool de `libuv`.
- **Python con hilos es el peor de los ocho** en 2 000 conexiones, y no por descriptores: 1 780 hilos
  contendiendo por el bloqueo global del intérprete.

---

## 4. 🧱 El otro lado: N peticiones concurrentes desde el cliente

El mismo problema visto desde quien llama. Veinte peticiones de 100 ms cada una, contra el servidor
del banco de pruebas:

```python
# Python
async def main():
    await asyncio.gather(*(una() for _ in range(20)))
```

```javascript
// Node
Promise.all(Array.from({length: 20}, una))
```

```go
// Go
var wg sync.WaitGroup
for i := 0; i < 20; i++ {
	wg.Add(1)
	go func() { defer wg.Done(); una() }()    // una goroutine por petición: barato
}
wg.Wait()
```

```java
// Java 21
try (var ex = Executors.newVirtualThreadPerTaskExecutor()) {
    ex.invokeAll(tareas);                     // un hilo virtual por petición
}
```

```text
Python asyncio.gather :    104 ms
Node   Promise.all    :    109 ms
Go     goroutines+WG  :    106 ms
Java   hilos virtuales:    129 ms
```

- **Veinte peticiones de 100 ms en ~110 ms**: la espera se solapa entera. Secuencialmente serían 2 000
  ms, y ese es el número con el que hay que comparar.
- **Los cuatro modelos dan lo mismo** a esta escala, que es justo la conclusión del capítulo `03`: con
  poca concurrencia, el modelo no decide nada.
- El de Java sale algo por encima porque incluye el arranque de la máquina virtual y del ejecutor; con
  más iteraciones converge con los demás.

---

## 5. 🧪 Ejercicios

Con solución al lado. Se teclean y se ejecutan; leerlos no cuenta.

### 🟢 E1 — Predecir antes de medir

Antes de ejecutar nada, predice la latencia total de los siete servidores con 50 conexiones. Luego
mide y compara.

> **Solución.** Las tres fórmulas: secuencial `N × t`; pool acotado `N/P × t`; cualquier modelo que no
> acote, `≈ t` más sobrecarga. Con N=50, t=100 ms y P=8 salen 5 000, 625 y ~100 ms, y lo medido fue
> 5 131, 727 y 116–177. **Lo interesante es cuando la predicción falla**: si un modelo no acotado
> tardara mucho más de 100 ms, el cuello estaría en el generador de carga y no en el servidor.

### 🟢 E2 — Romper `asyncio` con una línea

Cambia `await asyncio.sleep(0.1)` por `time.sleep(0.1)` en el servidor de `asyncio` y vuelve a medir.

> **Solución.** Pasa de 121 ms a unos 5 100 ms: se convierte en el servidor secuencial. El bucle de
> eventos tiene un solo hilo, y una llamada bloqueante dentro de una corrutina lo para entero. Es el
> error que la documentación de `asyncio` pone el primero, y la demostración de que **el modelo no
> protege de sí mismo**: basta una línea de código bloqueante en cualquier parte de la cadena.

### 🟡 E3 — El pool que serializa

Ejecuta el servidor Java en modo `pool` con tamaños 1, 2, 8 y 50, con 50 conexiones. Dibuja la curva.

> **Solución.** La latencia total sigue `N/P × t` hasta que `P ≥ N`, donde se aplana en ~100 ms: 5 000,
> 2 500, 625 y ~100 ms. Lo que hay que observar es que **la curva no tiene rodilla**: no existe un
> tamaño "óptimo" del pool para trabajo de espera, porque cualquier límite es un límite. El tamaño
> óptimo para espera es "no acotar", y acotar solo tiene sentido para proteger CPU o un recurso aguas
> abajo — y entonces el límite se elige por ese recurso, no por la latencia.

### 🟡 E4 — Contar hilos y memoria

Repite las medidas de 2 000 conexiones en tu máquina y anota hilos y memoria residente además de la
latencia.

> **Solución.** Los números absolutos variarán —sistema operativo, versión y núcleos—, pero **las
> proporciones se mantienen**: hilos de plataforma del orden de N, hilos ligeros del orden de los
> núcleos. El detalle que hay que cuidar: medir **durante** la carga y no después, porque los hilos
> se destruyen al terminar; de ahí el `sleep 0.7` entre lanzar la carga y contar. Y restar siempre una
> línea base sin carga, como en las medidas de memoria del bloque `07`.

### 🟠 E5 — Provocar el incidente del proveedor lento

Sube el retardo del servidor a 5 segundos y mide el modo `pool` de 8 con 50 conexiones. Luego compara
con hilos virtuales.

> **Solución.** El pool pasa de 727 ms a unos 31 s —`50/8 × 5 s`— mientras los hilos virtuales se
> quedan en ~5 s. Es el incidente del capítulo `03` reproducido en tu portátil: **un proveedor que se
> vuelve lento convierte un pool acotado en una caída**. La versión completa del ejercicio añade un
> segundo endpoint rápido que no toca al proveedor lento y comprueba que **también** se degrada: eso
> es lo que hace que el síntoma parezca general y la causa sea un solo integrante. Y la corrección que
> hay que probar después: un timeout de 500 ms en el lado del servidor, que convierte la caída en
> errores acotados.

### 🟠 E6 — Agotar los descriptores

Escribe un cliente que abra conexiones y no las cierre, hasta que el servidor deje de aceptar. Observa
el error en los dos lados.

> **Solución.** El servidor acaba con `Too many open files` o dejando de aceptar, y el cliente ve
> conexiones rechazadas. Lo que hay que observar es que **el error del servidor no menciona al cliente
> culpable** y que el resto del servicio —incluidas operaciones que no usan red— empieza a fallar a la
> vez, por `08/01 → 21`. Baja el límite con `ulimit -n 256` en el shell del servidor para que el
> experimento tarde segundos en vez de minutos. Y mide la métrica de descriptores durante el proceso:
> ver la curva subir hasta el techo es lo que hace que el capítulo `01` deje de ser abstracto.

### 🔴 E7 — El servidor que hace trabajo de CPU

Sustituye los 100 ms de espera por 100 ms de cálculo real en el bucle de eventos de Node y en Go.
Mide con 50 conexiones y explica la diferencia.

> **Solución.** Node se degrada linealmente —se convierte en secuencial, ~5 s— porque hay un solo hilo
> ejecutando manejadores. Go usa todos los núcleos y tarda aproximadamente `50/núcleos × 100 ms`. Es
> la demostración de que **el bucle de eventos paraleliza espera y no cálculo**, y de que la elección
> de modelo depende de cuál de los dos domina. Lo que hay que añadir para que el ejercicio esté
> completo: la corrección en Node es un `worker_thread` o un proceso aparte, y medir que con eso
> converge con Go — lo que demuestra que el problema era el modelo y no el lenguaje.

### 🔥 E8 — Fuera de conteo: el techo de verdad

Sube la concurrencia por escalones —50, 200, 1 000, 5 000, 20 000— contra cada modelo, y encuentra
dónde empieza a haber errores, no dónde sube la latencia.

> **Solución.** Antes de sacar conclusiones hay que quitar tres cuellos que no son del servidor: el
> límite de descriptores **del cliente** —el generador necesita tantos como conexiones—, el rango de
> puertos efímeros del sistema, y la cola de `listen`. Con eso resuelto, lo esperable es que los
> modelos de hilo del sistema fallen primero por memoria o por límite de hilos, y los ligeros aguanten
> hasta el límite de descriptores. **El resultado que hay que saber interpretar es el que no esperas**:
> si todos fallan a la vez y en el mismo número, el techo es del sistema —descriptores o puertos— y no
> del modelo, y la prueba no ha medido lo que creías. Ese es el motivo de registrar siempre errores y
> recursos, y no solo tiempos.

---

## 6. 📝 Versiones con las que se ejecutó

```text
Java    Zulu 21.0.12 (hilos virtuales) y 17.0.16 (el resto) — sdkman
Python  3.13.4
Node    24.21.0
Go      1.27.1
Máquina 8 núcleos, macOS
```

Las medidas de memoria son `ps -o rss=` y el conteo de hilos `ps -M`, tomados **durante** la carga.
Los números absolutos dependen de la máquina; lo que se mantiene entre máquinas son las proporciones
y el orden, que es lo que el lab enseña. Nada de lo que aparece aquí es una salida esperada: todas son
salidas reales.

---

**Anterior:** [`04` — Lab: formatos en cinco lenguajes](04-lab-formatos-en-cinco-lenguajes.md) ·
**Teoría:** [`08-entrada-salida-y-recursos`](../08-entrada-salida-y-recursos/) ·
**Bloque:** [README](README.md)
