// Shades of one color, for picking a theme value by eye. Edit `base` and the
// steps, build with `make shades`, then copy the hex you like into the theme.
#let base = rgb("#7A5A3C")
#let steps = (-30%, -20%, -10%, 0%, 10%, 20%, 30%, 40%)

#set page(paper: "a4", margin: 1.5cm)
#set text(font: "Libertinus Serif", size: 10pt)
#show raw: set text(font: "JetBrainsMono NF", size: 8.5pt)

#let sample(c) = [
  Physically #text(fill: c, raw("y")) is reconstructed per call from cells:
  one declared port, one cell (#text(fill: c, raw("pose")) = KinPose{T}).
  The stage functions #text(fill: c, raw("output_state"))/#text(fill: c, raw("output_direct"))
  read #text(fill: c, raw("x, m, t [, ws]")); see #text(fill: c, raw("state_derivative")).
]

#for s in steps {
  let c = if s < 0% { base.darken(-s) } else { base.lighten(s) }
  block(width: 100%, inset: (y: 4pt))[
    #box(width: 2.2cm, fill: c, height: 1.2em, radius: 2pt)
    #h(6pt) #raw(upper(c.to-hex())) #h(6pt)
    #text(size: 8pt, fill: luma(100))[#if s < 0% [darker #(-s)] else if s == 0% [current] else [lighter #s]]
    #sample(c)
  ]
}
