<?php

declare(strict_types=1);

namespace App\Http\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

/** La regla `integer` de Laravel acepta "10" (texto). El contrato dice entero: `is_int`, sin coerción. */
final class StrictInteger implements ValidationRule
{
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (! is_int($value)) {
            $fail('The :attribute must be an integer, not a string.');
        }
    }
}
