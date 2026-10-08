package dev.mono.legacy;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class LegacyApplication {
    public static void main(String[] args) {
        SpringApplication.run(LegacyApplication.class, args);
    }
}
