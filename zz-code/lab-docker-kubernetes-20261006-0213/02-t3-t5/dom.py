"""Renderiza una página en Chrome sin interfaz, con un perfil nuevo, y devuelve <title> y <main>."""
import re, subprocess, sys, tempfile, os
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
base = os.path.dirname(os.path.abspath(__file__))
with tempfile.TemporaryDirectory(dir=base, prefix="chrome-") as prof:
    p = subprocess.Popen([CHROME, "--headless=new", "--disable-gpu", "--dump-dom", "--virtual-time-budget=5000",
                          f"--user-data-dir={prof}", sys.argv[1]], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    try:
        out, _ = p.communicate(timeout=25)
    except subprocess.TimeoutExpired:
        p.terminate(); out, _ = p.communicate()
for m in re.findall(r"<title>[^<]*</title>|<main>.*?</main>", out, re.S):
    print(m)
