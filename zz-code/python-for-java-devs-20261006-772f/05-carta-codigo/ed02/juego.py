"""Un juego de cuarenta líneas: atrapar la pelota. Con --auto juega solo, sin teclado ni pantalla, para probarlo."""

import random
import sys

import pygame

AUTO = "--auto" in sys.argv
pygame.init()
screen = pygame.display.set_mode((480, 640))
clock = pygame.time.Clock()
paddle = pygame.Rect(200, 600, 80, 12)
ball, speed, score, missed = pygame.Vector2(240, 0), 220.0, 0, 0
random.seed(3)

frames = 0
while missed < 3 and frames < 1800:                   # tres pelotas perdidas, o 30 s a 60 cuadros/s
    dt = clock.tick(60) / 1000                        # segundos desde el cuadro anterior
    for event in pygame.event.get():                  # 1. entrada
        if event.type == pygame.QUIT:
            missed = 3
    keys = pygame.key.get_pressed()
    direction = (keys[pygame.K_RIGHT] - keys[pygame.K_LEFT]) if not AUTO else (ball.x > paddle.centerx) - (ball.x < paddle.centerx)
    paddle.x = max(0, min(400, paddle.x + direction * 360 * dt))
    ball.y += speed * dt                              # 2. actualizar: todo se mueve por segundo, no por cuadro
    if paddle.collidepoint(ball):
        score, speed, ball = score + 1, speed * 1.08, pygame.Vector2(random.randint(20, 460), 0)
    elif ball.y > 640:
        missed, ball = missed + 1, pygame.Vector2(random.randint(20, 460), 0)
    screen.fill("black")                              # 3. dibujar
    pygame.draw.rect(screen, "white", paddle)
    pygame.draw.circle(screen, "orange", ball, 8)
    pygame.display.flip()
    frames += 1

print(f"puntos {score} · perdidas {missed} · {frames} cuadros · {clock.get_fps():.0f} cuadros/s · velocidad final {speed:.0f} px/s")
pygame.quit()
