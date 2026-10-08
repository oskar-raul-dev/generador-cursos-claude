"""Pide una URL cada 100 ms durante N segundos; cuenta respuestas por código y las ventanas sin 200."""
import sys, time, urllib.request, collections
url, seconds = sys.argv[1], float(sys.argv[2])
codes = collections.Counter(); start = time.time(); bad_since = None; windows = []
while time.time() - start < seconds:
    t = time.time()
    try:
        code = urllib.request.urlopen(url, timeout=2).status
    except urllib.error.HTTPError as e:
        code = e.code
    except Exception as e:
        code = type(e).__name__
    codes[code] += 1
    if code == 200:
        if bad_since is not None:
            windows.append((bad_since - start, t - bad_since)); bad_since = None
    elif bad_since is None:
        bad_since = t
    time.sleep(max(0, 0.1 - (time.time() - t)))
if bad_since is not None:
    windows.append((bad_since - start, time.time() - bad_since))
total = sum(codes.values()); bad = total - codes[200]
print(f"{total} peticiones; {bad} sin 200 ({100*bad/total:.1f} %); por código: {dict(codes)}; cortes: " + (", ".join(f"desde {a:.1f} s, {d:.1f} s" for a, d in windows) or "ninguno"))
