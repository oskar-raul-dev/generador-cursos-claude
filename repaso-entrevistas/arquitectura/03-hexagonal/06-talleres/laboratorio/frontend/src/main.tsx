import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import { HttpOrdersApi } from "./api/httpOrdersApi";
import "./styles.css";

// Composition root del frontend: aquí, y solo aquí, se decide contra qué habla la UI.
// La URL base es la única configuración; el modo mock añade el service worker de MSW por delante
// del mismo adaptador HTTP.
const baseUrl: string = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:8081";
const mode: string = import.meta.env.VITE_API_MODE ?? "http";

async function bootstrap(): Promise<void> {
  if (mode === "mock") {
    const { worker } = await import("./mock/browser");
    // onUnhandledRequest: "bypass" deja pasar lo que no es de la API (los propios assets de Vite)
    await worker.start({ onUnhandledRequest: "bypass" });
  }
  const api = new HttpOrdersApi(baseUrl);
  createRoot(document.getElementById("root")!).render(
    <StrictMode>
      <App api={api} baseUrl={baseUrl} mode={mode} />
    </StrictMode>,
  );
}

void bootstrap();
