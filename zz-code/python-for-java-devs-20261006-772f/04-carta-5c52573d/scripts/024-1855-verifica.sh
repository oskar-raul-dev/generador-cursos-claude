# rescatado de la sesión 5c52573d, 2026-10-05T18:55:14Z · Pull JDK image and list Avro dependencies
echo "eclipse-temurin:21.0.12.1_1-jdk" >> /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/imagenes-bajadas.txt; (docker image inspect eclipse-temurin:21.0.12.1_1-jdk >/dev/null 2>&1 || docker pull -q eclipse-temurin:21.0.12.1_1-jdk) | tail -1; curl -s https://repo1.maven.org/maven2/org/apache/avro/avro/1.12.2/avro-1.12.2.pom | python3 -c "
import sys,re
t=sys.stdin.read()
for d in re.findall(r'<dependency>(.*?)</dependency>',t,re.S):
    g=re.search(r'<groupId>(.*?)</groupId>',d).group(1); a=re.search(r'<artifactId>(.*?)</artifactId>',d).group(1)
    v=re.search(r'<version>(.*?)</version>',d); s=re.search(r'<scope>(.*?)</scope>',d); o=re.search(r'<optional>(.*?)</optional>',d)
    print(g,a,v.group(1) if v else '-', s.group(1) if s else 'compile', 'optional' if o else '')"; curl -s https://repo1.maven.org/maven2/org/apache/avro/avro-parent/1.12.2/avro-parent-1.12.2.pom | grep -o "<jackson-bom.version>[^<]*\|<slf4j.version>[^<]*\|<commons-compress.version>[^<]*"
