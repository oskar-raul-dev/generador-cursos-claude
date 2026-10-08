import { defineConfig } from "vitest/config";

// Solo dominio y aplicación: no hay decoradores ni Nest en lo que se prueba aquí.
export default defineConfig({
  test: {
    environment: "node",
    include: ["src/domain/**/*.test.ts", "src/application/**/*.test.ts"],
  },
});
