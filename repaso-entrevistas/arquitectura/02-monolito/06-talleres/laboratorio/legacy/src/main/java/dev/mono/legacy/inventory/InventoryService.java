package dev.mono.legacy.inventory;

import dev.mono.legacy.inventory.internal.Product;
import dev.mono.legacy.inventory.internal.ProductRepository;
import dev.mono.legacy.inventory.internal.RemoteInventory;
import dev.mono.legacy.inventory.internal.StockStore;
import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.UUID;

// API de inventory. Taller 10: el stock puede vivir aquí (local) o en otro proceso, según
// legacy.inventory.mode:
//   local         el monolito: la reserva está en la transacción del pedido (la salida «fusionar»)
//   remote-naive  mono-inventory por HTTP, sin identificador ni compensación: la extracción habitual
//   remote        mono-inventory con reservas identificadas y compensación si el pedido se deshace
//                 (la salida «propiedad de datos y contrato»)
// El catálogo (nombre y precio) es siempre de este proceso.
@Service
public class InventoryService {
    private static final Logger log = LoggerFactory.getLogger(InventoryService.class);
    public enum Mode { LOCAL, REMOTE_NAIVE, REMOTE }

    private final ProductRepository products;
    private final StockStore stock;
    private final RemoteInventory remote;
    private final Mode mode;

    public InventoryService(ProductRepository products, StockStore stock, RemoteInventory remote,
                            @Value("${legacy.inventory.mode}") String mode) {
        this.products = products;
        this.stock = stock;
        this.remote = remote;
        this.mode = Mode.valueOf(mode.toUpperCase().replace('-', '_'));
    }

    public Mode mode() { return mode; }

    // leer, restar, escribir, con las filas de stock bloqueadas desde la lectura (taller 07)
    public ReservedStock reserve(UUID reservationId, String sku, int quantity) {
        Product p = products.findById(sku).orElse(null);
        if (p == null) {
            throw new LegacyException(ErrorCode.PRODUCT_NOT_FOUND, sku);
        }
        switch (mode) {
            case LOCAL -> reserveLocally(sku, quantity);
            case REMOTE_NAIVE -> remote.reserve(null, sku, quantity);
            case REMOTE -> {
                // se registra ANTES de llamar: si la llamada falla por la red, la reserva pudo aplicarse
                compensateOnRollback(reservationId, sku, quantity);
                remote.reserve(reservationId, sku, quantity);
            }
        }
        return new ReservedStock(p.getSku(), p.getName(), p.getPrice());
    }

    private void reserveLocally(String sku, int quantity) {
        Integer available = stock.lockAndRead(sku);
        if (available == null) {
            throw new LegacyException(ErrorCode.PRODUCT_NOT_FOUND, sku);
        }
        if (available < quantity) {
            throw new LegacyException(ErrorCode.INSUFFICIENT_INVENTORY,
                sku + ": requested " + quantity + ", available " + available);
        }
        stock.add(sku, -quantity);
    }

    // taller 06: lo que hacía el trigger orders_restore_stock
    public void release(String sku, int quantity) {
        switch (mode) {
            case LOCAL -> stock.add(sku, quantity);
            case REMOTE_NAIVE -> remote.release(null, sku, quantity);
            // remoto: solo cuando la cancelación ya confirmó (si se deshiciera, no hay que devolver nada)
            case REMOTE -> TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    remote.release(null, sku, quantity);
                }
            });
        }
    }

    // Taller 10: la compensación. Si la transacción del pedido se deshace —por una línea sin stock, un
    // fallo al confirmar o un timeout de esta misma llamada—, la reserva confirmada en mono-inventory se
    // libera por su id. Liberar un id que nunca se reservó no hace nada.
    private void compensateOnRollback(UUID reservationId, String sku, int quantity) {
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCompletion(int status) {
                if (status != STATUS_COMMITTED) {
                    try {
                        remote.release(reservationId, sku, quantity);
                    } catch (RuntimeException e) {
                        log.error("compensación pendiente: reserva {} de {} × {} sin liberar: {}",
                            reservationId, quantity, sku, e.getMessage());
                    }
                }
            }
        });
    }
}
