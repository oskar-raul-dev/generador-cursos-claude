import sys, json, time, subprocess, datetime
LAB="/Users/oskar/Developer/Learning/courses-ia-generated/cursos-contenedores-cloud-infra/lab-docker-kubernetes/src/lab"
sys.path.insert(0, LAB+"/scripts/measure")
import measure
out=[]
for n in range(3):
    subprocess.run(["task","cluster:down","--","minimo"],cwd=LAB,capture_output=True)
    subprocess.run(["task","cluster:up","--","minimo"],cwd=LAB,check=True,capture_output=True)
    r=measure.Run("docker","minimo")
    r.wait_all_ready(); time.sleep(60); before=r.vm_memory()["used_mib"]
    subprocess.run(["task","images:load","--","minimo"],cwd=LAB,check=True,capture_output=True)
    subprocess.run(["task","deploy","--","minimo"],cwd=LAB,check=True,capture_output=True)
    snap=r.snapshot(60)
    res={"date":datetime.datetime.now().isoformat(timespec="seconds"),"vm_cluster_mib":before,"vm_with_services_mib":snap["vm"]["used_mib"],"pods_by_ns":snap["pods_by_ns"]}
    print(json.dumps(res),flush=True); out.append(res)
json.dump(out,open(LAB+"/bench/b00/results/docker-minimo-servicios-g1-2026-10-03.json","w"),indent=2)
