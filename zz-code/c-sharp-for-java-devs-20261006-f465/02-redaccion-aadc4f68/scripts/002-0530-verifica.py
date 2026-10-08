# rescatado de la sesión aadc4f68, 2026-09-13T05:30:43Z · 
import unicodedata
f='21-datos-y-onnx.md'
t=open(f,encoding='utf-8').read()
for i,ch in enumerate(t):
    if ord(ch)>127 and 'CYRILLIC' in unicodedata.name(ch,''):
        print(repr(t[i-40:i+20]))
