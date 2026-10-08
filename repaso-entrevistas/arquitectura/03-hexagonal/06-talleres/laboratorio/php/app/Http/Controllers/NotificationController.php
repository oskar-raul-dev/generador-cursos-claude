<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Middleware\Authenticate;
use App\Http\Query;
use App\Http\Responses;
use Hex\Application\UseCase\ListNotifications;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final readonly class NotificationController
{
    public function __construct(private ListNotifications $list) {}

    public function list(Request $request): JsonResponse
    {
        $actor = Authenticate::context($request)->actor;
        $orderId = $request->query('orderId');
        $orderId = is_string($orderId) && $orderId !== '' ? Query::uuid($orderId, 'orderId') : null;

        return new JsonResponse(Responses::page($this->list->execute($actor, $orderId, Query::page($request)), Responses::notification(...)));
    }
}
