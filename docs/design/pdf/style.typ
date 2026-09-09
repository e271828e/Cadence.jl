// Typst styling for the design PDFs, included by pdf.yaml.
// The theme path arrives as the Typst input `theme`, set by THEME in the
// Makefile; the Julia grammar is the patched julia.sublime-syntax.
// Typst ignores the theme's default foreground, so unscoped code takes the fill set here.
#set raw(theme: sys.inputs.at("theme"), syntaxes: "julia.sublime-syntax")
#show raw: set text(size: 8.5pt)
#show raw.where(block: true): it => block(
  fill: luma(247), inset: 8pt, radius: 3pt, width: 100%,
  text(fill: rgb("#333A45"), it))
// Pandoc wraps tables in figures, which Typst won't break across pages.
#show figure.where(kind: table): set block(breakable: true)
// Pandoc's wrapper centers tables; cells read better left-aligned and ragged.
#show table.cell: set align(left)
#show table.cell: set par(justify: false)
// A nested list is a block inside its parent item, and Typst puts paragraph
// spacing above it; match the tight list leading instead.
#show list.item: set block(above: 0.65em)
