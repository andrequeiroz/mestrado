DOC = lambda
BASE := ../../dados/svsim.db

.PHONY: all clean

all: $(DOC).pdf clean

$(DOC).pdf: $(DOC).Rnw $(BASE)
	Rscript -e "knitr::knit2pdf('$<', clean = TRUE)"

clean:
	rm -rf ./figure $(addprefix $(DOC), .log .aux .tex)
