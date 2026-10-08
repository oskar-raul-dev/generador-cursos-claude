import { Injectable } from "@nestjs/common";
import type { Role } from "../../../application/actor.js";
import type { User, Users } from "../../../application/ports.js";
import { PrismaService } from "./prisma.service.js";

@Injectable()
export class PrismaUsers implements Users {
  constructor(private readonly prisma: PrismaService) {}

  async findByEmail(email: string): Promise<User | null> {
    const row = await this.prisma.db.users.findUnique({ where: { email } });
    return row && toUser(row);
  }

  async findById(id: string): Promise<User | null> {
    const row = await this.prisma.db.users.findUnique({ where: { id } });
    return row && toUser(row);
  }
}

function toUser(row: { id: string; email: string; password_hash: string; role: string }): User {
  return { id: row.id, email: row.email, passwordHash: row.password_hash, role: row.role.toUpperCase() as Role };
}
