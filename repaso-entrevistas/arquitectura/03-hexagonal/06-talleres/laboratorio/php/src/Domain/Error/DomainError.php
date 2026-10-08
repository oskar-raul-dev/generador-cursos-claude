<?php

declare(strict_types=1);

namespace Hex\Domain\Error;

use RuntimeException;

/** Errores de negocio del dominio: rechazos esperados con nombre propio. El borde les pone código HTTP; aquí no hay números. */
abstract class DomainError extends RuntimeException {}
