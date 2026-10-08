'use strict';

const http = require('http');

const host = process.env.HOST || '0.0.0.0';
const port = Number(process.env.PORT || 3000);

const server = http.createServer(function (req, res) {
  console.log(new Date().toISOString(), req.method, req.url);
  res.statusCode = 200;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.end(JSON.stringify({
    ok: true,
    node: process.version,
    pid: process.pid
  }) + '\n');
});

server.listen(port, host, function () {
  console.log('Servidor escuchando en http://' + host + ':' + port);
  console.log('Node:', process.version, '· PID:', process.pid);
});

// guardia: SIGTERM y SIGINT pueden llegar los dos, o dos veces
let shuttingDown = false;

function shutdown(signal) {
  if (shuttingDown) { return; }
  shuttingDown = true;

  console.log('Recibida', signal, '- cerrando servidor...');

  server.close(function () {
    console.log('Servidor cerrado. Adiós.');
    process.exit(0);
  });

  // red de seguridad: si algo se queda colgado, no esperamos al SIGKILL
  setTimeout(function () {
    console.log('Cierre forzado tras el tiempo límite.');
    process.exit(1);
  }, 8000).unref();
}

process.on('SIGTERM', function () { shutdown('SIGTERM'); });
process.on('SIGINT',  function () { shutdown('SIGINT');  });
