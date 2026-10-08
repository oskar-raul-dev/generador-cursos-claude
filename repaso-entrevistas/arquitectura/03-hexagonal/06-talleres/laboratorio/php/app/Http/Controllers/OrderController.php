<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Middleware\Authenticate;
use App\Http\Query;
use App\Http\Requests\CreateOrderRequest;
use App\Http\Responses;
use Hex\Application\UseCase\AuthorizePayment;
use Hex\Application\UseCase\CancelOrder;
use Hex\Application\UseCase\CreateOrder;
use Hex\Application\UseCase\CreateOrderCommand;
use Hex\Application\UseCase\GetOrder;
use Hex\Application\UseCase\ListOrders;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final readonly class OrderController
{
    public function __construct(
        private CreateOrder $create,
        private GetOrder $get,
        private ListOrders $list,
        private AuthorizePayment $pay,
        private CancelOrder $cancel,
    ) {}

    public function create(CreateOrderRequest $request): JsonResponse
    {
        $actor = Authenticate::context($request)->actor;
        $key = Query::idempotencyKey($request);
        $result = $this->create->execute(new CreateOrderCommand($actor, $key, hash('sha256', $request->canonical()), $request->lines()));
        $headers = $result->replayed ? ['Idempotent-Replay' => 'true'] : ['Location' => "/api/v1/orders/{$result->order->id}"];

        return new JsonResponse(Responses::order($result->order), $result->replayed ? 200 : 201, $headers);
    }

    public function list(Request $request): JsonResponse
    {
        $actor = Authenticate::context($request)->actor;

        return new JsonResponse(Responses::page($this->list->execute($actor, Query::page($request)), Responses::order(...)));
    }

    public function get(Request $request, string $orderId): JsonResponse
    {
        $actor = Authenticate::context($request)->actor;

        return new JsonResponse(Responses::order($this->get->execute($actor, Query::uuid($orderId, 'orderId'))));
    }

    public function pay(Request $request, string $orderId): JsonResponse
    {
        $actor = Authenticate::context($request)->actor;
        $id = Query::uuid($orderId, 'orderId');
        $key = Query::idempotencyKey($request);
        $result = $this->pay->execute($actor, $id, $key);

        return new JsonResponse(Responses::paymentResult($result->order, $result->payment), 200, $result->replayed ? ['Idempotent-Replay' => 'true'] : []);
    }

    public function cancel(Request $request, string $orderId): JsonResponse
    {
        $actor = Authenticate::context($request)->actor;

        return new JsonResponse(Responses::order($this->cancel->execute($actor, Query::uuid($orderId, 'orderId'))));
    }
}
