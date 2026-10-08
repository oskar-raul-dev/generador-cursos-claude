# rescatado de la sesión 5c52573d, 2026-10-05T17:19:51Z · Check bcrypt 5 behaviour with long passwords
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q bcrypt==5.0.0 2>/dev/null; python -c "
import bcrypt
try:
    bcrypt.hashpw(b\"x\"*80, bcrypt.gensalt()); print(\"sin error\")
except Exception as e: print(type(e).__name__, e)
"'
