# Naming inventory: test/fixtures.jl

Tip: 0c0a899. Sites flagged: 338. Renames: 2. Collisions: 0. Roster proposals: 0.
Kept without a row: keep:index 1, keep:typeparam 87, keep:spec 205, keep:glance 38, keep:family 2, keep:roster 1, keep:api 1.

This file reads like `src/`: the one-line stage methods' `c` (35 sites, the
component receiver across `output_state`/`output_direct`/`state_derivative`/
`state_update`/`state_events` guards and handlers) are `keep:glance` under R7,
and their destructured bundle fields (`x`, `s`, `u`, `y`, `t`, `Δt`, `ws`, 166
sites) and the `::Type{T}) where {T <: Real}` type parameter repeated on
almost every `input_types`/`output_types` method (87 sites, `keep:typeparam`)
are counted here rather than tabled per method. The same holds for the
constructors' spec-derivative keywords (`ω`, `ζ`, `q₀`, `k`, `kI`, `c₀`, `r₀`,
`h0`, `sa`/`sb`, and `condition`'s own `y`, `v`, `θ`, `ω` — 30 sites) and the
lone loop index (`i`, `Smoother.state_update`, line 246). Per-section tables
below hold only the sites that are not this pattern.

## Letters with more than one meaning in this file

- `c`: the component receiver in every stage method (35 sites, e.g.
  `output_direct(c::Gain, (; u))`) — and `Pendulum`'s own damping coefficient,
  a constructor keyword mirroring the `Pendulum.c` field seven lines above the
  next `state_derivative(c::Pendulum, …)` → see the trim table below.

## "the fragment-function idiom (§14.2)" — line 951

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 980 | `veh` | parameter | the `Vehicle` assembly `condition` extends | rename | `vehicle` |

## "the periphery's coverage set: devices and bindings (§11.3, §11.6)" — line 1240

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1310 | `sel` | parameter (keyword splat) | the labeled selectors `Readout` is built with | rename | `kw` |

## "the trim coverage set (§14.7)" — line 1315

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 1328 | `c` | parameter | the pendulum's damping coefficient, mirroring the `Pendulum.c` field it constructs | keep:spec | — |

## Collisions

None.

## Roster proposals

None.

## Questions

- `Pendulum(; g_l = 9.81, c = 0.5)`'s `c` (line 1328) mirrors the struct field
  `Pendulum.c` (a constructor parameter mirroring its field, out of the rules'
  reach), but it sits seven lines above `state_derivative(c::Pendulum, …)`,
  where `c` is the component per the file-wide convention. Kept here under the
  field-mirror exemption rather than renamed; flag if the two meanings sitting
  this close should force a rename instead.
- The `condition` generic's own-assembly parameter is spelled two ways across
  its multi-child methods: a bare letter for `SampledLoop` (`l`, matching
  `sample_times(l::SampledLoop)`) and a word for `Vehicle` (`veh`, proposed
  `vehicle` above). Both are individually compliant (R7's glance exception for
  `l`; the roster has nothing for `veh`), but the "every method alike" rule
  may want one style for the whole family.
- `Readout`'s `sel` splat (line 1310) plays the same generic
  keyword-passthrough role as `condition(veh::Vehicle; ref, kw...)`'s `kw`;
  proposed the roster's own name rather than a new word, since nothing about
  it is `Readout`-specific.
