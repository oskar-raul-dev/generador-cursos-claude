# rescatado de la sesión 5c52573d, 2026-10-05T16:36:47Z · Smoke-test wf03 twice and schedule tz
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op024-wf03-programacion-en-proceso.md wf03 'agenda_cache.py="""Dos réplicas' --pip apscheduler==3.11.3 schedule==1.2.2 --cmd "python agenda_cache.py; echo ---; python agenda_cache.py; echo ---; python -c \"
import schedule
j = schedule.every().day.at('08:00', 'America/Bogota').do(print)
print(j.next_run)\""
