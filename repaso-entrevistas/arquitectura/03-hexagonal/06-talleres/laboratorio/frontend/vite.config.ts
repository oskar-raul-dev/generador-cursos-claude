/// <reference types="vitest/config" />
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// La configuración de Vitest va en el mismo archivo: las pruebas del adaptador HTTP corren en
// Node contra los mismos handlers de MSW que usa el navegador en modo mock.
export default defineConfig({
  plugins: [react()],
  server: { port: 5173, strictPort: true },
  test: {
    environment: "node",
    include: ["src/**/*.test.ts"],
  },
});
