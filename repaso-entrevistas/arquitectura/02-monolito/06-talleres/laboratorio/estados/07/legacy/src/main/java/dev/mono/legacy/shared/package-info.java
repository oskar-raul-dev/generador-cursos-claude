// Núcleo compartido (shared kernel): errores del contrato, dinero y paginación. Lo usan todos los
// módulos y no depende de ninguno. Crece solo por decisión explícita (02/06).
@ApplicationModule(displayName = "Shared kernel", allowedDependencies = {})
package dev.mono.legacy.shared;

import org.springframework.modulith.ApplicationModule;
