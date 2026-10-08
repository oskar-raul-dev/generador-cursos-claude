"""Verifica por código de estado las URL de los .md que se le pasan (guía §14.3).

Uso: python3 verificar_urls.py <archivo.md>...
Imprime una línea por URL que no responde 200 (después de seguir redirecciones), con el destino
final cuando cambió de dominio o cayó en una portada. Sin dependencias.
"""
import re, sys, urllib.request, urllib.error, urllib.parse, concurrent.futures as cf

URL_RE = re.compile(r"https?://[^\s<>()`\"'\]]+")
CABECERAS = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) verificador-curso/1.0"}

def limpiar(u):
    return u.rstrip(".,;:*_")

def consultar(url):
    for metodo in ("HEAD", "GET"):
        try:
            req = urllib.request.Request(url, method=metodo, headers=CABECERAS)
            with urllib.request.urlopen(req, timeout=25) as r:
                return r.status, r.geturl()
        except urllib.error.HTTPError as e:
            if metodo == "HEAD" and e.code in (403, 405, 400, 404, 429, 501):
                continue
            return e.code, url
        except Exception as e:  # red, TLS, tiempo
            if metodo == "HEAD":
                continue
            return f"ERR {type(e).__name__}", url
    return "?", url

def main(archivos):
    urls = {}
    for f in archivos:
        texto = re.sub(r"```.*?```", "", open(f, encoding="utf-8").read(), flags=re.S)  # el código no es referencia
        for u in URL_RE.findall(texto):
            u = limpiar(u)
            if "localhost" in u or "127.0.0.1" in u or "example." in u or ".example" in u:
                continue
            urls.setdefault(u, f)
    malas = 0
    with cf.ThreadPoolExecutor(8) as ex:
        for (u, f), (st, final) in zip(urls.items(), ex.map(consultar, urls)):
            portada = urllib.parse.urlparse(final).path in ("", "/") and urllib.parse.urlparse(u).path not in ("", "/")
            if st != 200 or portada:
                malas += 1
                print(f"{st}\t{f}\t{u}" + (f"\t→ {final}" if final != u else ""))
    print(f"— {len(urls)} URL, {malas} a revisar")

if __name__ == "__main__":
    main(sys.argv[1:])
