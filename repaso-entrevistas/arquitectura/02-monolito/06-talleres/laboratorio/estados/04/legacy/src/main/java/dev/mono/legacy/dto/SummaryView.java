package dev.mono.legacy.dto;

import java.util.List;

public record SummaryView(List<Row> items) {
    public record Row(String customerId, int ordersCreated, int ordersCancelled, Money openAmount) {}
}
