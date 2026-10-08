# 07 — Evolución y migración desde un monolito

Este capítulo enseña a extraer un núcleo protegible desde un monolito acoplado por cambios pequeños, con una frontera verificable y un criterio para detener la migración.

## 1. 🎯 El problema

`OrderController` valida crédito, construye SQL y llama un SDK de pagos. Cada cambio de regla toca HTTP, base y proveedor. El equipo propone reorganizar todo el árbol de carpetas antes de entregar otra función. Ese movimiento cambia nombres sin cambiar la dirección de dependencias y eleva el riesgo de una reescritura larga.

## 2. 🧭 Elegir una costura

Una *seam* (costura de cambio) es un lugar donde se puede sustituir comportamiento sin editar todos los consumidores. En un monolito puede ser la llamada a `authorizePayment`, la función que guarda pedidos o una ruta interna. El primer candidato se elige por dolor observable: cambios frecuentes, pruebas imposibles, errores costosos o integración inestable. La [regla de dependencias](../01-fundamentos-y-modelo-mental/02-regla-de-dependencias-y-direccion-del-codigo.md) marca la meta; la [sobreabstracción](../01-fundamentos-y-modelo-mental/05-cuando-no-usarla-y-antipatrones.md) marca cuándo parar.

```text
antes: controller ─► SQL + SDK + regla de crédito
paso 1: controller ─► CreateOrder (regla existente caracterizada) ─► Orders (adapter SQL actual)
                  └─► AuthorizePayment ─► PaymentGateway (adapter SDK actual)
paso 2: sustituir un adapter detrás del mismo contrato cuando haya motivo
```

Esto es un *strangler* interno: se desvía una capacidad dentro del mismo despliegue antes de pensar en microservicios. *Branch by abstraction* permite mantener implementación vieja y nueva bajo un contrato temporal, cambiar llamadas gradualmente y retirar el camino viejo. La abstracción se conserva solo si sigue expresando una capacidad útil.

## 3. 🔄 Secuencia segura

1. Mide un flujo: crear pedido, autorizar pago, reservar inventario y responder. Registra errores y dependencias reales, no solo carpetas.
2. Escribe pruebas de caracterización del comportamiento actual, incluidos casos raros. Describen lo que ocurre, aunque luego se decida corregirlo; las correcciones de política se negocian por separado.
3. Crea una costura estrecha alrededor de la operación. Extrae `CreateOrder` sin cambiar transporte o base a la vez. El adaptador antiguo cumple el nuevo puerto.
4. Haz que el controller delegue y compara resultados. Despliega por tramos o con un selector reversible si el riesgo lo exige; mide divergencias y errores.
5. Migra persistencia o proveedor detrás de sus puertos y elimina el camino viejo tras comprobar tráfico y datos. Evita dos dueños de la misma escritura.
6. Detente cuando la regla cambia sin tocar HTTP/ORM/SDK, las pruebas de frontera detectan fugas y el coste de nuevas capas supera el cambio que queda por proteger.

Una base compartida puede mantener acoplamiento de datos aunque los imports estén limpios. Separarla exige ownership, migración y consistencia explícitos; no es requisito para un monolito modular. Duplicar escritura para comparar adaptadores puede alterar pagos o inventario: usa shadow reads o entornos controlados, nunca efectos reales duplicados sin estrategia. El coste temporal de dos caminos incluye configuración, métricas, soporte y una fecha de retirada.

## 4. 🧩 Ejemplo mínimo de sustitución

```java
interface PaymentGateway {
    PaymentResult authorize(String operationId, Money amount);
}
final class LegacyPaymentGateway implements PaymentGateway {
    private final CurrentSdk sdk;
    LegacyPaymentGateway(CurrentSdk sdk) { this.sdk = sdk; }
    public PaymentResult authorize(String id, Money amount) {
        return translate(sdk.charge(id, amount.inCents()));
    }
}

// Composition root: primero inyecta LegacyPaymentGateway en AuthorizePayment.
// Cuando el nuevo adapter satisface el mismo contrato, cambia la selección allí.
```

El contrato expresa una autorización, no todo el SDK. El caso de uso puede probarse con un doble y el adapter legado con una prueba de integración. La migración deja el sistema ejecutable en cada paso. Si la traducción revela que el proveedor antiguo no distingue `UnknownResult`, registra esa deuda antes de cambiar política de reintento.

## 5. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | módulos y tipos permiten aislar imports; Spring selecciona beans | crear seams, probar arranque y retirar wiring viejo | mover paquetes sin romper dependencia JPA |
| Node/TS | módulos y tokens permiten alternar providers | vigilar validación runtime y caminos async | dejar un service locator global |
| Go | interfaces junto al consumidor facilitan sustitución pequeña | construir dos adapters y seleccionar en `main` | crear un paquete `interfaces` para todo |
| Python | funciones y módulos facilitan wrappers incrementales | controlar imports y objetos globales | parchear dinámicamente sin pruebas de caracterización |

## 6. ⚖️ Criterio de parada

No hay premio por convertir todas las clases en puertos. Prioriza capacidad con beneficio medible: tiempo para cambiar una regla, facilidad de prueba, incidentes por integración y número de lugares que se editan. Si un módulo CRUD estable funciona con una frontera simple, déjalo. Si el monolito sigue compartiendo esquema, explica esa limitación en entrevista; hexagonal hace visible el acoplamiento, no lo elimina.

## ⚠️ Errores frecuentes

- “Hay que mover todo a nuevas carpetas antes de cambiar una dependencia.” Los imports y contratos son la frontera real.
- “Migrar a hexagonal equivale a crear microservicios.” Puede ocurrir dentro de un monolito.
- “El adapter viejo debe reescribirse primero.” Puede envolver el sistema legado detrás de un puerto mínimo.
- “Dos caminos pueden permanecer indefinidamente.” Aumentan coste y divergencia; fija retirada.
- “Las pruebas de caracterización bendicen todo comportamiento.” Documentan el estado actual para cambiarlo con intención.

## 7. ✅ Veredicto

Busca una costura donde el dolor sea visible, caracteriza el flujo, introduce un puerto pequeño y mueve la decisión de negocio al núcleo. Cambia adapters por pasos y retira el camino viejo. Detén la migración cuando la frontera ya protege los cambios que importan.

## 📚 Referencias

- [Martin Fowler: Legacy Seam](https://martinfowler.com/bliki/LegacySeam.html)
- [Martin Fowler: Branch by Abstraction](https://martinfowler.com/bliki/BranchByAbstraction.html)
- [Martin Fowler: Strangler Fig](https://martinfowler.com/bliki/StranglerFigApplication.html)
- [Martin Fowler: Breaking a monolith into microservices](https://martinfowler.com/articles/break-monolith-into-microservices.html)

## 🧠 Preguntas

1. 🟢 ¿Qué es una seam en un monolito?
2. 🟢 ¿Qué dolor te indica por dónde empezar?
3. 🟢 ¿Qué es una prueba de caracterización?
4. 🟢 ¿Qué significa strangler interno?
5. 🟢 ¿Qué es branch by abstraction?
6. 🟢 ¿Por qué mover carpetas no basta?
7. 🟡 ¿Qué debe hacer el adaptador legado?
8. 🟡 ¿Cómo eliges la primera capacidad a extraer?
9. 🟡 ¿Por qué conviene conservar el despliegue monolítico al principio?
10. 🟡 ¿Cómo comparas comportamiento viejo y nuevo sin duplicar pagos?
11. 🟡 ¿Qué contrato mínimo introducirías alrededor de un SDK de pagos?
12. 🟡 ¿Cómo retiras el camino viejo sin dejar llamadas ocultas?
13. 🟡 ¿Qué deuda deja una base de datos compartida?
14. 🟡 ¿Cuándo conservarías una abstracción temporal?
15. 🟡 ¿Qué aporta un token de provider en NestJS durante la migración?
16. 🟠 Dos adapters Go coexisten durante la migración. ¿Dónde seleccionas el nuevo sin filtrar un flag al caso de uso?
17. 🟠 El equipo propone reescribir todo antes de entregar valor. ¿Qué corte haces?
18. 🟠 Las pruebas de caracterización muestran un bug de crédito. ¿Qué haces?
19. 🟠 Ambos caminos escriben inventario para comparar resultados. ¿Qué riesgo detienes?
20. 🟠 Un módulo nuevo sigue importando entidades JPA del viejo. ¿Qué frontera falta?
21. 🟠 El feature flag lleva dos años activo para ambos caminos. ¿Qué decides?
22. 🟠 El adapter legado no distingue timeout de rechazo. ¿Cómo migras sin cobrar doble?
23. 🟠 El monolito ya tiene tests útiles y pocos cambios. ¿Cuándo paras?
24. 🟠 ¿Qué evidencia usarías para afirmar que la migración mejoró el diseño?

**Siguiente:** [Simulación de entrevista](08-simulacion-de-entrevista.md).
