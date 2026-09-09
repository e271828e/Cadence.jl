# Render the design documents to PDF. Run `make` here or from a git hook.
# Requires pandoc and typst (brew install pandoc typst).
# The default target is design.pdf, the spec and the decision log in one
# document, so that every cross-reference is an internal link. `make pair`
# renders the two separately; their cross-document links do not work in
# Preview. Settings live in pdf.yaml and style.typ. THEME selects the code
# color theme; `make gallery` renders sample code under every theme in
# gallery/themes/; `make shades` renders lighter and darker variants of one color.

THEME = gallery/themes/cadence.tmTheme
STYLE = pdf.yaml pdflinks.lua tablewidths.lua inlinecode.lua style.typ julia.sublime-syntax $(THEME) Makefile
PANDOC = pandoc -d pdf.yaml --pdf-engine-opt=--input=theme=$(THEME)

pdf: ../design.pdf

../design.pdf: ../spec.md ../decisions.md $(STYLE)
	$(PANDOC) -M combined=true ../spec.md ../decisions.md -o $@

pair: ../spec.pdf ../decisions.pdf

../%.pdf: ../%.md $(STYLE)
	$(PANDOC) $< -o $@

gallery: gallery/gallery.pdf

gallery/gallery.pdf: gallery/gallery.typ gallery/sample.jl gallery/themes/*.tmTheme julia.sublime-syntax
	typst compile --root .. $< $@

shades: gallery/shades.pdf

gallery/shades.pdf: gallery/shades.typ
	typst compile $< $@

.PHONY: pdf pair gallery shades
