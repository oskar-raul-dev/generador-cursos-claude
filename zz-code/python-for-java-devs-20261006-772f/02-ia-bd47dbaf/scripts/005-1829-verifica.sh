# rescatado de la sesión bd47dbaf, 2026-09-13T18:29:33Z · Verify the multi-word term bug
python3 -c '
SYMPTOM_TERMS = frozenset("""
    duele dolor adolorido
    no puedo comer no puedo masticar
    """.split())
print(sorted(SYMPTOM_TERMS))
msg = "buenas, no tienen cita el jueves?"
print("escala?", bool(set(msg.split()) & SYMPTOM_TERMS))
'
