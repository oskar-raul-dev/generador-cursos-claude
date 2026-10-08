"""Morphing desde cero: puntos, triangulación de Delaunay, una transformación afín por triángulo e interpolación."""

import time

import cv2
import numpy as np
from scipy.spatial import Delaunay

SIZE = 400


def draw_face(width, height, eye_y, eye_r, smile, skin):
    """Un rostro dibujado y sus puntos de referencia, que se conocen exactos porque los pone el código."""
    img = np.full((SIZE, SIZE, 3), 235, np.uint8)
    c = (SIZE // 2, SIZE // 2)
    cv2.ellipse(img, c, (width, height), 0, 0, 360, skin, -1)
    pts = [(c[0] + width * np.cos(t), c[1] + height * np.sin(t)) for t in np.linspace(0, 2 * np.pi, 12, endpoint=False)]
    for side in (-1, 1):                              # ojos: blanco, pupila negra, cuatro puntos y el centro
        ex, ey = c[0] + side * width * 0.42, c[1] - eye_y
        cv2.ellipse(img, (int(ex), int(ey)), (eye_r * 2, eye_r), 0, 0, 360, (255, 255, 255), -1)
        cv2.circle(img, (int(ex), int(ey)), eye_r - 2, (20, 20, 20), -1)
        pts += [(ex - eye_r * 2, ey), (ex + eye_r * 2, ey), (ex, ey - eye_r), (ex, ey + eye_r), (ex, ey)]
    nose = [(c[0], c[1] - 10), (c[0] - 12, c[1] + 25), (c[0] + 12, c[1] + 25)]
    cv2.fillPoly(img, [np.int32(nose)], (int(skin[0] * 0.8), int(skin[1] * 0.8), int(skin[2] * 0.8)))
    pts += nose
    mouth_y = c[1] + height * 0.5
    mouth = [(c[0] - 45, mouth_y), (c[0] - 20, mouth_y + smile), (c[0], mouth_y + smile * 1.2),
             (c[0] + 20, mouth_y + smile), (c[0] + 45, mouth_y)]
    cv2.polylines(img, [np.int32(mouth)], False, (40, 40, 160), 5)
    pts += mouth
    edge = SIZE - 1                                   # bordes y esquinas: la triangulación cubre toda la imagen
    pts += [(0, 0), (edge / 2, 0), (edge, 0), (edge, edge / 2), (edge, edge), (edge / 2, edge), (0, edge), (0, edge / 2)]
    return img, np.float32(pts)


img_a, pts_a = draw_face(120, 140, eye_y=30, eye_r=10, smile=0, skin=(150, 190, 230))
img_b, pts_b = draw_face(105, 165, eye_y=55, eye_r=14, smile=25, skin=(110, 150, 200))
triangles = Delaunay((pts_a + pts_b) / 2).simplices   # una sola triangulación, sobre el promedio, para los dos
print(f"puntos: {len(pts_a)} · triángulos: {len(triangles)}")


def warp_triangle(src, dst, tri_src, tri_dst):
    """Deforma un triángulo de src sobre el lugar de tri_dst en dst, con una afín calculada en su caja."""
    xs, ys, ws, hs = cv2.boundingRect(tri_src)
    xd, yd, wd, hd = cv2.boundingRect(tri_dst)
    local_src = np.float32(tri_src - (xs, ys))
    local_dst = np.float32(tri_dst - (xd, yd))
    affine = cv2.getAffineTransform(local_src, local_dst)
    patch = cv2.warpAffine(src[ys:ys + hs, xs:xs + ws], affine, (wd, hd), flags=cv2.INTER_LINEAR,
                           borderMode=cv2.BORDER_REFLECT_101)
    mask = np.zeros((hd, wd, 3), np.float32)
    cv2.fillConvexPoly(mask, np.int32(local_dst), (1, 1, 1), cv2.LINE_AA)
    region = dst[yd:yd + hd, xd:xd + wd]
    region[:] = region * (1 - mask) + patch * mask


def morph(alpha):
    target = np.float32((1 - alpha) * pts_a + alpha * pts_b)   # 1. interpolar la geometría (float32: lo pide OpenCV)
    warped_a, warped_b = np.zeros((SIZE, SIZE, 3), np.float32), np.zeros((SIZE, SIZE, 3), np.float32)
    for t in triangles:                               # 2. llevar cada imagen a esa geometría, triángulo por triángulo
        warp_triangle(img_a.astype(np.float32), warped_a, pts_a[t], target[t])
        warp_triangle(img_b.astype(np.float32), warped_b, pts_b[t], target[t])
    return np.uint8(np.clip((1 - alpha) * warped_a + alpha * warped_b, 0, 255))   # 3. y recién ahí mezclar color


def dissolve(alpha):
    return np.uint8((1 - alpha) * img_a + alpha * img_b)


def pupils(img):
    """Cuántas pupilas hay: manchas oscuras y sin rojo (la boca es roja). Un rostro bien formado tiene dos."""
    b, g, r = cv2.split(img.astype(np.int16))
    dark = (cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) < 120) & (r - g < 60)
    n, _, stats, _ = cv2.connectedComponentsWithStats(np.uint8(dark))
    return sum(1 for s in stats[1:] if s[4] > 30)


start = time.perf_counter()
frames = [morph(a) for a in np.linspace(0, 1, 11)]
per_frame = (time.perf_counter() - start) / 11 * 1000
print(f"11 cuadros en {per_frame:.0f} ms por cuadro")
print(f"extremos: α=0 difiere de A en {np.abs(frames[0].astype(int) - img_a).mean():.2f} · "
      f"α=1 difiere de B en {np.abs(frames[-1].astype(int) - img_b).mean():.2f} (niveles de gris, de 255)")
print(f"pupilas en A y en B: {pupils(img_a)} y {pupils(img_b)} · a α=0,5: fundido cruzado {pupils(dissolve(0.5))} · morphing {pupils(frames[5])}")

# Con triangulaciones distintas para A y B, los triángulos ya no se corresponden
wrong = Delaunay(pts_b).simplices
same = {tuple(sorted(t)) for t in triangles} & {tuple(sorted(t)) for t in Delaunay(pts_a).simplices} & {tuple(sorted(t)) for t in wrong}
print(f"triángulos que A, B y el promedio comparten si cada uno triangula por su cuenta: {len(same)} de {len(triangles)}")

strip = np.hstack([img_a, dissolve(0.5), frames[5], img_b])
cv2.imwrite("comparacion.png", strip)
cv2.imwrite("secuencia.png", np.hstack(frames[::2]))
