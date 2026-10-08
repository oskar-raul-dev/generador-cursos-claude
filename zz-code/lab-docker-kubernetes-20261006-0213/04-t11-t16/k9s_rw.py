# Maneja k9s en un pseudo-terminal y vuelca la pantalla después de cada tecla.
import os, pty, sys, time, select, pyte, json
COLS, ROWS = 160, 40
steps = json.load(open(sys.argv[1]))   # [[teclas, segundos de espera, etiqueta], ...]
pid, fd = pty.fork()
if pid == 0:
    os.environ['TERM'] = 'xterm-256color'
    os.environ['COLUMNS'] = str(COLS); os.environ['LINES'] = str(ROWS)
    os.execvp('k9s', ['k9s', '--context', 'kind-lab', '-n', 'apps', '--logoless'])
import fcntl, termios, struct
fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
screen = pyte.Screen(COLS, ROWS); stream = pyte.ByteStream(screen)
def pump(t):
    end = time.time() + t
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.1)
        if r:
            try: stream.feed(os.read(fd, 65536))
            except OSError: return
pump(6)
for keys, wait, label in steps:
    os.write(fd, keys.encode().decode('unicode_escape').encode())
    pump(wait)
    print(f'===== {label} ({keys!r})')
    for line in screen.display:
        if line.strip(): print(line.rstrip())
os.write(fd, b'\x03'); pump(1)
