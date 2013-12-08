REM initial latex
pdflatex jules-verne.tex

REM make bibliography
bibtex jules-verne

REM make glossary
bibtex jules-verne.gls

REM make list of symbols
bibtex jules-verne.losa

REM make index
makeindex -s gatech-thesis-index.ist jules-verne.idx

REM twice more
pdflatex jules-verne.tex
pdflatex jules-verne.tex

REM last of all, create the thumbnails
REM Acrobat Reader 5 generates these on-the-fly when
REM the document is loaded, but that's slow.  This
REM process makes .png previews of each page, and
REM puts them into the endproduct.  That way, the 
REM file has thumbnails even in Acrobat Reader 4, 
REM and it opens much faster in Acrobat Reader 5.
REM
REM The following is commented out.  If you're using
REM the bat file, you probably don't have perl...
REM First make the thumbnails
REM   thumbpdf.pl jules-verne.pdf
REM Then add them to the doc
REM   pdflatex jules-verne.tex

