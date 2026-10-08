"""Reconocimiento con SFace: la incrustación de 128 números, cuánto aguanta, y por qué un hash no la seudonimiza."""

import hashlib
import pathlib
import urllib.request

import cv2
import numpy as np
from skimage import data

MODELS = pathlib.Path("modelos")
YUNET = "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx"
SFACE = "https://github.com/opencv/opencv_zoo/raw/main/models/face_recognition_sface/face_recognition_sface_2021dec.onnx"
COSINE_SAME = 0.363                                   # el umbral que publica OpenCV para SFace con distancia coseno


def fetch(url):
    MODELS.mkdir(exist_ok=True)
    path = MODELS / url.rsplit("/", 1)[1]
    if not path.exists():
        urllib.request.urlretrieve(url, path)
    return str(path)


detector = cv2.FaceDetectorYN.create(fetch(YUNET), "", (0, 0), score_threshold=0.6)
recognizer = cv2.FaceRecognizerSF.create(fetch(SFACE), "")


def embed(bgr):
    """Detecta, alinea con los cinco puntos y devuelve la incrustación; None si no hay rostro."""
    detector.setInputSize((bgr.shape[1], bgr.shape[0]))
    faces = detector.detect(bgr)[1]
    if faces is None:
        return None
    aligned = recognizer.alignCrop(bgr, faces[0])     # recorte de 112×112 con los ojos en lugar fijo
    return recognizer.feature(aligned)


face = cv2.cvtColor(data.astronaut(), cv2.COLOR_RGB2BGR)
reference = embed(face)
print(f"incrustación: {reference.shape[1]} números {reference.dtype} · {reference.nbytes} bytes")

rng = np.random.default_rng(0)
h, w = face.shape[:2]
detector.setInputSize((w, h))
f = detector.detect(face)[1][0]                       # caja y cinco puntos: ojos, nariz, comisuras
(rx, ry), (lx, ly), (nx, ny), (mx1, my1), (mx2, my2) = f[4:14].reshape(5, 2).astype(int)
glasses, mask = face.copy(), face.copy()
glasses[min(ry, ly) - 18:max(ry, ly) + 18, rx - 30:lx + 30] = 15        # una franja oscura sobre los dos ojos
mask[ny + 5:int(f[1] + f[3]), int(f[0]):int(f[0] + f[2])] = 200          # un tapabocas claro, de la nariz al mentón
cv2.imwrite("oclusiones.jpg", np.hstack([glasses, mask]))
_, jpeg = cv2.imencode(".jpg", face, [cv2.IMWRITE_JPEG_QUALITY, 8])
VARIANTS = {
    "la misma foto": face,
    "más oscura (×0,4)": (face * 0.4).astype(np.uint8),
    "ruido fuerte": np.clip(face + rng.normal(0, 25, face.shape), 0, 255).astype(np.uint8),
    "JPEG calidad 8": cv2.imdecode(jpeg, cv2.IMREAD_COLOR),
    "girada 25°": cv2.warpAffine(face, cv2.getRotationMatrix2D((w / 2, h / 2), 25, 1), (w, h)),
    "en espejo": cv2.flip(face, 1),
    "rostro de 48 px": cv2.resize(cv2.resize(face, (110, 110)), (w, h)),
    "gafas oscuras": glasses,
    "tapabocas": mask,
}
print(f"\n{'variante':<20} {'coseno':>7}  ¿misma persona? (umbral {COSINE_SAME})")
for name, img in VARIANTS.items():
    vector = embed(img)
    if vector is None:
        print(f"{name:<20} {'—':>7}  no detectó rostro")
        continue
    score = recognizer.match(reference, vector, cv2.FaceRecognizerSF_FR_COSINE)
    print(f"{name:<20} {score:7.3f}  {'sí' if score >= COSINE_SAME else 'NO'}")

# Seudonimizar con un hash no sirve: dos incrustaciones de la misma persona nunca son iguales byte a byte
dark = embed(VARIANTS["más oscura (×0,4)"])
print(f"\nhash de la referencia: {hashlib.sha256(reference.tobytes()).hexdigest()[:16]}…")
print(f"hash de la oscura:     {hashlib.sha256(dark.tobytes()).hexdigest()[:16]}… (distinto)")
print(f"pero su coseno es {recognizer.match(reference, dark, cv2.FaceRecognizerSF_FR_COSINE):.3f}: el vector identifica, el hash no protege")
