package hex.orders.infrastructure.inbound.batch;

// Una línea que no cumple la forma del archivo. Es "saltable": va a cuarentena y el lote sigue.
public final class InvalidStockLine extends RuntimeException {

    public InvalidStockLine(StockLine line, String why) {
        super(why + ": " + line);
    }
}
