// El "test" de este fixture no usa framework de testing: comprueba que el
// compilador de Svelte funciona dentro del contenedor y produce JavaScript.
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const svelte = require('svelte/compiler');

const componentPath = path.join(__dirname, '..', 'src', 'App.svelte');
const source = fs.readFileSync(componentPath, 'utf8');

const result = svelte.compile(source, {
  name: 'App'
});

assert.ok(result.js.code.length > 0, 'el compilador no produjo código');
assert.ok(
  result.js.code.indexOf('svelte/internal') !== -1,
  'el código compilado no importa el runtime de Svelte'
);

console.log('✅ compiler smoke OK — Svelte ' + svelte.VERSION);
