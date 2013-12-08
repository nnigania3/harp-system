REM initial latex
latex jules-verne.tex

REM make bibliography
bibtex jules-verne

REM twice more
latex jules-verne.tex
latex jules-verne.tex

REM make postscript
dvips -G0 -Ppdf jules-verne

