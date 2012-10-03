distdir=dist
dbfile=$(distdir)/2012.sqlite3
xmlfile=$(distdir)/2012.xml
dtdfile=$(distdir)/dtd

distfiles=$(dbfile) $(xmlfile)
gzfiles=$(patsubst %,%.gz,$(distfiles))

programs=$(wildcard programs/*.html)

all: upload

fetch:
	./fetch.pl

update: $(distfiles)
compress: $(gzfiles)

upload: update compress $(dtdfile)
	xmllint --dtdvalid $(dtdfile) $(xmlfile) >/dev/null
	./upload.sh $(distdir)

$(distfiles): $(programs)
	@mkdir -p $(dir $@)
	./compile.pl $@

%.gz: %
	@mkdir -p $(dir $@)
	gzip -c $< >$@

prove:
	prove -l

clean:
	rm -f $(distfiles) $(gzfiles)
