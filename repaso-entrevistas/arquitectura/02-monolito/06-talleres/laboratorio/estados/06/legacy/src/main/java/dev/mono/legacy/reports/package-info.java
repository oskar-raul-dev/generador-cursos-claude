// Informe de pedidos y cierre diario: consultas síncronas disfrazadas de lote. Solo lee pedidos.
@ApplicationModule(allowedDependencies = {"orders", "shared"})
package dev.mono.legacy.reports;

import org.springframework.modulith.ApplicationModule;
