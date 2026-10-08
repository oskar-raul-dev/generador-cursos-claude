#!/bin/bash
# Imprime el <main> de una página renderizada en Chrome sin interfaz.
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --dump-dom --virtual-time-budget=5000 --user-data-dir=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/chrome-prof "$1" 2>/dev/null | grep -o '<title>[^<]*</title>\|<main>.*</main>'
