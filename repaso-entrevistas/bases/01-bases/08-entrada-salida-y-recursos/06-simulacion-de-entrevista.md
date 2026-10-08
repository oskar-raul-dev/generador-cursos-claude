# 06 — Simulación de entrevista

> El examen del bloque: 36 preguntas transversales que cruzan los cinco capítulos y cinco problemas
> de pizarra de veinte minutos. En voz alta y tecleando, que es como se responde de verdad.
>
> Las soluciones están en [`07` — Respuestas](07-respuestas.md). Se miran **después**.
>
> **Vigencia:** 2026-09-18. · **Requisito:** los cinco capítulos del bloque.

---

## 1. 🎯 Cómo se usa esto

```text
1. Cronómetro: 2 minutos por pregunta S#, 20 por problema de pizarra.
2. EN VOZ ALTA, y el código TECLEADO.
3. Primero la frase de 30 segundos; se amplía solo si quedó completa.
4. Después se compara y se anota qué capa faltó.
```

Dos reglas propias de este bloque:

- **Lleva siempre un número.** Este temario tiene medidas: el factor de once mil del búfer, los 2 014
  hilos contra 35, los cincuenta de `fsync`. Una respuesta con un número medido vale el doble que la
  misma respuesta en abstracto.
- **Di qué hace el hilo.** Casi todas las preguntas de este bloque se reducen a *"¿qué está haciendo
  mi hilo mientras espera?"*. Si tu respuesta no lo dice, está incompleta.

---

## 2. 🧠 Preguntas transversales

### Bloque A — El recurso

**S1.** ¿Qué es un descriptor de archivo y qué cosas lo usan? 🟢

**S2.** Te llega `Too many open files` en producción. ¿Qué haces en los primeros cinco minutos? 🟠

**S3.** ¿Por qué ese error aparece con memoria libre de sobra? 🟠

**S4.** ¿Quién cierra un archivo que olvidaste cerrar, en cada uno de los cinco lenguajes? 🟡

**S5.** ¿Dónde está la trampa de `defer` en Go? 🟡

**S6.** ¿Cómo distingues una fuga de descriptores de un dimensionado corto? 🟠

**S7.** ¿Qué métrica expondrías y con qué umbral? 🟡

### Bloque B — El paradigma

**S8.** ¿Qué significa "todo es un archivo" y qué unifica de verdad? 🟡

**S9.** ¿Por qué no se puede hacer `epoll` sobre un archivo regular? 🟠

**S10.** ¿Por qué existe `io_uring`? 🟠

**S11.** ¿Es Node de un solo hilo? 🟡

**S12.** ¿Qué devuelve `read` cuando el otro extremo cierra, y en qué se diferencia de un archivo? 🟡

**S13.** ¿Qué código funciona con archivos y falla con sockets? 🟠

### Bloque C — Los modelos

**S14.** Diferencia bloqueante, no bloqueante y asíncrono. 🟡

**S15.** ¿Cuál de las cuatro combinaciones es la peor? 🟡

**S16.** ¿Hasta cuántas conexiones aguanta hilo por conexión? 🟡

**S17.** ¿Son más rápidos los hilos virtuales? 🟠

**S18.** ¿Por qué un pool acotado puede tumbar un servicio? 🟠

**S19.** ¿Qué tienen en común Go y Java 21, y en qué se diferencian de Node? 🟡

**S20.** ¿Qué es el color de las funciones? 🟡

**S21.** ¿Cuándo es reactivo peor que bloqueante? 🟠

### Bloque D — El coste

**S22.** ¿Por qué leer byte a byte es mil veces más lento si el algoritmo es `O(n)`? 🟡

**S23.** ¿Qué tamaño de búfer usarías y por qué ese? 🟡

**S24.** Diferencia `flush` de `fsync`, y di a qué fallo sobrevive cada uno. 🟡

**S25.** ¿Cuánto cuesta `fsync` y por qué las bases de datos lo agrupan? 🟠

**S26.** ¿Qué es la contrapresión y qué pasa sin ella? 🟠

**S27.** ¿Qué relación tiene con las colas acotadas del bloque `06`? 🟠

### Bloque E — El árbol

**S28.** ¿Por qué un sistema de archivos no es un árbol? 🟡

**S29.** ¿Cómo detectas un ciclo de enlaces y qué guardas en el conjunto de visitados? 🟠

**S30.** ¿Qué hacen Java, Python y Go ante el mismo ciclo? 🟡

**S31.** ¿Por qué pedir el tamaño de cada archivo multiplica por cinco el recorrido? 🟠

### Bloque F — Las que descolocan

**S32.** El entrevistador dice que hilo por conexión "está obsoleto". ¿Qué contestas? 🟠

**S33.** ¿Cuándo es correcto no usar búfer? 🟠

**S34.** Si todo IO es leer y escribir en un descriptor, ¿por qué hay tantas bibliotecas distintas? 🟠

**S35.** Te piden bajar la latencia de un servicio y el perfilador de CPU no encuentra nada. ¿Por
dónde empiezas? 🔴

**S36.** Si tuvieras que enseñar este bloque en cinco minutos, ¿qué dirías y qué dejarías fuera? 🔴

---

## 3. 🧪 Problemas de pizarra

Veinte minutos cada uno, tecleados. Se pregunta lo que falte antes de escribir.

### P1 — Copiar un flujo, bien 🟡

Escribe una función que copie de un origen a un destino con búfer, cierre los dos recursos pase lo
que pase y devuelva los bytes copiados. En dos lenguajes distintos.

**Fuerza:** el cierre determinista y el bucle de lectura parcial. Quien escribe `read` una sola vez,
o quien cierra solo el destino, falla — y son los dos errores más comunes del bloque.

### P2 — El recorrido que no se cuelga 🟠

Recorre un árbol de directorios sumando tamaños, siguiendo enlaces simbólicos, sin colgarte con un
ciclo y sin morir por un permiso denegado.

**Fuerza:** reconocer que **es detección de ciclos**, y que la clave del conjunto de visitados no es
la ruta sino la identidad del inodo. Quien guarda rutas no detecta nada.

### P3 — El servidor, en tres modelos 🔴

Escribe el mismo servidor TCP de eco con retardo en tres modelos: hilo por conexión, pool acotado y
no bloqueante o hilos ligeros. Predice la latencia de cada uno con 50 conexiones **antes** de
medirla.

**Fuerza:** la aritmética del pool. `50/8 × 100 ms` tiene que salir de tu cabeza antes de ejecutar
nada; si la predicción no cuadra con la medida, eso es lo interesante.

### P4 — El escritor duradero 🔴

Escribe un registro de operaciones que garantice que, tras devolver el control, el dato sobrevive a
un corte de corriente. Mide el coste y propón la versión que agrupa.

**Fuerza:** la distinción entre los tres niveles de "escrito" y el compromiso explícito entre
durabilidad y rendimiento. La respuesta completa incluye qué se pierde al agrupar y cómo se acota.

### P5 — Los archivos duplicados 🟢

Un directorio con **500** archivos. Encuentra todos los pares con contenido idéntico.

**Fuerza:** que reconozcas que **la fuerza bruta acotada es la respuesta correcta**, pero con una
poda evidente: comparar los 124 750 pares byte a byte es absurdo; agrupar primero por tamaño y solo
entonces comparar deja el trabajo en casi nada. Proponer un hash criptográfico de todos los archivos
antes de mirar el tamaño es hacer más trabajo del necesario, y decirlo en voz alta es la respuesta.

---

## 4. 💡 Las frases que hay que tener listas

> **"El límite que aplica no es el que dice `ulimit`."** Es el menor de shell, núcleo por proceso y
> contenedor — y por eso el incidente dura horas cuando solo se mira uno.

> **"Un pool acotado protege la CPU y no protege la espera."** Si los hilos van a esperar red,
> acotarlos convierte la lentitud de un proveedor en una caída propia.

> **"Lo que cambia con los hilos virtuales no es la velocidad, es cuántos caben."** 2 014 hilos del
> sistema contra 35, misma latencia, cuatro veces menos memoria.

> **"`write` no es guardar."** Hay tres niveles —mi búfer, el núcleo, el disco— y cada uno sobrevive a
> un fallo distinto.

---

## 5. 📝 Qué anotar después

```text
Por cada pregunta fallada:
  ¿faltó la capa de 30 segundos, la de 2 minutos o el detalle?
  ¿di un número medido, o me quedé en lo cualitativo?
  ¿dije qué hace el hilo mientras espera?
```

La segunda es la que más distingue en este bloque: casi todas las respuestas tienen un número detrás,
y quien lo lleva se nota inmediatamente.

---

**Anterior:** [`05` — El árbol de directorios](05-el-arbol-de-directorios.md) ·
**Siguiente:** [`07` — Respuestas](07-respuestas.md) · **Bloque:** [README](README.md)
