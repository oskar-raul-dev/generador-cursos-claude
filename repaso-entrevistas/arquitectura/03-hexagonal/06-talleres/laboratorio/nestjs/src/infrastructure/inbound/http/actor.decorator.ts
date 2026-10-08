import { createParamDecorator, type ExecutionContext } from "@nestjs/common";
import type { AuthenticatedRequest } from "./auth.guard.js";

// @CurrentActor() en un controller: el Actor que dejó el guard. @CurrentToken(): jti y expiración,
// solo para logout.
export const CurrentActor = createParamDecorator((_: unknown, ctx: ExecutionContext) => {
  return ctx.switchToHttp().getRequest<AuthenticatedRequest>().actor;
});

export const CurrentToken = createParamDecorator((_: unknown, ctx: ExecutionContext) => {
  return ctx.switchToHttp().getRequest<AuthenticatedRequest>().token;
});
