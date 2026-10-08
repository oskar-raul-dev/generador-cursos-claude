# 06 — Simulación de entrevista

> El examen del bloque: preguntas que cruzan los cinco capítulos de datos y escenarios donde hay que
> diseñar consistencia sin transacción. Asume leídos [`01`](01-base-de-datos-por-servicio.md) a
> [`05`](05-evolucion-de-esquema-y-migraciones.md). Las respuestas de los escenarios están en
> [`07`](07-respuestas.md).
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 Cómo se usa esto

Mismo método, con el añadido propio de este bloque:

```text
1. Dos minutos por pregunta, cronómetro, en voz alta.
2. En los escenarios de datos, dibuja SIEMPRE los estados y las transiciones.
   Una saga explicada sin máquina de estados no se entiende ni se defiende.
3. Cuando digas "se compensa", di también qué pasa si la compensación falla.
4. Nombra el precio en consistencia: qué ve el usuario, y durante cuánto tiempo.
```

La trampa de este bloque es hablar de atomicidad sin hablar de aislamiento. Quien explica la saga y
no menciona los estados intermedios visibles, no la ha operado.

---

## 2. 🧠 Preguntas transversales

### Propiedad de los datos

1. **S1.** Enuncia la regla de base de datos por servicio y sus tres excepciones. 🟢
2. **S2.** ¿Qué cuatro acoplamientos produce compartir una base? 🟢
3. **S3.** ¿Por qué una réplica no elimina el acoplamiento de esquema? 🟡
4. **S4.** ¿Qué sustituye a una clave foránea entre servicios? 🟡
5. **S5.** ¿Qué mecanismo sostiene la regla: el documento o los permisos? 🟠

### Consultas

6. **S6.** ¿Cuáles son las tres opciones para consultar datos repartidos? 🟢
7. **S7.** ¿Por qué componer empeora la disponibilidad de una pantalla? 🟡
8. **S8.** ¿Cuándo pasarías de composición a proyección? Da los números. 🟠
9. **S9.** ¿Qué indica que una consulta necesite datos ajenos para **decidir**? 🟠
10. **S10.** ¿Quién debe ser dueño de una proyección y por qué? 🟡

### Saga

11. **S11.** ¿Qué garantía da una saga y cuál no da? 🟢
12. **S12.** Coreografía u orquestación: ¿cómo eliges? 🟡
13. **S13.** ¿Qué son los pasos compensable, pivote y reintentable? 🟢
14. **S14.** ¿Por qué 2PC no se usa entre microservicios? 🟡
15. **S15.** Tu saga se queda parada porque un servicio no responde ni bien ni mal. ¿Qué falta? 🟠
16. **S16.** ¿Qué haces cuando la compensación falla tres veces? 🟠

### Outbox e idempotencia

17. **S17.** ¿Qué es el problema de la doble escritura? 🟢
18. **S18.** ¿Por qué el outbox **garantiza** duplicados? 🟡
19. **S19.** ¿Por qué marca y efecto van en la misma transacción? 🟡
20. **S20.** Diferencia entre CDC sobre el outbox y CDC sobre tus tablas. 🟠
21. **S21.** ¿Quién genera la clave de idempotencia y con qué criterio? 🟢
22. **S22.** Un consumidor llama a un tercero no idempotente. ¿Cómo lo haces seguro? 🟠

### Migraciones

23. **S23.** ¿Por qué toda migración debe ser compatible con el código que ya corre? 🟢
24. **S24.** Nombra tres cambios de esquema seguros y tres inseguros. 🟢
25. **S25.** ¿Cómo se hace un backfill correctamente? 🟡
26. **S26.** ¿Por qué la contracción no va en el mismo despliegue? 🟡
27. **S27.** ¿Dónde harías correr las migraciones y por qué? 🟠

### Las que descolocan

28. **S28.** ¿Cómo explicas a producto que existe un estado "reservado pero no pagado"? 🔴
29. **S29.** El entrevistador dice que la consistencia eventual no es aceptable en banca. Responde.
    🔴
30. **S30.** ¿Qué incidente de datos has vivido y qué cambiaste después? 🔴
31. **S31.** Si solo pudieras exigir **una** práctica de este bloque, ¿cuál sería? 🔴
32. **S32.** Te piden garantizar que un cobro no se duplica nunca. ¿Qué prometes y qué no? 🔴
33. **S33.** ¿Cómo convences a un equipo de que deje de leer las tablas de otro? 🟠

---

## 3. 🎭 Escenarios de diseño

### E1 — La saga de un flujo nuevo

**Fuerza:** el diseño de la consistencia. Obliga a ordenar pasos, elegir pivote y diseñar
compensaciones.

Una aseguradora contrata una póliza en línea: validar al cliente, calcular la prima con un proveedor
externo de scoring, cobrar la primera cuota, emitir la póliza y enviarla por correo.

Diseña la saga: pasos, tipos, compensaciones, estados, vencimientos y qué se audita.

### E2 — Eventos duplicados en producción

**Fuerza:** el diagnóstico y la corrección estructural. Obliga a distinguir síntoma de causa.

Contabilidad detecta que algunos pedidos generaron dos reservas de stock. El consumidor tiene tabla
de deduplicación. Ocurrió durante una ventana en la que hubo un despliegue y un reequilibrio de
consumidores.

Di qué compruebas, cuál es la causa más probable y qué corriges para que no vuelva a pasar.

### E3 — La consulta que no cabe

**Fuerza:** la frontera. Obliga a elegir entre composición, proyección y rediseño.

El equipo de atención al cliente necesita una pantalla que liste los pedidos de un cliente, filtrados
por estado y por producto, ordenados por fecha y paginados. Los datos están en `orders`, `catalog`
y `customers`.

Elige la solución, justifica con números y di qué cuesta.

### E4 — Migración sin parada

**Fuerza:** la ejecución. Obliga a aplicar expand/contract sobre volumen real.

Hay que cambiar el tipo de una columna de importes en una tabla de cuarenta millones de filas,
ampliando la precisión decimal. El servicio factura a diario y no admite parada.

Diseña la secuencia completa, con tiempos, verificación y vuelta atrás.

### E5 — Separar el esquema compartido

**Fuerza:** el orden datos-proceso. Obliga a no sacar el servicio antes de separar los datos.

`orders` e `inventory` ya son dos servicios, pero comparten base de datos y algunas consultas
cruzan tablas de ambos. Nadie puede migrar su esquema sin coordinar.

Diseña el plan por fases, con lo que se despliega, cómo se mide y dónde está el punto de no retorno.

---

## 4. 🗣️ Las frases que hay que tener listas

> "Una saga da atomicidad de negocio, no aislamiento. Los estados intermedios son visibles, y por eso
> los modelo explícitamente en vez de esconderlos."

> "Asumo al-menos-una-vez y hago idempotente el consumidor, con la marca y el efecto en la misma
> transacción. Lo demás son garantías que no existen de extremo a extremo."

> "Toda migración tiene que funcionar con el código que ya está corriendo. Si no puedo hacerla así,
> negocio una ventana; lo que no hago es descubrirlo durante el despliegue."

---

**Anterior:** [`05` — Evolución de esquema y migraciones](05-evolucion-de-esquema-y-migraciones.md) ·
**Siguiente:** [`07` — Respuestas](07-respuestas.md) · **Relacionado:**
[`02-comunicacion/06`](../02-comunicacion/06-mensajeria-y-eventos.md) ·
[`04-operacion-y-resiliencia`](../04-operacion-y-resiliencia/)
