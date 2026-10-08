"""Un control de salida: nada se publica con un rostro reconocible ni con coordenadas GPS. Y desde qué pixelado deja de reconocerse."""

import pathlib
import sys
import urllib.request

import cv2
import numpy as np
from PIL import ExifTags, Image
from skimage import data

MODELS = pathlib.Path("modelos")
YUNET = "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx"
SFACE = "https://github.com/opencv/opencv_zoo/raw/main/models/face_recognition_sface/face_recognition_sface_2021dec.onnx"


def fetch(url):
    MODELS.mkdir(exist_ok=True)
    path = MODELS / url.rsplit("/", 1)[1]
    if not path.exists():
        urllib.request.urlretrieve(url, path)
    return str(path)


detector = cv2.FaceDetectorYN.create(fetch(YUNET), "", (0, 0), score_threshold=0.5)
recognizer = cv2.FaceRecognizerSF.create(fetch(SFACE), "")


def faces_in(bgr):
    detector.setInputSize((bgr.shape[1], bgr.shape[0]))
    found = detector.detect(bgr)[1]
    return [] if found is None else list(found)


def pixelate(bgr, block):
    h, w = bgr.shape[:2]
    return cv2.resize(cv2.resize(bgr, (w // block, h // block), interpolation=cv2.INTER_AREA), (w, h),
                      interpolation=cv2.INTER_NEAREST)


# La carpeta "para publicar", armada con casos sintéticos y la foto de prueba de scikit-image
out = pathlib.Path("para_publicar")
out.mkdir(exist_ok=True)
face = cv2.cvtColor(data.astronaut(), cv2.COLOR_RGB2BGR)
coffee = cv2.cvtColor(data.coffee(), cv2.COLOR_RGB2BGR)
x, y, w, h = faces_in(face)[0][:4].astype(int)
face_pix16 = face.copy(); face_pix16[y:y + h, x:x + w] = pixelate(face[y:y + h, x:x + w], 16)
face_pix4 = face.copy(); face_pix4[y:y + h, x:x + w] = pixelate(face[y:y + h, x:x + w], 4)
small = np.full((1080, 1920, 3), 120, np.uint8); small[500:540, 900:940] = cv2.resize(face[40:240, 130:330], (40, 40))
cv2.imwrite(str(out / "retrato.jpg"), face)
cv2.imwrite(str(out / "cafe.jpg"), coffee)
cv2.imwrite(str(out / "gato.jpg"), cv2.cvtColor(data.chelsea(), cv2.COLOR_RGB2BGR))
cv2.imwrite(str(out / "rostro_pixelado_16.jpg"), face_pix16)
cv2.imwrite(str(out / "rostro_pixelado_4.jpg"), face_pix4)
cv2.imwrite(str(out / "rostro_de_40px_en_1080p.jpg"), small)
exif = Image.Exif()
exif.get_ifd(ExifTags.IFD.GPSInfo).update({ExifTags.GPS.GPSLatitudeRef: "N", ExifTags.GPS.GPSLatitude: (4.0, 36.0, 14.0)})
Image.fromarray(data.coffee()).save(out / "cafe_con_gps.jpg", exif=exif)


def check(path):
    """Las razones para no publicar una imagen; una lista vacía significa que puede salir."""
    reasons = []
    with Image.open(path) as img:
        if img.getexif().get_ifd(ExifTags.IFD.GPSInfo):
            reasons.append("coordenadas GPS en el EXIF")
    found = faces_in(cv2.imread(str(path)))
    if found:
        reasons.append(f"{len(found)} rostro(s), confianza {max(f[-1] for f in found):.2f}")
    return reasons


blocked = 0
print(f"{'archivo':<28} veredicto")
for path in sorted(out.glob("*.jpg")):
    reasons = check(path)
    blocked += bool(reasons)
    print(f"{path.name:<28} {'BLOQUEADA: ' + '; '.join(reasons) if reasons else 'puede salir'}")

# ¿Desde qué pixelado deja de reconocerse? La referencia es el rostro sin tocar
reference = recognizer.feature(recognizer.alignCrop(face, faces_in(face)[0]))
print(f"\nrostro de {w} px de ancho · pixelado   ¿lo detecta?   coseno con el original")
for block in (2, 4, 8, 12, 16):
    img = face.copy(); img[y:y + h, x:x + w] = pixelate(face[y:y + h, x:x + w], block)
    found = faces_in(img)
    if not found:
        print(f"bloques de {block:>2} px ({w // block:>2} por lado)    no             —")
        continue
    score = recognizer.match(reference, recognizer.feature(recognizer.alignCrop(img, found[0])), cv2.FaceRecognizerSF_FR_COSINE)
    print(f"bloques de {block:>2} px ({w // block:>2} por lado)    sí          {score:6.3f} {'(misma persona)' if score >= 0.363 else ''}")

sys.exit(1 if blocked else 0)                         # en CI o en un pre-commit, el código de salida detiene la publicación
