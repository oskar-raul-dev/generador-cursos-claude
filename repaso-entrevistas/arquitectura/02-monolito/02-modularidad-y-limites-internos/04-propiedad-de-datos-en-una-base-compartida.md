# 04 — Propiedad de datos en una base compartida

Aprenderás a establecer ownership de datos sin exigir una base física por módulo. Compartir motor
puede conservar transacciones, joins y operación sencilla; lo peligroso es no saber quién puede
escribir, evolucionar y responder por cada estado.

## 1. 🎯 El síntoma

`orders` cambia directamente `inventory.reservations`, `payments` corrige el estado del pedido y un job
de reportes actualiza ambas tablas. Un cambio de columna exige buscar SQL por todo el repositorio y
ningún equipo puede garantizar la invariante.

```text
no hay ownership                 ownership lógico
orders ───┬─► orders             orders ─► orders
payments ─┼─► inventory          inventory ─► inventory
jobs ─────┴─► payments           payments ─► payments
                                      ▲
otros módulos ──API/vista/consulta publicada──┘
```

La base compartida no causó por sí sola el problema. Las escrituras cruzadas y la evolución sin
propietario hicieron que el esquema fuera una API accidental.

## 2. 🗝️ Ownership de escritura

Para cada tabla o conjunto coherente, declara un módulo propietario:

- solo él crea y cambia el estado autoritativo;
- valida las invariantes antes de escribir;
- decide migraciones compatibles y significado de columnas;
- publica comandos o vistas para consumidores;
- responde por reconciliación y calidad del dato.

Otros módulos pueden compartir la misma conexión física, pero no el derecho lógico a mutar. La
garantía conservada es una sola autoridad sobre cada invariante. El coste son APIs, vistas y alguna
duplicación de lectura.

## 3. 🗂️ Tablas, schemas y roles

Separar schemas hace visible el límite:

```sql
CREATE SCHEMA inventory AUTHORIZATION inventory_owner;
REVOKE INSERT, UPDATE, DELETE ON inventory.reservations FROM app_orders;
GRANT SELECT ON inventory.published_availability TO app_orders;
```

Los roles y permisos convierten una convención en control, pero no diseñan ownership. Si todos usan
la misma credencial con privilegios totales, dos schemas son solo nombres. Si un ORM genera accesos
cruzados o el equipo concede excepciones permanentes, el límite vuelve a ser nominal.

## 4. 👀 Lectura sin apropiarse de la escritura

| Necesidad | Mecanismo | Garantía | Coste |
|---|---|---|---|
| dato actual simple | consulta publicada/API local | semántica del propietario | dependencia en runtime local |
| reporting | vista SQL de solo lectura | una definición publicada | acoplamiento al esquema de vista |
| join operativo puntual | consulta coordinada | consistencia de la transacción | conocimiento explícito de dos fuentes |
| lectura frecuente especializada | proyección/read model | autonomía de lectura | retraso y reconciliación |

No conviertas cada join en una API por dogma. Dentro de la misma base, un join de solo lectura puede
ser la opción más simple si usa vistas publicadas, tiene dueño y no filtra tablas internas. Para
reporting transversal, una vista o réplica analítica puede evitar duplicar lógica en módulos.

## 5. 🔗 Claves foráneas y transacciones

Una clave foránea conserva integridad referencial aunque cruce ownership. También acopla migraciones
y orden de eliminación. Úsala si la garantía compensa y ambos lados aceptan el ciclo de evolución;
no la retires solo para parecer más independiente.

Una transacción local puede coordinar escrituras realizadas a través de las APIs de dos módulos. Eso
no autoriza a un módulo a usar el repository del otro. La frontera de transacción responde qué debe
confirmarse junto; la propiedad responde quién decide cada escritura.

## 6. 🪜 Migrar escrituras cruzadas

1. Inventaria SQL, ORM, jobs, triggers y scripts que escriben la tabla.
2. Declara propietario y semántica de cada operación.
3. Añade una API interna y migra un consumidor.
4. Observa resultados y conserva una ruta de reversión breve.
5. Revoca permisos o añade una regla arquitectónica.
6. Retira la ruta antigua y fecha las excepciones restantes.

Evita dual writes sin estrategia: si la ruta nueva y la vieja actualizan estados distintos, no hay
una autoridad. Durante la migración, un único escritor debe seguir siendo canónico y cualquier
sincronización debe poder reconciliarse.

## 7. 🧰 ORM y SQL directo

| Enfoque | Ayuda a | No garantiza | Trampa frecuente |
|---|---|---|---|
| ORM | mapear y centralizar repositorios | ownership entre módulos | importar entidades ajenas |
| SQL directo | consultas explícitas y eficientes | respeto de fronteras | escribir cualquier tabla por comodidad |
| Permisos de base | bloquear operaciones | buen modelo de módulos | una credencial global privilegiada |
| Vistas | publicar lectura estable | aislamiento de cambio total | `SELECT *` sobre detalles internos |

La elección no es ORM contra SQL. El criterio es si la herramienta puede limitar y hacer auditable
quién lee, escribe y migra.

## 8. ⚖️ Decisión y coste

Mantén una base compartida cuando simplifique operación, integridad y transacciones, pero asigna
propietarios de escritura y superficies de lectura. Separa almacenamiento físico solo si necesitas
aislamiento, escala u operación independiente y puedes pagar consistencia y migración. Añade permisos
de forma gradual para no romper procesos ocultos.

## ⚠️ Errores frecuentes

- «Base compartida significa datos sin dueño». Ownership es una decisión y un control.
- «Schema separado garantiza autonomía». Una credencial global puede ignorarlo.
- «Toda lectura cruzada debe ser una llamada». Un join publicado puede ser proporcional.
- «Una tabla por módulo basta». Scripts, triggers y migraciones también escriben.
- «Una foreign key viola modularidad». Puede preservar una garantía deliberada.

## 9. ✅ Veredicto

Haz que cada dato autoritativo tenga un escritor y un equipo responsables. Publica las lecturas que
otros necesitan y automatiza el límite con permisos o pruebas. La misma base puede alojar módulos
con ownership real; bases separadas también pueden conservar propiedad difusa.

## 📚 Referencias

- [Privileges, PostgreSQL 18](https://www.postgresql.org/docs/current/ddl-priv.html)
- [Database Roles, PostgreSQL 18](https://www.postgresql.org/docs/current/user-manag.html)
- [Constraints, PostgreSQL 18](https://www.postgresql.org/docs/current/ddl-constraints.html)
- [Rules and Privileges, PostgreSQL 18](https://www.postgresql.org/docs/current/rules-privileges.html)

## 🧠 Preguntas

1. 🟢 ¿Qué significa que un módulo sea propietario de un dato?
2. 🟢 ¿Qué diferencia hay entre compartir motor y compartir ownership?
3. 🟢 ¿Qué es una escritura cruzada?
4. 🟢 ¿Qué función cumple una vista publicada?
5. 🟢 ¿Qué puede hacer un rol de base para reforzar el límite?
6. 🟢 ¿Qué garantía preserva una clave foránea?
7. 🟢 ¿Qué diferencia hay entre propiedad de escritura y frontera transaccional?
8. 🟡 ¿Por qué dos schemas no garantizan autonomía?
9. 🟡 ¿Cuándo una lectura directa mediante vista puede ser proporcional?
10. 🟡 ¿Cuándo conviene una proyección en vez de una consulta publicada?
11. 🟡 ¿Qué coste introduce una clave foránea entre módulos?
12. 🟡 ¿Por qué una transacción cruzada no autoriza a usar repositories ajenos?
13. 🟡 ¿Cómo evaluarías ORM frente a SQL directo desde el ownership?
14. 🟡 ¿Qué accesos debes inventariar antes de revocar permisos?
15. 🟡 ¿Por qué una credencial global debilita el control por schemas?
16. 🟡 ¿Qué debería contener una concesión temporal de escritura?
17. 🟡 ¿Cómo mantienes reporting sin entregar ownership al módulo de reportes?
18. 🟠 `orders` actualiza stock para ahorrar una llamada local. ¿Qué migración propones?
19. 🟠 Un trigger modifica tablas de dos módulos. ¿Cómo decides conservarlo o retirarlo?
20. 🟠 Un join crítico usa tablas internas de tres módulos. ¿Qué alternativas compararías?
21. 🟠 Al revocar `UPDATE`, falla un job nocturno desconocido. ¿Cómo recuperas sin abandonar el límite?
22. 🟠 Una migración requiere dual write durante dos semanas. ¿Cómo defines autoridad y reconciliación?
23. 🟠 Una foreign key bloquea la evolución de `orders`. ¿Qué garantía perderías al retirarla?
24. 🟠 ¿Qué evidencia demostraría que hay ownership real aunque la base siga compartida?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [03 — Dirección de dependencias y ciclos entre módulos](03-direccion-de-dependencias-y-ciclos-entre-modulos.md).

**Siguiente:** [05 — Comunicación interna: llamadas, comandos y eventos](05-comunicacion-interna-llamadas-comandos-y-eventos.md).
