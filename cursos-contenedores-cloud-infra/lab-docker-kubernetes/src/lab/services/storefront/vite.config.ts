import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  preview: {
    // vite preview rechaza (403) los nombres de host que no conoce, y en compose lo llaman
    // "storefront". Es un servidor de vista previa, no de producción: la Fase 04 lo cambia por nginx.
    allowedHosts: true,
  },
})
