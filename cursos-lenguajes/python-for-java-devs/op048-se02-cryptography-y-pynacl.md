# 🔐 se02 — `cryptography` y PyNaCl

> Python para desarrolladores Java senior · **Carta** · Track `se` — Seguridad aplicada y
> criptografía · sección 2 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta. Si leíste
> [`se01`](op047-se01-el-modelo.md), ya sabes qué pregunta contesta cada primitiva; aquí se usan.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Dos encargos del back-office de Áurea que piden criptografía de verdad, y no solo TLS:

- **Una columna que no se puede leer en un respaldo.** Las notas de seguimiento de un plan integral tienen
  información clínica. La base está protegida, pero los respaldos viajan, se copian y se restauran en
  máquinas de prueba. La columna se guarda **cifrada**, y la clave vive en otro lado. Y como toda clave, un
  día hay que **rotarla** sin descifrar y recifrar la tabla entera en una ventana de mantenimiento.
- **Un archivo que solo la central puede abrir.** Los franquiciados mandan cada mes un archivo con datos de
  sus pacientes para la liquidación. Tienen que poder **cifrarlo para Áurea** sin compartir ningún secreto
  con Áurea, y nadie más —tampoco otro franquiciado— tiene que poder abrirlo.

El primero es cifrado simétrico con rotación; el segundo, cifrado asimétrico hacia una clave pública. Las dos
bibliotecas que valen la pena para esto son **`cryptography`** (50.0.2, del 2026-09-30) y **PyNaCl** (1.6.2,
del 2026-01-01), un enlace a `libsodium` con una API que hace difícil equivocarse.

---

## 🧠 2. El modelo

| Encargo | Construcción | Biblioteca | Por qué esa |
|---|---|---|---|
| Columna cifrada con rotación | `Fernet` + `MultiFernet` | `cryptography` | Cifrado autenticado con fecha, y rotación incluida |
| Archivo cifrado para la central | Caja sellada (*sealed box*): X25519 + XSalsa20-Poly1305 | PyNaCl | El remitente no necesita ningún secreto; solo la clave pública de Áurea |
| Derivar varias claves de una maestra | HKDF | `cryptography` | Una clave por uso, sin guardar cinco claves |

**La rotación con `MultiFernet`** funciona con una lista de claves: cifra siempre con la primera (la nueva) y
descifra probando todas. Rotar es agregar una clave nueva al principio; el `rotate()` vuelve a cifrar cada
valor con la nueva sin pasar por texto claro fuera de la función, y se puede hacer fila por fila, de a poco.
Cuando ya ninguna fila usa la vieja, la vieja se retira.

**La caja sellada** usa una clave pública de Áurea. El franquiciado cifra con ella; solo la clave privada de
Áurea descifra. Ni siquiera el franquiciado puede volver a abrir lo que cifró, y el mensaje no dice quién lo
mandó: si hace falta probar el remitente, se firma además (ver `se01`).

### Tu instinto de Java dice… y esta vez se equivoca

En Java, cifrar una columna suele ser un `AttributeConverter` de JPA con `Cipher.getInstance("AES/…")` y una
clave en el `application.yml`. El reflejo es escribir lo mismo en Python con la capa `hazmat` de
`cryptography`, eligiendo modo, relleno y vector de inicialización a mano. **`Fernet` ya es eso, bien hecho**:
AES-128 en CBC con HMAC-SHA256, vector aleatorio, marca de tiempo y formato de texto seguro para guardar en
una columna. Escribir tu propia combinación es reabrir problemas que Fernet ya cerró.

---

## 💻 3. El ejemplo que corre

```bash
uv add cryptography pynacl
```

`cifrado_backoffice.py`:

```python
"""Una columna cifrada con rotación de claves, y un archivo que solo la central puede abrir."""

from cryptography.fernet import Fernet, InvalidToken, MultiFernet
from nacl.public import PrivateKey, SealedBox

# ------------------------------------------------- 1. la columna de notas, con rotación de claves

old_key, new_key = Fernet(Fernet.generate_key()), Fernet(Fernet.generate_key())

# Hasta ayer, el back-office cifraba con la clave vieja.
row = old_key.encrypt("Control de periodoncia: buena evolución".encode())
print("guardado en la columna:", row[:24], "…")

# Hoy se rota: la nueva va primero, la vieja se conserva para leer lo que falta.
keys = MultiFernet([new_key, old_key])
print("se lee con la lista:", keys.decrypt(row).decode())
rotated = keys.rotate(row)                     # recifrado con la nueva, sin salir de la función
print("ya se lee solo con la nueva:", new_key.decrypt(rotated).decode())
try:
    old_key.decrypt(rotated)
except InvalidToken:
    print("y la vieja ya no la abre")

# ------------------------------------------------- 2. el archivo del franquiciado, sellado para la central

aurea_private = PrivateKey.generate()          # vive solo en la central
aurea_public = aurea_private.public_key        # se publica: cualquiera puede cifrar con ella

monthly_file = b"documento;plan;fase;valor\n1023456789;AS-221;2;1850000\n"
sealed = SealedBox(aurea_public).encrypt(monthly_file)     # lo hace el franquiciado
print("sellado:", len(sealed), "bytes; el original tenía", len(monthly_file))
print("lo abre la central:", SealedBox(aurea_private).decrypt(sealed).decode().splitlines()[0])

other = PrivateKey.generate()                  # otro franquiciado, con su propia clave
try:
    SealedBox(other).decrypt(sealed)
except Exception as error:
    print("otro franquiciado no puede:", type(error).__name__)
```

```bash
python3 cifrado_backoffice.py
```

Salida (Python 3.14.7, 05/10/2026) (el texto cifrado cambia en cada corrida):

```text
guardado en la columna: b'gAAAAAB…' …
se lee con la lista: Control de periodoncia: buena evolución
ya se lee solo con la nueva: Control de periodoncia: buena evolución
y la vieja ya no la abre
sellado: 102 bytes; el original tenía 54
lo abre la central: documento;plan;fase;valor
otro franquiciado no puede: CryptoError
```

El sellado agrega 48 bytes —la clave pública efímera del remitente (32) y la etiqueta de autenticación
(16)—: es el costo fijo de que el franquiciado no necesite ningún secreto.

**Detalles con intención**

- **`rotate()` y no "descifrar y volver a cifrar" a mano**: el texto claro no queda en ninguna variable del
  código de la migración, y la marca de tiempo original del token se conserva.
- **Las claves de Fernet son de 32 bytes en base64 URL-safe**: se generan con `Fernet.generate_key()` y se
  guardan en un gestor de secretos (`se05`), nunca en el código ni junto a la base que cifran.
- **La clave privada de la central no sale de la central.** Si un franquiciado la necesitara para algo, el
  diseño está mal: cada uno cifra con la pública.
- **`CryptoError`** es la excepción base de PyNaCl: el descifrado con otra clave falla al autenticar, no
  devuelve basura.

---

## ⚠️ 4. Lo que se rompe

**Buscar por una columna cifrada.** `WHERE notas = …` no funciona sobre valores cifrados con vector aleatorio:
el mismo texto cifra distinto cada vez. Si hace falta buscar por igualdad (un documento, por ejemplo), se
guarda además un HMAC del valor con otra clave —un índice ciego—, y se busca por él.

**La clave en el mismo respaldo.** Una columna cifrada cuyo respaldo incluye la tabla de configuración con la
clave no está cifrada en el respaldo. La clave vive en otro sistema, con otro acceso y otro respaldo.

**Rotar sin terminar.** La rotación tiene dos mitades: agregar la clave nueva y **retirar la vieja** cuando
ninguna fila la usa. Si la segunda mitad no se hace, la lista crece y la clave vieja —quizá la que se filtró—
sigue sirviendo para leer.

**Confundir la caja sellada con una firma.** Cualquiera con la clave pública de Áurea puede mandar un archivo
sellado diciendo que es de Suba. La caja da confidencialidad, no autenticidad del remitente.

---

## ⚖️ 5. Cuándo NO usarla

**Para lo que el motor ya cifra.** Si la base y sus respaldos están cifrados en reposo por el proveedor o por el
sistema de archivos, y los respaldos nunca salen de ese entorno, cifrar la columna en la aplicación agrega
complejidad (búsqueda, rotación) para proteger contra un escenario que ya está cubierto. La columna cifrada
paga cuando el respaldo **sale** de donde se controla.

**Para contraseñas.** Una contraseña no se cifra: se resume con una función lenta hecha para eso. Es `se03`.

**`hazmat` sin una razón escrita.** Si una receta resuelve el problema, se usa la receta.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Cifra con `Fernet` y descifra con `ttl=1` después de dos segundos. **Criterio:** falla por vencimiento y
   explicas para qué sirve la marca de tiempo.
2. Agrega una tercera clave a la rotación. **Criterio:** un valor cifrado con la más vieja se lee y se rota a la
   nueva en un paso.
3. Guarda la clave pública de la central en un archivo y sella con la cargada. **Criterio:** la central abre el
   archivo sellado con la clave pública leída de disco.

**🟡 Intermedio (4–6)**

4. Busca en la documentación de `cryptography` cómo se usa HKDF para derivar dos claves —una para cifrar
   notas y otra para el índice ciego— de una maestra. **Criterio:** dos claves distintas y deterministas a
   partir de la misma maestra.
5. Implementa el índice ciego para buscar pacientes por documento en una columna cifrada. **Criterio:** la
   búsqueda funciona con SQLite y el documento no aparece en claro en la base.
6. Agrega la firma del franquiciado al archivo sellado (`nacl.signing`). **Criterio:** la central verifica que
   el archivo es de Suba antes de abrirlo.

**🟠 Difícil (7–9)**

7. Escribe la migración de rotación de una tabla de 100.000 filas, de a 1.000, reanudable. **Criterio:** si se
   corta a la mitad, al relanzarla sigue donde iba y ninguna fila queda ilegible.
8. Mide el costo de cifrar y descifrar una nota de 500 caracteres con `Fernet`, 100.000 veces. **Criterio:** el
   tiempo por operación con la máquina, y si importa para el back-office.
9. Demuestra el problema de cifrar sin autenticar: cifra con AES-CTR de `hazmat` y cambia un byte del texto
   cifrado. **Criterio:** el texto claro cambia de forma predecible y nadie lo detecta.

**🔴 Muy difícil (10)**

10. Diseña el cifrado de los datos clínicos del back-office. **Criterio:** un documento de una página.
    *Rúbrica:* (a) qué columnas se cifran y por qué esas; (b) dónde vive la clave y quién la puede usar; (c) el
    procedimiento de rotación con su condición para retirar la clave vieja; (d) cómo se busca lo que hace falta
    buscar sin descifrar la tabla.

---

## 📚 7. Referencias

**Documentación oficial**

- `cryptography`, Fernet y MultiFernet: https://cryptography.io/en/latest/fernet/
- `cryptography`, HKDF: https://cryptography.io/en/latest/hazmat/primitives/key-derivation-functions/
- PyNaCl, cifrado de clave pública y cajas selladas: https://pynacl.readthedocs.io/en/latest/public/
- La especificación de Fernet: https://github.com/fernet/spec/blob/master/Spec.md

**Orden de lectura sugerido:** la página de Fernet, que es corta y tiene la rotación; después la de cajas
selladas de PyNaCl.

---

## 🚀 8. Cierre

El cifrado de aplicación se hace con recetas: `Fernet` para una columna, con `MultiFernet` para rotar sin
ventana de mantenimiento, y la caja sellada de PyNaCl para que alguien cifre hacia la central sin compartir
ningún secreto. Lo que no da ninguna receta es dónde vive la clave, y esa es la mitad del trabajo.

**La señal de que quedó bien:** *"El respaldo de la base se restauró en una máquina de pruebas, y las notas
clínicas seguían ilegibles; y rotamos la clave un martes sin parar nada."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-se-fase-02 -m "op se02 cerrada: columna con MultiFernet y archivo sellado para la central"
> ```
>
> Los commits llevan su prefijo (`op se02: …`) y los de ejercicio su número
> (`op se02 ej07: …`).
