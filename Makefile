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

$(distfile): compile.pl $(programs) area.yml category.yml hint.yml
	@mkdir -p $(dir $@)
	./compile.pl $@
	sqlite3 $@ "vacuum"
	sqlite3 $@ "select area,count(*) from location group by area"
	sqlite3 $@ "select category,count(*) from entry group by category"

%.gz: %
	gzip -c $< >$@

prove:
	prove -l

clean:
	rm -f $(distfile) $(gzfile)
