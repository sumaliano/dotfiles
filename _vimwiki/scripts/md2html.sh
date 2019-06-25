#!/usr/bin/bash

for f in *md;
do
	pandoc -f markdown -t html -s -c http://thomasf.github.io/solarized-css/solarized-dark.min.css $f -o ${f%.md}.html;
done
	
for f in *html;
do
	python3 fix_href.py $f;
done
