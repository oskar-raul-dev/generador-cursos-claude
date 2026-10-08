import { Body, Controller, HttpCode, Inject, Post } from "@nestjs/common";
import { Login } from "../../../application/usecases/login.js";
import { Logout } from "../../../application/usecases/logout.js";
import { CurrentToken } from "./actor.decorator.js";
import { Public, type TokenContext } from "./auth.guard.js";
import { LoginRequest } from "./dto.js";

@Controller("api/v1/auth")
export class AuthController {
  constructor(
    @Inject(Login) private readonly login: Login,
    @Inject(Logout) private readonly logout: Logout,
  ) {}

  @Public()
  @Post("login")
  @HttpCode(200)
  async doLogin(@Body() body: LoginRequest) {
    const token = await this.login.execute(body.email, body.password);
    return { accessToken: token.value, tokenType: "Bearer", expiresIn: token.expiresInSeconds };
  }

  @Post("logout")
  @HttpCode(204)
  async doLogout(@CurrentToken() token: TokenContext): Promise<void> {
    await this.logout.execute(token.jti, token.expiresAt);
  }
}
