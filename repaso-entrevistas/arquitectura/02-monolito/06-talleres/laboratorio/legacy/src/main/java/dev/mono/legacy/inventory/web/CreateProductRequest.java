package dev.mono.legacy.inventory.web;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CreateProductRequest(
    @NotNull @Pattern(regexp = "^SKU-[0-9]{3,}$") String sku,
    @NotBlank @Size(max = 120) String name,
    @NotNull @Valid MoneyInput unitPrice,
    @NotNull @Min(0) Integer stock) {

    public record MoneyInput(
        @NotNull @Pattern(regexp = "^[0-9]+\\.[0-9]{2}$", message = "must be a decimal with two digits") String amount,
        @NotNull @Pattern(regexp = "^USD$", message = "only USD is accepted") String currency) {}
}
