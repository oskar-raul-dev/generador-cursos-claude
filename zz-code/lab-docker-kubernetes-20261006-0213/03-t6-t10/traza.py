import json, sys
t = json.load(open(sys.argv[1])); t = t.get('trace', t)
spans = []
for rs in t.get('resourceSpans', []):
    svc = [a['value'].get('stringValue') for a in rs['resource']['attributes'] if a['key'] == 'service.name'][0]
    for ss in rs.get('scopeSpans', []):
        for s in ss['spans']:
            st, en = int(s['startTimeUnixNano']), int(s['endTimeUnixNano'])
            spans.append((st, svc, s['name'], s.get('kind', '').replace('SPAN_KIND_', ''), (en - st) / 1e6))
spans.sort(); t0 = spans[0][0]
print(len(spans), 'spans', sorted({x[1] for x in spans}))
for st, svc, name, kind, dur in spans:
    print(f"{(st - t0) / 1e6:8.1f} ms {dur:8.1f} ms  {svc:10} {kind:7} {name}")
