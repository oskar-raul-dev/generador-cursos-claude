<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Application\Error\InvalidCredentials;
use Hex\Application\Port\IssuedToken;
use Hex\Application\Port\PasswordHasher;
use Hex\Application\Port\TokenIssuer;
use Hex\Application\Port\Users;

/** Usuario + contraseña → token. La comparación y el formato del token son puertos. */
final readonly class Login
{
    public function __construct(private Users $users, private PasswordHasher $hasher, private TokenIssuer $tokens) {}

    public function execute(string $email, string $password): IssuedToken
    {
        // Mismo error exista o no el correo: no se revela quién tiene cuenta.
        $user = $this->users->findByEmail($email);
        if ($user === null || ! $this->hasher->matches($password, $user->passwordHash)) {
            throw new InvalidCredentials();
        }

        return $this->tokens->issue($user);
    }
}
