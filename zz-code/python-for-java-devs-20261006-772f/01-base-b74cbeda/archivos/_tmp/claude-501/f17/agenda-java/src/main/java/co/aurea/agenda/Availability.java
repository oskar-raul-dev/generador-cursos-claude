package co.aurea.agenda;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;

public record Availability(String branch, LocalDate day, List<Slot> slots) {

    private static final ZoneOffset BOGOTA = ZoneOffset.ofHours(-5);

    public record Slot(OffsetDateTime startsAt, int minutes) {}

    public static Availability of(String branch, LocalDate day) {
        List<Slot> slots = new ArrayList<>(36);
        for (int hour = 7; hour < 19; hour++) {
            for (int minute : new int[] {0, 20, 40}) {
                slots.add(new Slot(OffsetDateTime.of(day, LocalTime.of(hour, minute), BOGOTA), 20));
            }
        }
        return new Availability(branch, day, slots);
    }
}
