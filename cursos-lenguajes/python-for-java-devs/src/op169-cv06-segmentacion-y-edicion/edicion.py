"""Segmentar, borrar y agrandar: dos recortadores de fondo, dos rellenos y una superresolución, medidos contra la verdad."""

import pathlib
import time
import urllib.request

import cv2
import mediapipe as mp
import numpy as np
from mediapipe.tasks.python import BaseOptions, vision
from rembg import new_session, remove
from skimage import data
from skimage.metrics import peak_signal_noise_ratio as psnr

MODELS = pathlib.Path("modelos")
SELFIE = "https://storage.googleapis.com/mediapipe-models/image_segmenter/selfie_segmenter/float16/latest/selfie_segmenter.tflite"
FSRCNN = "https://github.com/Saafke/FSRCNN_Tensorflow/raw/master/models/FSRCNN_x2.pb"


def fetch(url):
    MODELS.mkdir(exist_ok=True)
    path = MODELS / url.rsplit("/", 1)[1]
    if not path.exists():
        urllib.request.urlretrieve(url, path)
    return str(path)


rgb = data.astronaut()
bgr = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)

# 1. Quitar el fondo: el segmentador de selfie de MediaPipe contra rembg con su modelo chico (u2netp)
segmenter = vision.ImageSegmenter.create_from_options(vision.ImageSegmenterOptions(
    base_options=BaseOptions(model_asset_path=fetch(SELFIE)), output_confidence_masks=True))
start = time.perf_counter()
confidence = segmenter.segment(mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)).confidence_masks[0].numpy_view()
mask_mp = confidence.squeeze() > 0.5
t_mp = time.perf_counter() - start

session = new_session("u2netp")                       # baja el modelo la primera vez, a ~/.rembg/models
remove(rgb, session=session, only_mask=True)          # la primera llamada carga la red: fuera de la medición
start = time.perf_counter()
mask_rembg = np.array(remove(rgb, session=session, only_mask=True)) > 127
t_rembg = time.perf_counter() - start
iou = (mask_mp & mask_rembg).sum() / (mask_mp | mask_rembg).sum()
print(f"fondo con MediaPipe: {mask_mp.mean():.1%} de la imagen es persona · {t_mp * 1000:.0f} ms")
print(f"fondo con rembg:     {mask_rembg.mean():.1%} de la imagen es persona · {t_rembg * 1000:.0f} ms")
print(f"coincidencia entre las dos máscaras (IoU): {iou:.2f}")
cv2.imwrite("sin_fondo.png", np.dstack([bgr, np.uint8(mask_rembg) * 255]))

# 2. Borrar: rayas sintéticas sobre la foto, y cuánto se acerca cada relleno a la foto original
damaged, scratch = bgr.copy(), np.zeros(bgr.shape[:2], np.uint8)
rng = np.random.default_rng(4)
for _ in range(25):
    p1, p2 = rng.integers(0, 512, 2), rng.integers(0, 512, 2)
    cv2.line(scratch, tuple(int(v) for v in p1), tuple(int(v) for v in p2), 255, 3)
damaged[scratch > 0] = 255
blurred = cv2.medianBlur(damaged, 9)
naive = np.where(scratch[..., None] > 0, blurred, damaged)
print(f"\nrayas: {(scratch > 0).mean():.1%} de los píxeles")
for name, img in (("sin reparar", damaged), ("mediana de 9×9", naive),
                  ("inpaint Telea", cv2.inpaint(damaged, scratch, 5, cv2.INPAINT_TELEA)),
                  ("inpaint Navier-Stokes", cv2.inpaint(damaged, scratch, 5, cv2.INPAINT_NS))):
    print(f"  {name:<22} PSNR {psnr(bgr, img):5.2f} dB")

# 3. Agrandar: reducir a la mitad y volver, con interpolación bicúbica o con una red (FSRCNN ×2)
small = cv2.resize(bgr, (256, 256), interpolation=cv2.INTER_AREA)
sr = cv2.dnn_superres.DnnSuperResImpl.create()
sr.readModel(fetch(FSRCNN))
sr.setModel("fsrcnn", 2)
start = time.perf_counter()
up_net = sr.upsample(small)
t_net = time.perf_counter() - start
up_cubic = cv2.resize(small, (512, 512), interpolation=cv2.INTER_CUBIC)
print(f"\nde 256 a 512: bicúbica PSNR {psnr(bgr, up_cubic):.2f} dB · FSRCNN PSNR {psnr(bgr, up_net):.2f} dB ({t_net * 1000:.0f} ms)")
