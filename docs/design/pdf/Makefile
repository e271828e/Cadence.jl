# Render the design documents to PDF. Run `make` here or from a git hook.
# Requires pandoc and typst (brew install pandoc typst).
# Settings live in pdf.yaml and style.typ. THEME selects the code color theme;
# `make gallery` renders sample code under every theme in gallery/themes/;
# `make shades` renders a strip of lighter and darker variants of one color.

THEME = gallery/themes/cadence.tmTheme
STYLE = pdf.yaml pdflinks.lua tablewidths.lua inlinecode.lua style.typ julia.sublime-syntax $(THEME) Makefile

pdf: ../spec.pdf ../decisions.pdf

../%.pdf: ../%.md $(STYLE)
	pandoc -d pdf.yaml --pdf-engine-opt=--input=theme=$(THEME) $< -o $@

gallery: gallery/gallery.pdf

gallery/gallery.pdf: gallery/gallery.typ gallery/sample.jl gallery/themes/*.tmTheme julia.sublime-syntax
	typst compile --root .. $< $@

shades: gallery/shades.pdf

gallery/shades.pdf: gallery/shades.typ
	typst compile $< $@

.PHONY: pdf gallery shades
