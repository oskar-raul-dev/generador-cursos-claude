# rescatado de la sesión 5c52573d, 2026-10-05T21:29:10Z · Verify docxtpl fixes split placeholder
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar05 && timeout 300 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /tmp python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore docxtpl python-docx==1.2.0 >/dev/null 2>&1; pip list 2>/dev/null | grep -i docxtpl; python -c "
from docx import Document
from docxtpl import DocxTemplate
t=Document(); p=t.add_paragraph(\"Informe de la sede \"); p.add_run(\"{{se\"); p.add_run(\"de}}\").bold=True; t.save(\"p.docx\")
d=DocxTemplate(\"p.docx\"); d.render({\"sede\":\"Kennedy\"}); d.save(\"o.docx\")
print(Document(\"o.docx\").paragraphs[0].text)"'
