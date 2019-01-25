PACKAGENAME=simple-oauth2
COLLECTS=oauth2
SCRBL=./scribblings/$(PACKAGENAME).scrbl

all: setup test

clean:
	find . -name compiled -type d | xargs rm -rf
	rm -rf $(COLLECTS)/doc
	rm -rf coverage

setup:
	raco setup --tidy $(COLLECTS)

link:
	raco pkg install --link -n $(PACKAGENAME) $(shell pwd)

unlink:
	raco pkg remove $(PACKAGENAME)

test:
	raco test -t -c $(COLLECTS)

coverage:
	raco cover -b -f coveralls -p $(PACKAGENAME)

readme: README.md
	markdown -r markdown_github -w html5 -o ./doc/readme.html \
		--standalone --self-contained README.md

htmldocs: $(SCRBL)
	raco scribble \
		--html \
		--dest $(COLLECTS)/doc \
		--dest-name index \
		++main-xref-in \
		--redirect-main http://docs.racket-lang.org/ \
		\
		$(SCRBL)

viewdocs:
	raco docs
