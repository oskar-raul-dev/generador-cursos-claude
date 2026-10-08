"""Una escena de manim: una lista de cinco números se ordena por burbuja, intercambio por intercambio."""

from manim import DOWN, LEFT, RIGHT, Scene, Square, Text, VGroup


class BubbleSort(Scene):
    def construct(self):
        values = [5, 2, 4, 1, 3]
        boxes = VGroup(*[VGroup(Square(side_length=1), Text(str(v))) for v in values]).arrange(RIGHT, buff=0.2)
        self.add(boxes)
        self.add(Text("burbuja", font_size=36).next_to(boxes, DOWN))
        items = list(boxes)
        for end in range(len(values) - 1, 0, -1):
            for i in range(end):
                if values[i] > values[i + 1]:
                    values[i], values[i + 1] = values[i + 1], values[i]
                    a, b = items[i], items[i + 1]
                    self.play(a.animate.move_to(b.get_center()), b.animate.move_to(a.get_center()), run_time=0.4)
                    items[i], items[i + 1] = b, a
        self.wait(0.5)
