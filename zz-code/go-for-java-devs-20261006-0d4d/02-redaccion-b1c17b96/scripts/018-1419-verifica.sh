# rescatado de la sesión b1c17b96, 2026-09-12T14:19:02Z · Find duplicate project tags across phases
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
for t in "atlassync/v0.2" "clearinghouse/v0.5" "eventrelay/v0.9" "opsreport/v0.5"; do
  echo "── $t"
  grep -ln "git tag -a $t " [01][0-9]-*.md | tr '\n' ' '
  echo
done
