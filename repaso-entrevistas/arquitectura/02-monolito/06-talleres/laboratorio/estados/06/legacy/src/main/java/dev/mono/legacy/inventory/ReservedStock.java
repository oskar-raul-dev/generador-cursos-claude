package dev.mono.legacy.inventory;

import java.math.BigDecimal;

// Lo que pedidos necesita saber de una reserva: nombre y precio en el momento de la venta. Antes,
// InventoryService.take devolvía la entidad Product entera.
public record ReservedStock(String sku, String name, BigDecimal unitPrice) {}
