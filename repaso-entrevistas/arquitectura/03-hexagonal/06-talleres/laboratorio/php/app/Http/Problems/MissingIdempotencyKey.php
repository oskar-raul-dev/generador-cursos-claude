<?php

declare(strict_types=1);

namespace App\Http\Problems;

use RuntimeException;

final class MissingIdempotencyKey extends RuntimeException {}
