<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use App\Http\Auth\AuthContext;
use App\Http\Auth\TokenVerifier;
use App\Http\Problems\Unauthenticated;
use Closure;
use Hex\Application\Actor;
use Hex\Application\Port\TokenRevocationStore;
use Hex\Application\Role;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

/**
 * El guardián del borde: verifica el bearer (firma, fecha) y la revocación por jti, y deja un
 * Actor de aplicación en los atributos de la petición. Ningún controlador ve un token.
 */
final readonly class Authenticate
{
    public function __construct(private TokenVerifier $verifier, private TokenRevocationStore $revocations) {}

    public function handle(Request $request, Closure $next): Response
    {
        $header = $request->header('Authorization', '');
        if (! str_starts_with($header, 'Bearer ')) {
            throw new Unauthenticated('UNAUTHENTICATED');
        }
        try {
            $claims = $this->verifier->verify(substr($header, 7));
        } catch (Throwable $e) {  // firma, expiración, forma: todo es "no autenticado"
            throw new Unauthenticated('UNAUTHENTICATED', $e);
        }
        if ($this->revocations->isRevoked($claims->tokenId)) {
            throw new Unauthenticated('TOKEN_REVOKED');
        }
        $actor = new Actor($claims->subject, $claims->email, Role::from($claims->role));
        $request->attributes->set('hex.auth', new AuthContext($actor, $claims));

        return $next($request);
    }

    /** Lo que el middleware dejó; un controlador sin el middleware no debería llamarlo. */
    public static function context(Request $request): AuthContext
    {
        return $request->attributes->get('hex.auth') ?? throw new Unauthenticated('UNAUTHENTICATED');
    }
}
