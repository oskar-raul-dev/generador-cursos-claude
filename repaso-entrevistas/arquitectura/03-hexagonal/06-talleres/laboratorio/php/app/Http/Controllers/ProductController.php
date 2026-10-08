<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Middleware\Authenticate;
use App\Http\Query;
use App\Http\Requests\CreateProductRequest;
use App\Http\Responses;
use Hex\Application\UseCase\CreateProduct;
use Hex\Application\UseCase\GetProduct;
use Hex\Application\UseCase\ListProducts;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final readonly class ProductController
{
    public function __construct(private ListProducts $list, private GetProduct $get, private CreateProduct $create) {}

    public function list(Request $request): JsonResponse
    {
        return new JsonResponse(Responses::page($this->list->execute(Query::page($request)), Responses::product(...)));
    }

    public function get(string $sku): JsonResponse
    {
        return new JsonResponse(Responses::product($this->get->execute($sku)));
    }

    public function create(CreateProductRequest $request): JsonResponse
    {
        $actor = Authenticate::context($request)->actor;
        $created = $this->create->execute($actor, $request->string('sku')->toString(), $request->string('name')->toString(),
            $request->unitPrice(), $request->integer('stock'));

        return new JsonResponse(Responses::product($created), 201, ['Location' => "/api/v1/products/{$created->product->sku}"]);
    }
}
