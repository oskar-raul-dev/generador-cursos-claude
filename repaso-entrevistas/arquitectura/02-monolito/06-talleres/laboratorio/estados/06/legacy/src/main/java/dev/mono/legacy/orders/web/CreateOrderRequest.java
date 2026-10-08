package dev.mono.legacy.orders.web;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.util.List;

public record CreateOrderRequest(@NotEmpty @Size(max = 50) List<@Valid @NotNull Line> lines) {

    public record Line(
        @NotNull @Pattern(regexp = "^SKU-[0-9]{3,}$") String sku,
        @NotNull @Min(1) @Max(1000) Integer quantity) {}
}
