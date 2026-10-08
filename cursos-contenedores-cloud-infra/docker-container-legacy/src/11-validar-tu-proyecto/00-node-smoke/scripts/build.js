const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const srcDir = path.join(__dirname, '..', 'src');
const distDir = path.join(__dirname, '..', 'dist');

// Node 10 no tiene fs.rmSync: llegó en 14.14. Delegamos el borrado recursivo en
// el shell del contenedor, pero SIEMPRE con la ruta absoluta: un 'rm -rf dist'
// relativo borraría el dist del directorio desde donde se invoque el script,
// que no tiene por qué ser la raíz del proyecto.
if (typeof fs.rmSync === 'function') {
  fs.rmSync(distDir, { recursive: true, force: true });
} else if (fs.existsSync(distDir)) {
  execSync('rm -rf "' + distDir + '"');
}

fs.mkdirSync(distDir, { recursive: true });

for (const file of fs.readdirSync(srcDir)) {
  fs.copyFileSync(
    path.join(srcDir, file),
    path.join(distDir, file)
  );
}

console.log('✅ build generado en ' + distDir);
