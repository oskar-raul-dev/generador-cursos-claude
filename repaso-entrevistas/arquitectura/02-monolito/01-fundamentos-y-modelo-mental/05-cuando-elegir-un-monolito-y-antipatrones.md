# 05 — Cuándo elegir un monolito y antipatrones

Aprenderás a defender un monolito como decisión proporcional, con supuestos y fecha de revisión. No
es una apuesta eterna: conserva simplicidad mientras dominio, equipos y operación no justifiquen
pagar el coste de distribuir.

## 1. 🎯 El escenario de decisión

Una startup de seis personas construye comercio B2B. Todavía no conoce su carga, las reglas cambian
cada semana y un equipo opera todo. Necesita confirmar pedido y reserva con consistencia fuerte. La
propuesta de «empezar con microservicios para no migrar después» convierte fronteras inciertas en
contratos remotos antes de tener evidencia.

La primera acción reversible es una aplicación desplegable con módulos incipientes y ownership de
datos documentado. La garantía prioritaria es aprender y entregar sin perder la invariante de stock.
El precio aceptado es desplegar el conjunto.

## 2. 🧭 Restricciones que favorecen mantenerlo unido

| Restricción | Señal | Por qué favorece un monolito |
|---|---|---|
| Dominio | lenguaje y límites inestables | refactor local más barato que contrato remoto |
| Equipo | pequeño y con ownership conjunto | poca ganancia en independencia organizacional |
| Consistencia | invariantes entre capacidades | transacción local disponible |
| Operación | plataforma y observabilidad inmaduras | menor superficie distribuida |
| Latencia | flujo interactivo corto | evita saltos y serialización internos |
| Entrega | prioridad en feedback | un pipeline y entorno simplifican el ciclo |

Ninguna fila decide sola. Regulación puede favorecer una unidad auditable o exigir aislamiento.
Carga alta puede resolverse con réplicas, caché o tuning; una parte caliente y medible puede favorecer
separación. El contexto compone la decisión.

## 3. 🚦 Señales para modularizar o distribuir

Primero modulariza cuando cambios de `payments` y `orders` se pisan, el ownership es difuso o las
pruebas requieren todo el sistema. Considera otra unidad de despliegue cuando, además, existe una
necesidad sostenida de:

- desplegar o revertir una capacidad con cadencia propia;
- aislar recursos, riesgo regulatorio o destino de fallo;
- escalar un cuello medido sin escalar el conjunto;
- permitir a un equipo operar con contratos y datos propios;
- usar una frontera de consistencia eventual aceptable.

La separación debe comprar autonomía efectiva. Si continúan el release train, las escrituras
cruzadas y las decisiones conjuntas, solo se añadieron fallos de red.

## 4. 🧨 *Premature distribution*

Distribuir prematuramente significa pagar contratos, descubrimiento, despliegue, telemetría,
seguridad, timeouts y consistencia eventual antes de que la autonomía compense. También endurece
límites de dominio que todavía cambian.

```text
incertidumbre alta
   ├─► límite local y refactorizable
   ├─► métricas de cambio/carga
   └─► revisión con evidencia

no: 20 contratos remotos para una organización de 6 personas
```

No implica «monolito primero» como dogma. Un equipo experimentado, dominio conocido y requisitos
fuertes de aislamiento o escalado selectivo pueden justificar servicios desde el inicio. La carga de
la prueba recae en la restricción, no en la moda.

## 5. 🪜 Decisión reversible y criterio de salida

Registra una decisión como hipótesis:

- **Supuestos:** un equipo, menos de X carga observada, una región, invariante local.
- **Decisión:** un despliegue con límites por capacidad.
- **Garantía:** pedido y reserva confirman juntos.
- **Coste:** release y escalado del conjunto.
- **Señales:** lead time por capacidad, incidentes por contención, perfil de CPU/I/O, coordinación.
- **Revisión:** fecha o umbral, no «cuando duela».

Ejemplo: revisar en tres meses o si `payments` provoca dos incidentes de aislamiento, requiere una
cadencia cuatro veces mayor o consume de forma sostenida el recurso limitante. El criterio no ordena
extraer; ordena reevaluar alternativas.

## 6. 🧰 Plataformas y operación

No se prescribe tecnología: Java, Node/TypeScript, Go y Python pueden empaquetar un monolito,
ejecutar réplicas y observar recursos. La plataforma altera memoria, concurrencia, build y talento,
pero no sustituye datos sobre carga, ownership o consistencia. Elegir framework y elegir topología
son decisiones relacionadas, no equivalentes.

## 7. ⚖️ Matriz de trade-offs

| Opción | Garantía o ventaja | Coste principal | Primera comprobación |
|---|---|---|---|
| Monolito simple | feedback y transacción local | límites blandos | cambios contenidos |
| Monolito modular | unidad operativa con límites | disciplina y controles | ownership respetado |
| Servicios | despliegue/aislamiento selectivo | distribución y datos repartidos | autonomía efectiva |

La matriz no puntúa automáticamente. Una restricción no negociable —por ejemplo aislamiento legal—
puede dominar varias ventajas menores.

## ⚠️ Errores frecuentes

- «Microservicios son el siguiente paso natural». Son una opción para restricciones concretas.
- «Empieza distribuido para no migrar». Anticipar límites erróneos también crea una migración.
- «Un monolito sirve solo para MVP». Puede operar durante toda la vida útil.
- «El número de usuarios decide». Importa el cuello medido y el modelo operativo.
- «Mantenerlo unido cierra opciones». Límites internos y decisiones revisables preservan opciones.

## 8. ✅ Veredicto

Elige monolito cuando la simplicidad local, la velocidad de aprendizaje y las garantías compartidas
valen más que una autonomía todavía hipotética. Declara qué te haría revisar la decisión. Distribuye
solo cuando una frontera entendida compre despliegue, datos, runtime o ownership independientes y la
organización pueda pagar su operación.

## 📚 Referencias

- [Monolith First, Martin Fowler](https://martinfowler.com/bliki/MonolithFirst.html)
- [Microservice Premium, Martin Fowler](https://martinfowler.com/bliki/MicroservicePremium.html)
- [Microservices, Martin Fowler y James Lewis](https://martinfowler.com/articles/microservices.html)
- [Design to scale out, Microsoft Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/guide/design-principles/scale-out)

## 🧠 Preguntas

1. 🟢 ¿Qué significa elegir una topología de forma proporcional?
2. 🟢 ¿Por qué un dominio incierto favorece límites locales?
3. 🟢 ¿Qué es *premature distribution*?
4. 🟢 ¿Qué garantía local puede favorecer un monolito?
5. 🟢 ¿Qué es un criterio de salida?
6. 🟢 ¿Qué diferencia hay entre señal de revisión y orden de extracción?
7. 🟢 ¿Qué coste de despliegue acepta un monolito?
8. 🟡 ¿Por qué el tamaño del equipo influye sin decidir por sí solo?
9. 🟡 ¿Cómo afecta la madurez operativa a la elección?
10. 🟡 ¿Por qué una carga alta no implica automáticamente servicios?
11. 🟡 ¿Cuándo modularizar es suficiente sin distribuir?
12. 🟡 ¿Qué autonomía debe comprar una extracción?
13. 🟡 ¿Cómo puede regulación favorecer decisiones opuestas?
14. 🟡 ¿Por qué un contrato remoto hace más caro corregir un límite?
15. 🟡 ¿Qué métricas revisarías antes de separar `payments`?
16. 🟡 ¿Cómo conserva opciones un monolito modular?
17. 🟡 ¿Cuándo servicios desde el inicio sí pueden ser razonables?
18. 🟠 Una startup de seis personas espera millones de usuarios, pero no tiene tráfico. ¿Qué propones?
19. 🟠 `inventory` consume 70 % de CPU durante dos campañas al año. ¿Qué medirías antes de extraerlo?
20. 🟠 Una norma exige aislar datos de pago. ¿Qué alternativas compararías además de un servicio?
21. 🟠 Dos equipos necesitan cadencias distintas, pero comparten una invariante fuerte. ¿Cómo priorizas?
22. 🟠 El monolito escala con réplicas, pero el pool de base se agota. ¿Qué cambia en tu diagnóstico?
23. 🟠 ¿Qué primera acción reversible propondrías antes de una separación física?
24. 🟠 ¿Qué evidencia te haría cancelar una extracción ya planeada?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [04 — Acoplamiento, cohesión y razones de cambio](04-acoplamiento-cohesion-y-razones-de-cambio.md).

**Siguiente:** [06 — Estilos de estructura interna: capas, clean, onion y vertical slice](06-estilos-de-estructura-interna.md).
