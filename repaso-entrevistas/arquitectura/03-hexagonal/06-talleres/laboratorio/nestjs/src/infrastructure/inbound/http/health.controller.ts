import { Controller, Get } from "@nestjs/common";
import { Public } from "./auth.guard.js";

@Controller()
export class HealthController {
  @Public()
  @Get("health")
  health(): { status: string } {
    return { status: "UP" };
  }
}
