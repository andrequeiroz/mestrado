DOC = defesa
all: $(DOC).pdf

.PHONY: clean bib

$(DOC).pdf: $(DOC).Rnw
	Rscript -e "knitr::knit2pdf('$<', compiler = 'xelatex')"

bib: ../referencias/mestrado.bib
	bibtex $(DOC)

clean:
	rm -rf $(addprefix $(DOC), .tex .log .aux .out .nav .toc .snm .blg .bbl -tikzDictionary) ./figure
