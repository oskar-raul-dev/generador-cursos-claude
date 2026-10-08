// Notificaciones al cliente. API: Notifications. Desde el taller 08 escucha OrderCancelled de orders:
// la dependencia se invirtió (antes orders llamaba a notifications).
@ApplicationModule(allowedDependencies = {"orders", "shared"})
package dev.mono.legacy.notifications;

import org.springframework.modulith.ApplicationModule;
