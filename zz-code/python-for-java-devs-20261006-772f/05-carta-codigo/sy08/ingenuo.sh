for f in $(ls entrada); do
  echo "$f: $(wc -l < entrada/$f)"
done | sort
