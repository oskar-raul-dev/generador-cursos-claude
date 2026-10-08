# 07 — Respuestas

> El solucionario del bloque `14-talleres`: las preguntas de los seis talleres en tres capas (⏱️ 30 segundos, 🗣️ 2 minutos,
> 🔬 el detalle) y los ejercicios con su solución, **compilada y corrida** contra el estado del taller. El enunciado se copia
> literal. Resuélvelos antes de leer.
>
> **Vigencia:** 2026-10-04.
>
> **Versiones ejecutadas:** JDK 21.0.12 · Maven 3.10.0 (`maven:3.10.0-eclipse-temurin-21`) · JUnit 6.1.3 · H2 2.5.252 (2026-10-04).

**Salto rápido:** [01 — Caracterización](#01--caracterización) · [02 — Igualdad, hash e inmutabilidad](#02--igualdad-hash-e-inmutabilidad) · [03 — Partir el God Object](#03--partir-el-god-object) · [04 — Strategy y State](#04--strategy-y-state) · [05 — Chain y Decorator](#05--chain-y-decorator) · [06 — Eventos y bloqueo optimista](#06--eventos-y-bloqueo-optimista)

---

# 01 — Caracterización

**01 → 1. ¿Qué afirma una prueba de caracterización, y qué no afirma? 🟢**

⏱️ Afirma que el código sigue haciendo lo que hace hoy. No afirma que eso sea lo correcto.
🗣️ Es una red para cambiar código sin especificación: cualquier cambio de comportamiento, querido o no, pone una prueba
en rojo, y alguien tiene que decidir si lo acepta. Por eso puede afirmar un defecto, como el doble abono de 1 660 000.
🔬 El nombre es de Feathers (*Working Effectively with Legacy Code*, cap. 13). La diferencia con una prueba de
especificación no está en la forma —las dos son `assertEquals`— sino en de dónde sale el valor esperado: en la de
caracterización, de correr el código y copiar lo que dio.

**01 → 2. ¿Por qué el legado da `BUILD SUCCESS` aunque no tenga ninguna prueba? 🟢**

⏱️ Porque `mvn test` compila y corre las pruebas que encuentra; si no hay ninguna, no hay nada que pueda fallar.
🗣️ El éxito de la construcción solo dice que el código compila. Un pipeline que exige "verde" sobre un módulo sin pruebas
no está protegiendo nada, y por eso la ausencia de la línea `Tests run` es la primera señal al heredar un módulo.
🔬 Surefire tiene la opción `failIfNoTests` para que la falta de pruebas falle la construcción; no es la configuración por
defecto.

**01 → 3. ¿Qué diferencia hay entre un fallo y un error en el resumen de JUnit, y cuál dio la base compartida? 🟡**

⏱️ Un fallo es una aserción que no se cumple; un error es una excepción inesperada. La base compartida dio diecinueve
errores.
🗣️ Las pruebas no llegaron a afirmar nada: el `@BeforeEach` lanzó la violación de clave primaria al abrir otra vez
`CTA-0001`. Un error en la preparación dice "el escenario no se pudo montar", que es distinto de "el comportamiento cambió".
🔬 JUnit 6 informa los fallos como `AssertionFailedError` (de opentest4j) y el resto de excepciones como errores; Surefire
los cuenta por separado en `Failures` y `Errors`.

**01 → 4. ¿Por qué se marca un defecto congelado con un comentario y no se deja la prueba sin escribir? 🟡**

⏱️ Porque sin la prueba, el arreglo del defecto pasaría sin que nadie lo decidiera, y sin el comentario la prueba parecería
una especificación del error.
🗣️ La prueba hace visible el cambio cuando llegue; el comentario `DEFECTO CONGELADO` le dice a quien la vea en rojo que el
cambio es esperado y que debe cambiarla en el mismo paso. Las dos cosas juntas convierten un defecto conocido en una
decisión por tomar.
🔬 Dejar el comportamiento sin cubrir tiene otro riesgo: alguien puede depender del defecto (un conciliador que espera dos
movimientos) y la prueba es la que lo descubre.

**01 → 5. ¿Por qué las pruebas llaman a `GestorCuentas` y no a sus métodos privados ni a las tablas? 🟡**

⏱️ Porque congelan lo que otros observan, y lo que otros observan es la fachada pública.
🗣️ Los talleres siguientes van a cambiar todo lo de dentro: el dinero, las clases, las tablas. Una prueba atada a la tabla
`movimiento` o a un método privado se rompería con cada uno de esos cambios aunque el comportamiento fuera el mismo, y
dejaría de ser una red para volverse un estorbo.
🔬 La excepción es la auditoría: se cuentan filas de la tabla porque no hay otra forma de observarla desde fuera, y se cuenta
solo eso, no el formato.

**01 → 6. ¿Por qué hay que vaciar `Notificador.ENVIADOS` dos veces en el `@BeforeEach`? 🟠**

⏱️ La primera, por lo que dejó la prueba anterior; la segunda, por los correos de las tres aperturas.
🗣️ La lista es estática: sobrevive entre pruebas. Sin la segunda limpieza, cada prueba tendría que afirmar tres correos de
apertura antes de los suyos, y una prueba de transferencia acabaría dependiendo del texto de la apertura.
🔬 El estado estático es el que más se cuela entre pruebas: la base se recrea, el gestor se crea de nuevo, pero la lista
estática vive lo que vive la clase. `14/06` lo elimina inyectando el notificador.

**01 → 7. ¿Por qué el extracto viejo solo aparece cuando el saldo vuelve a un valor que ya tuvo? 🟠**

⏱️ Porque la caché busca con una `Cuenta` cuyo `hashCode` incluye el saldo: solo encuentra la entrada vieja si el saldo es el
mismo con que se guardó.
🗣️ Con cualquier otro saldo, el `get` falla y el extracto se recarga de la base, bien. La entrada vieja queda huérfana,
nadie la borra, y vuelve a aparecer el día en que el saldo regresa a ese valor: con un depósito y un retiro iguales en una
cuenta sin comisión.
🔬 Es la clave mutable de `01/02` con un agravante: `depositar` invalida después de mutar y `retirar` antes, así que
ninguna de las dos encuentra la entrada. Además de devolver datos viejos, la caché crece sin límite.

**01 → 8. ¿Por qué no se congelan las fechas de los movimientos, y qué haría falta para poder hacerlo? 🟠**

⏱️ Porque salen de `LocalDateTime.now()` dentro del gestor, y cambian en cada corrida. Para congelarlas haría falta
inyectar un reloj.
🗣️ Afirmar una fecha que depende del reloj da una prueba que falla a ratos, que es peor que no tenerla. La salida es un
`java.time.Clock` que el gestor reciba por constructor, fijo en las pruebas con `Clock.fixed`; el legado no lo permite sin
cambiarlo.
🔬 Cambiar el constructor para inyectar el reloj es una refactorización segura —*Parameterize Constructor*, en el catálogo
de Feathers—, pero ya es un cambio: se hace con la suite en verde, no antes de tenerla.

**01 → 9. El arreglo inocente puso una sola prueba en rojo. ¿Qué te dice eso, y qué haces con esa prueba? 🟠**

⏱️ Que el arreglo cambió exactamente el comportamiento que se quería y nada más. La prueba se cambia para afirmar el
comportamiento nuevo y se le quita la marca de defecto.
🗣️ La única prueba en rojo es la del doble abono, con su `DEFECTO CONGELADO`. Si hubiera caído también la del extracto o la
de auditoría, el arreglo estaría tocando algo más. El cambio de la prueba va en el mismo paso que el arreglo, para que el
historial muestre las dos cosas juntas.
🔬 Lo que **no** se hace es borrar la prueba: pasa de congelar el defecto a especificar el arreglo
(`depositar_elMismoPagoDosVecesLoAplicaUnaVez`), y desde ahí protege contra la regresión.

**01 → 10. Tu jefe ve 224 líneas de prueba y ningún defecto arreglado. Defiende el día de trabajo en dos frases. 🔴**

⏱️ "Hoy no arreglé el doble abono, pero ahora sé exactamente qué cambia cuando lo arregle: una prueba, y ninguna otra. Los
próximos cinco cambios del módulo van a salir con esa misma garantía, en segundos."
🗣️ El argumento es de riesgo, no de calidad: sin la suite, cada cambio en un módulo que mueve dinero se sube a ciegas, y el
costo de un error en producción —un abono doble, una transferencia a una cuenta cerrada— es mayor que un día. Además, la
suite ya encontró y documentó seis defectos.
🔬 Lo que preguntará después: si no era más rápido probar solo el depósito. Sí, para este ticket; la suite completa se
justifica porque el plan es tocar el módulo entero, y se dice así, con el plan en la mano.

**01 → E1. Congela qué pasa al desbloquear una cuenta que no estaba bloqueada: el estado que queda y los correos que salen. 🟢**

**El primer intento que sale.** Afirmar que lanza una excepción, porque "desbloquear algo que no está bloqueado debería
fallar". Es escribir lo que uno espera, no lo que el código hace.

**La solución.** Correr y copiar:

```java
@Test
void desbloquear_unaCuentaQueNoEstabaBloqueadaNoFallaNiAvisa() {
    gestor.desbloquear("CTA-0001");
    assertFalse(gestor.consultarCuenta("CTA-0001").isBloqueada());
    assertEquals(List.of(), Notificador.ENVIADOS);
}
```

- `desbloquear` pone el *flag* en `false` sin mirar cómo estaba, audita y no manda correo. La prueba pasa.

**Lo que cuesta.** Nada; es una prueba de tres líneas.

**Lo que preguntará después.** Si es un defecto. Probablemente no: una operación idempotente es razonable. Pero deja
auditada una acción que no hizo nada, y eso puede ser ruido para quien revisa la auditoría.

**01 → E2. Congela qué pasa al abrir una cuenta con un número que ya existe: qué excepción llega a quien llama, qué causa envuelve, y si el saldo de la cuenta original o los correos cambian. 🟡**

**El primer intento que sale.** `assertThrows(IllegalArgumentException.class, …)`, porque las demás validaciones de la
apertura lanzan esa. El legado no valida el duplicado: lo descubre la base.

**La solución.**

```java
@Test
void abrir_conUnNumeroRepetidoFallaConLaExcepcionDeH2Envuelta() {
    RuntimeException e = assertThrows(RuntimeException.class, () -> gestor.abrirCuenta(
            "CTA-0001", "Carmen Díaz Ortega", "carmen.diaz@example.com", "AHORROS", "COP", 0, false));
    assertInstanceOf(SQLException.class, e.getCause());
    assertEquals(1_500_000.0, gestor.consultarSaldo("CTA-0001"));
    assertEquals(List.of(), Notificador.ENVIADOS);
}
```

- La corrida imprimió `java.lang.RuntimeException / org.h2.jdbc.JdbcSQLIntegrityConstraintViolationException`: el
  `catch (SQLException e) { throw new RuntimeException(e); }` del gestor envuelve la violación de clave primaria.
- Se afirma `SQLException` como causa, no la clase de H2: la prueba no debería atarse al motor.
- La cuenta de Ana no cambia y no sale correo, porque el `INSERT` falla antes de notificar.

**Lo que cuesta.** La prueba congela un detalle feo —que el error llegue como una `RuntimeException` genérica—, y cuando
alguien añada la validación con su mensaje, tendrá que cambiarla.

**Lo que preguntará después.** Qué debería lanzar. Una excepción del dominio con un mensaje como "ya existe la cuenta
CTA-0001", lanzada por una validación previa o traducida desde la violación de clave; las dos opciones tienen su costo (una
consulta más, o depender del motor para el mensaje).

**01 → E3. Escribe las pruebas de borde de la comisión de nómina: un retiro de exactamente 2 000 000 y otro de 2 000 001. Congela las dos comisiones. 🟠**

**El primer intento que sale.** Un solo retiro grande, como el de la suite. Los defectos de un umbral viven en el borde: un
`>` que debía ser `>=`.

**La solución.**

```java
@Test
void retirar_deNominaCobraDesdeElPesoSiguienteADosMillones() {
    gestor.abrirCuenta("CTA-0004", "Ana Rojas Medina", "ana.rojas@example.com", "NOMINA", "COP", 5_000_000, false);
    gestor.retirar("CTA-0004", 2_000_000);
    gestor.retirar("CTA-0004", 2_000_001);
    List<Movimiento> movs = gestor.extracto("CTA-0004");
    assertEquals(0.0, movs.get(0).getComision());
    assertEquals(8_000.004, movs.get(1).getComision(), 1e-9);
}
```

La corrida imprimió:

```text
[RETIRO 2000000.0, RETIRO 2000001.0 (comisión 8000.004)] saldo 991998.996
```

- Con exactamente 2 000 000 no hay comisión: el código usa `monto > 2_000_000`. Un peso más y cobra el 0,4 % **del monto
  entero**, con tres decimales: otro caso del defecto del `double`.

**Lo que cuesta.** Dos pruebas más por cada umbral del módulo; es lo que cuesta saber dónde está el borde.

**Lo que preguntará después.** Si el 0,4 % debería cobrarse sobre todo el monto o solo sobre lo que pasa de 2 000 000. Es
una pregunta de negocio: la prueba congela la respuesta actual para que nadie la cambie sin preguntarla.

**01 → E4. ¿Se reproduce el extracto viejo si el saldo de Ana vuelve a su valor con dos transferencias, de ida y vuelta, en lugar de un depósito y un retiro? Escribe la prueba que lo demuestra y explica la diferencia con la traza del §6. 🔴**

**El primer intento que sale.** Suponer que sí, porque "el saldo vuelve al mismo valor", y escribir la prueba con
`assertEquals(0, …)`. Falla.

**La solución.** No se reproduce, y la prueba lo congela así:

```java
@Test
void extracto_conDosTransferenciasDeIdaYVueltaNoQuedaViejo() {
    gestor.extracto("CTA-0001");                          // clave con saldo 1500000
    gestor.transferir("CTA-0001", "CTA-0003", 10_000);
    gestor.transferir("CTA-0003", "CTA-0001", 10_000);   // Ana vuelve a 1500000
    assertEquals(2, gestor.extracto("CTA-0001").size());
}
```

La corrida imprimió `[TRANSF_ENVIADA 10000.0 ref CTA-0003, TRANSF_RECIBIDA 10000.0 ref CTA-0003]`.

La traza:

```text
extracto()        put(Ana@1500000, [])
transferir 1→3    Ana@1500000 → resta → Ana@1490000 → remove(Ana@1490000): nada
transferir 3→1    Ana es destino: Ana@1490000 → suma → Ana@1500000 → remove(Ana@1500000): ¡la encuentra!
extracto()        get(Ana@1500000) → no hay → recarga: dos movimientos
```

- `transferir` invalida **después** de mutar, como `depositar`. En la segunda transferencia, el saldo de Ana ya mutado es
  justo el de la clave vieja, y el `remove` la borra por casualidad.
- Con depósito y retiro no pasa porque `retirar` invalida **antes** de mutar: busca con 1 600 000, no con 1 500 000.

**Lo que cuesta.** Entender una traza de cuatro pasos para una prueba de cinco líneas. Es el precio de caracterizar un
defecto que depende del orden de las operaciones.

**Lo que preguntará después.** Qué enseña el ejercicio: que un defecto de clave mutable no tiene una regla simple de
reproducción, y que "lo probé y no falló" no prueba nada. La salida no es más pruebas, es quitar la clave mutable
(`14/02`).

---

# 02 — Igualdad, hash e inmutabilidad

**02 → 1. ¿Qué regla del contrato de `hashCode` rompe el `Movimiento` del legado? 🟢**

⏱️ La que dice que dos objetos iguales según `equals` tienen que dar el mismo `hashCode`.
🗣️ `Movimiento` redefinía `equals` y heredaba el `hashCode` de `Object`, que depende de la identidad. Dos depósitos iguales
caían en cubetas distintas del `HashSet`, y `contains` ni siquiera llegaba a llamar a `equals`.
🔬 Es el ítem 11 de *Effective Java*. El compilador no lo detecta; algunos analizadores estáticos sí, y un `record` lo hace
imposible por construcción.

**02 → 2. ¿Por qué `Dinero` normaliza la escala en el constructor compacto? 🟢**

⏱️ Porque el `equals` del `record` delega en `BigDecimal.equals`, que compara también la escala: sin normalizar, 10,0 y
10,00 serían dineros distintos.
🗣️ Fijar dos decimales en el constructor hace que todo `Dinero` tenga la misma representación, y entonces la igualdad y el
hash generados por el `record` son correctos. De paso, es el único sitio donde se redondea.
🔬 La alternativa sería escribir `equals` y `hashCode` a mano con `compareTo` y `stripTrailingZeros`; normalizar es más
simple y deja además un `toString` uniforme.

**02 → 3. ¿Qué diferencia hay entre `new BigDecimal(0.1)` y `BigDecimal.valueOf(0.1)`? 🟡**

⏱️ El constructor recibe el `double` exacto, con su error binario; `valueOf` parte de su representación decimal corta,
`"0.1"`.
🗣️ `new BigDecimal(0.1)` vale 0,1000000000000000055511151231257827…, porque eso es lo que el `double` guarda de verdad.
`valueOf` usa `Double.toString`, que da el decimal más corto que identifica al `double`. Por eso `Dinero.de(double)` usa
`valueOf`, y por eso la frontera con `double` es aceptable mientras sea solo frontera.
🔬 Lo mejor sigue siendo no tener `double`: `Dinero.de(String)` es la forma que usan las pruebas y la que debería usar la
fachada cuando sus llamadores puedan cambiar.

**02 → 4. ¿Por qué `Cuenta` y `Dinero` tienen igualdades de tipos distintos? 🟡**

⏱️ `Cuenta` es una entidad: es la misma mientras tenga el mismo número. `Dinero` es un objeto de valor: es igual a otro si
sus campos son iguales.
🗣️ El saldo de una cuenta cambia y la cuenta sigue siendo la misma; dos billetes de 10 000 pesos son intercambiables. La
igualdad de cada uno responde esa diferencia, y por eso `Cuenta` compara solo `numero` y `Dinero` compara monto y moneda.
🔬 Es la distinción de `02/06` §2. El error del legado era tratar a la entidad como un valor (todos los campos en el
`hashCode`), que es lo que generan los IDE por defecto.

**02 → 5. ¿Por qué el `record` `Movimiento` no sirve para detectar el depósito reintentado? 🟡**

⏱️ Porque su igualdad incluye la fecha y la comisión, y dos intentos de la pasarela tienen fechas distintas.
🗣️ Un `record` compara todos sus componentes. "El mismo registro" y "el mismo pago" son preguntas distintas: la primera
mira todo; la segunda, solo cuenta, monto y referencia. Por eso el pago tiene su propio tipo, `ClaveDeposito`.
🔬 La tentación sería escribir un `equals` a mano en el `record` que ignore la fecha. Funciona, pero esconde dentro del
registro una regla de negocio que merece nombre.

**02 → 6. ¿Qué arregla el defecto del extracto: la igualdad de `Cuenta` o la clave `String`? ¿Por qué se hicieron las dos? 🟠**

⏱️ Cualquiera de las dos lo arregla sola. Se hicieron las dos porque protegen cosas distintas.
🗣️ La clave `String` deja la caché al margen de cómo se defina la igualdad de la entidad. La igualdad por número
protege a cualquier otro `Map` o `Set` de cuentas que se escriba mañana. Con solo la clave, el próximo mapa de cuentas
volvería a tener el defecto.
🔬 Con solo la igualdad por número, la caché funcionaría, pero dependería de que nadie vuelva a meter el saldo en el
`hashCode`. Una clave de un tipo inmutable como `String` no depende de nadie.

**02 → 7. Cuatro pruebas fallaron por el formato del dinero. ¿Qué preguntas haces antes de aceptarlo? 🟠**

⏱️ Quién lee esos textos y si alguien los procesa. Si solo los lee una persona, el cambio es una mejora; si los parsea un
sistema, es una ruptura.
🗣️ Los correos los lee Ana; el `toString` del extracto lo puede leer un reporte o un proceso de conciliación. Se pregunta
a quien consume cada salida, y si alguno parsea, el cambio se coordina o se mantiene el formato viejo en esa salida.
🔬 Lo que **no** se hace es actualizar las cuatro pruebas sin mirar: eso convierte la red en un trámite. La regla de §13.2 de
la guía pide nombrar cada prueba cambiada, justamente para que la decisión quede escrita.

**02 → 8. ¿Por qué `HALF_EVEN` y no `HALF_UP` para las comisiones? 🟠**

⏱️ Porque `HALF_UP` sube siempre los cincos y, sobre millones de redondeos, cobra de más; `HALF_EVEN` los reparte entre
arriba y abajo.
🗣️ Con `HALF_EVEN`, 0,025 baja a 0,02 y 0,035 sube a 0,04: en promedio el error se cancela. Es el redondeo bancario, y el que
recomienda Fowler para *Money*.
🔬 La regla de redondeo a veces la fija la norma (un regulador, un contrato). Si la norma dice `HALF_UP`, se usa esa: lo
importante es que viva en un solo sitio, el constructor de `Dinero`.

**02 → 9. ¿Por qué el paso 2 no se pudo partir en pasos más pequeños, y qué lo habría permitido? 🟠**

⏱️ Porque el dinero vive en cada método del God Object: cambiar su tipo obliga a tocarlos todos a la vez. Con las
responsabilidades separadas, habría sido un cambio por clase.
🗣️ Es el costo de hacer `14/02` antes que `14/03`. Se eligió este orden porque los tres defectos de igualdad eran los más
urgentes y porque partir el God Object es más seguro con el dinero ya bien tipado. Un orden alternativo, partir primero, da
pasos más pequeños aquí y más grandes allá.
🔬 Una técnica para partirlo igual: introducir `Dinero` solo en `Cuenta` con un *getter* puente que devuelva `double`, migrar
método por método y quitar el puente al final. Más pasos, cada uno en verde.

**02 → 10. Un compañero propone resolver el doble abono con un `UNIQUE (numero, referencia)` en la tabla `movimiento`, sin tocar las clases. Evalúa la propuesta. 🔴**

⏱️ La restricción es buena como defensa en profundidad, pero sola no basta: el gestor actualiza el saldo **antes** de
insertar el movimiento, en autocommit, así que el segundo depósito suma el saldo y después falla.
🗣️ Lo probé sobre `estados/02` con un gestor nuevo, que no tiene el conjunto `recientes` en memoria —como otro nodo o el
mismo después de reiniciar—. El segundo depósito lanzó la violación de la restricción, y el saldo quedó en 1 660 000,00:
abonado dos veces y con error. Para que la restricción proteja, el `INSERT` y el `UPDATE` tienen que ir en una transacción,
o el `INSERT` primero.
🔬 La prueba descubre además que la idempotencia en memoria de `14/02` solo vale para un proceso que no se reinicia. Y la
restricción, en **esta** tabla, tiene una trampa: la transferencia guarda en `referencia` la cuenta de la otra punta, así que
dos transferencias iguales entre las mismas cuentas chocarían. La forma durable es una tabla propia de pagos aplicados,
escrita en la misma transacción que el depósito: es el ejercicio E4 de `14/06`, que corre las dos versiones.

**02 → E1. Escribe la prueba que demuestra que `Dinero` es inmutable: después de `mas`, el original no cambió. 🟢**

**El primer intento que sale.** Afirmar solo el resultado de `mas`. Eso prueba la suma, no la inmutabilidad: hay que mirar
el original después de la operación.

**La solución.**

```java
@Test
void masNoCambiaElOriginal() {
    Dinero saldo = Dinero.de("1500000.00", Moneda.COP);
    Dinero nuevo = saldo.mas(Dinero.de("80000", Moneda.COP));
    assertEquals(Dinero.de("1500000.00", Moneda.COP), saldo);
    assertEquals(Dinero.de("1580000.00", Moneda.COP), nuevo);
    assertNotSame(saldo, nuevo);
}
```

- `assertNotSame` comprueba que `mas` devolvió **otro** objeto. La prueba pasa contra `estados/02`.

**Lo que cuesta.** Nada; pero la prueba solo cubre `mas`. La garantía de fondo la da el `record`: sus componentes son
`final`, y `BigDecimal` y el `enum` son inmutables.

**Lo que preguntará después.** Si un `record` siempre es inmutable. No: si un componente fuera una lista mutable, el
`record` también lo sería (`01/03` §5).

**02 → E2. Quita la normalización de escala del constructor compacto de `Dinero`, corre `DineroTest` y explica qué pruebas caen y por qué. Después, devuélvela. 🟡**

**El primer intento que sale.** Esperar que caiga solo la prueba de igualdad. Caen tres.

**La solución.** La corrida, sin la línea `monto = monto.setScale(2, RoundingMode.HALF_EVEN);`:

```text
[ERROR] Tests run: 5, Failures: 3, Errors: 0, Skipped: 0 <<< FAILURE! -- in banco.DineroTest
[ERROR] banco.DineroTest.elPorcentajeSeRedondeaAlCentavoALaPar <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <10000.00 COP> but was: <10000.00040 COP>
[ERROR] banco.DineroTest.desdeDoubleUsaLaRepresentacionCorta <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <0.10 COP> but was: <0.1 COP>
[ERROR] banco.DineroTest.diezYDiezConCeroSonElMismoDinero <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <10.0 COP> but was: <10.00 COP>
```

- **La igualdad:** 10,0 y 10,00 dejan de ser iguales, porque `BigDecimal.equals` compara la escala.
- **El redondeo:** `por("0.004")` devuelve 10 000,00040, con cinco decimales; nadie redondea. La normalización era también
  el único sitio de redondeo.
- **El formato:** `toString` imprime `0.1` en lugar de `0.10`. Quien compare textos —un correo— ve el cambio.

**Lo que cuesta.** Entender que una línea hacía tres trabajos. Es la razón para tenerla en el constructor y no repartida.

**Lo que preguntará después.** Por qué el mensaje de la igualdad dice `expected: <10.0 COP> but was: <10.00 COP>` si los dos
"valen lo mismo": porque `assertEquals` usa `equals`, y el `toString` muestra la escala que lo rompe.

**02 → E3. La pasarela reintenta un depósito con la misma referencia pero otro monto (un error de su lado). Congela qué hace hoy `estados/02` y di si es lo que el negocio debería querer. 🟠**

**El primer intento que sale.** Suponer que se rechaza, porque "la referencia ya se usó".

**La solución.**

```java
@Test
void mismaReferenciaOtroMontoSeAplica() {
    BaseDatos.crearEsquema();
    GestorCuentas gestor = new GestorCuentas();
    gestor.abrirCuenta("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", "AHORROS", "COP", 1_500_000.00, false);
    gestor.depositar("CTA-0001", 80_000, "PSE-7781");
    gestor.depositar("CTA-0001", 8_000, "PSE-7781");
    assertEquals(Dinero.de("1588000", Moneda.COP), gestor.saldo("CTA-0001"));
}
```

- Se aplica: `ClaveDeposito` incluye el monto, y con otro monto la clave es otra. Es el comportamiento que el legado
  **intentaba** tener, y el taller lo conservó.

**Lo que cuesta.** Nada en código; en negocio, un abono que probablemente no debería existir.

**Lo que preguntará después.** Qué querría el negocio. Lo más común es que la referencia identifique el pago sola, y que la
misma referencia con otro monto se **rechace y se alerte**, porque es un error de la pasarela o un intento de fraude. Eso
cambia `ClaveDeposito` a `(numeroCuenta, referencia)` y añade una regla: es un cambio de comportamiento, y va en su propio
paso con su prueba.

**02 → E4. Escribe `Dinero.repartir(int partes)`, que reparta un monto en partes iguales sin perder ni crear un centavo: 100,00 COP entre tres da 33,34, 33,33 y 33,33. Con su prueba. 🔴**

**El primer intento que sale.** `monto.divide(BigDecimal.valueOf(partes), 2, HALF_EVEN)` para cada parte: da 33,33 tres
veces, y se pierde un centavo.

**La solución.** Trabajar en centavos y repartir el resto uno a uno, como el `repartir` de *Money* en `08/05` §3:

```java
// reparte en partes iguales; los centavos que sobran van, uno a uno, a las primeras partes
public List<Dinero> repartir(int partes) {
    if (partes <= 0) throw new IllegalArgumentException("partes debe ser positivo");
    long centavos = monto.movePointRight(2).longValueExact();
    long base = Math.floorDiv(centavos, partes);
    long resto = centavos - base * partes;
    List<Dinero> resultado = new ArrayList<>();
    for (int i = 0; i < partes; i++) {
        long c = base + (i < resto ? 1 : 0);
        resultado.add(new Dinero(BigDecimal.valueOf(c, 2), moneda));
    }
    return resultado;
}
```

```java
@Test
void repartirNoPierdeNiCreaCentavos() {
    List<Dinero> partes = Dinero.de("100.00", Moneda.COP).repartir(3);
    assertEquals(List.of(Dinero.de("33.34", Moneda.COP), Dinero.de("33.33", Moneda.COP), Dinero.de("33.33", Moneda.COP)), partes);
    Dinero suma = partes.stream().reduce(Dinero.cero(Moneda.COP), Dinero::mas);
    assertEquals(Dinero.de("100.00", Moneda.COP), suma);
    assertEquals(List.of(Dinero.de("0.01", Moneda.COP), Dinero.cero(Moneda.COP)), Dinero.de("0.01", Moneda.COP).repartir(2));
}
```

- `movePointRight(2)` pasa a centavos sin redondear, y `longValueExact` lanza si quedara fracción, que la escala 2 impide.
- La prueba no solo mira las partes: comprueba que **suman** el total, que es la propiedad que importa. El caso de un
  centavo entre dos partes es el borde.

**Lo que cuesta.** Una decisión de negocio escondida: quién recibe el centavo que sobra. Aquí, las primeras partes.

**Lo que preguntará después.** Cómo se reparte por porcentajes (70/30 entre titulares): con pesos en lugar de partes iguales,
la versión `repartir(int... proporciones)` de `08/05`. Y qué pasa con montos negativos: `floorDiv` redondea hacia menos
infinito, así que el resto sigue siendo positivo y la suma cuadra.

---

# 03 — Partir el God Object

**03 → 1. ¿Qué es *Shotgun Surgery*, y cómo se midió en `estados/02`? 🟢**

⏱️ Un cambio pequeño que obliga a muchas ediciones pequeñas en sitios distintos. Se midió contando con `grep` las copias de
lo que cambia junto.
🗣️ En `estados/02`, el `SELECT` de cuenta y su mapeo aparecían cinco veces, `new Notificador()` seis y `BaseDatos.abrir()`
diez. Una columna nueva eran cinco mapeos que editar; en `14/02`, `getDouble("saldo")` se cambió en cinco sitios.
🔬 Es el *smell* opuesto a *Divergent Change* (una clase que cambia por muchos motivos); el God Object tiene los dos a la
vez. Contar es una métrica tosca pero honesta: dice cuántos sitios hay que recordar.

**03 → 2. ¿Qué es una raíz de composición, y dónde está en `estados/03`? 🟢**

⏱️ El único sitio donde se crean las piezas y se conectan entre sí. En `estados/03`, el constructor sin argumentos de
`GestorCuentas`.
🗣️ Fuera de ahí, ninguna clase hace `new` de sus dependencias: las recibe por constructor. Por eso un `Notificador` falso se
puede pasar en una prueba sin tocar el servicio.
🔬 En una aplicación con Spring, la raíz de composición es el contenedor (`04/06`). Aquí es una línea de código, y basta.

**03 → 3. ¿Por qué el taller exige que ninguna prueba cambie? 🟡**

⏱️ Porque una refactorización, por definición, no cambia el comportamiento. Si una prueba de caracterización hay que
tocarla, el paso cambió algo.
🗣️ Es la diferencia con `14/02`, donde se cambiaron siete pruebas porque se quería cambiar el comportamiento. Aquí, las 25
pruebas pasaron sin una línea cambiada, y esa es la evidencia de que el paso fue seguro.
🔬 La excepción admitida sería una prueba que mira detalles internos —una que leyera un campo privado del gestor—; la suite
de `14/01` se escribió sobre la fachada justo para que eso no pasara.

**03 → 4. ¿Qué diferencia hay entre partir una clase por tamaño y partirla por motivos de cambio? 🟡**

⏱️ Por tamaño se corta donde hay muchas líneas; por motivos de cambio, donde cambian por razones distintas. Lo segundo
deja piezas que cambian solas.
🗣️ El gestor se partió en ciclo de vida y movimientos porque los piden personas distintas (regulación y operaciones, contra
tarifas y productos), no porque fueran mitades. Un corte por tamaño podría haber dejado depositar y abrir juntos y
retirar aparte.
🔬 Es la lectura de SRP de `03/02`: una razón para cambiar es una persona o un rol que pide el cambio.

**03 → 5. ¿Por qué `Cuenta` tiene `recibirTransferencia` en lugar de usar `depositar` en la transferencia? 🟡**

⏱️ Porque `depositar` rechaza la cuenta cerrada, y usarlo en la transferencia corregiría un defecto congelado: el taller
promete no cambiar comportamiento.
🗣️ `transferir_aUnaCuentaCerradaSeAcepta` habría pasado a rojo. Corregirlo es correcto, pero es un cambio de comportamiento
y va en su propio paso, en `14/04`. El método lleva un comentario que dice cuándo se va.
🔬 Es el costo de no mezclar refactorización y corrección: código feo a propósito durante un taller. La alternativa, mezclar,
hace que una prueba en rojo no diga si el paso se equivocó o acertó.

**03 → 6. ¿Por qué el orden de las validaciones de `cerrar()` se conservó igual? 🟠**

⏱️ Porque cuando fallan dos a la vez, el orden decide qué mensaje ve quien llama, y ese mensaje es comportamiento.
🗣️ Una cuenta bloqueada y con saldo da "una cuenta bloqueada no se puede cerrar", no "para cerrar, el saldo debe ser
cero". Invertir el orden cambia la respuesta sin que nadie lo haya decidido.
🔬 La suite de `14/01` no cubre ese caso combinado: el orden se conservó por disciplina, no porque una prueba lo exigiera.
Es un hueco de la caracterización que vale la pena cerrar con una prueba.

**03 → 7. ¿Por qué no se movieron a `Cuenta` la validación de bloqueada y el tope de los menores? 🟠**

⏱️ Porque los próximos talleres las van a rehacer: la de bloqueada pasa a ser del State en `14/04`, y el tope a una cadena de
reglas en `14/05`. Moverlas ahora sería moverlas dos veces.
🗣️ Refactorizar hacia un destino incluye saber dónde parar. Aquí la tensión que se resolvía era el God Object, no las
reglas de las operaciones.
🔬 El tope de los menores, además, no depende solo de la cuenta: en `14/05` se aplica también a la transferencia, que
involucra dos cuentas.

**03 → 8. El total de líneas casi no cambió. ¿Qué se ganó, medido? 🟠**

⏱️ Que lo que cambia junto está junto: una copia del mapeo en lugar de cinco, un `new Notificador()` en lugar de seis, cero
conexiones abiertas en la lógica en lugar de diez, y la clase más grande pasó de 403 a 133 líneas.
🗣️ El costo de un cambio se mide en sitios a tocar, no en líneas totales. El ejercicio E1 lo mide: añadir una columna toca
ahora un mapeo y un `INSERT`, en lugar de cinco mapeos.
🔬 Lo que **no** se ganó todavía es probabilidad de error por cambio en las reglas: los dos `switch` siguen ahí, y es lo que
ataca `14/04`.

**03 → 9. ¿Cuándo se borra la fachada `GestorCuentas`, y qué hay que hacer antes? 🟠**

⏱️ Cuando ningún llamador la use. Antes, hay que migrar a cada uno a los servicios, y migrar las pruebas de caracterización.
🗣️ La fachada conserva la API vieja, con su `double`. Los llamadores nuevos usan los servicios; los viejos se migran de a
uno. Cuando el último deja de usarla, se borra.
🔬 Un `@Deprecated` en la fachada ayuda a que el compilador señale a los que quedan. Si nunca se migran, la fachada se queda
como la API pública estable del módulo, que también es un uso legítimo de Facade (`05/04`).

**03 → 10. Un compañero propone partir el gestor en una clase por operación: `Depositar`, `Retirar`, `Transferir`. Compárala con los dos servicios del taller. 🔴**

⏱️ Es una partición válida —una por caso de uso— que da clases más pequeñas y más autónomas, a costa de repartir lo
que las operaciones comparten: la caché de extractos, los depósitos recientes y los dos `switch` de comisiones.
🗣️ Con una clase por operación, `Depositar` y `Retirar` necesitan invalidar la misma caché, así que la caché tiene que salir
a una pieza propia, compartida. Los dos servicios la mantienen como estado privado de `ServicioMovimientos`. A cambio, una
clase por operación hace evidente qué dependencias usa cada caso: `Retirar` no necesita los depósitos recientes.
🔬 La elección depende de cuánto comparten los casos de uso. Aquí comparten bastante, y dos servicios son el corte más
barato; en un sistema con muchos casos de uso autónomos (estilo *command handler*), una clase por operación escala
mejor. Lo que preguntará después: cómo se prueba cada opción, y cuál de las dos deja más fácil el `14/05`.

**03 → E1. Añade la columna `sucursal` a la tabla `cuenta` (con un valor por defecto) y a `Cuenta`. Cuenta cuántos archivos tocaste y compáralo con los que habría que tocar en `estados/02`. 🟢**

**El primer intento que sale.** Añadir el campo solo a la tabla y a `Cuenta`, y olvidar el `INSERT`.

**La solución.** Cuatro archivos:

- `BaseDatos.java`: `sucursal VARCHAR(20) DEFAULT 'PRINCIPAL' NOT NULL`.
- `Cuenta.java`: el campo, el parámetro del constructor y su *getter*.
- `RepositorioCuentas.java`: la columna en `COLUMNAS`, una línea del mapeo y un parámetro del `INSERT`.
- `ServicioCuentas.java`: `"PRINCIPAL"` al construir la cuenta en `abrir`.

```java
@Test
void laCuentaNuevaQuedaEnLaSucursalPrincipal() {
    GestorCuentas gestor = new GestorCuentas();
    gestor.abrirCuenta("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", "AHORROS", "COP", 1_500_000.00, false);
    assertEquals("PRINCIPAL", gestor.consultarCuenta("CTA-0001").getSucursal());
}
```

En `estados/02` eran tres archivos, pero ocho sitios dentro de ellos: el esquema, `Cuenta`, los cinco mapeos de
`GestorCuentas` y su `INSERT`.

**Lo que cuesta.** Un archivo más que antes. El número de archivos no es la métrica; lo es el número de sitios que hay que
recordar, y bajó de ocho a cinco, todos con el compilador avisando (el constructor de `Cuenta` cambió de firma).

**Lo que preguntará después.** Por qué el compilador ayuda ahora y antes no: con *setters*, olvidar un `setSucursal` en uno de
los cinco mapeos compilaba y dejaba un `null`; con un constructor, olvidar el argumento no compila.

**03 → E2. Escribe una prueba que use el segundo constructor de `GestorCuentas` con un `Notificador` propio que solo cuente los correos, sin la lista estática. 🟡**

**El primer intento que sale.** Vaciar `Notificador.ENVIADOS` y contarla. Funciona, pero sigue dependiendo del estado
estático que comparten todas las pruebas.

**La solución.**

```java
static class NotificadorQueCuenta extends Notificador {
    int enviados;
    @Override public void enviar(String email, String mensaje) { enviados++; }
}

@Test
void elGestorAceptaUnNotificadorPropio() {
    NotificadorQueCuenta notificador = new NotificadorQueCuenta();
    Notificador.ENVIADOS.clear();
    GestorCuentas gestor = new GestorCuentas(new RepositorioCuentas(), new RepositorioMovimientos(), new Auditoria(), notificador);
    gestor.abrirCuenta("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", "AHORROS", "COP", 1_500_000.00, false);
    gestor.depositar("CTA-0001", 80_000, null);
    assertEquals(2, notificador.enviados);
    assertTrue(Notificador.ENVIADOS.isEmpty());
}
```

- La apertura y el depósito avisan: dos correos, y la lista estática queda vacía porque el `enviar` sobrescrito no la toca.

**Lo que cuesta.** Heredar de una clase concreta para fingirla. Funciona porque `Notificador` no es `final`; lo limpio es
una interfaz, y es lo que hace `14/06`.

**Lo que preguntará después.** Por qué no usar Mockito: se podría, y es lo habitual. El ejercicio muestra que la inyección por
constructor ya basta para probar, con o sin librería.

**03 → E3. Inyecta un `java.time.Clock` en `ServicioMovimientos` y escribe la prueba que fija la fecha de un depósito. 🟠**

**El primer intento que sale.** Cambiar el constructor existente y romper el de `GestorCuentas`. Se añade un constructor
nuevo y el viejo delega con `Clock.systemDefaultZone()`.

**La solución.** Un campo `reloj`, un constructor más, y `LocalDateTime.now(reloj)` en los tres sitios donde había
`LocalDateTime.now()`:

```java
@Test
void elDepositoLlevaLaFechaDelReloj() {
    Clock fijo = Clock.fixed(Instant.parse("2026-10-04T15:00:00Z"), ZoneId.of("America/Bogota"));
    RepositorioCuentas cuentas = new RepositorioCuentas();
    new ServicioCuentas(cuentas, new Auditoria(), new Notificador())
            .abrir("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", "AHORROS", "COP", 1_500_000.00, false);
    ServicioMovimientos servicio = new ServicioMovimientos(cuentas, new RepositorioMovimientos(), new Auditoria(),
            new Notificador(), fijo);
    servicio.depositar("CTA-0001", 80_000, "PSE-7781");
    assertEquals(LocalDateTime.of(2026, 10, 4, 10, 0), servicio.extracto("CTA-0001").get(0).fecha());
}
```

- Las 15:00 UTC son las 10:00 en Bogotá (UTC−5): la prueba fija también la zona, que es la otra mitad del problema.

**Lo que cuesta.** Un parámetro más en el constructor. Es la pregunta 8 de `14/01`: lo que no se podía congelar ahora se
puede.

**Lo que preguntará después.** Si la auditoría también debería usar el reloj: sí, por la misma razón; tiene su propio
`LocalDateTime.now()`.

**03 → E4. Al partir el gestor, `transferir` dejó de usar una sola conexión para los dos `UPDATE` y pasó a abrir una por operación. ¿Cambió el comportamiento? Escribe la prueba que lo responda, o explica por qué no se puede escribir. 🔴**

**El primer intento que sale.** Decir que sí, porque "una conexión era una transacción". No lo era: el legado trabajaba en
*autocommit*, y cada `UPDATE` se confirmaba solo.

**La solución.** No cambió: antes y después, si el segundo `UPDATE` falla, el primero ya está confirmado. En `estados/02` no
se podía probar, porque no había dónde provocar el fallo; en `estados/03`, sí, con un repositorio que falla al segundo
`guardar`:

```java
static class RepositorioQueFallaAlSegundoGuardar extends RepositorioCuentas {
    int guardados;
    @Override public void guardar(Cuenta c) {
        if (++guardados == 2) throw new RuntimeException("se cayó la conexión");
        super.guardar(c);
    }
}

@Test
void siFallaElSegundoUpdateElDineroSeVa() {
    RepositorioQueFallaAlSegundoGuardar cuentas = new RepositorioQueFallaAlSegundoGuardar();
    GestorCuentas gestor = new GestorCuentas(cuentas, new RepositorioMovimientos(), new Auditoria(), new Notificador());
    gestor.abrirCuenta("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", "AHORROS", "COP", 1_500_000.00, false);
    gestor.abrirCuenta("CTA-0003", "Luis Rojas Paz", "ana.rojas@example.com", "AHORROS", "COP", 0, true);
    assertThrows(RuntimeException.class, () -> gestor.transferir("CTA-0001", "CTA-0003", 250_000));
    assertEquals(Dinero.de("1250000", Moneda.COP), gestor.saldo("CTA-0001"));
    assertEquals(Dinero.de("0", Moneda.COP), gestor.saldo("CTA-0003"));
}
```

La corrida imprimió `1250000.00 COP / 0.00 COP`: Ana perdió 250 000 y Luis no los recibió.

**Lo que cuesta.** Admitir que la refactorización no empeoró nada, pero que el defecto existía desde el legado y ninguna
prueba lo veía. Es un séptimo defecto que la caracterización no congeló.

**Lo que preguntará después.** Cómo se arregla: con una transacción que abarque los dos `UPDATE` y los `INSERT`, que es parte
de `14/06`. Y por qué la inyección del repositorio fue lo que permitió escribir la prueba: sin un sitio donde provocar el
fallo, el defecto solo se ve en producción.

---

# 04 — Strategy y State

**04 → 1. ¿Qué *smell* son los dos `switch` de comisiones, y qué refactorización lo quita? 🟢**

⏱️ *Repeated Switches*: el mismo `switch` por tipo en dos sitios. Lo quita *Replace Conditional with Polymorphism*, y en su
forma de patrón, *Replace Conditional Logic with Strategy*.
🗣️ Cada tipo nuevo obligaba a editar los dos `switch`, y el `default` solo avisaba al ejecutar. Con la política en el tipo,
un tipo nuevo es una constante del `enum` que no compila sin su política.
🔬 En la 1.ª ed. de *Refactoring* el *smell* se llamaba *Switch Statements*; la 2.ª lo restringió a los repetidos (`12/01`).
Un solo `switch` que no se repite puede quedarse.

**04 → 2. ¿Por qué dos *flags* admiten un estado que el negocio no tiene? 🟢**

⏱️ Porque dos booleanos dan cuatro combinaciones y el negocio tiene tres estados: abierta, bloqueada y cerrada. La cuarta,
cerrada y bloqueada, existe porque nada la impide.
🗣️ El legado no tenía un sitio que dijera qué combinaciones valen; cada operación cambiaba un *flag* sin mirar el otro.
`bloquear` sobre una cerrada dejó los dos en `true`, y `14/01` lo congeló.
🔬 Es la idea de "hacer imposibles los estados ilegales": con un tipo de tres valores, la cuarta combinación no se puede
representar. Un `enum` lo consigue en Java; en lenguajes con tipos suma, un tipo con tres variantes.

**04 → 3. ¿Por qué `PoliticaComision` tiene dos métodos y no uno? 🟡**

⏱️ Porque el retiro y la transferencia de una corriente en pesos cobran distinto, 1 500 y 1 000, y la caracterización lo
congeló como comportamiento, no como defecto.
🗣️ Unificar los dos `switch` en uno habría cambiado el cobro de las transferencias sin que nadie lo decidiera, y la prueba
`transferir_desdeUnaCorrienteEnPesosCobra1000` se habría puesto en rojo. El comentario "no es un defecto conocido" que
`14/01` puso en esa prueba es el que evitó el error.
🔬 Es la pregunta de `12/05`: ¿es duplicación o un parecido casual? Aquí, parecido: dos reglas de negocio con la misma forma.
Si el negocio confirma que deberían ser iguales, se cambia en un paso aparte.

**04 → 4. ¿Qué diferencia hay entre `TipoCuenta` con su política y un `enum` con un `switch` afuera? 🟡**

⏱️ En el primero, cada constante lleva su comportamiento y no se puede crear una sin él; en el segundo, el comportamiento
vive en otro sitio y un tipo nuevo puede caer en el `default`.
🗣️ Con `switch` afuera, añadir `PREMIUM` compila aunque nadie haya decidido su comisión; con la política en el constructor
del `enum`, no compila hasta que se la dé. El conocimiento queda junto al tipo.
🔬 Una **expresión** `switch` sobre un `enum`, sin `default`, también obliga a cubrir todas las constantes: el compilador
avisa. Es una alternativa válida cuando el comportamiento no pertenece al tipo, como un reporte.

**04 → 5. ¿Por qué los métodos de `EstadoCuenta` son abstractos y no tienen comportamiento por defecto? 🟡**

⏱️ Para que cada estado tenga que responder a cada operación, y el compilador no deje olvidar ninguna.
🗣️ Con un comportamiento por defecto ("lanzar"), un estado nuevo hereda respuestas que nadie pensó. Con métodos abstractos,
añadir `EMBARGADA` obliga a escribir sus seis respuestas, y añadir una operación obliga a decidirla en los tres estados. El
precio son métodos vacíos en `ABIERTA`.
🔬 `06/06` usa la otra forma, con valores por defecto en la clase: menos líneas, y válida cuando casi todos los estados
comparten la respuesta. Las dos son State; difieren en qué error se prefiere evitar.

**04 → 6. ¿Por qué la apertura no usa `TipoCuenta.valueOf` para validar el tipo? 🟠**

⏱️ Porque `valueOf` lanza su propio mensaje ("No enum constant banco.TipoCuenta.CDT"), y el mensaje de la validación,
"tipo de cuenta desconocido: CDT", está congelado en la caracterización.
🗣️ El mensaje de error es parte de la API: quien llama puede mostrarlo o compararlo. Cambiarlo como efecto secundario de una
refactorización rompe la promesa de no cambiar comportamiento, así que se recorre `values()` y se conserva el texto.
🔬 Capturar la `IllegalArgumentException` de `valueOf` y relanzar con el mensaje viejo también funciona; recorrer `values()`
evita usar una excepción para una validación esperada.

**04 → 7. ¿Quién decide la transición en este `EstadoCuenta`, y cuándo convendría que la decidiera la cuenta? 🟠**

⏱️ El estado: `ABIERTA.alBloquear` devuelve `BLOQUEADA`. Convendría que decidiera la cuenta si la transición dependiera de
datos que solo ella tiene.
🗣️ `alCerrar` ya recibe el saldo como argumento, porque la transición depende de él. Si muchas transiciones necesitaran
datos de la cuenta, pasar todo por argumento sería ruido, y la tabla de transiciones en la cuenta sería más clara.
🔬 Es la tabla de `06/06` §6. Con tres estados y seis operaciones, que decida el estado es lo más corto; con veinte estados, una
máquina declarada en una tabla.

**04 → 8. Desbloquear una cuenta cerrada ahora se rechaza, y ninguna prueba cambió por eso. ¿Es un problema? 🟠**

⏱️ Es un hueco de la caracterización: el legado lo permitía, `14/01` no lo congeló, y el cambio pasó sin que la red avisara.
🗣️ La decisión es razonable —no tiene sentido desbloquear lo cerrado—, pero se tomó en silencio. Lo correcto era congelar
antes el comportamiento del legado y cambiar esa prueba aquí, nombrada como las otras dos.
🔬 Una suite de caracterización nunca es completa. Lo que se puede hacer es revisar, en cada refactorización, qué
comportamientos toca el cambio y si alguna prueba los cubre; esa revisión habría encontrado este caso.

**04 → 9. ¿Qué ganaste al poder probar `EstadoCuenta` sin base de datos? 🟠**

⏱️ Pruebas de milisegundos que cubren todas las transiciones, sin montar cuentas ni esquema.
🗣️ `EstadoCuentaTest` corre en milisegundos y prueba cada transición permitida y prohibida con una línea. Probar lo mismo a través
del gestor exigiría abrir cuentas, cerrarlas y bloquearlas en la base para cada caso.
🔬 Es la consecuencia de mover la regla a un objeto sin dependencias. El mismo argumento vale para las políticas de
comisión, que la misma clase prueba con un importe y nada más.

**04 → 10. El negocio pide que la comisión de la corriente baje a 1 200 en el retiro solo para clientes con más de cinco años. ¿Dónde entra en este diseño, y qué se rompe? 🔴**

⏱️ En la política de la corriente, pero la interfaz no le da lo que necesita: recibe solo el importe, y la antigüedad es de
la cuenta o del cliente. Hay que cambiar la firma.
🗣️ La opción directa es que `deRetiro` reciba la cuenta (o un objeto con lo que la comisión necesita), lo que obliga a tocar
la interfaz y sus tres implementaciones. La otra es una política nueva, `ComisionCorrienteAntigua`, elegida por algo más que
el tipo, y entonces el tipo ya no basta para elegir la política: la elección pasa a una fábrica que mira tipo y antigüedad.
🔬 Es el precio de rigidez que nombra §9 del taller: la interfaz se diseñó con lo que se necesitaba ese día. Lo que preguntará
después: cuándo la regla deja de ser un Strategy por tipo y pasa a ser un motor de reglas o una tabla de tarifas en la base.

**04 → E1. Añade a `EstadoCuentaTest` la prueba de que una cuenta cerrada no admite depósitos, retiros ni transferencias entrantes, con el mensaje de esta última. 🟢**

**El primer intento que sale.** Probarlo a través del gestor, abriendo y cerrando una cuenta. Funciona, pero es más lento y
mezcla lo que se prueba.

**La solución.**

```java
@Test
void unaCuentaCerradaNoAdmiteNingunMovimiento() {
    assertThrows(IllegalStateException.class, () -> EstadoCuenta.CERRADA.alDepositar("CTA-0005"));
    assertThrows(IllegalStateException.class, () -> EstadoCuenta.CERRADA.alRetirar("CTA-0005"));
    IllegalStateException e = assertThrows(IllegalStateException.class, () -> EstadoCuenta.CERRADA.alRecibir("CTA-0005"));
    assertEquals("la cuenta destino CTA-0005 está cerrada", e.getMessage());
}
```

**Lo que cuesta.** Nada; los métodos del `enum` son de paquete y la prueba vive en el mismo paquete.

**Lo que preguntará después.** Por qué los métodos no son públicos: porque solo `Cuenta` debería llamarlos; la prueba en el
mismo paquete los alcanza sin abrirlos al resto.

**04 → E2. Añade el tipo `PREMIUM`, que no cobra comisión en ninguna moneda, y la prueba de un retiro en dólares. Di cuántos archivos tocaste y por qué `ComisionFija` no sirve. 🟡**

**El primer intento que sale.** `PREMIUM(new ComisionFija("0", "0"))`. Cobra 2,50 en dólares, porque `ComisionFija` fija esa
regla para todos.

**La solución.** Dos archivos: una línea en `TipoCuenta` y una política nueva.

```java
// PREMIUM: no cobra nada, en ninguna moneda.
public final class SinComision implements PoliticaComision {

    @Override
    public Dinero deRetiro(Dinero importe) { return Dinero.cero(importe.moneda()); }

    @Override
    public Dinero deTransferencia(Dinero importe) { return Dinero.cero(importe.moneda()); }
}
```

```java
@Test
void premiumNoCobraEnNingunaMoneda() {
    BaseDatos.crearEsquema();
    GestorCuentas gestor = new GestorCuentas();
    gestor.abrirCuenta("CTA-0006", "Carmen Díaz Ortega", "carmen.diaz@example.com", "PREMIUM", "USD", 1_000, false);
    gestor.retirar("CTA-0006", 100);
    assertEquals(Dinero.de("900", Moneda.USD), gestor.saldo("CTA-0006"));
}
```

- La apertura acepta `PREMIUM` sin tocarla, porque valida contra `TipoCuenta.values()`. La base tampoco cambia: el tipo es
  un `VARCHAR`.

**Lo que cuesta.** Una clase de dos líneas útiles. Con el `switch`, habría sido un `case` en dos sitios.

**Lo que preguntará después.** Si `ComisionFija` debería parametrizar también lo de dólares. Podría (`ComisionFija("0", "0",
"0")`), pero sería una clase que se adapta a cada caso nuevo; una política distinta para una forma distinta es más clara.

**04 → E3. Escribe la migración SQL que pasa una tabla con `bloqueada` y `cerrada` a una sola columna `estado`, y pruébala en H2 con las cuatro combinaciones. Justifica qué estado recibe la fila cerrada y bloqueada. 🟠**

**El primer intento que sale.** Un `CASE` que mira `bloqueada` primero: la fila con los dos *flags* quedaría `BLOQUEADA`, y se
podría desbloquear y volver a operar una cuenta que el negocio cerró.

**La solución.**

```sql
ALTER TABLE cuenta ADD COLUMN estado VARCHAR(10);
UPDATE cuenta SET estado = CASE
    WHEN cerrada THEN 'CERRADA'
    WHEN bloqueada THEN 'BLOQUEADA'
    ELSE 'ABIERTA' END;
ALTER TABLE cuenta ALTER COLUMN estado SET NOT NULL;
ALTER TABLE cuenta DROP COLUMN bloqueada;
ALTER TABLE cuenta DROP COLUMN cerrada;
```

- Se añade la columna nullable, se llena, y solo después se exige `NOT NULL`: al revés, el `ALTER` fallaría con filas
  existentes.
- La prueba, en H2, crea las cuatro combinaciones, corre la migración y lee el resultado:

```text
CTA-A=ABIERTA CTA-B=BLOQUEADA CTA-C=CERRADA CTA-D=CERRADA
```

**La justificación.** Cerrar es irreversible y bloquear no: la combinación imposible se resuelve hacia el estado del que no se
vuelve. Pero es una decisión de negocio, y antes de correrla en producción se cuenta cuántas filas la tienen y se le
pregunta a alguien.

**Lo que cuesta.** Un paso que no se puede deshacer sin respaldo: el `DROP COLUMN` pierde la información de que esas cuentas
estaban también bloqueadas.

**Lo que preguntará después.** Cómo se hace sin parar el servicio: en dos despliegues (primero la columna nueva escrita junto
a las viejas, después el borrado), para que la versión anterior de la aplicación siga funcionando durante el cambio.

**04 → E4. Llega un requisito: el embargo judicial bloquea también los depósitos, y un desbloqueo normal no lo levanta. Añade el estado `EMBARGADA` y su prueba. Explica qué hizo el compilador cuando añadiste la operación nueva. 🔴**

**El primer intento que sale.** Un *flag* `embargada` en `Cuenta`, o un `if (motivo.equals("embargo"))` en `bloquear`: es
volver a lo que el taller quitó.

**La solución.** Una constante nueva y una operación nueva, `alEmbargar`, abstracta como las demás:

```java
EMBARGADA {
    @Override void alDepositar(String numero) {
        throw new IllegalStateException("la cuenta " + numero + " está embargada");
    }
    @Override void alRetirar(String numero) {
        throw new IllegalStateException("la cuenta " + numero + " está embargada");
    }
    @Override void alRecibir(String numero) {
        throw new IllegalStateException("la cuenta destino " + numero + " está embargada");
    }
    @Override EstadoCuenta alBloquear(String numero) { return EMBARGADA; }   // el embargo manda
    @Override EstadoCuenta alDesbloquear(String numero) {
        throw new IllegalStateException("un embargo no se levanta desbloqueando");
    }
    @Override EstadoCuenta alEmbargar(String numero) { return EMBARGADA; }
    @Override EstadoCuenta alCerrar(String numero, Dinero saldo) {
        throw new IllegalStateException("una cuenta embargada no se puede cerrar");
    }
};

abstract EstadoCuenta alEmbargar(String numero);
```

`ABIERTA` y `BLOQUEADA` pasan a `EMBARGADA`; `CERRADA` lanza. Y en `Cuenta`, `embargar()`, que delega como `bloquear()`.

```java
@Test
void unEmbargoBloqueaTambienLosDepositos() {
    Cuenta ana = new Cuenta("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", TipoCuenta.AHORROS, Moneda.COP,
            Dinero.de("1500000", Moneda.COP), EstadoCuenta.ABIERTA, false);
    ana.bloquear();
    ana.depositar(CIEN);                                       // bloqueada: los depósitos entran
    ana.embargar();
    IllegalStateException e = assertThrows(IllegalStateException.class, () -> ana.depositar(CIEN));
    assertEquals("la cuenta CTA-0001 está embargada", e.getMessage());
    ana.bloquear();
    assertEquals(EstadoCuenta.EMBARGADA, ana.getEstado());
    assertThrows(IllegalStateException.class, ana::desbloquear);
    assertEquals(Dinero.de("1500100", Moneda.COP), ana.getSaldo());
}
```

**Lo que hizo el compilador.** Al declarar `abstract EstadoCuenta alEmbargar(String numero)`, cada constante que no la
implementaba dejó de compilar: obligó a decidir qué pasa al embargar una cuenta abierta, una bloqueada y una cerrada. Y la
constante nueva no compiló hasta tener sus siete respuestas. Ninguna decisión quedó por defecto.

**Lo que cuesta.** Una constante de veinte líneas y una operación en los cuatro estados. Con *flags*, el mismo requisito habría
sido un tercer booleano y ocho combinaciones.

**Lo que preguntará después.** Quién levanta el embargo (otra operación, con su autorización), y si la columna `VARCHAR(10)`
admite `EMBARGADA` (sí: nueve caracteres). Y cuándo dejan de bastar las constantes: con estados que cambian por configuración
o por cliente, una máquina de estados declarada.

---

# 05 — Chain y Decorator

**05 → 1. ¿Qué variante de Chain of Responsibility usa este taller, y cómo corta? 🟢**

⏱️ La que acumula y en la que cualquiera puede cortar: cada eslabón comprueba lo suyo y pasa al siguiente, y el que lanza
una excepción detiene la cadena.
🗣️ Es la forma de los filtros de *servlet* y de `SecurityFilterChain` (`06/05` §6), no la del GoF clásico, donde el primer
eslabón que atiende responde y el resto no se entera. Aquí todos los eslabones atienden, en orden, hasta que uno rechaza.
🔬 El corte por excepción es lo natural en una validación: quien llama recibe el primer motivo de rechazo. El ejercicio E4
añade la otra variante, la que recorre todo y junta los mensajes.

**05 → 2. ¿Qué preocupación saca el decorador del servicio, y por qué se llama transversal? 🟢**

⏱️ La auditoría. Es transversal porque atraviesa todas las operaciones sin ser parte del negocio de ninguna.
🗣️ Retirar, depositar y transferir tienen reglas distintas, pero las tres se auditan igual. Escrita dentro de cada una, se
repite y se puede olvidar; como decorador, se escribe una vez y envuelve a todas.
🔬 Otras preocupaciones transversales con la misma forma: medición (E3), reintentos (`14/06`), transacciones, caché. En Spring
se resuelven con proxies y aspectos (`13/01`), que son decoradores generados.

**05 → 3. ¿Por qué `verificar` es `final` y `comprobar` abstracto? 🟡**

⏱️ Para que ningún eslabón pueda olvidar pasar al siguiente: el recorrido es de la clase base, y cada eslabón solo escribe su
comprobación.
🗣️ Si cada eslabón llamara a `siguiente.verificar` por su cuenta, uno que lo olvidara cortaría la cadena en silencio. Con
`verificar` `final`, la única forma de cortar es lanzar. Es un Template Method pequeño dentro de la cadena.
🔬 El precio: un eslabón no puede decidir "corto sin error". En esta cadena no hace falta; en una cadena de manejadores que
atienden (la aprobación por monto de `06/05`), sí, y el diseño sería otro.

**05 → 4. ¿Por qué `depositar` pasó a devolver un `boolean`? 🟡**

⏱️ Porque el decorador tiene que saber si el depósito se aplicó o era un reintento ignorado, para no auditar lo que no
pasó.
🗣️ Antes, la auditoría estaba dentro y el `return` temprano del reintento la saltaba. Desde afuera, el decorador solo ve que
la llamada volvió sin error. Sin el `boolean`, la auditoría registraría dos depósitos de `PSE-7781`.
🔬 La caracterización no lo habría detectado: su prueba de auditoría no incluye un reintento. Es un caso de "el decorador
necesita que la interfaz diga más", el costo de rigidez de §9 del taller.

**05 → 5. ¿Qué diferencia hay entre corregir el tope copiando el `if` y añadiendo un eslabón? 🟡**

⏱️ Copiar el `if` deja dos copias de la misma regla que pueden volver a separarse; el eslabón es una sola regla que las dos
operaciones usan.
🗣️ El defecto nació así: la regla estaba en un sitio y no en el otro. Copiarla resuelve el síntoma de hoy y deja la
condición para el próximo cambio —si el tope sube a 300 000, ¿quién recuerda las dos copias?—. Con el eslabón, el tope
cambia en un sitio.
🔬 Es la diferencia entre *Copy-Paste Programming* (`12/05`) y una abstracción con un solo dueño. El costo del eslabón es el
parámetro `verbo`, que existe solo para conservar el mensaje viejo.

**05 → 6. ¿Por qué el depósito no tiene su propia cadena? 🟠**

⏱️ Porque tiene una regla propia, el monto positivo, y la del estado vive en la cuenta. Una cadena de un eslabón para un uso
sería ceremonia.
🗣️ La cadena se paga cuando las reglas se comparten entre operaciones o cambian a menudo. El depósito no comparte nada que
el `if` no exprese en dos líneas.
🔬 Si mañana aparece una regla compartida —"una cuenta embargada no recibe depósitos ni transferencias"— el depósito gana su
cadena. Esa es la segunda variación real que justifica el patrón (`13/03` §2).

**05 → 7. ¿Qué pasaría si `OperacionesAuditadas` auditara antes de llamar al envuelto? 🟠**

⏱️ Auditaría también las operaciones que fallan, y no tendría la comisión, que solo el servicio calcula.
🗣️ Un retiro rechazado por saldo dejaría una fila "RETIRO" en la auditoría, y la caracterización lo detectaría solo si
contara filas después de un rechazo, cosa que hoy no hace. Además, el detalle no podría incluir la comisión.
🔬 Auditar intentos puede ser un requisito legítimo (seguridad, fraude), y entonces el decorador audita en un `finally` con el
resultado o la excepción. Es otro decorador, con otro nombre, no una variante silenciosa de este.

**05 → 8. Si invertir dos eslabones no tumba ninguna prueba de caracterización, ¿qué te dice eso de la red? 🟠**

⏱️ Que la red no cubre el orden de las reglas cuando fallan dos a la vez: hay comportamiento que nadie congeló.
🗣️ La caracterización se escribió con un caso por regla. El orden solo se ve con un caso que dispare dos reglas —un menor
bloqueado que retira 250 000—, y ese caso no estaba. El ejercicio E2 lo escribe.
🔬 La lección general: después de una refactorización que reordena algo, se pregunta qué combinaciones cubre la suite. Las
pruebas de propiedades, que generan combinaciones, son la herramienta para cuando el número crece.

**05 → 9. ¿Cuándo usarías un aspecto de Spring en lugar de este decorador? 🟠**

⏱️ Cuando la aplicación ya usa Spring y la preocupación aplica a muchas clases: el aspecto se declara una vez, sin escribir un
decorador por interfaz.
🗣️ El decorador a mano necesita una clase por interfaz y repetir cada método. Un aspecto con un *pointcut* intercepta todos
los métodos que coincidan, y el contenedor genera el proxy. A cambio, es menos visible: el código del servicio no dice que
alguien lo envuelve, y la autoinvocación lo salta (`13/01` §2).
🔬 En este módulo no hay contenedor, y el decorador a mano es lo que se pide escribir en una entrevista. En un proyecto con
Spring, la auditoría suele ser un aspecto o un `@EventListener` sobre eventos de dominio, que es el camino de `14/06`.

**05 → 10. El negocio pide que, en la pantalla de transferencias, se muestren todos los motivos de rechazo a la vez. ¿Qué cambia en la cadena? 🔴**

⏱️ La cadena necesita una segunda forma de recorrerse: sin cortar, juntando los mensajes de cada eslabón que falla. Las
reglas no cambian.
🗣️ Un método `errores(Solicitud)` en `Regla` recorre todos los eslabones, captura la excepción de cada uno y acumula su
mensaje. La operación sigue usando `verificar`, que corta; la pantalla usa `errores`, que informa. Es el ejercicio E4.
🔬 Lo que preguntará después: si algunos eslabones dependen de otros (`mismaMoneda` con destino nulo daría
`NullPointerException`), y cómo se ordena la lista que se muestra. Usar excepciones para acumular es cómodo pero caro; con
muchas reglas, cada eslabón devolvería un resultado en lugar de lanzar.

**05 → E1. Añade la regla "una transferencia no puede superar 10 000 000" solo a las transferencias, con su prueba, y comprueba que un retiro de ese monto sigue permitido. 🟢**

**El primer intento que sale.** Ponerla dentro de `montoPositivo`, que ya mira el monto. Mezcla dos reglas en un eslabón y la
aplica también al retiro.

**La solución.** Un eslabón nuevo y una línea en la cadena de la transferencia:

```java
public static Regla maximoPorTransferencia(String maximo) {
    return new Regla() {
        @Override protected void comprobar(Solicitud s) {
            if (s.importe().esMayorQue(Dinero.de(maximo, s.importe().moneda()))) {
                throw new IllegalArgumentException("el monto supera el máximo por transferencia");
            }
        }
    };
}

// en ServicioMovimientos
Reglas.destinoPuedeRecibir(), Reglas.mismaMoneda(), Reglas.topeDeMenores("transferir"),
Reglas.maximoPorTransferencia("10000000"));
```

```java
@Test
void unaTransferenciaNoPasaDelMaximo() {
    RuntimeException e = assertThrows(RuntimeException.class, () -> gestor.transferir("CTA-0004", "CTA-0001", 10_000_001));
    assertEquals("el monto supera el máximo por transferencia", e.getMessage());
    gestor.retirar("CTA-0004", 10_000_001);                  // el retiro no tiene ese eslabón
}
```

- `CTA-0004` es la nómina de Ana, abierta con 20 000 000 para la prueba. La suite completa quedó en 33 pruebas, en verde.

**Lo que cuesta.** Un eslabón de nueve líneas. Ningún eslabón existente cambió.

**Lo que preguntará después.** Si el máximo debería depender de la moneda: con 10 000 000 en dólares, sí. El parámetro
`maximo` se interpreta en la moneda del importe, y eso es un supuesto que una prueba en dólares dejaría escrito.

**05 → E2. Pon el tope de los menores antes de `origenPuedeRetirar` en la cadena del retiro y corre la suite. Después escribe la prueba que habría detectado el cambio. 🟡**

**El primer intento que sale.** Esperar que alguna prueba de caracterización caiga. No cae ninguna: las veinte siguen en
verde.

**La solución.** La prueba que congela el orden, con un menor bloqueado que intenta retirar más del tope:

```java
@Test
void unMenorBloqueadoVeElMensajeDelBloqueo() {
    BaseDatos.crearEsquema();
    GestorCuentas gestor = new GestorCuentas();
    gestor.abrirCuenta("CTA-0003", "Luis Rojas Paz", "ana.rojas@example.com", "AHORROS", "COP", 500_000, true);
    gestor.bloquear("CTA-0003", "revisión");
    RuntimeException e = assertThrows(RuntimeException.class, () -> gestor.retirar("CTA-0003", 250_000));
    assertEquals("la cuenta CTA-0003 está bloqueada", e.getMessage());
}
```

Con el orden invertido:

```text
[ERROR] banco.OrdenTest.unMenorBloqueadoVeElMensajeDelBloqueo <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <la cuenta CTA-0003 está bloqueada> but was: <un menor no puede retirar más de 200000>
[INFO] Tests run: 20, Failures: 0, Errors: 0, Skipped: 0 -- in banco.CaracterizacionTest
```

**Lo que cuesta.** Una prueba por par de reglas cuyo orden importa. No todas los tienen: dos reglas que nunca fallan a la
vez no necesitan prueba de orden.

**Lo que preguntará después.** Qué orden es el correcto. El del legado pone el estado antes que el tope: "está bloqueada"
dice más que "pasa del tope" a quien no puede operar de ninguna forma. Es una decisión de experiencia de usuario, y la
prueba la deja escrita.

**05 → E3. Escribe un segundo decorador que mida cuánto tarda cada operación, apílalo con el de auditoría, y di en qué orden los compones y por qué. 🟠**

**El primer intento que sale.** Medir dentro del de auditoría. Mezcla dos preocupaciones en un envoltorio.

**La solución.**

```java
// Otro decorador: mide cuánto tarda cada operación, la termine bien o mal.
public final class OperacionesMedidas implements OperacionesCuenta {

    private final OperacionesCuenta envuelto;
    private final List<String> mediciones;

    private <T> T medir(String nombre, Supplier<T> operacion) {
        long inicio = System.nanoTime();
        try {
            return operacion.get();
        } finally {
            mediciones.add(nombre + " " + (System.nanoTime() - inicio) / 1_000 + " µs");
        }
    }

    @Override public Movimiento retirar(String n, double m) { return medir("retirar", () -> envuelto.retirar(n, m)); }
    // … depositar y transferir igual; extracto, sin medir
}
```

```java
OperacionesCuenta pila = new OperacionesMedidas(new OperacionesAuditadas(servicio, auditoria), mediciones);
pila.retirar("CTA-0001", 30_000);
assertThrows(IllegalStateException.class, () -> pila.retirar("CTA-0001", 9_000_000));
assertEquals(List.of("RETIRO"), auditoria.acciones);
assertEquals(2, mediciones.size());
```

La corrida imprimió `[retirar 1568 µs, retirar 566 µs]`: dos mediciones, una auditoría.

- **El orden:** la medición va por fuera, para que el tiempo incluya la auditoría, que también escribe en la base y es parte
  de lo que el usuario espera. Si se quisiera medir solo el negocio, iría por dentro.
- La medición usa `finally`: mide también lo que falla. La auditoría no. Por eso son dos decoradores: tienen políticas
  distintas ante el error.

**Lo que cuesta.** Una clase más que repite los cuatro métodos de la interfaz. Con diez interfaces, diez decoradores: es el
punto donde un proxy dinámico o un aspecto empiezan a pagarse.

**Lo que preguntará después.** Si el orden de la pila se puede probar: sí, con una auditoría que también anote el tiempo, o
inspeccionando qué envuelve a qué. Y dónde se compone la pila: en la raíz de composición, la fachada.

**05 → E4. Añade a `Regla` una forma de recorrer la cadena sin cortar que devuelva todos los mensajes de error, y pruébala con una transferencia de un menor, bloqueado y en dólares, a una cuenta en pesos. 🔴**

**El primer intento que sale.** Un segundo método abstracto en cada eslabón que devuelva el error en lugar de lanzarlo.
Duplica las seis reglas.

**La solución.** Reutilizar `comprobar` y capturar lo que lance:

```java
// la variante que acumula: recorre todos los eslabones y junta los mensajes, sin cortar
public final List<String> errores(Solicitud s) {
    List<String> errores = new ArrayList<>();
    for (Regla r = this; r != null; r = r.siguiente) {
        try {
            r.comprobar(s);
        } catch (RuntimeException e) {
            errores.add(e.getMessage());
        }
    }
    return errores;
}
```

```java
@Test
void laCadenaQueAcumula() {
    Cuenta luis = new Cuenta("CTA-0003", "Luis Rojas Paz", "ana.rojas@example.com", TipoCuenta.AHORROS, Moneda.USD,
            Dinero.de("0", Moneda.USD), EstadoCuenta.BLOQUEADA, true);
    Cuenta ana = new Cuenta("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", TipoCuenta.AHORROS, Moneda.COP,
            Dinero.de("1500000", Moneda.COP), EstadoCuenta.ABIERTA, false);
    Regla cadena = Regla.cadena(Reglas.cuentasDistintas(), Reglas.montoPositivo(), Reglas.origenPuedeRetirar(),
            Reglas.destinoPuedeRecibir(), Reglas.mismaMoneda(), Reglas.topeDeMenores("transferir"));
    List<String> errores = cadena.errores(new Solicitud(luis, ana, Dinero.de("250000", Moneda.USD)));
    assertEquals(List.of("la cuenta CTA-0003 está bloqueada", "las cuentas tienen monedas distintas",
            "un menor no puede transferir más de 200000"), errores);
}
```

- Tres motivos, en el orden de la cadena. La cuenta de Luis en dólares es un dato inventado para la prueba, no la de §5.6.

**Lo que cuesta.** Excepciones como control de flujo: cada error construye una traza de pila que nadie mira. Con seis reglas
no se nota; con cientos, sí.

**Lo que preguntará después.** Qué pasa con un eslabón que depende de otro: con `destino` nulo, `mismaMoneda` lanzaría
`NullPointerException`, que también se acumularía como "mensaje". La salida es que las reglas devuelvan un resultado
(`Optional<String>`) en lugar de lanzar, y que `verificar` lance el primero: es la forma de las librerías de validación.

---

# 06 — Eventos y bloqueo optimista

**06 → 1. ¿Qué es una actualización perdida, y cuántos depósitos se perdieron en `estados/05`? 🟢**

⏱️ Dos operaciones leen el mismo valor, calculan por separado y escriben; la segunda en escribir borra a la primera. En
`estados/05` se perdieron entre 71 y 76 de cada cien depósitos concurrentes.
🗣️ Las tres corridas dieron 25 000, 29 000 y 24 000 de 100 000, sin un solo error: cada hilo creyó que su depósito había
entrado. Y las cien filas de movimiento sí se escribieron, así que el extracto y el saldo no cuadran.
🔬 Es el *lost update* de `08/03`. Que el número cambie en cada corrida es la marca de una carrera: el resultado depende de
cómo el planificador intercale los hilos.

**06 → 2. ¿Por qué los eventos se nombran en pasado? 🟢**

⏱️ Porque dicen algo que ya ocurrió y no se puede discutir: `DepositoRecibido`, no `RecibirDeposito`.
🗣️ Un evento no es una orden: quien lo recibe no puede rechazarlo, solo reaccionar. El nombre en pasado lo deja claro y lo
distingue de un comando (`06/04`), que pide algo que todavía puede fallar.
🔬 Es la convención de Evans y de Fowler para *Domain Event* (`09/02`). En la práctica, un evento en pasado también obliga a
publicarlo cuando de verdad pasó: después del `commit`.

**06 → 3. ¿Por qué una transacción sola no evitó la actualización perdida? 🟡**

⏱️ Porque con el aislamiento por defecto de H2, *read committed*, leer no bloquea la fila: dos transacciones leen el mismo
saldo y la segunda en confirmar sobrescribe a la primera.
🗣️ La transacción hace que **una** operación se confirme entera o nada; no ordena una operación respecto de las demás. Con
transacciones y sin versión, la prueba dio 8 000 y 19 000 de 100 000.
🔬 Con aislamiento serializable, o leyendo con `SELECT … FOR UPDATE` (bloqueo pesimista), la base sí lo evitaría, a costa de
esperas y bloqueos. El bloqueo optimista deja leer sin bloquear y detecta el conflicto al escribir.

**06 → 4. ¿Qué devuelve `executeUpdate` cuando la versión cambió, y qué hace el repositorio con eso? 🟡**

⏱️ Devuelve cero filas, porque el `WHERE version = ?` ya no encuentra la fila con la versión leída. El repositorio lanza
`ConflictoDeConcurrencia`.
🗣️ La excepción sale dentro de la transacción, que hace `rollback`: lo que la operación hubiera escrito antes —un movimiento,
el otro lado de una transferencia— se deshace con ella. El decorador de reintentos la atrapa afuera y repite todo.
🔬 Cero filas también podría significar que la cuenta no existe; aquí no pasa porque la operación la acaba de leer en la
misma transacción. Un repositorio más general distinguiría los dos casos.

**06 → 5. ¿Por qué los eventos se publican después del `commit` y no dentro de la transacción? 🟡**

⏱️ Porque si la transacción se deshace después de publicar, el correo ya salió por algo que no existe.
🗣️ Dentro de la lambda, un depósito que choca y se reintenta mandaría un correo por cada intento; uno que falla mandaría un
correo por un depósito deshecho. La prueba `loQueNoSeConfirmoNoSePublica` lo fija: un retiro rechazado no publica nada.
🔬 El precio: si la aplicación se cae entre el `commit` y la publicación, el evento se pierde. Cuando eso no es aceptable, el
evento se escribe en una tabla en la misma transacción y otro proceso lo publica (*transactional outbox*), que ya es
arquitectura y no objetos.

**06 → 6. ¿Por qué `EventoDeCuenta` es una interfaz sellada? 🟠**

⏱️ Para que el `switch` de los suscriptores sea exhaustivo: el compilador conoce todos los eventos y exige un caso por cada
uno.
🗣️ Un evento nuevo —`CuentaEmbargada`— no compila en `AvisosPorCorreo` hasta que alguien decida si manda correo. Con una
interfaz abierta y un `default`, el evento nuevo se ignoraría en silencio.
🔬 Es el reemplazo moderno de Visitor que discute `06/07`: tipos sellados y `switch` de patrones. El costo es que agregar un
evento obliga a tocar todos los `switch` sobre eventos, que es justo lo que se quiere aquí.

**06 → 7. ¿Por qué la espera entre reintentos es al azar y crece? 🟠**

⏱️ Al azar, para que los hilos que chocaron no vuelvan a chocar juntos; creciente, para que con mucha contención la carga
baje en lugar de subir.
🗣️ Si diez hilos chocan y todos esperan 2 ms, se despiertan a la vez y chocan de nuevo. Con una espera aleatoria entre 1 y
5·i ms, se reparten. Es la idea del *backoff* exponencial con *jitter*, en pequeño.
🔬 Sin espera, los reintentos serían un bucle activo que compite con los mismos hilos que causan el conflicto. Con veinte
intentos y esta espera, quinientos depósitos desde cincuenta hilos entraron todos (ejercicio E3).

**06 → 8. ¿Por qué los reintentos van por fuera de la auditoría? 🟠**

⏱️ Para que se audite una sola vez la operación que entró, y no cada intento.
🗣️ La auditoría solo registra lo que terminó bien, así que un intento que choca no deja fila. Por fuera, el decorador de
reintentos repite la pila completa, y la auditoría ve un solo éxito. Con esta auditoría, el orden inverso daría el mismo
resultado, pero por un detalle de ella, no por diseño.
🔬 Si la auditoría registrara también los intentos (`try`/`finally`), el orden sí cambiaría el resultado: por dentro, una
fila por intento. El orden de los decoradores se decide por lo que cada uno promete, y se escribe en la raíz de
composición.

**06 → 9. ¿Por qué `synchronized` en el servicio no resolvería el problema en producción? 🟠**

⏱️ Porque solo ordena los hilos de una JVM. Con dos instancias de la aplicación, cada una tiene su candado, y la base ve las
mismas actualizaciones perdidas.
🗣️ En la prueba, con un solo proceso, `synchronized` haría pasar los cien depósitos. Por eso es la respuesta que sale
primero, y por eso hay que decir que la prueba no representa producción: el recurso compartido es la fila de la base, y el
control tiene que estar donde está el recurso.
🔬 Además, `synchronized` en el servicio serializaría **todas** las operaciones, de todas las cuentas, en un solo candado. El
bloqueo optimista solo hace esperar a quien toca la misma cuenta.

**06 → 10. Una cuenta recaudadora recibe tres mil pagos por minuto, y los reintentos se disparan. ¿Qué cambias? 🔴**

⏱️ El bloqueo optimista funciona cuando los conflictos son raros; con una cuenta caliente, son la norma. Cambiaría a bloqueo
pesimista en esa operación, o dejaría de actualizar el saldo en cada pago.
🗣️ Tres opciones, de menos a más cambio: `SELECT … FOR UPDATE` al leer la cuenta, para que los pagos esperen en fila en lugar
de chocar; serializar los pagos de esa cuenta en una cola con un solo consumidor; o registrar solo los movimientos y
calcular el saldo de la cuenta recaudadora por agregación periódica, sin un `UPDATE` por pago.
🔬 Lo que preguntará después: cómo se decide cuál, y la respuesta es medir —cuántos reintentos por minuto, cuánta latencia— en
lugar de suponer. Y que la tercera opción cambia el modelo: el saldo pasa a ser un dato derivado, que es la puerta a
diseños por eventos que este corpus deja fuera.

**06 → E1. Escribe un suscriptor que cuente los eventos por tipo, y la prueba de una transferencia de Ana a Luis. 🟢**

**El primer intento que sale.** Contar dentro de `AvisosPorCorreo`. Mezcla dos suscriptores en uno; el publicador admite
cualquier número.

**La solución.** Un suscriptor en una lambda:

```java
@Test
void unSuscriptorQueCuentaPorTipo() {
    Map<String, Integer> porTipo = new TreeMap<>();
    PublicadorDeEventos publicador = new PublicadorDeEventos();
    publicador.suscribir(e -> porTipo.merge(e.getClass().getSimpleName(), 1, Integer::sum));
    RepositorioCuentas cuentas = new RepositorioCuentas();
    ServicioCuentas ciclo = new ServicioCuentas(cuentas, new Auditoria(), publicador);
    ciclo.abrir("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", "AHORROS", "COP", 1_500_000.00, false);
    ciclo.abrir("CTA-0003", "Luis Rojas Paz", "ana.rojas@example.com", "AHORROS", "COP", 0, true);
    new ServicioMovimientos(cuentas, new RepositorioMovimientos(), publicador).transferir("CTA-0001", "CTA-0003", 250_000);
    assertEquals(Map.of("CuentaAbierta", 2, "TransferenciaRecibida", 1), porTipo);
}
```

La corrida imprimió `{CuentaAbierta=2, TransferenciaRecibida=1}`.

- La transferencia publica un solo evento, el del destino. El origen no anota nada al debitar, porque nadie lo pidió.

**Lo que cuesta.** Nada; es el uso para el que existe el publicador.

**Lo que preguntará después.** Si el origen debería anotar `TransferenciaEnviada`. Si alguien la necesita —un aviso al que
envía, un límite diario—, sí; mientras nadie la necesite, es un evento que se publica para nadie.

**06 → E2. Usa el repositorio del ejercicio E4 de `14/03` —el que falla al segundo `guardar`— y escribe la prueba que demuestra que la transferencia ya es atómica: saldos intactos, ningún correo, ningún movimiento. 🟡**

**El primer intento que sale.** Copiar el repositorio tal cual. No compila: `guardar` ahora recibe la conexión.

**La solución.**

```java
static class RepositorioQueFallaAlSegundoGuardar extends RepositorioCuentas {
    int guardados;
    @Override public void guardar(Connection con, Cuenta c) throws SQLException {
        if (++guardados == 2) throw new RuntimeException("se cayó la conexión");
        super.guardar(con, c);
    }
}

@Test
void laTransferenciaYaEsAtomica() {
    Notificador.ENVIADOS.clear();
    RepositorioQueFallaAlSegundoGuardar cuentas = new RepositorioQueFallaAlSegundoGuardar();
    GestorCuentas gestor = new GestorCuentas(cuentas, new RepositorioMovimientos(), new Auditoria(), new Notificador());
    gestor.abrirCuenta("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", "AHORROS", "COP", 1_500_000.00, false);
    gestor.abrirCuenta("CTA-0003", "Luis Rojas Paz", "ana.rojas@example.com", "AHORROS", "COP", 0, true);
    Notificador.ENVIADOS.clear();
    assertThrows(RuntimeException.class, () -> gestor.transferir("CTA-0001", "CTA-0003", 250_000));
    assertEquals(Dinero.de("1500000", Moneda.COP), gestor.saldo("CTA-0001"));
    assertEquals(Dinero.de("0", Moneda.COP), gestor.saldo("CTA-0003"));
    assertEquals(List.of(), Notificador.ENVIADOS);
    assertEquals(0, gestor.extracto("CTA-0001").size());
}
```

La corrida imprimió `1500000.00 COP / 0.00 COP correos []`. En `estados/03`, la misma prueba daba 1 250 000 y 0.

**Lo que cuesta.** Nada en la prueba; en el código, la transacción del paso 2.

**Lo que preguntará después.** Por qué los decoradores no reintentan este fallo: porque no es un `ConflictoDeConcurrencia`.
Una caída de conexión real podría merecer reintento, pero es otra decisión, con otro riesgo (¿se confirmó o no antes de
caer?).

**06 → E3. Sube la prueba de concurrencia a cincuenta hilos y quinientos depósitos. ¿Alcanzan los veinte intentos? Mide cuántos depósitos fallan. 🟠**

**El primer intento que sale.** Afirmar el saldo esperado de 500 000 sin contar fallos: si alguno fallara, la prueba
lanzaría la `ExecutionException` y no diría cuántos.

**La solución.** Contar los que fallan y afirmar que el saldo cuadra con los que entraron:

```java
ExecutorService hilos = Executors.newFixedThreadPool(50);
List<Future<?>> tareas = new ArrayList<>();
for (int i = 0; i < 500; i++) tareas.add(hilos.submit(() -> gestor.depositar("CTA-0001", 1_000, null)));
int fallidos = 0;
for (Future<?> t : tareas) {
    try { t.get(); } catch (ExecutionException e) { fallidos++; }
}
hilos.shutdown();
assertEquals(Dinero.de(String.valueOf(1_000 * (500 - fallidos)), Moneda.COP), gestor.saldo("CTA-0001"));
```

La corrida imprimió `fallidos 0 saldo 500000.00 COP`: alcanzaron.

- La afirmación importante no es "cero fallos" sino "el saldo cuadra con lo que entró": aunque fallaran algunos, ninguno se
  perdería en silencio.

**Lo que cuesta.** Una corrida más lenta, y una prueba que sigue siendo no determinista: con otra máquina u otra carga, el
número de fallos puede no ser cero.

**Lo que preguntará después.** Qué pasa si fallan: el cliente ve un error y reintenta él, que es correcto; lo incorrecto era
perder el dinero. Y cómo se fija un límite: midiendo reintentos en producción, no adivinando el veinte.

**06 → E4. La idempotencia de los depósitos sigue en memoria. Hazla durable: el mismo pago aplicado desde dos instancias del gestor debe entrar una vez. Prueba también que dos transferencias iguales seguidas siguen funcionando. 🔴**

**El primer intento que sale.** La restricción de la pregunta 10 de `14/02`, `UNIQUE (numero, referencia)` en `movimiento`.
El mismo pago desde dos gestores entra una vez, pero la segunda prueba falla:

```text
[ERROR] banco.Ejercicios06Test.dosTransferenciasIgualesSeguidas <<< ERROR!
org.h2.jdbc.JdbcSQLIntegrityConstraintViolationException: Unique index or primary key violation: "PUBLIC.PAGO_UNICO
INDEX PUBLIC.PAGO_UNICO_INDEX_B ON PUBLIC.MOVIMIENTO(NUMERO NULLS FIRST, REFERENCIA NULLS FIRST) VALUES ( /* key:1 */
'CTA-0001', 'CTA-0003')"
```

La transferencia guarda en `referencia` la cuenta de la otra punta, así que dos transferencias iguales chocan.

**La solución.** Una tabla propia para los pagos aplicados, escrita en la misma transacción que el depósito:

```sql
CREATE TABLE pago_aplicado (
    numero     VARCHAR(10) NOT NULL,
    referencia VARCHAR(40) NOT NULL,
    PRIMARY KEY (numero, referencia))
```

```java
// dentro de la transacción del depósito, antes de guardar la cuenta
if (referencia != null) {
    try (var ps = con.prepareStatement("INSERT INTO pago_aplicado (numero, referencia) VALUES (?, ?)")) {
        ps.setString(1, numero);
        ps.setString(2, referencia);
        ps.executeUpdate();                          // el segundo intento choca aquí y todo se deshace
    }
}
```

```java
@Override
public boolean depositar(String numero, double monto, String referencia) {
    try {
        return depositarUnaVez(numero, monto, referencia);
    } catch (RuntimeException e) {
        if (e.getCause() instanceof java.sql.SQLIntegrityConstraintViolationException) {
            return false;   // otro nodo, u otro arranque, ya lo aplicó: la base lo sabe
        }
        throw e;
    }
}
```

```java
@Test
void elMismoPagoEnDosNodosSeAplicaUnaVez() {
    GestorCuentas nodoA = new GestorCuentas();
    nodoA.abrirCuenta("CTA-0001", "Ana Rojas Medina", "ana.rojas@example.com", "AHORROS", "COP", 1_500_000.00, false);
    nodoA.depositar("CTA-0001", 80_000, "PSE-7781");
    GestorCuentas nodoB = new GestorCuentas();          // sin memoria de lo que hizo el nodo A
    nodoB.depositar("CTA-0001", 80_000, "PSE-7781");
    assertEquals(Dinero.de("1580000", Moneda.COP), nodoB.saldo("CTA-0001"));
    assertEquals(1, nodoB.extracto("CTA-0001").size());
}
```

Con la tabla, las cinco pruebas del ejercicio y la suite completa pasan: 38 pruebas.

- La clave primaria hace el trabajo que el `Set` en memoria hacía a medias: la comprueba la base, para todos los procesos.
- La violación se traduce en "ya aplicado" (`false`), que es lo que el reintento de la pasarela necesita saber; no es un
  error para quien llama.
- La clave es `(numero, referencia)`, sin el monto: el mismo pago con otro monto ahora **no entra** (comprobado: el saldo se
  queda en 1 580 000). Pero se trata en silencio como "ya aplicado", y el ejercicio E3 de `14/02` pedía rechazarlo **y
  alertar**: esa alerta, que distingue el reintento del error de la pasarela, es el paso siguiente que esta solución no da.

**Lo que cuesta.** Una tabla y un `INSERT` por depósito con referencia. Y un cambio de comportamiento —la misma referencia con
otro monto deja de entrar— que hay que nombrar como tal.

**Lo que preguntará después.** Qué hacer con el `Set` en memoria: puede quedarse como atajo para no ir a la base en el caso
común, o irse; la verdad ya está en la tabla. Y si la tabla crece sin límite: se purga lo más viejo que la ventana de
reintentos de la pasarela.
