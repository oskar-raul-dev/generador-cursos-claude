# 🧪 convenciones-git-20261007-7514 · cómo correr estas pruebas

> **Curso:** convenciones-git · **Tanda:** alineacion · **Creado:** 2026-10-07
> **Propósito:** generar 00-convencion-de-git-y-tags.md en los cursos en preparación de cursos-bd
> Se llena **mientras se prueba**: cada script nuevo entra aquí en la misma sesión. Las reglas, en
> `zz-code/README.md` § "El README de cada directorio". Si una sección no aplica, se dice por qué.

## 1. 🎯 Qué se prueba y para qué

`generar.py` → escribe `00-convencion-de-git-y-tags.md` en la raíz de los 19 cursos en preparación de
`cursos-bd/` (los once de `ruta-no-sql/`, los siete de `gestores-sql/` y `ruta-sql`), a partir de la
plantilla `zz-instrucciones/plantillas/convencion-de-git-y-tags.md`. Los nombres de cada curso salen
de sus lineamientos (alcance `D-09`, contrato §7, guía); donde no hay decisión, la forma por defecto
con la marca ⏳. No alimenta ningún H-n ni B-n.

## 2. 🛠️ Prerrequisitos

Python 3 (probado con 3.13.4), solo biblioteca estándar. Sin Docker.

## 3. 🧭 Reglas antes de correr

No aplica: no levanta contenedores. **Nunca pisa** un archivo existente: para regenerar uno, primero
se borra ese archivo con `rm`, nombrado.

## 4. ▶️ Cómo se corre

```bash
python3 zz-code/convenciones-git-20261007-7514/generar.py              # vista previa, no escribe
python3 zz-code/convenciones-git-20261007-7514/generar.py --escribir \
  > zz-code/convenciones-git-20261007-7514/salidas/generar.txt
for c in cursos-bd/ruta-no-sql cursos-bd/gestores-sql cursos-bd/ruta-sql; do
  python3 zz-instrucciones/herramientas/verificador_base.py $c --perfil=courses-ia | grep convencion
done
```

Desde la raíz del repositorio. Los datos de cada curso están en el diccionario `CURSOS`.

## 5. 📏 Cómo se mide

No aplica: genera documentos, no mide.

## 6. 🧮 Los intermedios que amasan la salida

No aplica: la salida es el documento generado, con los párrafos rehechos a 100 columnas (`refluir`).

## 7. ✅ Qué se espera ver

Resultado del 2026-10-07, en `salidas/generar.txt`: 19 líneas `escrito …` y el verificador sin
errores sobre los archivos de la convención (solo el aviso `CALLOUT` por 🔑, que los cursos legacy
también usan).

## 8. 📂 Salidas

`salidas/generar.txt`. Los 19 documentos viven en los cursos, no aquí.

## 9. 🧹 Limpieza

Nada fuera de este directorio y de los 19 archivos generados.

## 10. 🚫 Qué se dejó fuera

Nada.
