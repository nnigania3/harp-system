REM initial latex
latex jules-verne.tex

REM make bibliography
bibtex jules-verne

REM make glossary
bibtex jules-verne.gls

REM make list of symbols
bibtex jules-verne.losa

REM make index
makeindex -s gatech-thesis-index.ist jules-verne.idx

REM twice more
latex jules-verne.tex
latex jules-verne.tex

REM make postscript
dvips -G0 -Ppdf jules-verne

