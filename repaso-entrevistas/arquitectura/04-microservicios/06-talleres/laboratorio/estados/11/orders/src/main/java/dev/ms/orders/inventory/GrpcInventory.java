package dev.ms.orders.inventory;

import com.google.protobuf.InvalidProtocolBufferException;
import com.google.rpc.ErrorInfo;
import com.google.rpc.PreconditionFailure;
import dev.ms.inventory.v1.CommitRequest;
import dev.ms.inventory.v1.HoldItem;
import dev.ms.inventory.v1.HoldRequest;
import dev.ms.inventory.v1.InventoryServiceGrpc;
import dev.ms.inventory.v1.ReleaseRequest;
import dev.ms.orders.service.Errors;
import io.grpc.Channel;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import io.grpc.protobuf.StatusProto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

// El inventario por gRPC (taller 04), y la capa anticorrupción de orders: traduce el idioma de
// inventory (retenciones, FAILED_PRECONDITION con PreconditionFailure) al de orders (reservas,
// InsufficientInventory con el índice de línea que promete el contrato público).
//
// Tres decisiones que son de este adaptador:
//  - un plazo NUEVO en cada llamada (withDeadlineAfter), nunca un stub con plazo fijo; el plazo
//    viaja en la llamada (grpc-timeout) y el servidor lo ve en su context;
//  - DEADLINE_EXCEEDED y UNAVAILABLE son "no sé": InventoryUnavailable, que OrderService compensa;
//  - FAILED_PRECONDITION trae el detalle estructurado (PreconditionFailure con el SKU, ErrorInfo con el
//    stock en mano por SKU), nunca en el texto del mensaje.
public class GrpcInventory implements Inventory {

    private static final Logger log = LoggerFactory.getLogger(GrpcInventory.class);

    private final InventoryServiceGrpc.InventoryServiceBlockingStub stub;
    private final long deadlineMs;

    public GrpcInventory(Channel channel, long deadlineMs) {
        this.stub = InventoryServiceGrpc.newBlockingStub(channel);
        this.deadlineMs = deadlineMs;
    }

    private InventoryServiceGrpc.InventoryServiceBlockingStub call() {
        return stub.withDeadlineAfter(deadlineMs, TimeUnit.MILLISECONDS);
    }

    @Override
    public void reserve(UUID orderId, List<Line> lines) {
        var request = HoldRequest.newBuilder().setReference(orderId.toString());
        lines.forEach(l -> request.addItems(HoldItem.newBuilder().setSku(l.sku()).setQty(l.quantity())));
        try {
            call().hold(request.build());
        } catch (StatusRuntimeException e) {
            if (e.getStatus().getCode() == Status.Code.FAILED_PRECONDITION) throw outOfStock(e, lines);
            throw unavailable("Hold", orderId, e);
        }
    }

    @Override
    public void release(UUID orderId) {
        try {
            call().release(ReleaseRequest.newBuilder().setReference(orderId.toString()).build());
        } catch (StatusRuntimeException e) {
            throw unavailable("Release", orderId, e);
        }
    }

    @Override
    public int consume(UUID orderId) {
        try {
            return call().commit(CommitRequest.newBuilder().setReference(orderId.toString()).build()).getCommitted();
        } catch (StatusRuntimeException e) {
            throw unavailable("Commit", orderId, e);
        }
    }

    // FAILED_PRECONDITION + PreconditionFailure → InsufficientInventory con lines[i], que es lo que el
    // contrato público promete. El detalle viaja estructurado; nunca se parsea el mensaje de texto.
    private static Errors.InsufficientInventory outOfStock(StatusRuntimeException e, List<Line> lines) {
        String sku = null;
        Map<String, String> onHand = Map.of();
        var status = StatusProto.fromThrowable(e);
        if (status != null) {
            try {
                for (var any : status.getDetailsList()) {
                    if (any.is(PreconditionFailure.class)) sku = any.unpack(PreconditionFailure.class).getViolations(0).getSubject();
                    if (any.is(ErrorInfo.class)) onHand = any.unpack(ErrorInfo.class).getMetadataMap();
                }
            } catch (InvalidProtocolBufferException ignored) { }
        }
        for (int i = 0; i < lines.size(); i++) {
            if (lines.get(i).sku().equals(sku))
                return new Errors.InsufficientInventory(sku, i, lines.get(i).quantity(), Integer.parseInt(onHand.getOrDefault(sku, "0")));
        }
        return new Errors.InsufficientInventory(lines.getFirst().sku(), 0, lines.getFirst().quantity(), 0);
    }

    private static Errors.InventoryUnavailable unavailable(String rpc, UUID orderId, StatusRuntimeException e) {
        log.warn("inventory {} for order {}: {}", rpc, orderId, e.getStatus());
        return new Errors.InventoryUnavailable(e);
    }
}
