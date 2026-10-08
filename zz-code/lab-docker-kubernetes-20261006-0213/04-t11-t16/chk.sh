u="$1"
r=$(curl -s -o /dev/null -L --max-redirs 5 -m 25 -A "Mozilla/5.0 (Macintosh) curl-check" -w "%{http_code} %{num_redirects} %{url_effective}" "$u")
echo "$r $u"
