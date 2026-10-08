# 04 — Acoplamiento, cohesión y razones de cambio

Aprenderás a localizar el acoplamiento que encarece cambios sin perseguir independencia absoluta.
La pregunta senior no es «¿hay acoplamiento?», sino «¿entre qué unidades, por qué garantía y con
qué coste de coordinación?».

## 1. 🎯 El síntoma concreto

Una regla de promociones cambia y obliga a modificar `orders`, `inventory` y `payments`. El equipo
mira los imports y concluye que solo hay una dependencia. En producción, sin embargo, `CreateOrder`
necesita disponibilidad de las tres capacidades y una escritura coordinada.

Contar imports no captura los datos, el tiempo, el despliegue ni las decisiones humanas. Tampoco
todo acoplamiento es malo: reservar stock debe conocer alguna promesa de `inventory`.

## 2. 🧲 Tipos de acoplamiento

| Tipo | Evidencia | Pregunta de decisión |
|---|---|---|
| Código | imports, tipos, módulos de build | ¿qué compila o cambia junto? |
| Datos | escrituras, esquema, modelo compartido | ¿quién puede cambiar el estado? |
| Cambio | archivos que co-cambian en commits | ¿qué razones de cambio viajan juntas? |
| Despliegue | releases coordinadas, compatibilidad | ¿qué debe promoverse junto? |
| Tiempo | espera síncrona, orden, disponibilidad | ¿qué debe responder ahora? |
| Organización | aprobaciones, handoffs, ownership | ¿quién debe coordinar para decidir? |

La combinación importa. Una llamada local crea acoplamiento de código y ejecución, pero puede ser
barata si conserva una transacción y un equipo posee ambos lados. El mismo contrato por HTTP añade
red sin comprar autonomía si los equipos siguen cambiándolo y desplegándolo juntos.

## 3. 🧩 Cohesión y razón de cambio

Cohesión es que elementos agrupados colaboren para una responsabilidad con razones de cambio
relacionadas. `ReserveInventory`, disponibilidad y movimientos de stock suelen compartir lenguaje
e invariantes. Meter el envío de correo en el mismo módulo porque se ejecuta después reduce cohesión:
su política, disponibilidad y cadencia son distintas.

```text
cambio: nueva política de reserva
  ├─ stock disponible
  ├─ expiración de reserva
  └─ liberación de unidades

cambio distinto: plantilla y proveedor de notificación
```

La volatilidad ayuda: cosas que cambian juntas de forma recurrente son candidatas a permanecer
juntas. No uses un solo commit como causalidad; confirma el patrón con historia, incidentes y
conocimiento del dominio.

## 4. 🔗 Connascence como lente opcional

*Connascence* nombra formas de conocimiento compartido: nombre, tipo, significado, posición,
algoritmo o tiempo. Es útil para preguntar si el acoplamiento es explícito y cercano o implícito y
distante. No hace falta recitar una taxonomía para decidir.

`orders` y `payments` pueden compartir el significado de `COP` y la precisión del monto. Ese acuerdo
es necesario; esconderlo no lo elimina. Conviene expresarlo en un tipo o contrato pequeño y asignar
ownership. En cambio, depender del orden accidental de campos o de que dos jobs corran al mismo
segundo es acoplamiento débilmente visible y peligroso.

## 5. 🔄 Coordinación frente a duplicación

Centralizar una regla evita duplicación, pero crea un propietario y consumidores coordinados.
Duplicar una representación pequeña permite evolución local, pero puede divergir. Decide según:

- frecuencia y coste de la divergencia;
- estabilidad del concepto compartido;
- cantidad y autonomía de consumidores;
- capacidad de detectar incompatibilidades;
- garantía que requiere una fuente única.

Para un identificador de pedido, compartir un tipo mínimo puede ser barato. Para un modelo `Order`
canónico con pago, inventario y notificación, el coste de cambio compartido suele dominar. DRY no es
una orden de centralización arquitectónica.

## 6. 🔍 Método de análisis

1. Selecciona un cambio o incidente real.
2. Registra archivos, tablas, despliegues, llamadas y equipos afectados.
3. Separa dependencias necesarias de accidentes históricos.
4. Nombra la garantía: atomicidad, respuesta inmediata, consistencia o lenguaje común.
5. Compara mantener, mediar, duplicar o mover ownership.
6. Elige un cambio reversible y una métrica de coordinación.

La observación «12 commits tocaron ambos módulos» sugiere acoplamiento de cambio. La inferencia es
que comparten una razón o un límite incorrecto. El diagnóstico exige revisar si esos commits fueron
una migración excepcional o un patrón estable.

## 7. 🧰 Plataformas

No se necesita código comparativo: imports y visibilidad cambian entre Java, Node/TypeScript, Go y
Python, pero aquí la decisión se apoya en historia de cambios, datos, runtime y equipos. Las
herramientas de cada ecosistema pueden dibujar dependencias estáticas; ninguna infiere por sí sola
la razón de negocio ni el coste organizacional.

## 8. ⚖️ Decisión y coste

Conserva acoplamiento cuando expresa una invariante valiosa y su cercanía abarata la coordinación.
Redúcelo cuando une elementos con volatilidades o propietarios distintos sin una garantía que lo
justifique. Una interfaz, evento o duplicación solo es mejor si mueve la dependencia relevante; de
lo contrario cambia su apariencia.

## ⚠️ Errores frecuentes

- «Todo acoplamiento es malo». Un sistema útil coordina capacidades.
- «Menos imports significa más autonomía». Datos y despliegues pueden seguir unidos.
- «Un evento desacopla». Productor y consumidores aún comparten semántica, orden y entrega.
- «Cohesión alta significa módulo grande». La granularidad depende de razones de cambio.
- «Duplicar siempre viola DRY». La duplicación puede comprar autonomía deliberada.

## 9. ✅ Veredicto

Optimiza acoplamiento, no su ausencia. Haz explícitas las dependencias necesarias, acerca lo que
protege la misma invariante y separa lo que cambia por razones distintas. Evalúa el resultado en las
cinco monedas y revisa si la coordinación real disminuye.

## 📚 Referencias

- [Connascence](https://connascence.io/)
- [Microservice Trade-Offs, Martin Fowler](https://martinfowler.com/articles/microservice-trade-offs.html)
- [Big Ball of Mud, Brian Foote y Joseph Yoder](https://www.laputan.org/pub/foote/mud.pdf)

## 🧠 Preguntas

1. 🟢 ¿Qué es acoplamiento de código?
2. 🟢 ¿Qué es acoplamiento de datos?
3. 🟢 ¿Qué es acoplamiento de cambio?
4. 🟢 ¿Qué es acoplamiento temporal?
5. 🟢 ¿Qué es cohesión funcional?
6. 🟢 ¿Qué significa razón de cambio?
7. 🟢 ¿Qué aporta *connascence* como lente?
8. 🟡 ¿Por qué contar imports no mide autonomía?
9. 🟡 ¿Cuándo una llamada local representa acoplamiento razonable?
10. 🟡 ¿Cómo puede HTTP conservar acoplamiento de cambio y despliegue?
11. 🟡 ¿Qué diferencia hay entre acoplamiento necesario y accidental?
12. 🟡 ¿Cómo usarías el historial de commits sin confundir correlación con causa?
13. 🟡 ¿Por qué volatilidad y cohesión deben analizarse juntas?
14. 🟡 ¿Qué coste organizacional puede esconder una API técnicamente limpia?
15. 🟡 ¿Cuándo compartir un tipo pequeño es mejor que duplicarlo?
16. 🟡 ¿Cuándo duplicar una representación compra autonomía?
17. 🟡 ¿Qué garantía podría justificar mantener `orders` e `inventory` cerca?
18. 🟠 Un evento cambia siempre junto con tres consumidores. ¿Qué acoplamiento sigue presente?
19. 🟠 Dos módulos no se importan, pero escriben la misma tabla. ¿Qué cambiarías primero?
20. 🟠 Un equipo central aprueba cada cambio de un modelo canónico. ¿Qué alternativas compararías?
21. 🟠 Un ciclo refleja una invariante compartida real. ¿Romperías el ciclo o moverías el límite?
22. 🟠 La duplicación produjo una discrepancia regulatoria. ¿Qué garantía priorizarías ahora?
23. 🟠 ¿Qué métrica y criterio de parada usarías al reducir coordinación entre equipos?
24. 🟠 ¿Cómo explicarías que una dependencia más explícita puede ser mejor que una aparentemente débil?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [03 — Monolito tradicional, modular y *big ball of mud*](03-monolito-tradicional-modular-y-big-ball-of-mud.md).

**Siguiente:** [05 — Cuándo elegir un monolito y antipatrones](05-cuando-elegir-un-monolito-y-antipatrones.md).
