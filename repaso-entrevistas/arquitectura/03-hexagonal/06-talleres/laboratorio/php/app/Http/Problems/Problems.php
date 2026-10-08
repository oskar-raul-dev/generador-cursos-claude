<?php

declare(strict_types=1);

namespace App\Http\Problems;

use Hex\Application\Error\AccessDenied;
use Hex\Application\Error\IdempotencyKeyReused;
use Hex\Application\Error\InvalidCredentials;
use Hex\Application\Error\NotFound;
use Hex\Application\Error\ProductAlreadyExists;
use Hex\Domain\Error\EmptyOrder;
use Hex\Domain\Error\InsufficientInventory;
use Hex\Domain\Error\OrderNotCancellable;
use Hex\Domain\Error\OrderNotPayable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\MethodNotAllowedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Throwable;

/**
 * El traductor central: cada error propio se convierte UNA vez en problem+json con el código
 * estable del contrato. Ni el dominio ni los casos de uso conocen estos números.
 */
final class Problems
{
    public static function render(Throwable $e, Request $request): JsonResponse
    {
        return match (true) {
            $e instanceof InsufficientInventory => self::problem($request, 409, 'Insufficient inventory', 'INSUFFICIENT_INVENTORY', $e->getMessage(),
                [['field' => "lines[{$e->lineIndex}].quantity", 'message' => "requested {$e->requested}, available {$e->available}"]]),
            $e instanceof OrderNotPayable => self::problem($request, 409, 'Order not payable', 'ORDER_NOT_PAYABLE', $e->getMessage()),
            $e instanceof OrderNotCancellable => self::problem($request, 409, 'Order not cancellable', 'ORDER_NOT_CANCELLABLE', $e->getMessage()),
            $e instanceof EmptyOrder => self::problem($request, 400, 'Validation failed', 'VALIDATION_FAILED', $e->getMessage(), [['field' => 'lines', 'message' => 'must not be empty']]),
            $e instanceof NotFound => $e->kind === 'PRODUCT'
                ? self::problem($request, 404, 'Product not found', 'PRODUCT_NOT_FOUND', $e->identifier)
                : self::problem($request, 404, 'Order not found', 'ORDER_NOT_FOUND'),
            $e instanceof AccessDenied => self::problem($request, 403, 'Forbidden', 'FORBIDDEN'),
            $e instanceof InvalidCredentials => self::problem($request, 401, 'Invalid credentials', 'INVALID_CREDENTIALS'),
            $e instanceof IdempotencyKeyReused => self::problem($request, 422, 'Idempotency-Key reused with a different payload', 'IDEMPOTENCY_KEY_REUSED'),
            $e instanceof ProductAlreadyExists => self::problem($request, 409, 'Product already exists', 'PRODUCT_ALREADY_EXISTS', $e->getMessage()),
            $e instanceof Unauthenticated => self::problem($request, 401, $e->problemCode === 'TOKEN_REVOKED' ? 'Token revoked' : 'Unauthenticated', $e->problemCode),
            $e instanceof MissingIdempotencyKey => self::problem($request, 400, 'Idempotency-Key required', 'IDEMPOTENCY_KEY_REQUIRED'),
            $e instanceof ValidationFailed => self::problem($request, 400, 'Validation failed', 'VALIDATION_FAILED', errors: $e->errors),
            // Form Requests: 400 con campos, no el 422 con `errors: {campo: [...]}` de Laravel.
            $e instanceof ValidationException => self::problem($request, 400, 'Validation failed', 'VALIDATION_FAILED', errors: self::fields($e)),
            $e instanceof NotFoundHttpException => self::problem($request, 404, 'Not found', 'ORDER_NOT_FOUND'),
            $e instanceof MethodNotAllowedHttpException => self::problem($request, 405, 'Method not allowed', 'VALIDATION_FAILED'),
            $e instanceof HttpExceptionInterface => self::problem($request, $e->getStatusCode(), $e->getMessage() ?: 'Error',
                $e->getStatusCode() < 500 ? 'VALIDATION_FAILED' : 'INTERNAL_ERROR'),
            default => self::unexpected($e, $request),
        };
    }

    /** @param list<array{field: string, message: string}>|null $errors */
    private static function problem(Request $request, int $status, string $title, string $code, ?string $detail = null, ?array $errors = null): JsonResponse
    {
        $body = ['type' => 'about:blank', 'title' => $title, 'status' => $status, 'instance' => '/'.ltrim($request->path(), '/'), 'code' => $code];
        if ($detail !== null && $detail !== '') {
            $body['detail'] = $detail;
        }
        if ($errors !== null && $errors !== []) {
            $body['errors'] = $errors;
        }
        $headers = ['Content-Type' => 'application/problem+json'];
        if ($status === 401) {
            $headers['WWW-Authenticate'] = 'Bearer';
        }

        return new JsonResponse($body, $status, $headers);
    }

    /** `lines.0.quantity` → `lines[0].quantity`, con el primer mensaje de cada campo. */
    private static function fields(ValidationException $e): array
    {
        $out = [];
        foreach ($e->errors() as $key => $messages) {
            $field = preg_replace('/\.(\d+)/', '[$1]', $key);
            $out[] = ['field' => $field, 'message' => $messages[0] ?? 'invalid'];
        }

        return $out;
    }

    private static function unexpected(Throwable $e, Request $request): JsonResponse
    {
        Log::error("unexpected error handling {$request->method()} {$request->path()}", ['exception' => $e]);

        return self::problem($request, 500, 'Internal error', 'INTERNAL_ERROR');
    }
}
