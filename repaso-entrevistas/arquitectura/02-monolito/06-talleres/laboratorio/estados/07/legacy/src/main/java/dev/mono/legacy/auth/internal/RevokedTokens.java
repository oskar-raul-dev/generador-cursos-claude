package dev.mono.legacy.auth.internal;

import org.springframework.stereotype.Component;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

// tokens cerrados con logout; en memoria, "porque es rápido"
@Component
public class RevokedTokens {
    private final Set<String> jtis = ConcurrentHashMap.newKeySet();

    public void revoke(String jti) { jtis.add(jti); }

    public boolean isRevoked(String jti) { return jti != null && jtis.contains(jti); }
}
