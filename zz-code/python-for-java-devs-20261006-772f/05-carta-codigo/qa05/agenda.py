"""La agenda de un odontólogo: reservar, cancelar y reagendar espacios. Tiene un error sembrado."""

from dataclasses import dataclass, field


class SlotTaken(Exception):
    pass


@dataclass
class Agenda:
    slots: set[str]
    bookings: dict[str, str] = field(default_factory=dict)   # id de reserva → espacio
    taken: dict[str, str] = field(default_factory=dict)      # espacio → paciente
    _next: int = 0

    def book(self, slot: str, patient: str) -> str:
        if slot not in self.slots:
            raise ValueError(f"no existe el espacio {slot}")
        if slot in self.taken:
            raise SlotTaken(slot)
        self._next += 1
        booking_id = f"R{self._next}"
        self.bookings[booking_id] = slot
        self.taken[slot] = patient
        return booking_id

    def cancel(self, booking_id: str) -> None:
        slot = self.bookings.pop(booking_id)
        del self.taken[slot]

    def reschedule(self, booking_id: str, new_slot: str) -> None:
        old_slot = self.bookings[booking_id]
        patient = self.taken[old_slot]
        if new_slot in self.taken and new_slot != old_slot:
            raise SlotTaken(new_slot)
        self.taken[new_slot] = patient
        self.bookings[booking_id] = new_slot
        if new_slot != old_slot:
            del self.taken[old_slot]
