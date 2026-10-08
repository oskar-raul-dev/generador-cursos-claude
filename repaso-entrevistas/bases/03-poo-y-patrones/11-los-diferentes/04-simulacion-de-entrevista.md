# 04 — Simulación de entrevista

> El examen del bloque `11-los-diferentes`: preguntas transversales que cruzan Go, JavaScript y TypeScript, y Python, y cinco
> ejercicios de diseño de veinte minutos. Asume leídos los capítulos [`01`](01-go.md) a [`03`](03-python.md). Las respuestas,
> en [`05` — Respuestas](05-respuestas.md#04--simulación-de-entrevista).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** Go 1.27.1 · TypeScript 7.0.2 (2026-10-04).

---

## 1. 🧭 Cómo se usa este documento

- **Con cronómetro.** Una pregunta `S#`: dos minutos en voz alta. Un ejercicio: veinte minutos.
- **Sin traducir línea a línea.** La pregunta de fondo de este bloque es siempre la misma: *"¿qué hace este lenguaje en lugar
  de lo que harías en Java?"*. Una traducción literal de un patrón de Java es la respuesta que el entrevistador espera que
  evites.
- **Con el porqué del lenguaje.** Cada diferencia tiene una causa: Go no tiene herencia, JavaScript decide `this` al llamar,
  Python ejecuta las definiciones. Nombrar la causa vale más que recordar el idioma.
- **Solo después, el solucionario.** Las `S#` que ya son preguntas de capítulo remiten a su respuesta.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Go

**S1.** ¿Es Go orientado a objetos? 🟢

**S2.** ¿Por qué el *embedding* no es herencia? 🟡

**S3.** ¿Qué ocupa en Go el lugar del Builder? 🟢

**S4.** ¿Por qué la interfaz se define en el paquete que la usa? 🟠

**S5.** ¿Qué trampa tiene devolver un puntero nulo como `error`? 🟠

### Bloque B — JavaScript y TypeScript

**S6.** ¿Qué es `class` en JavaScript? 🟡

**S7.** ¿Por qué se pierde `this` al pasar un método como función? 🟠

**S8.** ¿Qué garantiza TypeScript en ejecución? 🟠

**S9.** ¿Qué reemplaza al Visitor en TypeScript? 🟡

**S10.** ¿Por qué Node atiende muchas conexiones con un hilo, y qué no se puede hacer en él? 🟠

### Bloque C — Python

**S11.** ¿Es el `@decorator` el patrón Decorator? 🟡

**S12.** ¿Tiene Python interfaces? 🟠

**S13.** ¿A quién llama `super()` en Python? 🟠

**S14.** ¿Qué patrones hay detrás de SQLAlchemy y de Django ORM? 🟡

**S15.** ¿Cómo se escribe un objeto de valor en Python? 🟢

### Bloque D — Entre los tres

**S16.** ¿En cuál de los tres lenguajes las interfaces se cumplen sin declararlas, y qué cambia eso? 🟡

**S17.** ¿Qué ocupa el lugar del Singleton en Go, en JavaScript y en Python? 🟡

**S18.** ¿Qué tienen en común el *type switch* de Go, `singledispatch` de Python y las uniones de TypeScript frente al `switch`
sellado de Java? 🟠

**S19.** ¿Qué ocupa el lugar de Strategy en los tres? 🟢

**S20.** ¿Qué ocupa el lugar de *try-with-resources* en los tres? 🟡

**S21.** ¿Dónde se comprueban los tipos en Go, en TypeScript y en Python? 🟠

**S22.** ¿Qué patrón de concurrencia trae cada uno en el lenguaje? 🟠

### Bloque E — Contra Java

**S23.** ¿Qué patrones del GoF desaparecen al pasar de Java a un lenguaje con funciones de primera clase? 🟠

**S24.** ¿Qué pierdes al dejar el `switch` sellado de Java 21? 🟡

### Bloque F — Las que descolocan

**S25.** "En Go hacemos Template Method con *embedding*, como siempre." ¿Qué preguntas? 🔴

**S26.** "Tipamos todo con TypeScript, así que no validamos las respuestas del API." ¿Qué respondes? 🔴

**S27.** "Para auditar en producción, ponemos `@auditado` en todos los métodos." ¿Qué propones? 🔴

**S28.** "Patrones de diseño son cosas de Java; en Python no hacen falta." ¿Estás de acuerdo? 🔴

**S29.** "Para pasar de Java a Go, traducimos las clases a *structs* y las interfaces a interfaces." ¿Qué sale mal? 🔴

**S30.** Te piden elegir entre Go, Node y Python para un servicio de consultas de saldo con mucho tráfico. ¿Qué preguntas
haces? 🔴

---

## 3. 📐 Ejercicios de diseño

### E1 — Un Strategy en cuatro lenguajes (traducir)

**Fuerza:** reconocer qué parte del patrón es del problema y qué parte es del lenguaje.

En Java, la comisión de una transferencia depende del tipo de cuenta, con una interfaz `PoliticaComision` y una clase por
tipo (`AHORROS` 0,5 %, `CORRIENTE` 0,8 %, `NOMINA` sin comisión), elegidas con un `EnumMap`. Tradúcelo a Go, a JavaScript y a
Python como lo escribiría alguien que conoce cada lenguaje.

### E2 — La validación que no valida (revisar)

**Fuerza:** encontrar la trampa del *embedding* en un *pull request* de Go.

```go
type Notificador struct{}

func (n Notificador) Avisar(p Persona, msg string) error {
	return n.enviar(destinoDe(p), n.formatear(msg))
}
func (Notificador) formatear(msg string) string             { return msg }
func (Notificador) enviar(destino, texto string) error      { return correo.Enviar(destino, texto) }

type NotificadorSMS struct{ Notificador }

func (NotificadorSMS) enviar(destino, texto string) error   { return sms.Enviar(destino, texto) }
func (NotificadorSMS) formatear(msg string) string          { return recortar(msg, 160) }
```

El equipo dice que los avisos por SMS de los vencimientos de Luis "llegan por correo y sin recortar", aunque el código del
SMS "está ahí". Diagnostica y corrige.

### E3 — El número de cuenta enmascarado (elegir, sin patrón)

**Fuerza:** reconocer que una transformación de datos no necesita un patrón en ningún lenguaje.

Las pantallas muestran `CTA-0001` como `CTA-••01`. Un compañero propone, en los tres servicios (Go, Node y Python), una
interfaz `Enmascarador` con una implementación por tipo de dato y una fábrica. Diseña la solución en los tres.

### E4 — El servicio de avisos en TypeScript (revisar)

**Fuerza:** encontrar los dos errores de quien escribe Java en TypeScript.

```ts
class ServicioAvisos {
  constructor(private correo: Correo) {}
  avisar(d: DocumentoVencido) { this.correo.enviar(d.email, `Tu ${d.tipo} venció`); }
}

const respuesta = await fetch(`/api/documentos/vencidos?hoy=${hoy}`);
const vencidos = (await respuesta.json()) as DocumentoVencido[];
vencidos.forEach(servicio.avisar);
```

Nombra los defectos, priorízalos y corrige.

### E5 — El ORM del nuevo servicio en Python (elegir)

**Fuerza:** elegir entre Active Record y Data Mapper por la forma de la lógica, no por la moda.

Hay que escribir en Python dos servicios: uno de administración de catálogos (tipos de documento, países, tarifas), casi
todo altas, bajas y cambios; y el de cuentas, con transferencias, bloqueos, comisiones y reglas que cruzan objetos. Elige ORM
para cada uno y justifica.

---

## 4. 🧭 Las frases que hay que tener listas

> "En Go no hay herencia: el *embedding* reenvía métodos con el receptor embebido, así que lo que varía entra por una
> interfaz."

> "`class` en JavaScript es sintaxis sobre prototipos y `this` lo pone quien llama; y TypeScript no comprueba nada al
> ejecutar, así que lo que entra se valida en la frontera."

> "El `@decorator` de Python transforma una función al definirla; el Decorator del GoF envuelve un objeto al configurar."

---

**Anterior:** [`03` — Python](03-python.md) ·
**Siguiente:** [`05` — Respuestas](05-respuestas.md) ·
**Relacionado:** [`06/01` — Strategy](../06-comportamiento/01-strategy.md)
