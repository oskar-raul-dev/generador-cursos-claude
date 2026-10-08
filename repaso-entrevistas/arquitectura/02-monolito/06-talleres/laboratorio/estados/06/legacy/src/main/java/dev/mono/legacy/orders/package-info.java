// Pedidos: crear, consultar y cancelar. API: OrderService, OrderSnapshot y el puerto PaymentLookup.
// No depende de payments: payments depende de pedidos e implementa PaymentLookup (el ciclo se rompe
// invirtiendo esa dependencia).
@ApplicationModule(allowedDependencies = {"inventory", "auth", "notifications", "shared"})
package dev.mono.legacy.orders;

import org.springframework.modulith.ApplicationModule;
