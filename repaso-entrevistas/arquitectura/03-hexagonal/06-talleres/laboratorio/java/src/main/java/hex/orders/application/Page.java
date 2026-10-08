package hex.orders.application;

import java.util.List;
import java.util.function.Function;

// Una página con cursor opaco; `nextCursor` es null en la última. El cursor lo fabrica y lo
// interpreta el adaptador de salida; aplicación y UI lo pasan tal cual.
public record Page<T>(List<T> items, String nextCursor) {

    public <R> Page<R> map(Function<T, R> mapper) {
        return new Page<>(items.stream().map(mapper).toList(), nextCursor);
    }
}
