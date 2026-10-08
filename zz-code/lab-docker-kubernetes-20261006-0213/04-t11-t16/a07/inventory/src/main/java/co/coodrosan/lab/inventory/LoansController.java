package co.coodrosan.lab.inventory;

import java.util.Map;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

// G11 (Fase 24): la entrada de la saga del préstamo. Valida, registra y contesta 202; la saga sigue sola (LoanSaga).
@RestController
public class LoansController {

    record LoanRequest(String sku, String originStore, String destinationStore, Integer quantity) { }

    private final LoanSaga saga;

    LoansController(LoanSaga saga) {
        this.saga = saga;
    }

    private static ResponseEntity<Object> error(HttpStatus status, String code, String message) {
        return ResponseEntity.status(status).body(Map.of("error", code, "message", message));
    }

    // G13: el préstamo ya pedido con esta clave. El mismo pedido devuelve el mismo préstamo (202, como la primera vez),
    // sin arrancar otra saga; otro pedido con la misma clave es un error de quien llama.
    private ResponseEntity<Object> replay(LoanSaga.Loan previous, LoanRequest request) {
        if (!previous.sku().equals(request.sku()) || !previous.originStore().equals(request.originStore())
                || !previous.destinationStore().equals(request.destinationStore()) || previous.quantity() != request.quantity()) {
            return error(HttpStatus.UNPROCESSABLE_CONTENT, "unprocessable", "la clave ya se usó con otro préstamo");
        }
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(previous);
    }

    @PostMapping("/loans")
    public ResponseEntity<Object> request(@RequestBody LoanRequest request,
                                          @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey) {
        if (request.sku() == null || !request.sku().matches("^SKU-[0-9]{4}$")
                || request.originStore() == null || !request.originStore().matches("^DRO-[0-9]{3}$")
                || request.destinationStore() == null || !request.destinationStore().matches("^DRO-[0-9]{3}$")
                || request.quantity() == null || request.quantity() < 1) {
            return error(HttpStatus.UNPROCESSABLE_CONTENT, "unprocessable",
                    "se esperan sku (SKU-0000), originStore y destinationStore (DRO-000) y quantity ≥ 1");
        }
        if (request.originStore().equals(request.destinationStore())) {
            return error(HttpStatus.UNPROCESSABLE_CONTENT, "unprocessable", "el origen y el destino son la misma droguería");
        }
        if (idempotencyKey != null) {
            LoanSaga.Loan previous = saga.findByKey(idempotencyKey);
            if (previous != null) {
                return replay(previous, request);
            }
        }
        try {
            LoanSaga.Loan loan = saga.start(request.sku(), request.originStore(), request.destinationStore(),
                    request.quantity(), idempotencyKey);
            return ResponseEntity.status(HttpStatus.ACCEPTED).body(loan);
        } catch (DuplicateKeyException e) {
            // Dos pedidos con la misma clave a la vez: el índice único dejó pasar uno.
            return replay(saga.findByKey(idempotencyKey), request);
        }
    }

    @GetMapping("/loans/{loanId}")
    public ResponseEntity<Object> loan(@PathVariable String loanId) {
        long id = LoanSaga.parseId(loanId);
        LoanSaga.Loan loan = id < 0 ? null : saga.find(id);
        return loan == null ? error(HttpStatus.NOT_FOUND, "not_found", "no existe el préstamo " + loanId) : ResponseEntity.ok(loan);
    }
}
