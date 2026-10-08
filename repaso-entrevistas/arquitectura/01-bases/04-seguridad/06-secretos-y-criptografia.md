# 06 — Secretos y criptografía

> Dónde viven las credenciales y cómo se rotan, qué se cifra en reposo y en tránsito y con qué, el
> sobre criptográfico que usa toda la nube, y cómo se guardan las contraseñas. Con el criterio de
> siempre: **nunca implementes criptografía, úsala bien**.
> Asume leído [`05` — mTLS, zero-trust y service mesh](05-mtls-zero-trust-y-mesh.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

La contraseña de la base de datos está en `application.yml`, versionada en el repositorio desde
2019. Nadie recuerda quién la puso y cambiarla exige desplegar catorce servicios.

Eso no es un descuido puntual: es el estado por defecto de muchos sistemas, y tiene consecuencias
concretas:

```text
Está en el historial de Git      → borrarla del archivo no la borra del historial
La ve todo el que clona          → incluidos contratistas y equipos que ya no están
No se puede rotar sin desplegar  → así que nadie la rota
No hay registro de quién la usó  → y ante una brecha, no se sabe el alcance
```

> **Regla:** un secreto en el código no es un secreto. Y la prueba es que rotarlo requiere un
> despliegue, lo que significa que en la práctica no se rota nunca.

---

## 2. 🗝️ Gestión de secretos

**Qué es.** Un almacén dedicado que guarda credenciales, las entrega bajo autenticación, registra
cada acceso y permite rotarlas sin desplegar.

Las opciones y su nivel:

```text
Variables de entorno   → mejor que el código. Siguen en el manifiesto, se ven en un `ps`
                         y en los volcados de memoria. Es el mínimo, no la solución.
Secret del orquestador → Kubernetes Secret: está en base64, NO cifrado, salvo que actives
                         cifrado en reposo en etcd. Mejor, y aún limitado.
Gestor dedicado        → Vault, Secrets Manager, Parameter Store. Cifrado, con control de
                         acceso por identidad, registro de auditoría y rotación automática.
```

**Lo que distingue a un gestor dedicado**, y es lo que hay que nombrar:

- **Rotación automática**: el gestor cambia la credencial en el origen y en el almacén, y las
  aplicaciones la reciben sin desplegar.
- **Registro de acceso**: quién pidió qué secreto y cuándo. Ante una brecha, es lo que acota el
  alcance.
- **Credenciales dinámicas**, que es la función más infravalorada: Vault puede **crear un usuario
  de base de datos al vuelo** con TTL de una hora. No hay contraseña compartida que filtrar porque
  cada instancia tiene la suya y caduca sola.

**El problema del secreto cero.** Si la aplicación necesita una credencial para autenticarse contra
el gestor, ¿dónde vive esa? La respuesta moderna: **en ningún sitio**, porque se usa la identidad
de la plataforma —la cuenta de servicio de Kubernetes, el rol de la instancia— que la infraestructura
ya proporciona y rota. Es exactamente la identidad de servicio de
[`05`](05-mtls-zero-trust-y-mesh.md) reutilizada.

**Cuándo sí un gestor dedicado.** Cualquier sistema con datos regulados, cualquiera con más de un
entorno, y cualquiera donde rotar sea un requisito.

**Cuándo no.** Un proyecto interno de una persona sin datos sensibles: ahí variables de entorno más
un `.gitignore` bien puesto es proporcional.

> ⚠️ **Advertencia.** Los `Secret` de Kubernetes están **codificados en base64, no cifrados**.
> Cualquiera con permiso de lectura sobre el espacio de nombres los ve en claro. Saberlo es una de
> las preguntas más discriminantes del capítulo.

> **Veredicto:** la medida del éxito no es que los secretos estén guardados, es que **rotarlos sea
> un evento rutinario**. Si rotar da miedo, no hay gestión de secretos.

---

## 3. 🧯 Qué hacer con un secreto filtrado

**Qué es.** El procedimiento, porque la respuesta intuitiva —borrarlo del archivo— es la
equivocada.

```text
1. ROTAR PRIMERO. La credencial está comprometida desde el momento en que se subió.
   Borrarla del repositorio no la invalida.
2. Revisar el registro de acceso: ¿se usó desde algún sitio inesperado?
3. Limpiar el historial de Git, si procede. Y asumir que pudo clonarse.
4. Notificar según la naturaleza del dato y la normativa.
5. Poner detección: escaneo de secretos en el pipeline y en cada push.
```

- **El orden importa.** Mucha gente empieza por el paso 3, que es cosmético: mientras la credencial
  siga siendo válida, el riesgo sigue vivo.
- El paso 5 es el que evita la repetición: herramientas de detección de secretos en el
  pre-commit y en CI, que fallan el build.

> **Veredicto:** ante un secreto filtrado, la primera acción es rotar, no borrar. Decirlo en ese
> orden demuestra que has pasado por ello.

---

## 4. 🔐 Cifrado: en tránsito y en reposo

**Qué es.** Dos problemas distintos con soluciones distintas, y conviene no mezclarlos.

**En tránsito.** TLS 1.3 —o 1.2 como mínimo—, y mTLS entre servicios cuando la identidad importa.
La normativa financiera lo exige también **dentro** del perímetro, que es uno de los argumentos
reales de la malla.

**En reposo.** Y aquí hay tres niveles que resuelven cosas distintas:

| Nivel | Qué protege | Qué NO protege |
|---|---|---|
| **Disco / volumen** | El robo del disco físico o del snapshot | A quien tenga acceso a la base de datos |
| **Base de datos (TDE)** | Los archivos y los backups | A quien se conecte con credenciales válidas |
| **Campo a campo, en la aplicación** | Incluso del administrador de base de datos | Nada más: es el más fuerte y el más caro |

- **El cifrado de disco es el más común y el que menos protege**: contra el riesgo realista —un
  acceso indebido a la base de datos— no hace nada, porque el motor descifra de forma transparente.
- **El cifrado a nivel de campo** es lo que se exige para datos especialmente sensibles: un número
  de tarjeta, un identificador fiscal. Y su precio es real: **no puedes buscar ni indexar por un
  campo cifrado**, salvo con técnicas que degradan la seguridad.
- La salida habitual para poder buscar: guardar además un **hash determinista con sal secreta** del
  campo, que permite igualdad exacta sin exponer el valor.

**El sobre criptográfico (envelope encryption)**, que es como lo hace toda la nube y hay que saber
explicarlo:

```text
1. Se genera una clave de datos (DEK) aleatoria para cifrar ESE dato
2. La DEK se cifra con una clave maestra (KEK) que vive en el HSM y NUNCA sale de ahí
3. Se guardan juntos: el dato cifrado y la DEK cifrada
4. Para descifrar: se pide al KMS que descifre la DEK, y con ella se descifra el dato
```

- **Ventaja**: la clave maestra nunca sale del módulo de seguridad, y rotar la KEK solo obliga a
  volver a cifrar las DEK —pequeñas—, no los datos.
- Es exactamente el mecanismo del **crypto-shredding** de
  [`02-eventos/07`](../02-eventos/07-event-sourcing.md): destruir la DEK de un sujeto deja sus
  datos ilegibles sin tocarlos.

> **Veredicto:** "ciframos en reposo" no dice nada sin decir **a qué nivel**. La pregunta que
> distingue es: *"¿protege contra el robo del disco, o contra alguien con credenciales de base de
> datos?"*.

---

## 5. 🧂 Contraseñas: hash, no cifrado

**Qué es.** Las contraseñas **no se cifran**: se resumen con una función lenta y con sal. Cifrar
implica poder descifrar, y eso es exactamente lo que no se quiere.

```text
MAL:  MD5, SHA-1, SHA-256 a secas → rápidas por diseño; un GPU prueba miles de millones/s
BIEN: bcrypt · scrypt · Argon2id  → LENTAS a propósito, con coste ajustable
```

- **La sal** es única por usuario y evita las tablas precomputadas; va guardada junto al hash y no
  es secreta.
- **La pimienta** es un valor secreto adicional, común a todos y guardado **fuera** de la base de
  datos: si se filtra la base, los hashes siguen siendo inatacables.
- **Argon2id es el recomendado hoy**; bcrypt sigue siendo aceptable y es lo que Spring Security usa
  por defecto con `BCryptPasswordEncoder`.
- **El coste se ajusta**: se sube el factor de trabajo conforme el hardware mejora, y
  `DelegatingPasswordEncoder` permite migrar de algoritmo sin invalidar las contraseñas existentes
  —se rehashea en el siguiente inicio de sesión correcto—.

> ⚠️ **Advertencia.** "Ciframos las contraseñas" es un error de vocabulario que delata: si se
> pueden descifrar, una brecha las expone todas. La palabra correcta es **hash**, y la pregunta de
> seguimiento suele ser cuál.

> **Veredicto:** hash lento, sal única, y coste que se sube con el tiempo. Y si el sistema puede
> mostrarte tu contraseña olvidada, está mal por definición.

---

## 6. 🧪 Lo que no se implementa

**Qué es.** El principio más importante del capítulo:

> **Nunca implementes criptografía. Úsala bien.**

Lo que eso significa en la práctica:

- **Nada de algoritmos propios.** Ni "ciframos con XOR y una clave larga". La criptografía se
  rompe en los detalles, y esos detalles llevan décadas de análisis público.
- **Modos seguros por defecto**: AES-GCM o ChaCha20-Poly1305, que son **autenticados** —detectan
  manipulación—. `AES/ECB` es el error clásico: cifra cada bloque igual, así que los patrones del
  original se ven en el resultado.
- **Aleatoriedad criptográfica**: `SecureRandom`, nunca `Random`. Un identificador de sesión
  generado con `Random` es predecible.
- **Comparación en tiempo constante** para secretos: comparar un token con `equals` filtra
  información por el tiempo de respuesta. En Java, `MessageDigest.isEqual`.
- **Nunca reutilizar un nonce** con la misma clave en GCM: rompe la confidencialidad por completo.

> 💡 **Truco.** Una respuesta que suma: *"no implementaría nada; usaría la librería del proveedor y
> me aseguraría de tres cosas: modo autenticado, aleatoriedad criptográfica y que las claves vivan
> en un KMS"*. Reconocer los límites propios en criptografía es señal de experiencia, no de
> ignorancia.

---

## 7. 🧭 Cómo se elige

```text
¿Dónde viven los secretos?
    ¿Datos regulados, varios entornos, rotación requerida? → gestor dedicado (Vault, Secrets Manager)
    ¿Kubernetes sin gestor?  → Secret + cifrado en reposo de etcd. Y saber que es base64.
    ¿Cómo se autentica la app contra el gestor? → con la identidad de la plataforma. Nunca
                                                  con otra credencial guardada.
    ¿Puedes usar credenciales dinámicas? → hazlo: un usuario por instancia, con TTL.

¿Qué cifras y a qué nivel?
    Tránsito                    → TLS 1.3; mTLS entre servicios si la normativa lo pide
    Reposo, riesgo = robo físico→ cifrado de disco. Barato, y protege poco.
    Reposo, riesgo = acceso indebido a la BD → campo a campo, con sobre criptográfico
    ¿Necesitas buscar por el campo cifrado? → hash determinista con sal secreta, aparte

¿Contraseñas?
    → Argon2id o bcrypt. Sal por usuario. Coste ajustable. Nunca "cifrado".

Y siempre:
    → no implementes criptografía; usa modos autenticados, SecureRandom y un KMS.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Ciframos las contraseñas" | Se **hashean** con función lenta y sal; cifrar implica poder descifrar |
| "Usamos SHA-256 para contraseñas" | Es rápida por diseño: hace falta bcrypt, scrypt o Argon2id |
| "Los Secret de Kubernetes están cifrados" | Están en **base64**, salvo que actives cifrado en reposo de etcd |
| "Borré la clave del repositorio" | Sigue en el historial y sigue siendo válida: primero se **rota** |
| "Ciframos en reposo" | ¿A qué nivel? El de disco no protege de quien accede a la base de datos |
| "Implementamos nuestro cifrado" | Nunca. Usa la librería, en modo autenticado, con claves en KMS |
| "Comparamos el token con `equals`" | Filtra por tiempo: `MessageDigest.isEqual` |
| "Variables de entorno es suficiente" | Es el mínimo; siguen en el manifiesto y en los volcados |

---

## 📚 Para profundizar

- **Libro** — Prabath Siriwardena y Nuwan Dias, *Microservices Security in Action* (Manning,
  2020). Capítulos sobre gestión de secretos y protección de datos en despliegues contenedorizados.
- **Libro** — Ross Anderson, *Security Engineering*, 3ª ed. (Wiley, 2020). Capítulos de
  criptografía y de gestión de claves: el porqué de todo lo de §6, disponible gratis en la web del
  autor.
- **Libro** — Laurentiu Spilca, *Spring Security in Action*, 2ª ed. (Manning, 2024). El capítulo
  de `PasswordEncoder`, con `DelegatingPasswordEncoder` y la migración de algoritmo.
- [OWASP — Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html):
  el ciclo de vida completo, incluido el problema del secreto cero.
- [OWASP — Cryptographic Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html):
  qué algoritmo para qué, con las recomendaciones vigentes para contraseñas.
- [HashiCorp Vault — What is Vault](https://developer.hashicorp.com/vault/docs/about-vault/what-is-vault):
  secretos dinámicos, rotación y autenticación por identidad de plataforma.
- [OWASP Top 10](https://owasp.org/projects/top-ten): la categoría de fallos criptográficos,
  con los casos reales que la componen.
- **Video** — GOTO Conferences y OWASP, charlas sobre gestión de secretos en Kubernetes y sobre
  errores criptográficos frecuentes. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`08` — Respuestas](08-respuestas.md).

1. ¿Por qué un secreto en el código no es un secreto? 🟢
2. ¿Con qué se hashean las contraseñas? 🟢
3. ¿Qué es la sal y para qué sirve? 🟢
4. ¿Qué es el sobre criptográfico? 🟢
5. ¿Qué tres niveles de cifrado en reposo existen? 🟢
6. ¿Por qué SHA-256 no sirve para contraseñas? 🟡
7. ¿Cómo están guardados los Secret de Kubernetes? 🟡
8. ¿Qué diferencia hay entre sal y pimienta? 🟡
9. ¿Qué son las credenciales dinámicas? 🟡
10. ¿Qué es el problema del secreto cero y cómo se resuelve hoy? 🟡
11. ¿Por qué `Random` no sirve para generar un identificador de sesión? 🟡
12. ¿Qué es un modo de cifrado autenticado y por qué importa? 🟡
13. ¿Cuál es el primer paso ante un secreto filtrado, y por qué? 🟠
14. ¿Contra qué NO protege el cifrado de disco? 🟠
15. ¿Qué precio tiene cifrar campo a campo? 🟠
16. ¿Cómo se busca por un campo cifrado? 🟠
17. ¿Por qué rotar la clave maestra no obliga a recifrar los datos? 🟠
18. ¿Cómo se migra de bcrypt a Argon2id sin invalidar las contraseñas? 🟠
19. ¿Por qué comparar un token con `equals` es un problema? 🟠
20. ¿Cuál es la medida real del éxito en gestión de secretos? 🟠
21. Diseña la gestión de secretos de una plataforma bancaria en Kubernetes:
    credenciales de base de datos, claves de firma y certificados. 🔴
22. Hay que guardar el número de tarjeta para poder cobrar recurrentemente, y
    además buscar por los últimos cuatro dígitos. Diseña el almacenamiento. 🔴
23. Alguien subió la contraseña de producción al repositorio hace tres meses.
    Describe el procedimiento completo. 🔴

---

**Anterior:** [`05` — mTLS, zero-trust y service mesh](05-mtls-zero-trust-y-mesh.md) ·
**Siguiente:** [`07` — Simulación de entrevista](07-simulacion-de-entrevista.md) ·
**Relacionado:** [`03` — OAuth2, OIDC y JWT](03-oauth2-oidc-y-jwt.md)
