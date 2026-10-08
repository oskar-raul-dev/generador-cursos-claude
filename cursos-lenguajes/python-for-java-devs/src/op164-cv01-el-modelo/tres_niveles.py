"""El mismo problema en tres niveles: encontrar rostros con una regla de píxeles, con características (Haar) y con una red (YuNet)."""

import pathlib
import time
import urllib.request

import cv2
import numpy as np
from skimage import data

MODELS = pathlib.Path("modelos")
YUNET = "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx"
# OpenCV 5 ya no trae las cascadas dentro del paquete: viven en opencv_contrib, módulo xobjdetect
HAAR = ("https://raw.githubusercontent.com/opencv/opencv_contrib/5.x/modules/xobjdetect/data/haarcascades/"
        "haarcascade_frontalface_default.xml")


def fetch(url):
    """Baja el modelo una vez y lo deja en modelos/."""
    MODELS.mkdir(exist_ok=True)
    path = MODELS / url.rsplit("/", 1)[1]
    if not path.exists():
        urllib.request.urlretrieve(url, path)
    return str(path)


# La escena: la foto de prueba de scikit-image (dominio público, NASA) en cinco variantes, y dos imágenes sin rostro
face = cv2.cvtColor(data.astronaut(), cv2.COLOR_RGB2BGR)
rotated = cv2.warpAffine(face, cv2.getRotationMatrix2D((256, 256), 30, 1.0), (512, 512), borderValue=(90, 90, 90))
tiles = [
    ("rostro 1:1,6", cv2.resize(face, (320, 320)), True),
    ("rostro 1:3,3", cv2.resize(face, (154, 154)), True),
    ("rostro 1:6,6", cv2.resize(face, (77, 77)), True),
    ("girado 30°", cv2.resize(rotated, (240, 240)), True),
    ("espejo y oscuro", cv2.resize(cv2.flip(face, 1) // 3, (240, 240)), True),
    ("café", cv2.resize(cv2.cvtColor(data.coffee(), cv2.COLOR_RGB2BGR), (300, 200)), False),
    ("gato", cv2.resize(cv2.cvtColor(data.chelsea(), cv2.COLOR_RGB2BGR), (300, 200)), False),
]
rng = np.random.default_rng(1)
scene = rng.integers(70, 110, (720, 1400, 3), dtype=np.uint8)
boxes, x, y = [], 20, 20
for name, img, has_face in tiles:
    h, w = img.shape[:2]
    if x + w > 1380:
        x, y = 20, y + 340
    scene[y:y + h, x:x + w] = img
    boxes.append((name, x, y, w, h, has_face))
    x += w + 30


def score(name, rects, seconds):
    """Cada imagen con rostro cuenta una vez; todo lo demás (una segunda caja, o algo en el café) sobra."""
    hit = set()
    for rx, ry, rw, rh in rects:
        cx, cy = rx + rw / 2, ry + rh / 2
        inside = [b for b in boxes if b[1] <= cx < b[1] + b[3] and b[2] <= cy < b[2] + b[4]]
        if inside and inside[0][5]:
            hit.add(inside[0][0])
    missed = [b[0] for b in boxes if b[5] and b[0] not in hit]
    print(f"{name:<18} {len(rects):>4} detecciones · {len(hit)}/5 rostros · {len(rects) - len(hit):>3} sobrantes · "
          f"{seconds * 1000:5.1f} ms · no encontró: {', '.join(missed) or '—'}")


# 1. Píxeles: una regla de color de piel en YCrCb, y manchas grandes
start = time.perf_counter()
ycrcb = cv2.cvtColor(scene, cv2.COLOR_BGR2YCrCb)
mask = cv2.inRange(ycrcb, (0, 133, 77), (255, 173, 127))
mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))
n, _, stats, _ = cv2.connectedComponentsWithStats(mask)
blobs = [tuple(s[:4]) for s in stats[1:] if s[4] > 300]
score("1 regla de color", blobs, time.perf_counter() - start)

# 2. Características: la cascada de Haar de Viola y Jones (2001); en OpenCV 5, solo con opencv-contrib
gray = cv2.cvtColor(scene, cv2.COLOR_BGR2GRAY)
haar = cv2.CascadeClassifier(fetch(HAAR))
start = time.perf_counter()
found = haar.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5)
score("2 Haar", [tuple(r) for r in found], time.perf_counter() - start)

# 3. Red: YuNet, una red convolucional de 230 KB entrenada para rostros
yunet = cv2.FaceDetectorYN.create(fetch(YUNET), "", (scene.shape[1], scene.shape[0]), score_threshold=0.7)
start = time.perf_counter()
_, faces = yunet.detect(scene)
score("3 YuNet (red)", [tuple(f[:4]) for f in (faces if faces is not None else [])], time.perf_counter() - start)

print(f"\nescena {scene.shape[1]}×{scene.shape[0]} · píxeles con 'color de piel': {mask.mean() / 255:.1%}")
print(f"tamaños: modelo YuNet {pathlib.Path(fetch(YUNET)).stat().st_size / 1024:.0f} KB · "
      f"cascada Haar {pathlib.Path(fetch(HAAR)).stat().st_size / 1024:.0f} KB")
cv2.imwrite("escena.jpg", scene)
