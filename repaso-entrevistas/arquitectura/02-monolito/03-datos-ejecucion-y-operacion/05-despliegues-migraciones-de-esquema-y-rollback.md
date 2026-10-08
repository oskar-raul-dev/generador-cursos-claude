# 05 — Despliegues, migraciones de esquema y rollback

Aprenderás a cambiar código y esquema sin convertir el despliegue único en una apuesta
irreversible: por qué un solo artefacto no significa una sola versión corriendo, cómo secuenciar un
cambio de esquema que sirva a las dos, y qué vuelta atrás existe de verdad cuando los datos ya
cambiaron.

## 1. 🎯 Síntoma y decisión

Un release renombra `total` a `total_cents` con una migración que corre al arrancar la aplicación. El
despliegue es *rolling*: la primera réplica nueva arranca, ejecuta la migración y empieza a servir.
Las tres réplicas viejas, que siguen atendiendo tráfico, fallan con `column "total" does not exist`.
Checkout devuelve errores durante los doce minutos que tarda el rollout. Alguien lanza el rollback
del código y no mejora nada: la versión anterior espera una columna que ya no existe.

El monolito es un solo artefacto, pero durante el despliegue corren dos versiones sobre el mismo
esquema. La decisión de este capítulo es cómo secuenciar código y datos para que cada paso sirva a
todas las versiones vivas, y dónde está el punto de no retorno.

## 2. 🧠 Modelo mental

```text
tiempo ─────────────────────────────────────────────────────────────────────►
réplicas   N  N  N  N          N  N  N+1 N+1          N+1 N+1 N+1 N+1
esquema    total               total + total_cents                 total_cents
                               ▲ expandir                          ▲ contraer, en otro release,
                                 ambas versiones funcionan           cuando nadie lee total
regla: todo esquema intermedio sirve a toda versión que pueda estar corriendo
```

El código se revierte reemplazando el artefacto; los datos no. Una columna añadida es fácil de
ignorar, una columna borrada no vuelve y un valor convertido no recuerda cuál era. Por eso se
**expande** primero —añadir sin quitar—, se cambian escritores y lectores con el esquema ampliado,
y se **contrae** al final, cuando la ventana de rollback cerró. La contracción es el único paso
irreversible, y se da cuando ya no hace falta volver.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | errores 500 en checkout durante los doce minutos del rollout; `column "total" does not exist` solo en réplicas de la versión N; la migración se ejecutó al arrancar la primera réplica N+1; el rollback del código no restauró el servicio |
| Inferencia | una migración destructiva corrió antes de retirar a los lectores antiguos |
| Diagnóstico | el esquema no fue compatible con las versiones en convivencia, y el rollback dependía de un esquema que ya no existía |
| Recomendación | expand-contract en tres releases, migración como paso propio del despliegue y contracción tras la ventana de rollback |

Qué refutaría el diagnóstico: si el error apareciera en las réplicas N+1, el defecto estaría en el
código nuevo y no en la compatibilidad. Y si solo fallaran consultas de un reporte que lee la base
directamente, el problema sería un consumidor no inventariado del esquema, que expand-contract
también debe incluir.

## 4. 🛠️ Secuencia expand-contract

Una migración compatible separa introducción, adopción y retirada. Supón que `total` ya almacena
centavos y solo cambia su nombre a `total_cents`; si cambia la unidad monetaria, hace falta una
conversión validada adicional. Primero se añade la columna nueva. Mientras existan escritores
antiguos, `total` conserva la autoridad y una sincronización transaccional explícita mantiene ambas
representaciones. El backfill reanudable debe coordinarse con esa sincronización para no sobrescribir
valores recientes. Tras retirar los escritores antiguos y verificar convergencia, se cambian los
lectores y la autoridad de escritura. La columna anterior se conserva durante la ventana de rollback;
solo se elimina cuando ninguna versión soportada la necesita.

```text
expandir ─► código compatible ─► backfill ─► cambiar tráfico ─► contraer
   ▲               │                 │              │              │
 rollback fácil    versiones mixtas métricas        abortar        irreversible
```

Cada paso declara precondición, señal de éxito y aborto. Un backfill grande se pagina, limita y
puede continuar; no comparte una transacción gigantesca con DDL. Un feature flag controla conducta,
pero no vuelve compatible un esquema ni sustituye una copia de seguridad restaurada en un ensayo.

El rollback de código solo es seguro mientras la versión anterior entienda los datos nuevos. Después
de una transformación destructiva, la recuperación puede ser *roll-forward* o restauración con
pérdida explícita de ventana. Por eso la contracción se retrasa y se observa que no haya lecturas ni
escrituras antiguas antes de ejecutarla.

## 5. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | JAR/imagen reproducible y migrador versionado | la herramienta no vuelve reversible el DDL | ejecutar migración destructiva al arrancar todas las réplicas |
| Node/TypeScript | lockfile, build y migraciones explícitas | un rollback de paquete no restaura columnas | mezclar backfill largo con DDL |
| Go | binario reproducible y comando de migración separado | el binario no coordina compatibilidad | acoplar todo al startup |
| Python | wheel/imagen y migrador versionado | downgrade automático puede perder datos | editar migraciones ya aplicadas |

Las cuatro trampas son variantes del mismo error: tratar el esquema como parte del artefacto. El
JAR, el paquete, el binario y el wheel se reemplazan y se revierten; la base no. Por eso la migración
se versiona junto con el código, pero se ejecuta como un paso propio, con su decisión de avanzar o
abortar, y nunca como efecto lateral de que arranque una réplica.

## 6. ⚖️ Decisión y coste

Expande el esquema, migra los datos y cambia lectores y escritores antes de contraer. Conservas compatibilidad entre versiones a cambio de sincronización temporal, pruebas y limpieza posterior. Una ventana de mantenimiento puede reducir ese coste si el negocio acepta la interrupción. Suspende el avance ante divergencias o fallos de versiones soportadas; contrae únicamente al terminar la ventana de recuperación.

## ⚠️ Errores frecuentes

- «Un solo artefacto significa despliegue instantáneo». Un rolling deployment mezcla versiones durante minutos; un canary, durante horas.
- «El rollback deshace la migración». Revierte el código; los datos transformados y las columnas borradas se quedan como están.
- «Renombrar una columna es un cambio pequeño». Para las versiones que la leen es una ruptura de contrato, y en un rolling deployment las dos conviven.
- «Si la herramienta tiene `down`, el cambio es reversible». Un `down` que recrea una columna no recupera los datos que contenía.
- «Migrar al arrancar simplifica el despliegue». Deja el cambio de esquema en manos de la primera réplica que arranca, antes de que nadie decida.

## 7. ✅ Veredicto

Trata el esquema como un contrato con todas las versiones que pueden estar corriendo a la vez.
Expande primero, cambia escritores y lectores sobre el esquema ampliado, y contrae en otro release,
cuando la ventana de rollback haya cerrado y la observación confirme que nadie usa lo viejo. Ejecuta
las migraciones como un paso propio del despliegue y ensaya la restauración: para una transformación
destructiva es la única vuelta atrás que existe.

## 📚 Referencias

- [Expand and Contract Pattern](https://www.tim-wellhausen.de/papers/ExpandAndContract/ExpandAndContract.html)
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [PostgreSQL Backup and Restore](https://www.postgresql.org/docs/current/backup.html)

## 🧠 Preguntas

1. 🟢 ¿Por qué un rolling deployment obliga a pensar en versiones mixtas aunque el monolito sea un único artefacto?
2. 🟢 ¿Qué significan expandir y contraer en una migración de esquema?
3. 🟢 ¿Qué diferencia hay entre revertir código y revertir datos?
4. 🟢 ¿Qué es un backfill y por qué debe ser reanudable?
5. 🟢 ¿Qué controla una feature flag y qué no puede controlar?
6. 🟢 ¿Qué es *roll-forward* y cuándo es la única salida?
7. 🟡 ¿Por qué renombrar una columna en un solo paso rompe un rolling deployment?
8. 🟡 ¿Cuándo aceptarías una ventana de mantenimiento en lugar de expand-contract?
9. 🟡 ¿Por qué no conviene ejecutar la migración al arrancar cada réplica?
10. 🟡 Durante la fase intermedia, ¿quién tiene la autoridad de escritura sobre `total` y `total_cents`, y cómo se mantienen sincronizadas?
11. 🟡 ¿Cómo evitas que el backfill sobrescriba valores que la aplicación escribió mientras corría?
12. 🟡 ¿Qué señal observarías antes de contraer?
13. 🟡 ¿Qué define la duración de la ventana de rollback?
14. 🟡 ¿Por qué un backfill grande no debe ir en la misma transacción que el DDL?
15. 🟡 ¿Qué operaciones de DDL pueden bloquear la tabla en producción y cómo lo mitigas?
16. 🟡 ¿Qué aporta ensayar una restauración de backup que no aporta tenerlo?
17. 🟡 ¿Qué debe permanecer igual entre una migración lanzada desde Java y una ejecutada como comando Go separado?
18. 🟠 ¿Por qué editar una migración ya aplicada es igual de riesgoso en Node/TypeScript y Python?
19. 🟠 A mitad del rollout aparecen `column "total" does not exist` en las réplicas viejas. ¿Qué haces en los primeros minutos?
20. 🟠 El backfill lleva el 60 % y detectas valores divergentes entre las dos columnas. ¿Continúas, pausas o reviertes?
21. 🟠 Una migración añade una columna `NOT NULL` con valor por defecto en una tabla grande. ¿Qué verificarías antes de lanzarla?
22. 🟠 El cambio de unidad monetaria de `total` exige convertir datos. ¿Cómo lo harías reversible hasta el último paso?
23. 🟠 Un equipo quiere desplegar esquema y código juntos «para simplificar» y otro separar en tres releases. ¿Cómo decidirías?
24. 🟠 ¿Qué criterio te permite contraer y dar por cerrada la migración?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [04 — Rendimiento, caché y escalado](04-rendimiento-cache-y-escalado.md).

**Siguiente:** [06 — Observabilidad y resiliencia del monolito](06-observabilidad-y-resiliencia-del-monolito.md).
