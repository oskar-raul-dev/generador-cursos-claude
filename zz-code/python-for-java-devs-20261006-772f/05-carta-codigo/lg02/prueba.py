from pathlib import Path
from lxml import etree
import factura_xml as f
print(f.summarize(f.load(Path("factura.xml"))))
print(len(etree.parse("bomba.xml").getroot().text or ""))
print(etree.parse("bomba.xml", f.SAFE_PARSER).getroot().text)
