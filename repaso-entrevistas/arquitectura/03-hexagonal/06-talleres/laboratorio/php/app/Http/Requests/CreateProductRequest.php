<?php

declare(strict_types=1);

namespace App\Http\Requests;

use App\Http\Rules\StrictInteger;
use Hex\Domain\Money;
use Illuminate\Foundation\Http\FormRequest;

final class CreateProductRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'sku' => ['required', 'string', 'regex:/^SKU-[0-9]{3,}$/'],
            'name' => ['required', 'string', 'min:1', 'max:120'],
            'unitPrice' => ['required', 'array'],
            'unitPrice.amount' => ['required', 'string', 'regex:/^-?[0-9]+\.[0-9]{2}$/'],   // "35" no vale: dos decimales
            'unitPrice.currency' => ['required', 'string', 'regex:/^[A-Z]{3}$/'],
            'stock' => ['required', 'integer', new StrictInteger, 'min:0'],
        ];
    }

    public function unitPrice(): Money
    {
        return Money::parse($this->string('unitPrice.amount')->toString(), $this->string('unitPrice.currency')->toString());
    }
}
