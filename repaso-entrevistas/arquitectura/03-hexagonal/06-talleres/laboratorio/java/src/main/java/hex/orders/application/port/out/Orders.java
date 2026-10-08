package hex.orders.application.port.out;

import hex.orders.application.Page;
import hex.orders.application.PageRequest;
import hex.orders.domain.Order;

import java.util.Optional;
import java.util.UUID;

// Persistencia del agregado. `list` con customerId null lista todos (operator).
public interface Orders {

    Optional<Order> find(UUID id);

    void save(Order order);

    Page<Order> list(UUID customerId, PageRequest page);
}
