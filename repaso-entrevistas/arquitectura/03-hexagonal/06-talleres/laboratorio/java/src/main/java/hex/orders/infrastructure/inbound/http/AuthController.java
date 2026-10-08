package hex.orders.infrastructure.inbound.http;

import hex.orders.application.usecase.Login;
import hex.orders.application.usecase.Logout;
import hex.orders.infrastructure.inbound.http.ApiDtos.LoginRequest;
import hex.orders.infrastructure.inbound.http.ApiDtos.TokenResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final Login login;
    private final Logout logout;
    private final ActorResolver actors;

    public AuthController(Login login, Logout logout, ActorResolver actors) {
        this.login = login;
        this.logout = logout;
        this.actors = actors;
    }

    @PostMapping("/login")
    TokenResponse login(@Valid @RequestBody LoginRequest body) {
        var token = login.execute(new Login.Command(body.email(), body.password()));
        return new TokenResponse(token.value(), "Bearer", token.expiresInSeconds());
    }

    @PostMapping("/logout")
    ResponseEntity<Void> logout(@AuthenticationPrincipal Jwt jwt) {
        logout.execute(actors.logoutCommand(jwt));
        return ResponseEntity.noContent().build();
    }
}
