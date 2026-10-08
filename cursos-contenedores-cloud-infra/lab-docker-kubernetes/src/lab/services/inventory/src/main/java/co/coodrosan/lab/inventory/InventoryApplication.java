package co.coodrosan.lab.inventory;

import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.scheduling.annotation.EnableScheduling;

// G11: @EnableScheduling, para el barrido de la saga del préstamo (LoanSaga.sweep).
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
