# pdf creator and index creator
LATEX  = pdflatex
BIBTEX = bibtex
DVIPDF = dvipdf
INDEX  = makeindex

# filename ant extensions
FILE = "thesis_main"
TEXEXT = .tex
DVIEXT = .dvi
PDFEXT = .pdf
IDXEXT = .idx
NOMEXT = .nlo
GLSEXT = .nls

#
VIEW = okular
GREP = grep
LS   = ls

all:
	@make compile

compile:
	@$(LATEX) $(FILE)$(TEXEXT)
#	@$(BIBTEX) $(FILE)
#	@$(LATEX) $(FILE)$(TEXEXT)
	@$(LATEX) $(FILE)$(TEXEXT)

view:
	@$(VIEW) $(FILE)$(PDFEXT) &

clean:
	@$(LS) $(FILE).* | $(GREP) -v $(TEXEXT) | xargs $(RM)
	@$(RM) *~
	@$(RM) *.aux
	@$(RM) **/*.aux
