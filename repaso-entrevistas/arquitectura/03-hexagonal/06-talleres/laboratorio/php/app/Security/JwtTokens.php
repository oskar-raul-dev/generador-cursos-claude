<?php

declare(strict_types=1);

namespace App\Security;

use App\Http\Auth\TokenClaims;
use App\Http\Auth\TokenVerifier;
use DateTimeImmutable;
use DateTimeZone;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Hex\Application\Port\Clock;
use Hex\Application\Port\IssuedToken;
use Hex\Application\Port\TokenIssuer;
use Hex\Application\Port\User;
use Illuminate\Support\Str;
use UnexpectedValueException;

/** JWT HS256 con php-jwt. Implementa el puerto TokenIssuer (para Login) y la interfaz TokenVerifier del borde HTTP. */
final readonly class JwtTokens implements TokenIssuer, TokenVerifier
{
    public function __construct(private string $secret, private int $ttlSeconds, private Clock $clock) {}

    public function issue(User $user): IssuedToken
    {
        $now = $this->clock->now();
        $expiresAt = $now->modify("+{$this->ttlSeconds} seconds");
        $jti = str_replace('-', '', (string) Str::uuid());
        $value = JWT::encode([
            'sub' => $user->id, 'email' => $user->email, 'role' => $user->role->value, 'jti' => $jti,
            'iat' => $now->getTimestamp(), 'exp' => $expiresAt->getTimestamp(),
        ], $this->secret, 'HS256');

        return new IssuedToken($value, $jti, $expiresAt, $this->ttlSeconds);
    }

    public function verify(string $token): TokenClaims
    {
        $claims = (array) JWT::decode($token, new Key($this->secret, 'HS256'));   // firma, exp y nbf los comprueba la librería
        foreach (['sub', 'jti', 'exp'] as $required) {
            if (! isset($claims[$required])) {
                throw new UnexpectedValueException("missing claim {$required}");
            }
        }

        return new TokenClaims(
            (string) $claims['sub'], (string) ($claims['email'] ?? ''), (string) ($claims['role'] ?? ''), (string) $claims['jti'],
            (new DateTimeImmutable('@'.(int) $claims['exp']))->setTimezone(new DateTimeZone('UTC')),
        );
    }
}
