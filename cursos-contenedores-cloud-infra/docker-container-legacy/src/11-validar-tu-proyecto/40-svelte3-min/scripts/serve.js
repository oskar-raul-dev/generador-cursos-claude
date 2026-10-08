// Servidor estático mínimo escrito para el fixture: así no agregamos otra
// dependencia (ni otra capa de compatibilidad) solo para servir archivos.
const http = require('http');
const fs = require('fs');
const path = require('path');

const publicDir = path.join(__dirname, '..', 'public');
const host = '0.0.0.0';
const port = Number(process.env.PORT || 5000);

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.map': 'application/json; charset=utf-8'
};

const server = http.createServer((req, res) => {
  const requested = req.url === '/' ? '/index.html' : req.url.split('?')[0];
  const filePath = path.join(publicDir, requested);

  // Sin esta comprobación, un '..' en la URL serviría archivos de fuera de
  // public/. El fixture es de laboratorio, pero no vamos a enseñar el agujero.
  if (filePath.indexOf(publicDir) !== 0) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  fs.readFile(filePath, (err, content) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('No encontrado: ' + requested);
      return;
    }

    const type = types[path.extname(filePath)] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': type });
    res.end(content);
  });
});

server.listen(port, host, () => {
  console.log('Servidor estático en http://' + host + ':' + port);
});

process.on('SIGTERM', () => {
  server.close(() => process.exit(0));
});
