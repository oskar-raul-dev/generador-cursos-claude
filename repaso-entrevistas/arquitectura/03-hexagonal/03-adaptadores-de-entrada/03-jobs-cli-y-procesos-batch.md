# 03 — Jobs, CLI y procesos batch

Este capítulo enseña a reutilizar una intención de aplicación desde un reloj, una terminal o un lote, y a decidir qué estado necesita el adaptador para reanudar sin repetir efectos.

## 1. 🎯 El problema

Un cron nocturno confirma pedidos pendientes con SQL y una regla propia, mientras HTTP usa `ConfirmOrder`. Al cambiar el límite de inventario, el cron y la API divergen. Además, un reinicio a mitad del lote vuelve a procesar desde cero.

## 2. 🧭 Frontera y dirección

```text
scheduler / CLI / archivo ─► adaptador ─► ConfirmOrderCommand ─► caso de uso
                                 │                   │
                 checkpoint, lock, logs       política e invariantes
```

El disparador decide cuándo, con qué parámetros, qué lote leer y cómo informar progreso. El caso de uso decide si un pedido puede confirmarse; depende de puertos propios y nunca de `argv`, una expresión cron o el formato CSV. Los [puertos de entrada](../02-nucleo-aplicacion-y-dominio/03-puertos-de-entrada.md) permiten esta reutilización. Una transacción por todo el lote suele bloquear demasiado; el [límite de consistencia](../02-nucleo-aplicacion-y-dominio/05-transacciones-y-limites-de-consistencia.md) se decide por elemento o por unidad pequeña.

## 3. 🔄 Diseño del procesamiento

Un job selecciona una página acotada de pedidos, toma un lock o lease si habrá varias instancias, e invoca el caso de uso por pedido con una identidad de operación estable. Registra un checkpoint solo después del efecto confirmado. Reanudar implica volver a leer desde un cursor estable y tolerar repetir la última unidad. El cursor de lectura no reemplaza la idempotencia: nuevas filas y cambios de orden pueden causar saltos si se pagina solo por offset.

La CLI valida flags y credenciales del operador, presenta un resumen y convierte resultados a exit codes. Un modo `dry-run` debe tener semántica clara: si el caso de uso no ofrece una evaluación sin efectos, no se implementa ejecutando y haciendo rollback cuando hay llamadas remotas. Para lotes, fija tamaño, concurrencia, timeout, cancelación y política por error. El coste del adaptador está en checkpoints, locking, métricas y runbooks; la política de negocio sigue en un lugar.

## 4. 🧩 Implementación mínima

En Go, la composición ocurre fuera del runner; el adapter usa un puerto de aplicación y un origen de IDs. `Process` puede recibir `context.Context` para cancelación técnica sin llevarlo a la entidad de dominio.

```go
import "context"

type ConfirmOrder interface {
    Execute(ctx context.Context, orderID, operationID string) error
}
type PendingOrders interface {
    NextPage(ctx context.Context, cursor string, limit int) ([]string, string, error)
}
type Job struct { UseCase ConfirmOrder; Source PendingOrders }

func (j Job) Execute(ctx context.Context, cursor string) (string, error) {
    ids, next, err := j.Source.NextPage(ctx, cursor, 100)
    if err != nil { return cursor, err }
    for _, id := range ids {
        if err := j.UseCase.Execute(ctx, id, "confirm:"+id); err != nil {
            return cursor, err // no avanzar checkpoint sobre un fallo
        }
    }
    return next, nil // el runner persiste el checkpoint
}
```

El composition root construye `Job{UseCase: useCase, Source: pendingOrdersReader}` y el scheduler lo llama. Python puede usar el mismo puerto sin framework:

```python
import argparse


def main(confirm_order, checkpoint):
    parser = argparse.ArgumentParser()
    parser.add_argument("--order-id", required=True)
    args = parser.parse_args()
    operation_id = f"confirm:{args.order_id}"
    confirm_order.execute(args.order_id, operation_id)
    checkpoint.record(operation_id)
    return 0

# El composition root construye las dependencias y llama main(confirm_order, checkpoint).
```

El ejemplo de CLI muestra un elemento, no un checkpoint transaccional: ante caída entre ejecución y registro, `execute` debe ser idempotente. En producción se comprueba exit code, correlación y política de permisos del operador.

## 5. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | Spring ofrece `@Scheduled` y ejecución de tareas | lock distribuido, reanudación y límites | creer que `@Scheduled` evita solapamientos entre réplicas |
| Node/TS | timers y procesos ofrecen disparadores | persistir estado y detener promesas al cerrar | usar un `setInterval` como cola durable |
| Go | `context` y binarios facilitan cancelación y CLI | scheduler externo, cursor y composición | compartir una transacción para todo el lote |
| Python | `argparse` y scripts simplifican la CLI | checkpoint, concurrencia y errores | confundir fin del proceso con éxito del lote |

## 6. ⚖️ Decisión y coste

Si el lote es pequeño, una ejecución manual con IDs explícitos puede bastar. Si crece, introduce primero idempotencia y un cursor seguro; después concurrencia y locking según evidencia. Una prueba del caso de uso no demuestra reanudación: prueba una caída tras procesar el primer elemento y verifica que la repetición no duplica efectos. Observa duración, elementos exitosos, fallidos, pendientes y edad del checkpoint.

## ⚠️ Errores frecuentes

- “Un cron necesita su propia lógica de negocio.” Cambia el disparador, no la invariante.
- “Una transacción larga garantiza todo el lote.” Aumenta locks y no cubre efectos remotos.
- “El offset basta para reanudar.” Una lista mutable puede mover filas entre páginas.
- “El lock reemplaza la idempotencia.” Un lease puede expirar y el proceso puede caer.
- “`dry-run` equivale a rollback.” Un correo o pago remoto no revierte con la base.

## 7. ✅ Veredicto

Reutiliza casos de uso por elemento o unidad de consistencia. El adaptador administra disparador, progreso y operación. El precio es una infraestructura de reanudación que merece crecer con el tamaño y el daño potencial del lote.

## 📚 Referencias

- [Spring Framework: task execution and scheduling](https://docs.spring.io/spring-framework/reference/integration/scheduling.html)
- [Go: package context](https://pkg.go.dev/context)
- [Python: argparse](https://docs.python.org/3/library/argparse.html)
- [Node.js: timers](https://nodejs.org/api/timers.html)

## 🧠 Preguntas

1. 🟢 ¿Qué tienen en común un job, una CLI y HTTP como entradas?
2. 🟢 ¿Qué decide el scheduler y qué decide el caso de uso?
3. 🟢 ¿Qué es un checkpoint de lote?
4. 🟢 ¿Para qué sirve un lock o lease en un job?
5. 🟢 ¿Qué es un `dry-run`?
6. 🟢 ¿Qué debe expresar el exit code de una CLI?
7. 🟢 ¿Por qué el dominio no recibe `argv`?
8. 🟡 ¿Por qué prefieres transacciones pequeñas en batch?
9. 🟡 ¿Cuándo guardas el checkpoint?
10. 🟡 ¿Por qué un cursor estable supera a paginar por offset mutable?
11. 🟡 ¿Qué relación hay entre lease e idempotencia?
12. 🟡 ¿Cómo propagas cancelación en Go sin contaminar el dominio?
13. 🟡 ¿Qué observabilidad necesita un proceso nocturno?
14. 🟡 ¿Qué riesgo tiene `@Scheduled` con varias réplicas de Spring?
15. 🟡 ¿Por qué `setInterval` de Node no es una cola durable?
16. 🟡 ¿Qué valida una CLI antes de invocar el caso de uso?
17. 🟠 El job cae después de procesar un pedido y antes del checkpoint. ¿Qué ocurre al reanudar?
18. 🟠 Dos réplicas ejecutan el mismo cron. ¿Cómo evitas daño?
19. 🟠 El lote contiene un registro inválido entre mil válidos. ¿Qué política defines?
20. 🟠 Un `dry-run` llama un proveedor de pagos y luego hace rollback. ¿Qué corriges?
21. 🟠 La CLI escribe SQL para confirmar pedidos. ¿Cómo la reconectas al núcleo?
22. 🟠 Un batch de diez horas bloquea filas todo el tiempo. ¿Cómo cambias el límite?
23. 🟠 Un operador reintenta manualmente una ejecución parcial. ¿Qué identificadores conservas?
24. 🟠 ¿Cuándo evitarías construir un framework de jobs propio?

**Siguiente:** [Autenticación, autorización y contexto de actor](04-autenticacion-autorizacion-y-contexto-de-actor.md).
