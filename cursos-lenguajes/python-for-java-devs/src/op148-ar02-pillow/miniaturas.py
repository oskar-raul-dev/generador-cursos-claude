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
