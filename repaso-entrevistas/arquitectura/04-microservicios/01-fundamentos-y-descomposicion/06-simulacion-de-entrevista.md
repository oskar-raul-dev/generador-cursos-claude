# 06 — Simulación de entrevista

> El examen del bloque: preguntas transversales que cruzan los cinco capítulos y escenarios de diseño
> con papel. Asume leídos [`01`](01-que-es-un-microservicio.md) a
> [`05`](05-el-servicio-por-dentro.md). Las respuestas de los escenarios están en
> [`07`](07-respuestas.md); las `S#` remiten a la pregunta de capítulo que las cubre.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 Cómo se usa esto

No es un cuestionario para leer. Es un simulacro, y funciona si se usa como tal:

```text
1. Cronómetro a dos minutos por pregunta. Si te pasas, la respuesta es demasiado larga.
2. En voz alta. Siempre. Lo que se piensa claro y se dice mal, en la entrevista cuenta como mal.
3. Sin mirar el solucionario hasta haber contestado. Si no sabes, di "no lo sé" y sigue.
4. Los escenarios: quince minutos, papel, y dibujando. Nadie diseña de cabeza.
```

La forma de la respuesta que se practica aquí es siempre la misma: **treinta segundos que contestan,
dos minutos que desarrollan, y el detalle solo si lo piden**. Empezar por el detalle es el error más
común de los perfiles técnicos.

---

## 2. 🧠 Preguntas transversales

### Definición y precio

1. **S1.** Define microservicio en una frase, sin usar la palabra "pequeño". 🟢
2. **S2.** Nombra las cuatro cosas que dejan de ser gratis al separar un servicio. 🟢
3. **S3.** ¿Qué compran de verdad los microservicios, y qué no compran? 🟡
4. **S4.** ¿Por qué separar un servicio empeora la latencia por petición? 🟡
5. **S5.** Tu equipo despliega todo junto los jueves. ¿Qué compra la autonomía? 🟠

### Fronteras

6. **S6.** ¿Cómo decides por dónde cortar un sistema? Da tus criterios en orden. 🟡
7. **S7.** ¿Qué te dice el historial de commits sobre las fronteras de un sistema? 🟡
8. **S8.** Dos servicios escriben el mismo campo. ¿Qué concluyes? 🟠
9. **S9.** Una consulta necesita datos de tres servicios **para decidir**, no para mostrar. ¿Qué
   indica? 🟠
10. **S10.** ¿Cuándo aceptarías un servicio que solo hace CRUD? 🟠

### Migración

11. **S11.** ¿Qué extraes primero de un monolito, y por qué ese criterio? 🟡
12. **S12.** ¿En qué orden se separan datos y proceso? 🟢
13. **S13.** ¿Cuál es el punto de no retorno de una migración? 🟡
14. **S14.** Llevas ocho meses migrando y el monolito ha crecido. ¿Qué falló? 🟠
15. **S15.** ¿Cómo mides que una fase de migración terminó? 🟠

### Antipatrones

16. **S16.** Enumera las cuatro preguntas que detectan un monolito distribuido. 🟢
17. **S17.** "Compartimos la base solo para leer." Desmóntalo. 🟡
18. **S18.** ¿Cuándo una librería compartida es sana y cuándo es tóxica? 🟠
19. **S19.** Calcula la disponibilidad de una cadena de cinco servicios al 99,9 % y di qué significa.
    🟡
20. **S20.** Te dan diez minutos y un repositorio ajeno. ¿Qué miras? 🟠

### El servicio por dentro

21. **S21.** Diferencia entre liveness y readiness, y el error clásico. 🟢
22. **S22.** Enumera los cinco pasos de un apagado ordenado. 🟢
23. **S23.** ¿Qué es un chassis y qué no puede contener nunca? 🟡
24. **S24.** ¿Qué dependencias pondrías en el readiness de `orders`? 🟠
25. **S25.** Tu tablero muestra errores 502 coincidiendo con los despliegues. Diagnostica. 🟠

### Las que descolocan

26. **S26.** El entrevistador dice que los microservicios son siempre mejores que un monolito.
    ¿Qué contestas? 🟠
27. **S27.** ¿Cuál es la peor decisión de arquitectura que has tomado, y qué aprendiste? 🔴
28. **S28.** Un compañero propone quince servicios para un producto sin usuarios. Tienes dos minutos
    para convencerle. 🔴
29. **S29.** ¿Cómo convences a negocio de invertir un trimestre en algo que no añade funcionalidad?
    🔴
30. **S30.** Si tuvieras que elegir **una sola** práctica de este bloque para un equipo que empieza,
    ¿cuál sería y por qué? 🔴
31. **S31.** Te piden dar un número de microservicios en la primera reunión. Responde sin evadirte.
    🟠
32. **S32.** ¿Qué harías en tus primeras dos semanas en un equipo con un monolito distribuido? 🔴

---

## 3. 🎭 Escenarios de diseño

Quince minutos cada uno, con papel. Se dibuja, se decide y se defiende en voz alta.

### E1 — Corte de un dominio nuevo

**Fuerza:** la frontera. Obliga a elegir criterios de descomposición y a defenderlos.

Una plataforma de reservas de restaurantes: búsqueda de locales, reserva de mesa, pago de señal,
valoraciones, y un panel para el restaurante. Tres equipos.

Propón el corte de servicios, di qué criterio aplicaste en cada uno y señala las dos decisiones más
discutibles.

### E2 — Migración con base de datos compartida

**Fuerza:** el orden. Obliga a separar datos antes que proceso y a planificar por fases reversibles.

Un monolito de facturación de diez años, con ciento veinte tablas, que factura a diario y no admite
parada. El negocio quiere poder desplegar cambios de reglas fiscales sin esperar al ciclo mensual.

Diseña las cuatro primeras fases, con lo que se despliega en cada una y cómo se vuelve atrás.

### E3 — La respuesta correcta es no separar

**Fuerza:** decir que no. El escenario está construido para que separar sea la respuesta equivocada.

Un equipo de cuatro personas mantiene un sistema de gestión interna con ochenta usuarios. Despliegan
cada dos semanas. La dirección ha leído sobre microservicios y pide una propuesta de migración.

Prepara la respuesta: qué propones, cómo lo justificas y qué concedes.

### E4 — Diagnóstico de un monolito distribuido

**Fuerza:** el diagnóstico. Obliga a identificar acoplamientos concretos y a priorizar.

Te incorporas a un sistema con doce servicios. Síntomas: se despliegan juntos los martes por la
noche, las pruebas necesitan un entorno completo que falla la mitad de las veces, y un cambio de un
campo tocó cinco repositorios.

Di qué mirarías, en qué orden, y cuál sería tu primer trabajo con impacto.

### E5 — El primer servicio extraído

**Fuerza:** la ejecución. Del diseño al detalle operativo: chassis, health checks, apagado.

Has decidido extraer `notifications` de un monolito. Es el primer servicio del sistema.

Diseña qué hay dentro, qué trae el chassis, qué health checks tiene, cómo se despliega y cómo
demuestras que la extracción funcionó.

---

## 4. 🗣️ Las frases que hay que tener listas

Tres, para cuando te quedes en blanco. Son ciertas, son breves y abren conversación:

> "Un microservicio no es un servicio pequeño: es uno que puedes desplegar solo y que es dueño de sus
> datos. Si no se cumplen las dos cosas, tienes un módulo con latencia de red."

> "Los microservicios no compran rendimiento ni resiliencia: compran independencia. La resiliencia se
> construye aparte y se paga aparte."

> "Prefiero equivocarme por tener pocos servicios que por tener muchos: juntar dos es fácil, separar
> mal es caro durante años."

---

**Anterior:** [`05` — El servicio por dentro](05-el-servicio-por-dentro.md) · **Siguiente:**
[`07` — Respuestas](07-respuestas.md) · **Relacionado:**
[`02-comunicacion`](../02-comunicacion/) · [`05-plataformas`](../05-plataformas/)
