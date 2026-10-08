import { setupWorker } from "msw/browser";
import { handlers } from "./handlers";

// El service worker de MSW intercepta `fetch` en el navegador. `public/mockServiceWorker.js` lo
// genera `npx msw init public/` y se versiona junto al proyecto.
export const worker = setupWorker(...handlers);
