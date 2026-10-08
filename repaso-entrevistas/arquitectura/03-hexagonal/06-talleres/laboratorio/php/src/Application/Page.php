<?php

declare(strict_types=1);

namespace Hex\Application;

use Closure;

/**
 * Página con cursor opaco (null en la última). El cursor lo fabrica y lo lee el adaptador.
 *
 * @template T
 */
final readonly class Page
{
    /** @param list<T> $items */
    public function __construct(public array $items, public ?string $nextCursor) {}

    /**
     * @template R
     *
     * @param  Closure(T): R  $fn
     * @return Page<R>
     */
    public function map(Closure $fn): self
    {
        return new self(array_map($fn, $this->items), $this->nextCursor);
    }
}
