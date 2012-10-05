distdir=dist
distfile=$(distdir)/2012.sqlite3

gzfile=$(patsubst %,%.gz,$(distfile))
programs=$(wildcard programs/*.html)

all: upload

fetch:
	./fetch.pl

update: $(distfile)
compress: $(gzfile)

upload: update compress
	./upload.sh $(distdir)

$(distfile): compile.pl $(programs) area.yml category.yml
	@mkdir -p $(dir $@)
	./compile.pl $@

%.gz: %
	gzip -c $< >$@

prove:
	prove -l

clean:
	rm -f $(distfile) $(gzfile)
