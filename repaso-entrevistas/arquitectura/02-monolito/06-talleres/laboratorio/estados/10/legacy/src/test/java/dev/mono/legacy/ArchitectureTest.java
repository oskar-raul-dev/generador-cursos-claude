package dev.mono.legacy;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import jakarta.persistence.Entity;
import org.junit.jupiter.api.Test;
import org.springframework.data.repository.Repository;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

// Taller 06: lo que Spring Modulith no mira. Modulith vigila las dependencias ENTRE módulos; estas
// reglas vigilan la forma DENTRO de cada uno. ArchUnit es la versión que trae Modulith 2.1.1.
class ArchitectureTest {
    static final JavaClasses CLASSES = new ClassFileImporter()
        .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
        .importPackages("dev.mono.legacy");

    @Test
    void webLayerDoesNotTouchRepositories() {
        noClasses().that().resideInAPackage("..web..")
            .should().dependOnClassesThat().areAssignableTo(Repository.class)
            .because("un controlador habla con la API de su módulo, no con sus tablas")
            .check(CLASSES);
    }

    @Test
    void entitiesAreInternal() {
        classes().that().areAnnotatedWith(Entity.class)
            .should().resideInAPackage("..internal..")
            .because("una entidad JPA es detalle de su módulo; fuera sale un snapshot o un DTO")
            .check(CLASSES);
    }
}
