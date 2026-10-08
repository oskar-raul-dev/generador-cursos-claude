# rescatado de la sesión 03630220, 2026-09-13T18:25:37Z · Version consistency audit
echo "--- SDK ---"; grep -rhoE "10\.0\.[0-9]+" *.md | sort | uniq -c
echo "--- EF Core / libs ---"; grep -rhoE "(EF Core|Dapper|xUnit[^ ]*|Testcontainers|NSubstitute|BenchmarkDotNet|Serilog|Polly)[ v]*[0-9]+\.[0-9]+\.[0-9]+" *.md | sort | uniq -c
echo "--- C#/Java/VS ---"; grep -rhoE "(C# [0-9.]+|Java [0-9]+( LTS)?|Visual Studio [A-Za-z]* ?[0-9]+(, [0-9.]+)?|SQL Server [0-9]+|\.NET Framework [0-9.]+|\.NET [0-9]+)" *.md | sort | uniq -c | sort -rn | head -40
