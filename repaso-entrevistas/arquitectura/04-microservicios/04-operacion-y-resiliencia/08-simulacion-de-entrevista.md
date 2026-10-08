# 08 — Simulación de entrevista

> El examen del bloque: preguntas que cruzan los siete capítulos de operación y escenarios de
> diagnóstico y de entrega. Asume leídos [`01`](01-descubrimiento-y-enrutamiento.md) a
> [`07`](07-testing-de-microservicios.md). Las respuestas de los escenarios están en
> [`09`](09-respuestas.md).
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 Cómo se usa esto

Este bloque es el que más se parece a una entrevista de guardia, así que el método cambia un poco:

```text
1. En los diagnósticos, di SIEMPRE tres hipótesis ordenadas por probabilidad
   y cómo distingues una de otra. Una sola hipótesis es adivinar.
2. Antes de proponer una solución, di qué recurso se está agotando.
3. Dos minutos por pregunta, en voz alta, con cronómetro.
4. En los escenarios: quince minutos, papel, y dibuja la cadena de llamadas.
```

La trampa característica: empezar por la herramienta —"pondría un mesh", "usaría tal panel"— en vez de
por el mecanismo. Primero qué falla y por qué; la herramienta, después.

---

## 2. 🧠 Preguntas transversales

### Descubrimiento y borde

1. **S1.** ¿Por qué el balanceo por conexión no reparte el tráfico de HTTP/2? 🟡
2. **S2.** ¿Cuánto tarda tu sistema en dejar de mandar tráfico a una instancia muerta? 🟠
3. **S3.** ¿Qué va en el gateway y qué no? 🟢
4. **S4.** ¿Qué es un BFF y quién debe poseerlo? 🟢
5. **S5.** "Ya lo valida el gateway." ¿Por qué es peligroso? 🟡

### Resiliencia

6. **S6.** ¿Qué se propaga en una caída en cascada y en qué dirección? 🟢
7. **S7.** ¿Cómo se calcula un timeout? 🟢
8. **S8.** Enumera las cuatro reglas del reintento. 🟢
9. **S9.** ¿A quién protege el circuit breaker, y dónde vive su estado? 🟡
10. **S10.** ¿En qué orden implantarías las cinco medidas con una semana? 🟠
11. **S11.** ¿Por qué el reintento es el único mecanismo que puede empeorar el incidente? 🟡

### Observabilidad

12. **S12.** ¿Qué pregunta responde cada uno de los tres pilares? 🟢
13. **S13.** ¿Dónde se pierde el contexto de traza? 🟢
14. **S14.** ¿Por qué una traza muestreada a medias no sirve? 🟡
15. **S15.** ¿Qué muestreo configurarías con mucho tráfico y pocos errores? 🟠
16. **S16.** Define un SLI y un SLO para la confirmación de pedidos. 🟠

### Mesh

17. **S17.** ¿Qué mueve un mesh fuera del código y qué no mueve? 🟢
18. **S18.** ¿Por qué su mejor argumento es el poliglotismo? 🟡
19. **S19.** ¿Por qué un mesh puede duplicar un cobro? 🟡
20. **S20.** Seis servicios, una plataforma: ¿mesh sí o no? 🟠

### Entrega

21. **S21.** ¿Qué tres cosas rompen el despliegue independiente? 🟢
22. **S22.** Diferencia entre rolling, blue-green y canary. 🟢
23. **S23.** ¿Por qué blue-green no da vuelta atrás atómica? 🟡
24. **S24.** ¿Qué verificas tras un despliegue para promover o revertir? 🟠
25. **S25.** ¿Cómo evitas que los feature flags se acumulen? 🟠

### Testing

26. **S26.** ¿Por qué se deforma la pirámide en microservicios? 🟢
27. **S27.** ¿Qué sustituye al entorno de integración completo? 🟡
28. **S28.** ¿Por qué una base en memoria no vale en pruebas de componente? 🟡
29. **S29.** Nombra cuatro cosas que casi nadie prueba. 🟢
30. **S30.** Tu suite de extremo a extremo falla el 30 % por motivos ajenos. ¿Qué haces? 🟠

### Las que descolocan

31. **S31.** ¿Cuál es el peor incidente que has vivido y qué cambiaste después? 🔴
32. **S32.** El entrevistador dice que con un mesh ya no hace falta resiliencia en el código.
    Responde. 🟠
33. **S33.** ¿Cómo convences a un equipo de reducir sus pruebas de extremo a extremo? 🔴
34. **S34.** Te toca guardia esta noche en un sistema que no conoces. ¿Qué miras antes de irte a
    dormir? 🔴
35. **S35.** Si solo pudieras exigir **una** práctica operativa a un equipo nuevo, ¿cuál sería? 🔴

---

## 3. 🎭 Escenarios de diseño

### E1 — La cascada de latencia

**Fuerza:** el diagnóstico bajo presión. Obliga a identificar el recurso agotado y a ordenar
correcciones.

A las 10:14, el p99 de `orders` pasa de 300 ms a 8 s. CPU normal, memoria normal, hilos al máximo.
`customers` y `segments` responden bien. `payments`, tres saltos más allá, tiene una consulta lenta por
un índice perdido en un despliegue.

Explica la cadena, di qué se está agotando, y ordena las correcciones por relación entre efecto y
esfuerzo.

### E2 — Estrategia de pruebas y despliegue de un servicio nuevo

**Fuerza:** la entrega completa. Del commit a producción, con lo que se prueba y lo que se verifica.

Vas a añadir el noveno servicio a un sistema que ya tiene ocho. El equipo tiene un entorno de
integración que falla a menudo y pruebas de extremo a extremo lentas.

Diseña la estrategia de pruebas y el pipeline, y di qué **no** vas a hacer y por qué.

### E3 — El despliegue que gotea errores

**Fuerza:** la convivencia de versiones. Obliga a distinguir apagado, contrato y capacidad.

Cada despliegue produce un goteo de errores durante unos minutos. Nadie sabe por qué; se ha
normalizado como "ruido de despliegue".

Da tres hipótesis ordenadas, di cómo las distingues y qué corriges en cada caso.

### E4 — ¿Mesh o no?

**Fuerza:** la decisión con coste. Obliga a razonar organización y no solo tecnología.

Un sistema con 25 servicios en tres plataformas. Requisito nuevo: mTLS en todo el tráfico interno. El
equipo de plataforma propone adoptar un service mesh.

Da tu recomendación, los números que pedirías antes de decidir, y qué dejarías en el código pase lo
que pase.

### E5 — Observabilidad desde cero

**Fuerza:** la priorización. Obliga a elegir qué se instrumenta primero con presupuesto limitado.

Un sistema con doce servicios tiene logs abundantes, ninguna traza y métricas dispares. Los
incidentes se diagnostican leyendo logs durante horas.

Diseña el plan de seis semanas: qué se hace primero, qué se mide y cómo sabes que ha funcionado.

---

## 4. 🗣️ Las frases que hay que tener listas

> "En una cascada no se propaga el error, se propaga la lentitud, y va hacia arriba. Por eso el
> servicio que se cae casi nunca es el que falla."

> "El timeout no mide mi paciencia con el otro: mide cuánto puedo esperar sin quedarme sin recursos.
> Por eso lo calculo desde mi presupuesto, no desde su p99."

> "Sustituyo el entorno donde todo está desplegado a la vez por contratos verificados en CI: falla
> solo cuando de verdad rompo a alguien, y falla en mi pipeline."

---

**Anterior:** [`07` — Testing de microservicios](07-testing-de-microservicios.md) · **Siguiente:**
[`09` — Respuestas](09-respuestas.md) · **Relacionado:**
[`05-plataformas`](../05-plataformas/) ·
[`03-datos-y-consistencia`](../03-datos-y-consistencia/)
