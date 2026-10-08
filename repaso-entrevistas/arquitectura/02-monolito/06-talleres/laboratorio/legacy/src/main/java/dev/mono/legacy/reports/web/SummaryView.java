package dev.mono.legacy.reports.web;

import dev.mono.legacy.shared.Money;

import java.util.List;

public record SummaryView(List<Row> items) {
    public record Row(String customerId, int ordersCreated, int ordersCancelled, Money openAmount) {}
}
