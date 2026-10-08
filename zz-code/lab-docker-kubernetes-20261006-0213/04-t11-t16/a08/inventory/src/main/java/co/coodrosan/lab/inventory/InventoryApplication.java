package co.coodrosan.lab.inventory;

import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.aot.hint.annotation.RegisterReflectionForBinding;
import org.springframework.scheduling.annotation.EnableScheduling;

// G11: @EnableScheduling, para el barrido de la saga del préstamo (LoanSaga.sweep).
// a08: los records que viajan en ResponseEntity<Object> o por JSON: el AOT de Spring no los ve, y la imagen nativa
// necesita saber de antemano que Jackson va a leer sus componentes.
@RegisterReflectionForBinding({StockController.StockLevel.class, StockController.MovementRequest.class,
        StockController.StockMovement.class, StockController.ReasonCode.class, SalesController.SaleRequest.class,
        SalesController.Sale.class, LoansController.LoanRequest.class, LoanSaga.Loan.class, LoanSaga.LoanStep.class})
@SpringBootApplication
@EnableScheduling
public class InventoryApplication {

	public static void main(String[] args) {
		// `java -jar … migrate`: el Job de migraciones (G3). Sin servidor web: migra y termina.
		if (args.length > 0 && args[0].equals("migrate")) {
			SpringApplication app = new SpringApplication(InventoryApplication.class);
			app.setWebApplicationType(WebApplicationType.NONE);
			var context = app.run(args);
			context.getBean(Migrator.class).migrate();
			System.exit(SpringApplication.exit(context));
		}
		SpringApplication.run(InventoryApplication.class, args);
	}

	// Con SQLite, el esquema se crea al arrancar, como en G1. Con Postgres, no: lo crea el Job, antes.
	@Bean
	ApplicationRunner migrateSqliteOnStartup(Migrator migrator) {
		return args -> {
			if (!StoreConfig.postgres() && !(args.getSourceArgs().length > 0 && args.getSourceArgs()[0].equals("migrate"))) {
				migrator.migrate();
			}
		};
	}

}
