"""La agenda contra un modelo ingenuo, con secuencias que genera Hypothesis."""

from hypothesis import settings
from hypothesis import strategies as st
from hypothesis.stateful import Bundle, RuleBasedStateMachine, consumes, invariant, rule

from agenda import Agenda, SlotTaken

SLOTS = ["08:00", "08:40", "09:20", "15:00", "15:40"]
slots = st.sampled_from(SLOTS)
patients = st.sampled_from(["PAC-1", "PAC-2", "PAC-3"])


class AgendaMachine(RuleBasedStateMachine):
    bookings = Bundle("bookings")

    def __init__(self):
        super().__init__()
        self.agenda = Agenda(set(SLOTS))
        self.model: dict[str, str] = {}               # el modelo: espacio → paciente, y nada más
        self.where: dict[str, str] = {}               # reserva → espacio, en el modelo

    @rule(target=bookings, slot=slots, patient=patients)
    def book(self, slot, patient):
        if slot in self.model:
            try:
                self.agenda.book(slot, patient)
            except SlotTaken:
                return None                           # rechazar está bien: el modelo dice que está ocupado
            raise AssertionError(f"reservó {slot}, que estaba ocupado")
        booking_id = self.agenda.book(slot, patient)
        self.model[slot], self.where[booking_id] = patient, slot
        return booking_id

    @rule(booking=consumes(bookings))
    def cancel(self, booking):
        if booking is None:
            return
        self.agenda.cancel(booking)
        del self.model[self.where.pop(booking)]

    @rule(booking=bookings, new_slot=slots)
    def reschedule(self, booking, new_slot):
        if booking is None or booking not in self.where:
            return
        old = self.where[booking]
        if new_slot in self.model and new_slot != old:
            return                                     # el modelo no lo permite: no se intenta
        self.agenda.reschedule(booking, new_slot)
        self.model[new_slot] = self.model.pop(old)
        self.where[booking] = new_slot

    @invariant()
    def agenda_matches_model(self):
        assert self.agenda.taken == self.model


AgendaMachine.TestCase.settings = settings(max_examples=200, stateful_step_count=20)
TestAgenda = AgendaMachine.TestCase
