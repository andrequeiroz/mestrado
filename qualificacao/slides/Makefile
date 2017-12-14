DOC = slides
BASE := ../../dados/svsim.db

.PHONY: all clean

all: $(DOC).pdf

$(DOC).pdf: $(DOC).Rnw $(BASE)
	Rscript -e "knitr::knit2pdf('$<')"

clean:
	rm -rf ./figure $(addprefix $(DOC), .aux .bbl .blg .log .nav .out .snm .tex -tikzDictionary .toc)
