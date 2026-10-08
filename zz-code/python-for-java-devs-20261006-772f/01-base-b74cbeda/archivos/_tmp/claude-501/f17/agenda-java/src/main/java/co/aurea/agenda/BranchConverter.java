package co.aurea.agenda;

import co.aurea.agenda.AvailabilityController.Branch;
import java.util.Locale;
import org.springframework.core.convert.converter.Converter;
import org.springframework.stereotype.Component;

/** Acepta la sede en minúsculas, igual que la API de Python. */
@Component
public class BranchConverter implements Converter<String, Branch> {
    @Override
    public Branch convert(String source) {
        return Branch.valueOf(source.toUpperCase(Locale.ROOT));
    }
}
