import ftplib
import ssl

with ftplib.FTP_TLS(context=ssl.create_default_context(), timeout=30) as ftp:
    ftp.connect("ftps.aseguradora.example", 21)
    ftp.login("aurea", "…")
    pass
    for name, facts in ftp.mlsd("salida/aurea"):
        if facts["type"] == "file":
            print(name, facts["size"], facts["modify"])
