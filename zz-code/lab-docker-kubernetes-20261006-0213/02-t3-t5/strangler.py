import urllib.request, collections, sys, json
c=collections.Counter(); precios=collections.Counter()
for i in range(200):
    r=urllib.request.urlopen("http://api.localhost:8080/pricing/prices/SKU-0003?store=DRO-007")
    who=r.headers.get("X-Contestado-Por","pricing"); c[who]+=1; precios[json.loads(r.read())["price"]]+=1
print(sys.argv[1], dict(c), "precios:", dict(precios))
