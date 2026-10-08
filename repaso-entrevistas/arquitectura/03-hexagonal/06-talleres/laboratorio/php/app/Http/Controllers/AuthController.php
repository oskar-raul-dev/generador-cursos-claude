<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Middleware\Authenticate;
use App\Http\Requests\LoginRequest;
use Hex\Application\UseCase\Login;
use Hex\Application\UseCase\Logout;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

/** Los controladores son delgados: forma → caso de uso → forma. El contenedor inyecta los casos de uso por tipo. */
final readonly class AuthController
{
    public function __construct(private Login $login, private Logout $logout) {}

    public function login(LoginRequest $request): JsonResponse
    {
        $token = $this->login->execute($request->string('email')->toString(), $request->string('password')->toString());

        return new JsonResponse(['accessToken' => $token->value, 'tokenType' => 'Bearer', 'expiresIn' => $token->expiresInSeconds]);
    }

    public function logout(Request $request): Response
    {
        $auth = Authenticate::context($request);
        $this->logout->execute($auth->token->tokenId, $auth->token->expiresAt);

        return new Response('', 204);
    }
}
