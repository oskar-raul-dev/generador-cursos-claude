import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// el navegador habla con :35173 y Vite reenvía /api y /health al legado: sin CORS que configurar
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      "/api": "http://localhost:38081",
      "/health": "http://localhost:38081",
    },
  },
});
