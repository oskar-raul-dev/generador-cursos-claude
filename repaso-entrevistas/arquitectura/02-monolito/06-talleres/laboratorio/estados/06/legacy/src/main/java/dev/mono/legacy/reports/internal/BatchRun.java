package dev.mono.legacy.reports.internal;

import jakarta.persistence.*;

import java.time.Instant;

// lo que el "cierre diario" deja escrito; /batches/{id} lo devuelve tal cual
@Entity
@Table(name = "batch_runs")
public class BatchRun {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "job_name")
    private String jobName;
    private String status;
    @Column(name = "started_at")
    private Instant startedAt;
    @Column(name = "ended_at")
    private Instant endedAt;
    @Column(name = "orders_read")
    private int ordersRead;
    private String host;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getJobName() { return jobName; }
    public void setJobName(String jobName) { this.jobName = jobName; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Instant getStartedAt() { return startedAt; }
    public void setStartedAt(Instant startedAt) { this.startedAt = startedAt; }
    public Instant getEndedAt() { return endedAt; }
    public void setEndedAt(Instant endedAt) { this.endedAt = endedAt; }
    public int getOrdersRead() { return ordersRead; }
    public void setOrdersRead(int ordersRead) { this.ordersRead = ordersRead; }
    public String getHost() { return host; }
    public void setHost(String host) { this.host = host; }
}
