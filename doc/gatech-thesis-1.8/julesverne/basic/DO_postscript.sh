#!/bin/sh -e

# initial latex
latex jules-verne.tex

# make bibliography
bibtex jules-verne

# twice more
latex jules-verne.tex
latex jules-verne.tex

# make postscript
dvips -G0 -Ppdf jules-verne

