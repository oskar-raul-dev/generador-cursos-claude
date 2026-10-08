# Perfil personal — restricciones y preferencias del plan de IA

Archivo separado del contenido técnico (`Curriculo_Maestro_IA_VFinal.md`) para poder
actualizarlo sin tocar el currículo. Si algo de aquí cambia, revisar qué partes
del currículo dependen de ello.

**Última actualización:** 2026-07-13 (V_Final sin fechas de inicio)

## 1. Tiempo disponible y calendario
- **6 horas por semana, estables todo el año** (sin variación estacional).
- **Calendario fijo:**

| Cuándo | Duración | Qué |
|---|---|---|
| 2 noches entre semana | 1.5 h c/u | Abre con 10 min de reconstrucción sin mirar; luego material nuevo. Canal preferido: libro + cuaderno. |
| Sábado en la mañana | 1.5 h + break + 1.5 h | Material nuevo; cierra con 20-30 min reconstruyendo el bloque 1. Aquí va el video pesado. |
| Viernes alterno | ~45 min | **Tiempo extra.** Tarjetas de repaso de fases pasadas, antes de la noche libre. |

- Los 10 min de apertura y los 20-30 de cierre salen **de dentro** de las 6 h.
- El viernes de descompresión (cine, videojuegos, lectura recreativa) **se protege**: es lo que hace que las 6 h existan durante 30 meses.
- **Microjornadas de 10-15 min**: fase 2, solo cuando el calendario anterior sea hábito (~2 meses). No antes.
- Implicación en el currículo: plan completo ~30-34 meses.

## 2. Estructura del plan
- **Secuencial casi todo.** Único paralelismo: **Pista B (práctica) junto con la Fase 0** — aprox. 4 h/sem matemáticas + 2 h/sem Pista B.
- A partir de la Fase 1, una sola cosa a la vez.
- **Fases renumeradas a enteros (0-10).** No hay fases ".5".

## 3. Ingeniería de datos
- **Fase propia (Fase 2)**, justo antes del ML. Incluye el **simulador de datos de operación** como entregable obligatorio.

## 4. Urgencia de resultados
- **Sin apuro: profundidad primero.** La Pista B es alfabetización práctica, no carrera por algo mostrable.

## 5. Estilo de aprendizaje
- **Mezcla equilibrada de video, lectura y programación**, sin recortar ningún canal. Preferencia personal por libro + subrayado + apuntes a mano — que es *producción activa*, no consumo pasivo.
- **Regla del costo real del video:** la duración nominal **no** es el costo. Ver pausando, retrocediendo y tomando apuntes cuesta **2-3× la duración nominal**. Un curso de "40 horas de video" son ~100 h de trabajo. Al planear se usa el tiempo real, nunca el nominal.
- **Corolario:** ver un video sin pausar es consumo, no estudio, y no cuenta contra las 6 h.
- El video pesado va al **sábado** (bloque largo tolera pausas); las noches de 1.5 h son para libro + cuaderno.

## 6. Método de estudio (nuevo en V_Final)
- **Problema declarado:** dificultad para la lectura profunda; tendencia a saltar entre Wikipedia y prompts sin que quede residuo. Diagnóstico: eso es *reconocimiento pasivo*, no aprendizaje.
- **Corrección:** recuperación activa. Después de leer, cerrar el material y **producir** la explicación por escrito. Lo que no se puede producir, no se aprendió.
- **Regla del mazo:** lo que falle en una reconstrucción se anota. Esa lista **es** el mazo de tarjetas del viernes alterno.
- **Diagnóstico de entrada por fase (obligatorio):** 3-5 preguntas al abrir cada fase, 1-2 de fases anteriores. Fallarlas convierte el repaso en prerequisito.
- **Bitácora por fase:** una página al cerrar cada fase. Insumo del case study de la Fase 10.

## 7. Presupuesto de recursos
- **Mayormente gratuitos**, con compras puntuales: libros sueltos y **bundles de Humble Bundle**.
- Prioridad de compra: (1) Géron, (2) Kleppmann, (3) Chip Huyen.
- Se prefieren las ediciones oficiales gratuitas de los autores.
- **Cómputo:** Fases 0-4 en laptop. Fases 5-8: Colab gratuito primero, Colab Pro (~USD 10/mes) solo en las fases que lo necesiten. GPU propia solo si una rama post-Fase 10 lo justifica.

## 8. Dominios de negocio de interés
Declarados (cuatro): inventarios retail/supermercados, logística, trading/inversión en bolsa, desarrollo y mantenimiento de software legacy.

- **Hilo conductor del proyecto tesis: logística + inventarios retail** (plataforma de operaciones logísticas e inventario).
- **Trading/inversión** y **software legacy**: ramas de especialización opcionales post-Fase 10.

## Perfil de entrada (contexto fijo)
- Licenciado en Ciencias de la Computación (UCV), especialista en desarrollo web (backend). Base matemática universitaria sólida pero ~20 años sin práctica activa → la Fase 0 es reconstrucción de fluidez, no aprendizaje desde cero.
- **Objetivo declarado:** potenciar la IA en el trabajo actual (empresa grande, backend/legacy). No es un cambio de carrera. Existe la posibilidad de ofertas internas, pero no es el motor del plan.

## Decisiones cerradas en la V_Final
- **Track B de 6 meses: descartado.** Se evaluó ampliar la pista práctica a un "semestre de reconocimiento" con ciencia de datos. Razones del rechazo: (a) duplicaría el aprendizaje de datos, que ya es la Fase 2 en el mes ~8.5; (b) retrasaría el eje ~6 meses; (c) ampliaría precisamente la única parte del plan que caduca. **Track B queda en 3 meses, en paralelo solo con la Fase 0.**
- **Ubicación de datos:** entre GOFAI y ML. Cerrada.
- **Simulador de datos:** entregable obligatorio de la Fase 2.
- **IA simbólica fuera del Track B:** no es "lo que está en la práctica"; vive en el Track A.
- **`Guia_Proyecto_Claude_y_Prompts.md`: rescatada y sustituida** por `guia-proyecto.md` (chats, prompts, ciclo de iteración, directorios, skills).
- **Skills de Claude: solo PPTX**, y solo al llegar a la Fase 10. Las CLIs propias de MD→DOCX/PDF ya cubren el resto.
- **Herramientas de Fase 0:** SymPy como verificador de derivaciones. Octave/SciLab descartados (ninguna fase posterior los usa). R queda como opcional solo en la Fase 4.
- **Sin fechas de calendario:** el plan se mide en semanas y horas de trabajo real. La fecha de arranque se decide al empezar.
- **Ansiedad por obsolescencia:** registrada y resuelta. Lo que caduca en 3 años son las herramientas (Pista B, 3 meses). Lo que no caduca es el eje: matemáticas, algoritmos, sistemas de datos, arquitecturas. El plan ya está construido casi enteramente sobre lo segundo.

## Decisiones abiertas / por revisar
- Fase 8 (RL, 10-12 semanas): candidata a recorte a 6-8 semanas. Sin resolver.
- Orden Fase 6 (Visión) → Fase 7 (NLP): se mantiene. Existe argumento para invertirlas.
- **Pendiente de ejecución (no de decisión):** subir los cinco documentos al Project, pegar las instrucciones nuevas, y borrar del conocimiento el currículo v2 y `Guia_Proyecto_Claude_y_Prompts.md` — tener dos versiones dando vueltas es la forma más segura de estudiar sobre el plan equivocado.
- "Proyecto de aprendizaje de domingo": vive en otro Project. **No está presupuestado en las 6 h de este plan** — si consume horas, revisar el impacto aquí.