"""Secretos con tipo que no se imprime, leídos de archivos montados, y el filtro que tapa la bitácora."""

import logging
import os
import pathlib

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

# Lo que montaría Docker en /run/secrets; aquí, una carpeta local para el ejemplo.
secrets_dir = pathlib.Path("secrets")
secrets_dir.mkdir(exist_ok=True)
(secrets_dir / "aurea_cartera_db_password").write_text("Cartera-9f3K!")   # con el prefijo
os.environ["AUREA_DB_HOST"] = "cartera-db.interno"
os.environ["AUREA_PAYMENTS_TOKEN"] = "tok_live_51Hx9"            # este sí, por variable de entorno


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="AUREA_", secrets_dir="secrets")
    db_host: str
    cartera_db_password: SecretStr
    payments_token: SecretStr


settings = Settings()
print("configuración:", settings)


# ------------------------------------------------- el escape clásico, y su tapón
class RedactSecrets(logging.Filter):
    """Reemplaza los valores de los secretos conocidos en cualquier registro."""

    def __init__(self, *secrets: SecretStr):
        super().__init__()
        self.values = [s.get_secret_value() for s in secrets]

    def filter(self, record: logging.LogRecord) -> bool:
        message = record.getMessage()
        for value in self.values:
            message = message.replace(value, "[secreto]")
        record.msg, record.args = message, None
        return True


logging.basicConfig(format="%(levelname)s %(message)s", level=logging.INFO)
log = logging.getLogger("cartera")
dsn = (f"postgresql://cartera:{settings.cartera_db_password.get_secret_value()}"
       f"@{settings.db_host}/cartera")

log.error("no se pudo conectar a %s", dsn)                    # sin filtro: la contraseña sale
log.addFilter(RedactSecrets(settings.cartera_db_password, settings.payments_token))
log.error("no se pudo conectar a %s", dsn)                    # con filtro: tapada

# ------------------------------------------------- lo que ve un volcado del entorno
print("en el entorno:", sorted(k for k in os.environ if k.startswith("AUREA_")))
