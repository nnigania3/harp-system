#!/bin/sh -e

# initial latex
latex jules-verne.tex

# make bibliography
bibtex jules-verne

# make glossary
bibtex jules-verne.gls

# make list of symbols 
bibtex jules-verne.losa

# make index
makeindex -s gatech-thesis-index.ist jules-verne.idx

# twice more
latex jules-verne.tex
latex jules-verne.tex

# make postscript
dvips -G0 -Ppdf jules-verne

