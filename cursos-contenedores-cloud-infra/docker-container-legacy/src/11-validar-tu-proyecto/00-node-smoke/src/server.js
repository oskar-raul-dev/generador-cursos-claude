const http = require('http');
const fs = require('fs');
const path = require('path');

// 0.0.0.0 y no 127.0.0.1: un servidor que escucha en loopback dentro del
// contenedor no es alcanzable desde el host aunque publiques el puerto.
const host = '0.0.0.0';
const port = Number(process.env.PORT || 3000);

const server = http.createServer((req, res) => {
  const messagePath = path.join(__dirname, 'message.txt');
  const message = fs.readFileSync(messagePath, 'utf8').trim();

  res.writeHead(200, {
    'Content-Type': 'application/json'
  });

  res.end(JSON.stringify({
    ok: true,
    message,
    node: process.version,
    pid: process.pid
  }));
});

server.listen(port, host, () => {
  console.log('Servidor escuchando en http://' + host + ':' + port);
});

// Sin este handler el contenedor tarda diez segundos en morir: Docker manda
// SIGTERM, nadie lo atiende y termina aplicando SIGKILL.
process.on('SIGTERM', () => {
  console.log('SIGTERM recibido');
  server.close(() => {
    console.log('Servidor cerrado');
    process.exit(0);
  });
});
