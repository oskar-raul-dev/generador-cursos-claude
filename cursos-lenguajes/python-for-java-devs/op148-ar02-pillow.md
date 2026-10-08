# 🖼️ ar02 — Pillow

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 2 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Las fotos llegan del teléfono: grandes, de lado y con las coordenadas de dónde se tomaron. Antes de mostrarlas en una página o adjuntarlas a un correo, hay que
hacer tres cosas: reducirlas, enderezarlas y quitarles los metadatos que no deberían viajar. **Pillow** es la biblioteca de imágenes de Python desde hace quince años
(el sucesor de PIL), y hace las tres; la pregunta es si las hace **por defecto**, y la respuesta es que no del todo.

La sección arma un *pipeline* de miniaturas sobre una imagen de muestra sintética —un degradado con una palabra, de 4000×3000, marcada "de lado" en su EXIF y con
coordenadas GPS—, y mide lo que importa: cuánto ahorra `draft` al decodificar, qué pasa si no se aplica la orientación, qué formato de salida rinde más, y por dónde se
escapa el GPS.

---

## 🧠 2. El modelo

| Paso | Qué hace | El error si se omite |
|---|---|---|
| `Image.open` | Lee el encabezado; los píxeles, cuando se necesitan | — |
| `img.draft("RGB", (800, 800))` | Le pide al decodificador JPEG que reduzca **mientras lee** (por 2, 4 u 8) | Decodificar 12 megapíxeles para tirar 11 |
| `ImageOps.exif_transpose` | Rota según la etiqueta `Orientation` y la quita | Miniaturas acostadas |
| `img.thumbnail((800, 800))` | Reduce en el lugar, conservando la proporción | — |
| `img.save(..., exif=...)` | Guarda; **sin** `exif=`, no copia los metadatos | Con `exif=` del original, el GPS viaja |

### Esto sí funciona igual

Es `ImageIO.read` y `Graphics2D.drawImage` con un `AffineTransform`, o Thumbnailator en Java: abrir, transformar, escribir. La orientación EXIF tampoco la aplica
`ImageIO` sola; quien vino de Java ya pasó por la foto acostada.

---

## 💻 3. El ejemplo que corre

`miniaturas.py`:

```python
"""Un pipeline de miniaturas con Pillow: orientación EXIF, GPS que se va, draft y formatos de salida."""

import io
import time

from PIL import ExifTags, Image, ImageDraw, ImageOps, features

# Una foto de muestra sintética de 4000×3000, "tomada con el teléfono de lado" y con coordenadas GPS
photo = Image.radial_gradient("L").resize((4000, 3000)).convert("RGB")
ImageDraw.Draw(photo).text((100, 100), "ARRIBA", fill="red", font_size=400)
exif = Image.Exif()
exif[ExifTags.Base.Orientation] = 6                       # "rotar 90° a la derecha para ver bien"
exif[ExifTags.Base.Make] = "Teléfono de prueba"
exif.get_ifd(ExifTags.IFD.GPSInfo).update({ExifTags.GPS.GPSLatitudeRef: "N", ExifTags.GPS.GPSLatitude: (4.0, 41.0, 53.0)})
photo.save("muestra.jpg", quality=92, exif=exif)


def thumbnail(path, use_draft):
    start = time.perf_counter()
    with Image.open(path) as img:
        if use_draft:
            img.draft("RGB", (800, 800))                  # el decodificador JPEG reduce mientras lee
        img = ImageOps.exif_transpose(img)               # aplica la orientación y la quita del EXIF
        img.thumbnail((800, 800))
    return img, (time.perf_counter() - start) * 1000


plain, ms_plain = thumbnail("muestra.jpg", use_draft=False)
fast, ms_draft = thumbnail("muestra.jpg", use_draft=True)
print(f"miniatura sin draft {ms_plain:5.0f} ms · con draft {ms_draft:4.0f} ms · tamaño {fast.size}")

with Image.open("muestra.jpg") as original:
    naive = original.copy(); naive.thumbnail((800, 800))
    print(f"sin exif_transpose: {naive.size} (acostada) · con: {fast.size} (de pie)")
    print("GPS en el original:", bool(original.getexif().get_ifd(ExifTags.IFD.GPSInfo)))

for fmt, options in (("JPEG", {"quality": 85}), ("WEBP", {"quality": 80}), ("AVIF", {"quality": 60}), ("PNG", {})):
    if fmt == "AVIF" and not features.check("avif"):
        print("AVIF: no disponible en esta compilación de Pillow"); continue
    buffer = io.BytesIO()
    start = time.perf_counter()
    fast.save(buffer, fmt, **options)
    elapsed = (time.perf_counter() - start) * 1000
    buffer.seek(0)
    gps = bool(Image.open(buffer).getexif().get_ifd(ExifTags.IFD.GPSInfo))
    print(f"{fmt:<5} {buffer.getbuffer().nbytes / 1024:6.1f} KB · {elapsed:5.1f} ms · GPS: {gps}")

# Conservar el EXIF "para no perder la fecha" arrastra también el GPS
buffer = io.BytesIO()
fast.save(buffer, "JPEG", quality=85, exif=fast.getexif())
buffer.seek(0)
print("JPEG con exif=fast.getexif(): GPS:", bool(Image.open(buffer).getexif().get_ifd(ExifTags.IFD.GPSInfo)))
```

```bash
pip install Pillow
python3 miniaturas.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre; los tamaños, de una imagen sintética que comprime mucho mejor que una foto):

```text
miniatura sin draft    80 ms · con draft   41 ms · tamaño (600, 800)
sin exif_transpose: (800, 600) (acostada) · con: (600, 800) (de pie)
GPS en el original: True
JPEG    23.3 KB ·   7.2 ms · GPS: False
WEBP     5.4 KB ·  57.5 ms · GPS: False
AVIF     4.0 KB ·  35.7 ms · GPS: False
PNG     79.1 KB ·  30.0 ms · GPS: False
JPEG con exif=fast.getexif(): GPS: True
```

`draft` parte el tiempo a la mitad (80 → 41 ms) porque el decodificador entrega la imagen ya reducida a un cuarto. Sin `exif_transpose`, la miniatura sale **800×600,
acostada**: los píxeles del JPEG están de lado y solo la etiqueta dice cómo verlos. Los formatos: AVIF da el archivo más chico (4,0 KB) y JPEG el más rápido de
escribir (7,2 ms); WebP queda en medio en tamaño y es el más lento. Ninguno lleva el GPS, porque `save` sin `exif=` no copia metadatos. Pero la última línea es
la trampa: guardar con `exif=` "para no perder la fecha de la foto" **se lleva también las coordenadas**.

**Detalles con intención**

- **`draft`** solo funciona con JPEG (y en parte con PCD), antes de cargar los píxeles, y reduce por potencias de dos: pide al menos el tamaño indicado.
- **`exif_transpose`** devuelve una imagen nueva, ya rotada, y borra la etiqueta `Orientation` para que nadie la vuelva a aplicar.
- **`features.check("avif")`**: las ruedas oficiales de Pillow 12 traen AVIF (en esta corrida, sí); una compilación propia puede no tenerlo.
- **La imagen es sintética** (un degradado con texto): los tamaños comparan formatos entre sí, no predicen lo que pesará una foto real.

---

## ⚠️ 4. Lo que se rompe

**Conservar el EXIF entero.** Fecha, cámara… y GPS. Se copian solo las etiquetas que se quieren (`exif = Image.Exif(); exif[ExifTags.Base.DateTime] = …`) o se borra la
sección GPS (`del exif[ExifTags.IFD.GPSInfo]`) antes de guardar.

**La bomba de descompresión.** Una imagen de 50.000×50.000 píxeles pesa unos kilobytes comprimida y gigas en memoria. Pillow avisa por encima de
`Image.MAX_IMAGE_PIXELS` (unos 89 millones) y falla al doble; no se sube ese límite para imágenes que manda un usuario.

**El modo de color.** Un PNG con transparencia (`RGBA`) no se guarda como JPEG: `OSError: cannot write mode RGBA as JPEG`. Se convierte a `RGB` sobre un fondo.

**El perfil de color que se pierde.** Las fotos de teléfonos recientes vienen en Display P3; guardar sin `icc_profile=` las deja con colores lavados en el navegador.

---

## ⚖️ 5. Cuándo NO usarlo

**Para miles de imágenes por minuto.** `pyvips` (libvips) procesa por bloques con poca memoria y es varias veces más rápido en *pipelines* grandes.

**Si el servicio ya tiene un CDN que redimensiona.** Las imágenes se suben una vez y el CDN entrega cada tamaño.

**Para visión por computador.** Detección, segmentación o filtros complejos son trabajo de OpenCV o scikit-image (`ar03`).

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las ocho líneas, y por qué la miniatura sin `exif_transpose` sale acostada.
2. Repite con una foto tuya (sin datos sensibles). **Criterio:** la tabla de formatos con una foto real, y cuánto cambia contra la sintética.
3. Guarda la miniatura conservando solo la fecha del EXIF. **Criterio:** la fecha está y el GPS no.

**🟡 Intermedio (4–6)**

4. Procesa una carpeta de 200 imágenes con `ProcessPoolExecutor`. **Criterio:** el tiempo con 1 y con 8 procesos.
5. Abre un PNG `RGBA` y guárdalo como JPEG sobre fondo blanco. **Criterio:** sin error, y sin bordes negros donde había transparencia.
6. Compara la calidad de JPEG 85 y AVIF 60 con una métrica (SSIM de scikit-image). **Criterio:** el número de cada uno.

**🟠 Difícil (7–9)**

7. Construye una imagen de 20.000×20.000 en un PNG y ábrela. **Criterio:** la advertencia de bomba de descompresión, y cómo la conviertes en error.
8. Conserva el perfil ICC al hacer la miniatura de una foto en Display P3. **Criterio:** la miniatura se ve igual que el original en el navegador.
9. Mide el mismo *pipeline* con `pyvips`. **Criterio:** tiempo y memoria máxima contra Pillow, con 200 imágenes.

**🔴 Muy difícil (10)**

10. Diseña el servicio de subida de imágenes de un sistema. **Criterio:** una página. *Rúbrica:* (a) el *pipeline* con sus pasos; (b) qué metadatos se conservan y por
    qué; (c) los límites contra bombas y archivos falsos; (d) los formatos de salida, con números.

---

## 📚 7. Referencias

**Documentación oficial**

- Pillow: https://pillow.readthedocs.io/en/stable/
- `ImageOps.exif_transpose`: https://pillow.readthedocs.io/en/stable/reference/ImageOps.html
- Formatos de imagen que Pillow lee y escribe: https://pillow.readthedocs.io/en/stable/handbook/image-file-formats.html

**Orden de lectura sugerido:** el tutorial de Pillow; después la página de formatos, en la sección de JPEG (`draft`, `quality`, `icc_profile`).

---

## 🚀 8. Cierre

Pillow hace las miniaturas, pero no endereza ni limpia sola: `exif_transpose` es obligatorio, `draft` parte el tiempo a la mitad, y el GPS se va solo si no se copia
el EXIF entero. AVIF da el archivo más chico, JPEG el más rápido. Y las imágenes de usuarios llegan con límites de tamaño, no con confianza.

**La señal de que quedó bien:** *"Ninguna miniatura sale acostada, ninguna lleva coordenadas, y el tamaño máximo de entrada está escrito en el código."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-02 -m "op ar02 cerrada: miniaturas con orientación, sin GPS, con draft y formatos medidos"
> ```
>
> Los commits llevan su prefijo (`op ar02: …`) y los de ejercicio su número
> (`op ar02 ej07: …`).
