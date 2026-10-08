package dev.mono.legacy.dto;

// Taller 04: sin el objeto `user` que el legado devolvía "para que el front no tenga que pedirlo" (con
// el hash de la contraseña dentro)
public record TokenResponse(String accessToken, String tokenType, long expiresIn) {}
