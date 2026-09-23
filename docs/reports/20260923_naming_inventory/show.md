# Naming inventory: src/show.jl

Tip: f64b9f3. Sites flagged: 20. Renames: 4. Collisions: 1. Roster proposals: 1.

## Letters with more than one meaning in this file

- `T`: an activation scalar (`_activations_label`'s comprehension), an artifact type (the top-level `for` at line 256) → the artifact-type loop renamed below
- `x`: the rendered artifact (line 257), not the state → renamed below
- `k`: a tick index (`_lines(::Schedule)`), an anchor index (`_lines(::Structure)`) → both loop indices, kept

## `_anchor_name(anchor::Int) = …` — line 15

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 15 | `c` | generator | one decimal digit of the anchor index | keep:glance | — |

## `_count(n::Int, noun::String) = …` — line 18

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 18 | `n` | param | how many of `noun` there are, read three times; `count` is a Base function this file calls (line 216) | rename | `number` |

## `_names_label(names) = …` — line 34

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 34 | `names` | param | the names to list; `Base.names` is exported | collision | `name_list` |

## `function _table(indent::String, header::Vector{String}, rows::Vector{Vector{String}})` — line 38

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 39 | `j` | comprehension | the column index | keep:index | — |

## `Base.show(io::IO, structure::Structure) = …` — line 60

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 60 | `io` | param | the output stream, Base's own name for it | roster? | `io` (see Roster proposals) |

## `function _lines(structure::Structure)` — line 66

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 86 | `k` | comprehension destructure | the anchor's index | keep:index | — |

## `Base.show(io::IO, outputs::Outputs) =` — line 94

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 94 | `io` | param | the output stream | roster? | `io` |

## `function _lines(outputs::Outputs)` — line 99

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 103 | `ci` | comprehension | the component index | keep:index | — |

## `Base.show(io::IO, events::Events) = …` — line 114

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 114 | `io` | param | the output stream | roster? | `io` |

## `function Base.show(io::IO, schedule::Schedule)` — line 135

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 135 | `io` | param | the output stream | roster? | `io` |

## `function _lines(schedule::Schedule)` — line 146

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 165 | `L` | local | the hyperperiod in base ticks, read six times; an uppercase local, not a type parameter | rename | `hyperperiod` |
| 170 | `k` | for | the ruler's tick index | keep:index | — |
| 176 | `k` | generator | the chart's tick index | keep:index | — |

## `_activations_label(built::Build) =` — line 185

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 187 | `T` | comprehension | one activation scalar, the numeric type | keep:glance | — |

## `Base.show(io::IO, built::Build) =` — line 191

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 191 | `io` | param | the output stream | roster? | `io` |

## `function _feedthrough(structure::Structure, outputs::Outputs)` — line 198

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 200 | `ci` | for | the consumer's component index | keep:index | — |

## `Base.show(io::IO, deployment::Deployment) =` — line 234

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 234 | `io` | param | the output stream | roster? | `io` |

## `for T in (Structure, Outputs, Events, Schedule, Build, Deployment)` — line 256

| line | name | bound by | holds | code | proposal |
| --- | --- | --- | --- | --- | --- |
| 256 | `T` | top-level for | an artifact type, not the numeric type | rename | `Artifact` |
| 257 | `io` | param | the output stream | roster? | `io` |
| 257 | `x` | param | the artifact rendered; `x` is the state | rename | `artifact` |

## Collisions

- `names` (line 34, `_names_label`) shares its name with `Base.names`, exported from Base. No `names` is defined in the package, and the scope does not call it. Proposal `name_list`.

## Roster proposals

- `io`: 7 sites here (every `Base.show` method), the output stream. It is Base's own parameter name for `show`, `print` and `write`; the roster would admit it as the convention every `show` method follows.

## Questions

- The file names a `Build` parameter `built` (lines 185, 191, 214) to dodge the function `build`; `readers.jl` names the same thing `b` or `build`. If `build` joins `path` as an exception (`readers.md`), `built` becomes a rename to `build`; if not, `built` is the file's answer and the others should follow it.
- The loop variable at line 256 holds a type in a top-level `for`, bound once per artifact and spliced by `@eval`. The proposal capitalizes it (`Artifact`) as a type-valued binding; the rules do not say how a type-valued non-parameter binding is spelled.
