"""¿La versión nueva del contrato rompe a los clientes de la anterior? Parámetros obligatorios y campos quitados."""

import json

V1 = {"paths": {"/cuotas": {"get": {"parameters": [{"name": "saldo", "required": True}, {"name": "cuota", "required": True}],
      "responses": {"200": {"properties": ["saldo", "cuota", "cuotas"]}}}}}}
V2 = {"paths": {"/cuotas": {"get": {"parameters": [{"name": "saldo", "required": True}, {"name": "cuota", "required": True},
                                                   {"name": "sede", "required": True}],
      "responses": {"200": {"properties": ["saldo", "cuota", "numero_cuotas"]}}}}}}


def breaking(old: dict, new: dict) -> list[str]:
    found = []
    for path, ops in old["paths"].items():
        for method, op in ops.items():
            new_op = new["paths"].get(path, {}).get(method)
            if new_op is None:
                found.append(f"{method.upper()} {path}: desapareció")
                continue
            before = {p["name"] for p in op["parameters"]}
            for p in new_op["parameters"]:
                if p["required"] and p["name"] not in before:
                    found.append(f"{method.upper()} {path}: parámetro obligatorio nuevo '{p['name']}'")
            gone = set(op["responses"]["200"]["properties"]) - set(new_op["responses"]["200"]["properties"])
            found += [f"{method.upper()} {path}: la respuesta ya no trae '{g}'" for g in sorted(gone)]
    return found


print(json.dumps(breaking(V1, V2), ensure_ascii=False, indent=1))
