"""Lee, valida y transforma la factura UBL con lxml, con un parser que no confía en nadie."""

from decimal import Decimal
from pathlib import Path

from lxml import etree

# Nuestro mapa de prefijos: las consultas no dependen de los prefijos que traiga el documento.
NS = {
    "inv": "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2",
    "cac": "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2",
    "cbc": "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
}

# Un parser para XML que llega de afuera: sin entidades, sin red, sin árboles gigantes.
SAFE_PARSER = etree.XMLParser(
    resolve_entities=False,
    no_network=True,
    huge_tree=False,
    remove_blank_text=True,
)

# Las consultas tienen nombre: el código que las usa no sabe nada de XPath.
INVOICE_ID = etree.XPath("string(/inv:Invoice/cbc:ID)", namespaces=NS)
SUPPLIER_NIT = etree.XPath("string(//cac:AccountingSupplierParty//cbc:CompanyID)", namespaces=NS)
LINE_AMOUNTS = etree.XPath("//cac:InvoiceLine/cbc:LineExtensionAmount/text()", namespaces=NS)
LINE_BY_ID = etree.XPath("//cac:InvoiceLine[cbc:ID=$line]/cbc:LineExtensionAmount/text()",
                         namespaces=NS)


def load(path: Path) -> etree._ElementTree:
    return etree.parse(str(path), SAFE_PARSER)


def check_digit(nit: str) -> int:
    """Dígito de verificación del NIT colombiano: pesos primos, módulo 11."""
    weights = (3, 7, 13, 17, 19, 23, 29, 37, 41, 43, 47, 53, 59, 67, 71)
    total = sum(int(d) * w for d, w in zip(reversed(nit), weights))
    rest = total % 11
    return rest if rest in (0, 1) else 11 - rest


def validate(tree: etree._ElementTree, schema_path: Path) -> list[str]:
    schema = etree.XMLSchema(etree.parse(str(schema_path), SAFE_PARSER))
    if schema.validate(tree):
        return []
    # Cada error trae línea y ruta: es lo que hace falta para decirle a Patricia qué corregir.
    return [f"línea {e.line}: {e.path}: {e.message}" for e in schema.error_log]


def summarize(tree: etree._ElementTree) -> dict[str, object]:
    amounts = [Decimal(a) for a in LINE_AMOUNTS(tree)]
    nit_element = tree.find(".//cac:AccountingSupplierParty//cbc:CompanyID", NS)
    declared_dv = int(nit_element.get("schemeID"))
    nit = SUPPLIER_NIT(tree)
    return {
        "invoice": INVOICE_ID(tree),
        "nit": nit,
        "nit_ok": check_digit(nit) == declared_dv,
        "lines": len(amounts),
        "total": sum(amounts, Decimal(0)),
        "line_2": LINE_BY_ID(tree, line="2"),
    }


if __name__ == "__main__":
    tree = load(Path("factura.xml"))
    print(summarize(tree))
    print(validate(tree, Path("factura-minima.xsd")) or "válida")
