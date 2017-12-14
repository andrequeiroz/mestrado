DOC = texto
PARTES := $(wildcard ./partes/*)
BASES := $(addprefix ../../dados/, svsim.db o3.db)
MODELOS := $(addprefix ../../modelos/, svsim/svsim.jags.model o3/o3.jags.model1 o3/o3.jags.model2)

.PHONY: all clean

all: $(DOC).pdf

$(DOC).pdf: $(DOC).Rnw $(PARTES) $(BASES) $(MODELOS)
	Rscript -e "knitr::knit2pdf('$<')"

clean:
	rm -rf ./figure $(addprefix $(DOC), .aux .bbl .blg .log .out .tex -tikzDictionary .toc) $(addprefix ./partes/, capa.aux texto-tikzDictionary)
