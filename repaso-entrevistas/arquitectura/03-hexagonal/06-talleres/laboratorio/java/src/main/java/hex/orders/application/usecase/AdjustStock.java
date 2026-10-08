package hex.orders.application.usecase;

import hex.orders.application.Actor;
import hex.orders.application.port.out.Inventory;
import hex.orders.application.port.out.UnitOfWork;

// Taller 11. Un ajuste de existencias (recepción del proveedor, merma, inventario físico). Solo
// operator. Lo llama un lote desde un CSV, y mañana podría llamarlo un endpoint o una cola: la
// política (quién puede, qué se rechaza) vive aquí y no en el ItemWriter.
public final class AdjustStock {

    public record Command(Actor actor, String sku, int delta, String reason) {}

    public record Result(String sku, int delta, int available) {}

    private final Inventory inventory;
    private final UnitOfWork unitOfWork;

    public AdjustStock(Inventory inventory, UnitOfWork unitOfWork) {
        this.inventory = inventory;
        this.unitOfWork = unitOfWork;
    }

    public Result execute(Command command) {
        command.actor().requireOperator();
        if (command.delta() == 0) {
            throw new IllegalArgumentException("delta must not be zero");
        }
        return unitOfWork.run(() -> new Result(command.sku(), command.delta(), inventory.adjust(command.sku(), command.delta())));
    }
}
