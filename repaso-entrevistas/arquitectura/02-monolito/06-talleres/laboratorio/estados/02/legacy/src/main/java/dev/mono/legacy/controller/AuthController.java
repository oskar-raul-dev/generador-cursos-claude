package dev.mono.legacy.controller;

import dev.mono.legacy.service.AuthService;
import dev.mono.legacy.util.Json;
import dev.mono.legacy.util.LegacyException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final AuthService auth;

    public AuthController(AuthService auth) {
        this.auth = auth;
    }

    @PostMapping("/login")
    public Object login(@RequestBody Map<String, String> body) {
        try {
            return auth.login(body.get("email"), body.get("password"));
        } catch (LegacyException e) {
            return Json.error(e.getMessage());
        }
    }

    @PostMapping("/logout")
    public Object logout(@AuthenticationPrincipal Jwt jwt) {
        auth.logout(jwt.getId());
        return Map.of("ok", true);
    }
}
