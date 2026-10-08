"""Vídeo con modelos: detectar en cada cuadro, detectar cada N y seguir, y estabilizar; todo contra una verdad conocida."""

import pathlib
import time
import urllib.request

import cv2
import numpy as np
from skimage import data

MODELS = pathlib.Path("modelos")
YUNET = "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx"
W, H, FRAMES, FPS = 640, 360, 150, 30


def fetch(url):
    MODELS.mkdir(exist_ok=True)
    path = MODELS / url.rsplit("/", 1)[1]
    if not path.exists():
        urllib.request.urlretrieve(url, path)
    return str(path)


detector = cv2.FaceDetectorYN.create(fetch(YUNET), "", (W, H), score_threshold=0.6)

# El vídeo sintético: la cabeza de la foto de prueba cruza un fondo texturizado, y la cámara tiembla
sprite = cv2.resize(cv2.cvtColor(data.astronaut(), cv2.COLOR_RGB2BGR)[20:260, 110:350], (150, 150))
detector.setInputSize((150, 150))
fx, fy, fw, fh = detector.detect(sprite)[1][0][:4]     # la caja del rostro dentro del sprite, una sola vez
rng = np.random.default_rng(5)
background = cv2.GaussianBlur(rng.integers(40, 200, (H, W, 3), dtype=np.uint8), (0, 0), 3)
shake = np.cumsum(rng.normal(0, 2.0, (FRAMES, 2)), axis=0) * 0.6 + rng.normal(0, 3.0, (FRAMES, 2))
writer = cv2.VideoWriter("sintetico.mp4", cv2.VideoWriter_fourcc(*"mp4v"), FPS, (W, H))
truth = []
for i in range(FRAMES):
    x, y = int(40 + i * 3.0), int(100 + 40 * np.sin(i / 20))           # la trayectoria de la cabeza
    frame = background.copy()
    frame[y:y + 150, x:x + 150] = sprite
    dx, dy = shake[i]
    frame = cv2.warpAffine(frame, np.float32([[1, 0, dx], [0, 1, dy]]), (W, H), borderMode=cv2.BORDER_REFLECT)
    truth.append((x + fx + dx, y + fy + dy, fw, fh))
    writer.write(frame)
writer.release()


def iou(a, b):
    ax, ay, aw, ah = a; bx, by, bw, bh = b
    ix, iy = max(0, min(ax + aw, bx + bw) - max(ax, bx)), max(0, min(ay + ah, by + bh) - max(ay, by))
    return ix * iy / (aw * ah + bw * bh - ix * iy)


def frames():
    cap = cv2.VideoCapture("sintetico.mp4")
    while (ok := cap.read())[0]:
        yield ok[1]
    cap.release()


def run(name, every, tracker_factory=None):
    detector.setInputSize((W, H))
    boxes, tracker, start = [], None, time.perf_counter()
    for i, frame in enumerate(frames()):
        if i % every == 0 or tracker is None:
            faces = detector.detect(frame)[1]
            box = tuple(faces[0][:4]) if faces is not None else None
            if tracker_factory and box is not None:
                tracker = tracker_factory()
                tracker.init(frame, tuple(int(v) for v in box))
        else:
            ok, found = tracker.update(frame)
            box = tuple(found) if ok else None
        boxes.append(box)
    seconds = time.perf_counter() - start
    scores = [iou(b, t) if b is not None else 0.0 for b, t in zip(boxes, truth)]
    print(f"{name:<30} {len(boxes) / seconds:6.0f} cuadros/s · IoU media {np.mean(scores):.2f} · "
          f"mínima {np.min(scores):.2f} · perdidos {sum(b is None for b in boxes)}")


print(f"vídeo: {FRAMES} cuadros de {W}×{H} a {FPS} cuadros/s ({FRAMES / FPS:.0f} s)\n")
run("detectar en cada cuadro", every=1)
for name, factory in (("MIL", cv2.TrackerMIL.create), ("KCF", cv2.TrackerKCF.create), ("CSRT", cv2.TrackerCSRT.create)):
    run(f"detectar cada 10 + {name}", every=10, tracker_factory=factory)
run("detectar cada 30 + KCF", every=30, tracker_factory=cv2.TrackerKCF.create)

# Estabilizar: estimar el movimiento de la cámara con flujo óptico, suavizarlo y compensarlo
def camera_path(exclude_faces):
    prev, motion = None, []
    detector.setInputSize((W, H))
    for frame in frames():
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        mask = np.full((H, W), 255, np.uint8)
        if exclude_faces and (faces := detector.detect(frame)[1]) is not None:
            x, y, w, h = faces[0][:4].astype(int)
            mask[max(0, y - h):y + 2 * h, max(0, x - w):x + 2 * w] = 0      # sin puntos sobre el sujeto que se mueve
        if prev is not None:
            pts = cv2.goodFeaturesToTrack(prev, 300, 0.01, 10, mask=prev_mask)
            nxt, status, _ = cv2.calcOpticalFlowPyrLK(prev, gray, pts, None)
            m, _ = cv2.estimateAffinePartial2D(pts[status == 1], nxt[status == 1], method=cv2.RANSAC)
            motion.append((m[0, 2], m[1, 2]))
        prev, prev_mask = gray, mask
    return np.vstack([[0, 0], np.cumsum(motion, axis=0)])


real = shake - shake[0]
kernel = np.ones(15) / 15
jump = lambda p: np.abs(np.diff(p, axis=0)).mean()
print(f"\nsalto medio de la cámara entre cuadros, sin estabilizar: {jump(real):.2f} px")
for label, exclude in (("puntos en toda la imagen", False), ("puntos fuera del rostro", True)):
    path = camera_path(exclude)
    smooth = np.column_stack([np.convolve(np.pad(path[:, k], 7, mode="edge"), kernel, "valid") for k in range(2)])
    left = real - (path - smooth)                     # el temblor que queda después de compensar lo estimado
    print(f"{label:<26} error de la trayectoria {np.abs(path - real).mean():6.2f} px · "
          f"salto que queda {jump(left):.2f} px")
