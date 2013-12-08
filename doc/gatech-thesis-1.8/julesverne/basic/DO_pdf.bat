REM initial latex
pdflatex jules-verne.tex

REM make bibliography
bibtex jules-verne

REM twice more
pdflatex jules-verne.tex
pdflatex jules-verne.tex
