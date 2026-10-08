package dev.ms.monolith.service;

import dev.ms.monolith.repository.IdempotencyRepository;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;

// Una operación con Idempotency-Key se ejecuta una vez: la repetición devuelve la respuesta
// guardada, y la misma clave con otro cuerpo es un error del cliente. Se guarda en la MISMA
// transacción que el efecto (quien llama ya está dentro de una).
@Component
public class Idempotency {

    public record Replay(int status, String body) {}

    private final IdempotencyRepository repo;
    private final JsonMapper json;

    public Idempotency(IdempotencyRepository repo, JsonMapper json) { this.repo = repo; this.json = json; }

    public Optional<Replay> lookup(String key, Actor actor, Object request) {
        if (key == null || key.isBlank()) throw new Errors.IdempotencyKeyRequired();
        return repo.find(key, actor.id()).map(stored -> {
            if (!stored.requestHash().equals(hash(request))) throw new Errors.IdempotencyKeyReused();
            return new Replay(stored.status(), stored.body());
        });
    }

    public void remember(String key, Actor actor, Object request, int status, Object response) {
        repo.save(key, actor.id(), hash(request), status, json.writeValueAsString(response));
    }

    /** Sustituye la respuesta guardada: solo para resolver un resultado incierto (PAYMENT_PENDING). */
    public void resolve(String key, Actor actor, Object response) {
        repo.replaceBody(key, actor.id(), json.writeValueAsString(response));
    }

    private String hash(Object request) {
        try {
            var digest = MessageDigest.getInstance("SHA-256").digest(json.writeValueAsString(request).getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

}
