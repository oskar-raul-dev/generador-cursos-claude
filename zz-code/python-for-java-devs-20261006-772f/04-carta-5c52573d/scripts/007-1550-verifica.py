# rescatado de la sesión 5c52573d, 2026-10-05T15:50:26Z · Build and measure an X12 ISA segment
isa = "ISA*00*" + " "*10 + "*00*" + " "*10 + "*ZZ*" + "AUREA".ljust(15) + "*ZZ*" + "ASEGURADORA".ljust(15) + "*260928*1200*^*00501*000000905*0*T*:~"
print(len(isa)); print(isa); print(repr(isa[3]), repr(isa[104]), repr(isa[105]), repr(isa[82]))
