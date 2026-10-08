"""Qué son de verdad los 478 puntos de MediaPipe: una malla ajustada, no mediciones; con su estabilidad, su espejo y lo que inventa."""

import pathlib
import urllib.request

import cv2
import mediapipe as mp
import numpy as np
from mediapipe.tasks.python import BaseOptions, vision
from skimage import data

MODELS = pathlib.Path("modelos")
LANDMARKER = "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task"
YUNET = "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx"


def fetch(url):
    MODELS.mkdir(exist_ok=True)
    path = MODELS / url.rsplit("/", 1)[1]
    if not path.exists():
        urllib.request.urlretrieve(url, path)
    return str(path)


landmarker = vision.FaceLandmarker.create_from_options(vision.FaceLandmarkerOptions(
    base_options=BaseOptions(model_asset_path=fetch(LANDMARKER)),
    output_face_blendshapes=True, output_facial_transformation_matrixes=True, num_faces=1))

# Índices de la malla canónica de MediaPipe (fijos: el punto 1 es siempre la punta de la nariz)
EYE_OUT_R, EYE_OUT_L, NOSE, MOUTH_R, MOUTH_L, CHIN = 33, 263, 1, 61, 291, 152
IRIS_R, IRIS_L = 468, 473                             # centros de iris: los diez últimos puntos son de los ojos


def mesh(bgr):
    """Los puntos en píxeles (x, y) y la profundidad relativa z; None si no hay rostro."""
    result = landmarker.detect(mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)))
    if not result.face_landmarks:
        return None, result
    h, w = bgr.shape[:2]
    pts = np.array([(p.x * w, p.y * h, p.z * w) for p in result.face_landmarks[0]])
    return pts, result


face = cv2.cvtColor(data.astronaut(), cv2.COLOR_RGB2BGR)
pts, result = mesh(face)
print(f"puntos: {len(pts)} · coeficientes de expresión: {len(result.face_blendshapes[0])} · "
      f"matriz de pose: {np.array(result.facial_transformation_matrixes[0]).shape}")
iod = np.linalg.norm(pts[IRIS_R, :2] - pts[IRIS_L, :2])
print(f"distancia entre iris: {iod:.1f} px · nariz en ({pts[NOSE, 0]:.0f}, {pts[NOSE, 1]:.0f}) · "
      f"z de la nariz {pts[NOSE, 2]:.1f} (relativa, no milímetros)")
top = sorted(result.face_blendshapes[0], key=lambda c: c.score, reverse=True)[:3]
print("expresión más marcada:", ", ".join(f"{c.category_name} {c.score:.2f}" for c in top))

# Los cinco puntos de YuNet contra los ojos de la malla
yunet = cv2.FaceDetectorYN.create(fetch(YUNET), "", (512, 512))
f = yunet.detect(face)[1][0]
yunet_eyes = np.array([[f[4], f[5]], [f[6], f[7]]])
print(f"YuNet contra la malla: ojo derecho a {np.linalg.norm(yunet_eyes[0] - pts[IRIS_R, :2]):.1f} px, "
      f"izquierdo a {np.linalg.norm(yunet_eyes[1] - pts[IRIS_L, :2]):.1f} px")

# Estabilidad: la misma foto con ruido leve, diez veces; cuánto se mueve cada punto
rng = np.random.default_rng(0)
runs = [mesh(np.clip(face + rng.normal(0, 4, face.shape), 0, 255).astype(np.uint8))[0] for _ in range(10)]
jitter = np.linalg.norm(np.stack(runs)[:, :, :2] - pts[:, :2], axis=2)
print(f"\ncon ruido leve: desplazamiento mediano {np.median(jitter):.2f} px · máximo {jitter.max():.2f} px "
      f"({jitter.max() / iod:.1%} de la distancia entre iris)")

# Espejo: el punto 33 es el ojo derecho de la persona; en la foto espejada, el 33 cae donde estaba el 263
flipped, _ = mesh(cv2.flip(face, 1))
mirror_x = 512 - flipped[:, 0]
print(f"espejo: el 33 espejado queda a {abs(mirror_x[EYE_OUT_R] - pts[EYE_OUT_L, 0]):.1f} px del 263 original")

# Oclusión: se tapa la boca con un rectángulo gris; el modelo igual devuelve la boca
covered = face.copy()
y0, y1 = int(pts[NOSE, 1] + 0.25 * iod), int(pts[CHIN, 1] - 0.15 * iod)
x0, x1 = int(pts[MOUTH_R, 0] - 0.3 * iod), int(pts[MOUTH_L, 0] + 0.3 * iod)
covered[y0:y1, x0:x1] = 128
occluded, _ = mesh(covered)
moved = np.linalg.norm(occluded[[MOUTH_R, MOUTH_L], :2] - pts[[MOUTH_R, MOUTH_L], :2], axis=1)
print(f"boca tapada: {len(occluded)} puntos igual · comisuras inventadas a {moved[0]:.1f} y {moved[1]:.1f} px de las reales")

for i in range(len(pts)):
    cv2.circle(face, (int(pts[i, 0]), int(pts[i, 1])), 1, (0, 255, 0), -1)
cv2.imwrite("malla.jpg", face)
