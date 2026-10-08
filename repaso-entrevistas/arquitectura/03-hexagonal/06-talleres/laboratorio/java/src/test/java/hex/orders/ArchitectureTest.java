package hex.orders;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

// La regla de dependencias como prueba: si alguien importa Spring, JPA o un adaptador desde el
// núcleo, el build falla. Es la frontera que el diagrama promete, verificada por el compilador
// de reglas y no por convención de carpetas.
@AnalyzeClasses(packages = "hex.orders", importOptions = ImportOption.DoNotIncludeTests.class)
class ArchitectureTest {

    @ArchTest
    static final ArchRule domainDependsOnNothingOutside = noClasses()
        .that().resideInAPackage("hex.orders.domain..")
        .should().dependOnClassesThat().resideInAnyPackage(
            "hex.orders.application..", "hex.orders.infrastructure..",
            "org.springframework..", "jakarta.persistence..", "org.hibernate..", "com.mongodb..");

    @ArchTest
    static final ArchRule applicationDoesNotKnowInfrastructure = noClasses()
        .that().resideInAPackage("hex.orders.application..")
        .should().dependOnClassesThat().resideInAnyPackage(
            "hex.orders.infrastructure..", "org.springframework..", "jakarta.persistence..",
            "org.hibernate..", "jakarta.servlet..", "com.mongodb..");

    @ArchTest
    static final ArchRule inboundDoesNotTouchOutbound = noClasses()
        .that().resideInAPackage("hex.orders.infrastructure.inbound..")
        .should().dependOnClassesThat().resideInAPackage("hex.orders.infrastructure.outbound..");
}
