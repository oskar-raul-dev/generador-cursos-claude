"""Tres detectores de rostros contra la escala y el giro, y un detector de códigos QR que no necesita modelo."""

import pathlib
import time
import urllib.request

import cv2
import mediapipe as mp
import numpy as np
from mediapipe.tasks.python import BaseOptions, vision
from skimage import data

MODELS = pathlib.Path("modelos")
URLS = {
    "yunet": "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx",
    "haar": "https://raw.githubusercontent.com/opencv/opencv_contrib/5.x/modules/xobjdetect/data/haarcascades/"
            "haarcascade_frontalface_default.xml",
    "blaze": "https://storage.googleapis.com/mediapipe-models/face_detector/blaze_face_short_range/float16/1/"
             "blaze_face_short_range.tflite",
}


def fetch(key):
    MODELS.mkdir(exist_ok=True)
    path = MODELS / URLS[key].rsplit("/", 1)[1]
    if not path.exists():
        urllib.request.urlretrieve(URLS[key], path)
    return str(path)


haar = cv2.CascadeClassifier(fetch("haar"))
yunet = cv2.FaceDetectorYN.create(fetch("yunet"), "", (640, 640), score_threshold=0.7)
blaze = vision.FaceDetector.create_from_options(
    vision.FaceDetectorOptions(base_options=BaseOptions(model_asset_path=fetch("blaze")), min_detection_confidence=0.5))

DETECTORS = {
    "Haar": lambda img: len(haar.detectMultiScale(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY), 1.1, 5)),
    "YuNet": lambda img: 0 if (f := yunet.detect(img)[1]) is None else len(f),
    "BlazeFace (MediaPipe)": lambda img: len(blaze.detect(
        mp.Image(image_format=mp.ImageFormat.SRGB, data=cv2.cvtColor(img, cv2.COLOR_BGR2RGB))).detections),
}

face = cv2.cvtColor(data.astronaut(), cv2.COLOR_RGB2BGR)


def canvas(size, angle=0):
    """La foto de prueba de lado `size`, girada `angle` grados, en el centro de un lienzo gris de 640×640."""
    img = cv2.resize(face, (size, size))
    if angle:
        m = cv2.getRotationMatrix2D((size / 2, size / 2), angle, 1.0)
        img = cv2.warpAffine(img, m, (size, size), borderValue=(90, 90, 90))
    out = np.full((640, 640, 3), 90, np.uint8)
    o = (640 - size) // 2
    out[o:o + size, o:o + size] = img
    return out


SIZES, ANGLES = (512, 320, 160, 96, 64, 48, 32), (0, 15, 30, 45, 60, 90)
print(f"{'detector':<22} {'lado más chico':>15} {'giro mayor':>12} {'ms por imagen':>14}")
for name, detect in DETECTORS.items():
    sizes = [s for s in SIZES if detect(canvas(s)) == 1]
    angles = [a for a in ANGLES if detect(canvas(320, a)) == 1]
    img = canvas(160)
    start = time.perf_counter()
    for _ in range(20):
        detect(img)
    ms = (time.perf_counter() - start) / 20 * 1000
    print(f"{name:<22} {min(sizes, default=0):>12} px {max(angles, default=0):>10}° {ms:>12.1f}")
    print(f"{'':<22} un rostro, exacto, en: {sizes} px · {angles}°")

# Códigos: el nivel de píxeles alcanza cuando el objeto se diseñó para ser leído por una máquina
qr = cv2.QRCodeEncoder.create().encode("AUREA-CHAPINERO-0042")
qr = cv2.resize(qr, None, fx=6, fy=6, interpolation=cv2.INTER_NEAREST)
reader = cv2.QRCodeDetector()
print("\nQR con 'AUREA-CHAPINERO-0042':")
for label, img in (
    ("derecho", qr),
    ("girado 37°", cv2.warpAffine(qr, cv2.getRotationMatrix2D((qr.shape[1] / 2, qr.shape[0] / 2), 37, 0.7), qr.shape[::-1],
                                  borderValue=255)),
    ("desenfocado 5×5", cv2.GaussianBlur(qr, (5, 5), 0)),
    ("desenfocado 9×9", cv2.GaussianBlur(qr, (9, 9), 0)),
):
    text, _, _ = reader.detectAndDecode(cv2.copyMakeBorder(img, 40, 40, 40, 40, cv2.BORDER_CONSTANT, value=255))
    print(f"  {label:<18} → {text or '(no leído)'}")
