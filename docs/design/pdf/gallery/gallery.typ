// Renders sample.jl under every theme listed below, for side-by-side comparison.
// Build with `make gallery` in the parent directory. To adopt a theme, copy it
// set THEME in ../Makefile. The panel, fonts, fill and size match style.typ.
#let themes = (
  "themes/cadence.tmTheme",
  "themes/GitHub.tmTheme",
  "themes/Solarized_light.tmTheme",
  "themes/Tomorrow.tmTheme",
  "themes/Eiffel.tmTheme",
  "themes/Mac_Classic.tmTheme",
  "themes/Espresso.tmTheme",
  "themes/IDLE.tmTheme",
  "themes/Dawn.tmTheme",
  "themes/Clouds.tmTheme",
)

#set page(paper: "a4", margin: 1.5cm, columns: 2)
#set text(font: "Libertinus Serif", size: 9pt)
#set raw(syntaxes: "../julia.sublime-syntax")
#show raw: set text(font: "JetBrainsMono NF", size: 7pt)
#let sample = read("sample.jl")

#for file in themes [
  #block(breakable: false, width: 100%)[
    #text(weight: "bold")[#file]
    #block(fill: luma(247), inset: 6pt, radius: 3pt, width: 100%)[
      #set raw(theme: file)
      #text(fill: rgb("#333A45"), raw(sample, lang: "julia", block: true))
    ]
  ]
]
