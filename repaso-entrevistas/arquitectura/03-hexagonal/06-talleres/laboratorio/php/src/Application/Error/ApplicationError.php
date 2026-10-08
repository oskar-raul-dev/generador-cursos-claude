<?php

declare(strict_types=1);

namespace Hex\Application\Error;

use RuntimeException;

/** Errores de aplicación: existencia, permisos, credenciales, idempotencia. */
abstract class ApplicationError extends RuntimeException {}
