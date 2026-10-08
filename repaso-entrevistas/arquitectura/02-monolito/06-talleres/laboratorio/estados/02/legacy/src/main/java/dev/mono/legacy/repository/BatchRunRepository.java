package dev.mono.legacy.repository;

import dev.mono.legacy.entity.BatchRun;
import org.springframework.data.jpa.repository.JpaRepository;


public interface BatchRunRepository extends JpaRepository<BatchRun, Long> {
}
