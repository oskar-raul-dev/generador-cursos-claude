# rescatado de la sesión aadc4f68, 2026-09-13T04:54:50Z · 
import unicodedata,glob
allowed=set('⏳🔜🪦🧬💸💲🧭🧠⚠️💡📝🪞🩻⚰️📖⚖️🧪🧱📏📚🚀📌🎯✅🚫💻🗂️📐🔧🏷️⭐🔭🧵💵📊🏛️🗄️🚚🪟🌐🧰🎲🏚️✔️😉▶️')
for f in ['18-blazor-server-wasm-mvc.md','19-observabilidad-y-operacion.md','20-contenedor-y-la-factura.md']:
    t=open(f,encoding='utf-8').read()
    bad={}
    for ch in set(t):
        o=ord(ch)
        if o<128: continue
        cat=unicodedata.category(ch)
        if cat in ('Lm','Cf','Mn') or (cat=='Zs' and ch!=' '):
            bad[ch]=bad.get(ch,0)+t.count(ch)
    print(f, bad)
