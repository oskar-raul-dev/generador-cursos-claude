<?php

declare(strict_types=1);

namespace App\Http\Requests;

use App\Http\Rules\StrictInteger;
use Hex\Application\UseCase\LineRequest;
use Illuminate\Foundation\Http\FormRequest;

final class CreateOrderRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'lines' => ['required', 'array', 'min:1', 'max:50'],
            'lines.*.sku' => ['required', 'string', 'regex:/^SKU-[0-9]{3,}$/'],
            'lines.*.quantity' => ['required', 'integer', new StrictInteger, 'min:1', 'max:1000'],
        ];
    }

    /** @return list<LineRequest> */
    public function lines(): array
    {
        return array_map(fn (array $l) => new LineRequest($l['sku'], $l['quantity']), $this->validated('lines'));
    }

    /** Huella canónica del cuerpo para la idempotencia. */
    public function canonical(): string
    {
        return implode(',', array_map(fn (LineRequest $l) => "{$l->sku}:{$l->quantity}", $this->lines()));
    }
}
