DOC = dissertacao
all: $(DOC).pdf

.PHONY: clean bib

$(DOC).pdf: $(DOC).Rnw $(addprefix ./estrutura/, capa.tex rosto.tex termo.tex catalogo.tex dedicatoria.tex agradecimento.tex resumo.tex abstract.tex) $(addprefix ./partes/, 1_intro.Rnw 2_mld.Rnw 3_mvs.Rnw 4_estimacao.Rnw 5_resultados.Rnw 6_conclusao.Rnw anexo.Rnw)
	Rscript -e "knitr::knit2pdf('$<', compiler = 'xelatex')"

bib: ../mestrado.bib
	bibtex $(DOC)

clean:
	rm -rf $(addprefix $(DOC), .log .aux .out .tex .toc .bbl .blg .lof .lot .lol -tikzDictionary) ./figure ./estrutura/*.aux
