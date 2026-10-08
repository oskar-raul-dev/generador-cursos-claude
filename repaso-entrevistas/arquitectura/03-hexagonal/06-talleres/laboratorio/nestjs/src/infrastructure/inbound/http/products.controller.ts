import { Body, Controller, Get, Inject, Param, Post, Query, Res } from "@nestjs/common";
import type { Response } from "express";
import type { Actor } from "../../../application/actor.js";
import { mapPage, pageRequest } from "../../../application/page.js";
import { CreateProduct } from "../../../application/usecases/create-product.js";
import { GetProduct } from "../../../application/usecases/get-product.js";
import { ListProducts } from "../../../application/usecases/list-products.js";
import { CurrentActor } from "./actor.decorator.js";
import { CreateProductRequest, toPageResponse, toProductResponse } from "./dto.js";

@Controller("api/v1/products")
export class ProductsController {
  constructor(
    @Inject(ListProducts) private readonly listProducts: ListProducts,
    @Inject(GetProduct) private readonly getProduct: GetProduct,
    @Inject(CreateProduct) private readonly createProduct: CreateProduct,
  ) {}

  @Get()
  async list(@Query("cursor") cursor?: string, @Query("limit") limit?: string) {
    const page = await this.listProducts.execute(pageRequest(cursor, limit ? Number(limit) : null));
    return toPageResponse(mapPage(page, toProductResponse));
  }

  @Get(":sku")
  async get(@Param("sku") sku: string) {
    return toProductResponse(await this.getProduct.execute(sku));
  }

  @Post()
  async create(@CurrentActor() actor: Actor, @Body() body: CreateProductRequest, @Res({ passthrough: true }) res: Response) {
    const created = await this.createProduct.execute(actor, body.sku, body.name, body.unitPrice.toMoney(), body.stock);
    res.status(201).setHeader("Location", `/api/v1/products/${created.product.sku}`);
    return toProductResponse(created);
  }
}
