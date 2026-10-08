package co.coodrosan.contingencia.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

// Un domicilio esperando moto. La Braqui lo lee de esta tabla, no de un servicio.
@Entity
@Table(name = "dispatch")
public class Dispatch {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "store_id")
    private String storeId;
    private String address;
    private String status = "PENDING";
    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    protected Dispatch() { }

    public Dispatch(String storeId, String address) {
        this.storeId = storeId;
        this.address = address;
    }

    public Long getId() { return id; }
}
