DOC = parcial

.PHONY: clean

all: $(DOC).pdf clean

$(DOC).pdf: $(DOC).tex
	latexmk -quiet -pdf -pdflatex="pdflatex -interaction=errorstopmode" -use-make $<

clean:
	latexmk -c
