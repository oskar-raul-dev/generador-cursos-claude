# Renderiza la escena en calidad baja y resume el resultado
manim -ql --disable_caching --progress_bar none escena.py BubbleSort > manim.log 2>&1
video=media/videos/escena/480p15/BubbleSort.mp4
echo "animaciones: $(grep -o 'Played [0-9]* animations' manim.log)"
echo "vídeo: $(du -k "$video" | cut -f1) KB · $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video") s · 854×480 a 15 c/s"
