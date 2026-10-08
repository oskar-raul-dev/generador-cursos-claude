package co.aurea.agenda;

import java.time.LocalDate;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AvailabilityController {

    @GetMapping("/availability")
    public Availability availability(
            @RequestParam Branch branch,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate day) {
        return Availability.of(branch.name().toLowerCase(), day);
    }

    public enum Branch { CENTRO, CHAPINERO, SUBA, KENNEDY, USAQUEN }
}
