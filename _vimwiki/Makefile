
CSS = ./markdown-css-themes/xxx.css
MDFILES = $(wildcard ./md/*.md)
HTMLFILES = $(subst ./md,./html,$(MDFILES:.md=.html))

all: update ${HTMLFILES}

html/%.html: md/%.md
	mkdir -p html;
	pandoc -s -f markdown -t html5 -c ${CSS} $< -o $@;
	python3 scripts/fix_href.py $@;

update:
	for f in ${MDFILES}; do touch ${MDFILES}; done

clean: 
	# for f in ${HTMLFILES}; do /bin/rm $${f}; done
	/bin/rm -rf html;

