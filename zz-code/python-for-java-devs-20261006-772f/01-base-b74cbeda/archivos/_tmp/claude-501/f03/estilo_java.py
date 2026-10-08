"""El motor de comisiones escrito con el reflejo de Java: jerarquía de estrategias."""

from abc import ABC, abstractmethod
from decimal import Decimal


class ReferralFeePolicy(ABC):
    """Contrato de cálculo de la comisión de un aliado."""

    @abstractmethod
    def calculate(self, treatment_value: Decimal, specialty: str,
                  month_to_date: Decimal) -> Decimal:
        ...


class PercentagePolicy(ReferralFeePolicy):
    def __init__(self, percentage: Decimal) -> None:
        self._percentage = percentage

    def calculate(self, treatment_value, specialty, month_to_date):
        return treatment_value * self._percentage


class MinimumPerCasePolicy(ReferralFeePolicy):
    def __init__(self, percentage: Decimal, minimum: Decimal) -> None:
        self._percentage = percentage
        self._minimum = minimum

    def calculate(self, treatment_value, specialty, month_to_date):
        return max(treatment_value * self._percentage, self._minimum)


class MonthlyCapPolicy(ReferralFeePolicy):
    def __init__(self, percentage: Decimal, cap: Decimal) -> None:
        self._percentage = percentage
        self._cap = cap

    def calculate(self, treatment_value, specialty, month_to_date):
        fee = treatment_value * self._percentage
        remaining = self._cap - month_to_date
        return min(fee, max(remaining, Decimal("0")))


class BySpecialtyPolicy(ReferralFeePolicy):
    def __init__(self, default: Decimal, by_specialty: dict[str, Decimal]) -> None:
        self._default = default
        self._by_specialty = by_specialty

    def calculate(self, treatment_value, specialty, month_to_date):
        return treatment_value * self._by_specialty.get(specialty, self._default)


class ReferralFeePolicyFactory:
    """Construye la política de cada aliado."""

    def __init__(self) -> None:
        self._policies: dict[str, ReferralFeePolicy] = {}

    def register(self, partner_id: str, policy: ReferralFeePolicy) -> None:
        self._policies[partner_id] = policy

    def get(self, partner_id: str) -> ReferralFeePolicy:
        if partner_id not in self._policies:
            raise KeyError(f"aliado sin política registrada: {partner_id}")
        return self._policies[partner_id]


class ReferralFeeCalculator:
    def __init__(self, factory: ReferralFeePolicyFactory) -> None:
        self._factory = factory

    def calculate(self, partner_id, treatment_value, specialty, month_to_date):
        return self._factory.get(partner_id).calculate(
            treatment_value, specialty, month_to_date
        )


def build_factory() -> ReferralFeePolicyFactory:
    factory = ReferralFeePolicyFactory()
    factory.register("P001", PercentagePolicy(Decimal("0.15")))
    factory.register("P002", PercentagePolicy(Decimal("0.12")))
    factory.register("P003", PercentagePolicy(Decimal("0.20")))
    factory.register("P004", MinimumPerCasePolicy(Decimal("0.10"), Decimal("150000")))
    factory.register("P005", MonthlyCapPolicy(Decimal("0.18"), Decimal("2000000")))
    factory.register("P006", BySpecialtyPolicy(
        Decimal("0.10"), {"implantologia": Decimal("0.20"), "endodoncia": Decimal("0.12")}))
    return factory
