import re,pathlib,sys
def count(files):
    n=0
    for f in files:
        s=pathlib.Path(f).read_text()
        s=re.sub(r'\{\{-?\s*/\*.*?\*/\s*-?\}\}','',s,flags=re.S)
        n+=sum(1 for l in s.splitlines() if l.strip() and not l.strip().startswith('#'))
    return n
lab=pathlib.Path('.')
plain=[p for p in sorted((lab/'deploy/manifests').rglob('*.yaml')) if p.name!='namespace.yaml']+[p for p in sorted((lab/'deploy/jobs').glob('*.yaml'))]
chart_t=[p for p in (lab/'charts/platform').rglob('*') if p.is_file() and 'templates' in p.parts and p.suffix in ('.yaml','.tpl')]
chart_v=[p for p in (lab/'charts/platform').rglob('*values*.yaml')]
chart_m=[p for p in (lab/'charts/platform').rglob('Chart.yaml')]
print(f"YAML plano de la Fase 12: {len(plain)} archivos, {count(plain)} líneas sin comentarios")
print(f"chart: {len(chart_t)} plantillas ({count(chart_t)} líneas), {len(chart_v)} archivos de valores ({count(chart_v)}), {len(chart_m)} Chart.yaml ({count(chart_m)})")
lab_c=lab/'charts/platform/charts/lab-common/templates/_helpers.tpl'
print(f"  de las plantillas, lab-common: {count([lab_c])} líneas; las de los servicios: {count([p for p in chart_t if p!=lab_c])}")
print(f"  el perfil lab: {count([lab/'charts/platform/values-lab.yaml'])} líneas; medicion: {count([lab/'charts/platform/values-medicion.yaml'])}")
