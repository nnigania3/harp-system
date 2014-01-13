PAPER = wondp-sim
TEX = $(wildcard *.tex)
BIB = references.bib
FIGS = fig/harmonica.pdf fig/chdl.pdf fig/toolchain.pdf fig/arch.pdf

.PHONY: all clean

$(PAPER).pdf: $(TEX) $(BIB) $(FIGS) jpaper.cls
	echo $(FIGS)
	pdflatex $(PAPER)
	bibtex $(PAPER)
	pdflatex $(PAPER)
	pdflatex $(PAPER)

fig/%.pdf : fig/%.fig
	cd fig; fig2mpdf $(<F);	cd ..

clean:
	rm -f *.aux *.bbl *.blg *.log *.out $(PAPER).pdf fig/toolchain.pdf \
              fig/harmonica.pdf fig/arch.pdf
