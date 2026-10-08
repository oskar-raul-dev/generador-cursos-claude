import { InvalidCredentials } from "../errors.js";
import type { IssuedToken, PasswordHasher, TokenIssuer, Users } from "../ports.js";

export class Login {
  constructor(
    private readonly users: Users,
    private readonly hasher: PasswordHasher,
    private readonly tokens: TokenIssuer,
  ) {}

  async execute(email: string, password: string): Promise<IssuedToken> {
    // Mismo error exista o no el correo: no se revela quién tiene cuenta.
    const user = await this.users.findByEmail(email);
    if (!user || !(await this.hasher.matches(password, user.passwordHash))) {
      throw new InvalidCredentials();
    }
    return this.tokens.issue(user);
  }
}
