"""Como dom.py, pero con un perfil fijo (argumento 2): para ver lo que guarda la caché del navegador."""
import re, subprocess, sys
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
p = subprocess.Popen([CHROME, "--headless=new", "--disable-gpu", "--dump-dom", "--virtual-time-budget=5000",
                      f"--user-data-dir={sys.argv[2]}", sys.argv[1]], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
try:
    out, _ = p.communicate(timeout=25)
except subprocess.TimeoutExpired:
    p.terminate(); out, _ = p.communicate()
for m in re.findall(r"<title>[^<]*</title>|<main>.*?</main>", out, re.S):
    print(m)
