// Idempotencia de los comandos que crean o cobran: la misma Idempotency-Key del mismo actor con el
// mismo cuerpo devuelve la respuesta guardada; con otro cuerpo, 422. API: Idempotency.
@ApplicationModule(allowedDependencies = "shared")
package dev.mono.legacy.idempotency;

import org.springframework.modulith.ApplicationModule;
