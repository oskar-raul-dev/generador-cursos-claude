# rescatado de la sesión 5c52573d, 2026-10-05T21:35:14Z · List keyframe timestamps
timeout 300 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore av==19.0.1 >/dev/null 2>&1; python -c "
import av
for p in (\"muestra.mp4\", \"corte_copia.mp4\"):
    with av.open(p) as c:
        s=c.streams.video[0]
        print(p, [round(float(pk.pts*s.time_base),2) for pk in c.demux(s) if pk.is_keyframe and pk.pts is not None])"'
