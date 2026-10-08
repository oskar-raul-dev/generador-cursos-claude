<?php

declare(strict_types=1);

namespace App\Http\Auth;

/** Interfaz del borde de entrada, no un puerto del núcleo: el núcleo nunca ve un token. */
interface TokenVerifier
{
    public function verify(string $token): TokenClaims;
}
