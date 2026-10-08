package dev.mono.legacy;

import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModule;
import org.springframework.modulith.core.ApplicationModules;

import java.util.stream.Collectors;

// Taller 06: Spring Modulith toma cada subpaquete directo de dev.mono.legacy como un módulo, su raíz
// como API pública y sus subpaquetes como internos. verify() falla ante un ciclo, un acceso a un tipo
// interno de otro módulo o una dependencia fuera de allowedDependencies (package-info.java).
class ModularityTest {
    static final ApplicationModules MODULES = ApplicationModules.of(LegacyApplication.class);

    @Test
    void modulesAreVerified() {
        // el grafo real, calculado desde el bytecode: es la evidencia, no el dibujo
        MODULES.forEach(m -> System.out.println("módulo " + m.getIdentifier() + " → " + dependencies(m)));
        MODULES.verify();
    }

    private static String dependencies(ApplicationModule module) {
        return module.getDirectDependencies(MODULES).uniqueModules()
            .map(d -> d.getIdentifier().toString()).sorted().collect(Collectors.joining(", ", "[", "]"));
    }
}
