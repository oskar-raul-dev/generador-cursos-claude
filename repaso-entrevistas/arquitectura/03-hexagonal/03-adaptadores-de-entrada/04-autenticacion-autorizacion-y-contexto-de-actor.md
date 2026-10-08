# 04 — Autenticación, autorización y contexto de actor

Este capítulo enseña a separar la prueba de identidad de la decisión de negocio sobre quién puede operar un pedido. La separación permite que HTTP, jobs y mensajes aporten un actor comprensible para la aplicación sin introducir JWT en el dominio.

## 1. 🎯 El problema

El controller comprueba que el token tenga el rol `ADMIN` y deja cancelar cualquier pedido. Un job interno no lleva JWT y omite la comprobación. El fallo es una autorización contextual implementada como propiedad de un transporte, mientras el caso de uso se ejecuta desde varias entradas.

## 2. 🧭 Identidad, permiso y dirección

```text
credencial / token ─► autenticador del borde ─► Actor(id, tenant, capabilities)
                                              │
                                              ▼
                              CancelOrder(actor, orderId)
                                      │
                          política contextual + invariante
```

Autenticar responde quién presentó la credencial y si es válida. Autorizar responde si ese actor puede realizar esta acción sobre este recurso. El borde puede rechazar rutas públicas o requerir un permiso grueso; el caso de uso debe verificar reglas dependientes del pedido, como “solo el dueño del pedido o un operador habilitado puede cancelarlo”. La entidad mantiene sus invariantes, por ejemplo que un pedido enviado no pueda cancelarse. El [reparto de validación](../02-nucleo-aplicacion-y-dominio/06-validacion-errores-y-resultados.md) también aplica a la seguridad.

`Actor` es una representación propia de aplicación: identificador, tenant verificado, tipo (usuario o servicio) y capacidades necesarias. No contiene token crudo, claims sin verificar, `SecurityContext` ni objeto de framework. El adaptador convierte credenciales verificadas a ese contrato. Un consumidor autentica al productor o usa una identidad de servicio según su canal; no finge que un usuario emitió una acción si no puede demostrarlo.

## 3. 🔄 Flujo de cancelación y auditoría

1. El borde verifica credencial, expiración, audiencia y procedencia según su mecanismo, y establece una identidad confiable.
2. El adaptador crea `Actor` a partir de claims permitidos y verificados. Nunca toma `actorId` del JSON público como prueba de identidad.
3. `CancelOrder` carga el pedido, evalúa permiso contextual para ese actor y aplica la invariante del agregado. La consulta de permisos externos puede ser un puerto de salida si la política los necesita.
4. La aplicación registra una acción auditable con actor, operación, recurso, resultado y correlación; infraestructura almacena y protege ese registro. La auditoría no debe incluir tokens ni datos innecesarios.

El contexto de correlación y trazas puede viajar por infraestructura, pero la autorización debe recibir datos explícitos. Los contextos implícitos de hilo o async son útiles para logs; si la política depende de ellos sin contrato, una ejecución desde job puede saltarse controles. La propagación entre procesos exige verificar confianza y no aceptar headers de identidad arbitrarios.

## 4. 🧩 Contrato mínimo

```java
record Actor(String id, String tenantId, Set<String> capabilities) {}
record CancelOrderCommand(String orderId, Actor actor) {}

final class CancelOrder {
    private final Orders orders;
    CancelOrder(Orders orders) { this.orders = orders; }

    void execute(CancelOrderCommand c) {
        Order order = orders.find(c.orderId());
        if (!order.tenantId().equals(c.actor().tenantId())) throw new AccessDenied();
        if (!order.customerId().equals(c.actor().id())
            && !c.actor().capabilities().contains("CANCEL_OTHERS_ORDER")) {
            throw new AccessDenied();
        }
        order.cancel(); // también protege su estado
        orders.save(order);
    }
}
```

El código muestra una política simple. En producción, el adapter HTTP construye `Actor` después de autenticar; un worker configura una identidad de servicio con capacidades limitadas. El composition root inyecta `Orders` en el caso de uso; ningún tipo de Spring Security entra en él. Si los permisos cambian frecuentemente, se verifica vigencia con un puerto dedicado y se documenta la ventana de caché.

## 5. 🧰 Cuatro plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | Spring Security autentica y autoriza requests | mapear principal a actor y evaluar recurso | usar `SecurityContextHolder` en dominio |
| Node/TS | NestJS guards protegen rutas | verificar token y pasar actor explícito | asumir que un guard resuelve ownership |
| Go | middleware envuelve handlers y `context` transporta valores | definir claves tipadas y contrato de actor | tomar un header público como identidad |
| Python | FastAPI dependencies extraen credenciales | verificar claims y aplicar permiso contextual | dejar toda autorización en la dependencia HTTP |

## 6. ⚖️ Decisión y coste

Duplicar una comprobación gruesa en el borde y otra contextual en aplicación puede ser correcto: la primera evita trabajo innecesario; la segunda protege la acción desde cualquier driver. El coste son actor explícito, pruebas de matrices de permiso y auditoría. Para operaciones internas sin usuario, una identidad de servicio explícita reduce ambigüedad. Prueba al menos dueño, tercero, operador, otro tenant y job; una prueba de ruta autenticada sola no verifica la regla.

## ⚠️ Errores frecuentes

- “La autorización siempre vive en el controller.” La propiedad del recurso debe sobrevivir a otras entradas.
- “El JWT es el actor.” Es una credencial externa con claims y ciclo de vida propios.
- “Un rol global autoriza cualquier pedido.” Puede faltar tenant, ownership o estado.
- “El contexto implícito simplifica todo.” Oculta una entrada de política y dificulta pruebas.
- “Un worker es confiable por estar dentro de la red.” Su identidad y permisos también se delimitan.

## 7. ✅ Veredicto

Verifica credenciales en el borde, pasa un actor mínimo y confiable, y decide permisos dependientes del recurso en aplicación. El dominio protege estados válidos. Esta frontera cuesta contratos y pruebas, pero evita que la seguridad dependa de una ruta concreta.

## 📚 Referencias

- [Spring Security: autorización de solicitudes](https://docs.spring.io/spring-security/reference/servlet/authorization/authorize-http-requests.html)
- [NestJS: guards](https://docs.nestjs.com/guards)
- [FastAPI: seguridad](https://fastapi.tiangolo.com/tutorial/security/)
- [RFC 9110: semántica HTTP](https://www.rfc-editor.org/rfc/rfc9110.html)

## 🧠 Preguntas

1. 🟢 ¿Qué diferencia hay entre autenticación y autorización?
2. 🟢 ¿Qué es un actor de aplicación?
3. 🟢 ¿Dónde se verifica un JWT recibido por HTTP?
4. 🟢 ¿Qué dato de identidad no debes confiar al body público?
5. 🟢 ¿Qué es una autorización contextual?
6. 🟢 ¿Qué invariante conserva el dominio al cancelar un pedido?
7. 🟢 ¿Qué registra una auditoría útil sin exponer secretos?
8. 🟡 ¿Por qué un rol global no basta para cancelar cualquier pedido?
9. 🟡 ¿Cómo autorizas un job que no representa a un usuario?
10. 🟡 ¿Por qué pasas `Actor` explícitamente al caso de uso?
11. 🟡 ¿Qué verifica el borde antes de construir `Actor`?
12. 🟡 ¿Cuándo una consulta de permisos merece un puerto de salida?
13. 🟡 ¿Qué diferencia hay entre un guard de NestJS y una regla de ownership?
14. 🟡 ¿Qué riesgo tiene `SecurityContextHolder` dentro del dominio Java?
15. 🟡 ¿Cómo evitas confiar en un header de identidad en Go?
16. 🟡 ¿Qué casos mínimos pruebas para una política por tenant?
17. 🟠 HTTP autoriza por rol, pero batch cancela sin control. ¿Qué mueves?
18. 🟠 Un request trae `actorId` distinto al token. ¿Cuál usas y por qué?
19. 🟠 Un servicio reenvía claims de usuario a otro proceso. ¿Qué verificas?
20. 🟠 Un operador puede cancelar pedidos ajenos solo en su tenant. ¿Dónde expresas la regla?
21. 🟠 El token expira durante un job largo. ¿Cómo modelas la identidad de ejecución?
22. 🟠 Una caché de permisos permite una acción recién revocada. ¿Qué decides?
23. 🟠 Una prueba del controller pasa, pero un consumidor elude autorización. ¿Qué prueba falta?
24. 🟠 ¿Cuándo aceptarías una verificación duplicada en borde y aplicación?

**Siguiente:** [DTO, mapeo y presentación de errores](05-dto-mapeo-y-presentacion-de-errores.md).
