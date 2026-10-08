package hex.orders.infrastructure.inbound.batch;

// Una línea del CSV del proveedor: sku,delta,reason. Es la forma pública del archivo, como un DTO.
public record StockLine(String sku, String delta, String reason) {}
