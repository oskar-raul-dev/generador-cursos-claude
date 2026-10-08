"""Pide una URL cada 100 ms y reporta las ventanas sin 200 (para medir cortes)."""
import sys, time, urllib.request
url, seconds = sys.argv[1], float(sys.argv[2])
start = time.time(); bad_since = None; windows = []; total = ok = 0
while time.time() - start < seconds:
    t = time.time()
    try:
        code = urllib.request.urlopen(url, timeout=1).status
    except urllib.error.HTTPError as e:
        code = e.code
    except Exception:
        code = 0
    total += 1
    if code == 200:
        ok += 1
        if bad_since is not None:
            windows.append((bad_since - start, t - bad_since)); bad_since = None
    elif bad_since is None:
        bad_since = t
    time.sleep(max(0, 0.1 - (time.time() - t)))
if bad_since is not None:
    windows.append((bad_since - start, time.time() - bad_since))
print(f"{url}: {ok}/{total} con 200; cortes: " + (", ".join(f"desde {a:.1f} s, {d:.1f} s" for a, d in windows) or "ninguno"))
