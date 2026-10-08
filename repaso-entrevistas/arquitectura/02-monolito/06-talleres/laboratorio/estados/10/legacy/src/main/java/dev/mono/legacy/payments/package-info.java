// Pagos: AuthorizePayment contra el proveedor externo. Depende de orders (lee el pedido y le pide que
// registre el resultado) e implementa su puerto PaymentLookup.
@ApplicationModule(allowedDependencies = {"orders", "idempotency", "shared"})
package dev.mono.legacy.payments;

import org.springframework.modulith.ApplicationModule;
