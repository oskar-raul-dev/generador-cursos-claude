import svelte from 'rollup-plugin-svelte';
import resolve from '@rollup/plugin-node-resolve';

export default {
  input: 'src/main.js',
  output: {
    sourcemap: false,
    format: 'iife',
    name: 'app',
    file: 'public/build/bundle.js'
  },
  plugins: [
    svelte({
      emitCss: false
    }),
    // Sin node-resolve, Rollup no sabe encontrar 'svelte/internal' dentro de
    // node_modules y el bundle se queda con imports sin resolver.
    resolve({
      browser: true,
      dedupe: ['svelte']
    })
  ]
};
