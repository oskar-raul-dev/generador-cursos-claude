from fabric import Connection
conn = Connection("pfjd-centro", port=22, user="revisor",
                  connect_kwargs={"key_filename": "revisor", "look_for_keys": False})
result = conn.run("stat -c '%s %Y' /respaldos/odontovia.sql.gz", hide=True, warn=True)
print(result.ok, result.stdout.strip().split()[0])
bad = conn.run("stat /no/existe", hide=True, warn=True)
print(bad.ok, bad.exited)
