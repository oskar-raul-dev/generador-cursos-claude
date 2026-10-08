package dev.ms.orders.web;

import dev.ms.orders.service.Actor;
import dev.ms.orders.service.Errors;
import tools.jackson.databind.json.JsonMapper;

import java.util.Base64;
import java.util.Map;
import java.util.UUID;

// orders no verifica tokens: confía en el gateway (decisión A3). Envoy validó la firma y dejó el
// contenido del token en x-jwt-payload (base64url, sin firma). Solo es seguro si NADIE puede llegar a
// orders sin pasar por Envoy: en producción, red interna cerrada o mTLS; en este laboratorio, el
// puerto 28082 está abierto en el host, y el taller lo dice (06/04 §4).
final class ActorResolver {
    private static final JsonMapper JSON = new JsonMapper();

    private ActorResolver() {}

    @SuppressWarnings("unchecked")
    static Actor from(String payloadHeader) {
        if (payloadHeader == null || payloadHeader.isBlank()) throw new Errors.Unauthenticated();
        var claims = (Map<String, Object>) JSON.readValue(Base64.getUrlDecoder().decode(payloadHeader), Map.class);
        return new Actor(UUID.fromString((String) claims.get("sub")), (String) claims.get("email"), (String) claims.get("role"));
    }
}
