# rescatado de la sesión 5c52573d, 2026-10-05T16:27:32Z · Inspect paramiko prefetch semantics
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c "pip install -q --root-user-action=ignore paramiko==5.0.0 >/dev/null 2>&1; python - <<'EOF'
import inspect, paramiko.sftp_file as f
src = inspect.getsource(f.SFTPFile.prefetch)
print(src[:1600])
print('ctx:', hasattr(paramiko.SFTPClient, '__enter__'))
EOF"
