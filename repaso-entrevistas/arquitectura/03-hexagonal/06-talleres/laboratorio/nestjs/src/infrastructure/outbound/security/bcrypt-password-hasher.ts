import { Injectable } from "@nestjs/common";
import { compare } from "bcryptjs";
import type { PasswordHasher } from "../../../application/ports.js";

// Los hashes de la semilla son $2y$10$…: bcryptjs los verifica sin más.
@Injectable()
export class BcryptPasswordHasher implements PasswordHasher {
  matches(rawPassword: string, hash: string): Promise<boolean> {
    return compare(rawPassword, hash);
  }
}
