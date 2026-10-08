# rescatado de la sesión aadc4f68, 2026-09-13T05:30:51Z · 
import unicodedata
t=open('/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs/21-datos-y-onnx.md',encoding='utf-8').read()
bad=[ch for ch in set(t) if ord(ch)>127 and ('CYRILLIC' in unicodedata.name(ch,'') or 'GREEK' in unicodedata.name(ch,''))]
print(bad)
