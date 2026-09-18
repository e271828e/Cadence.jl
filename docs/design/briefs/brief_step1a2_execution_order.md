# Brief: step 1a, second pass, "dataflow" becomes "execution order"

Follow-up to `brief_step1a_vocabulary_sweep.md` (commit `d0b7712`). Tip:
`d0b7712`. Docs only; no source, no test suite. One commit.

## Why

The first pass renamed the evaluation order to "dataflow". That word names a
graph, what feeds what. Nearly every site names an order, the sequence the
executor walks, or a position in it. The prose word for the order is now
**"execution order"**. The `Dataflow` type keeps its name, since the
artifact carries the feedthrough edges and the name sets as well as the
order; the spec will say the artifact carries the execution order (step 1b's
business, not this pass's).

Three spellings by role:

- **"execution order"**, the noun and the glossary headword. First use per
  section glosses it: "(the order in which the stage functions run, fixed at
  build time from the feedthrough graph)". Bare "the order" afterward where
  the sentence is unambiguous.
- **"ordering"**, the activity or the problem.
- **a position in the execution order**, never "execution-order position".

Two sites were about the graph all along and take **"feedthrough graph"** or
**"feedthrough edge"**. Three pre-existing generic uses of "dataflow" (3695,
9287–9288, 9499) mean data moving through ports and stay.

## Reading

`docs/design/tools/spec_style.md`, whole. Then the table below; read each
site in its paragraph before applying the replacement, and rewrap the
paragraph to 80 rendered columns where the new phrase changes line lengths.

## The site table

Line numbers are at `d0b7712`. "current" is the phrase to find; "new" is the
exact replacement unless the cell says otherwise.

| line | current | new |
| --- | --- | --- |
| 138 | static evaluation dataflow | static execution order |
| 172 | signal and dataflow model | signal and ordering model |
| 331 | flattened away for the dataflow | flattened away for ordering |
| 371 | position in the [dataflow](#g-dataflow) | position in the [execution order](#g-execution-order) |
| 378 | dataflow annotation | ordering annotation |
| 564 | ### 5.1 The dataflow problem | ### 5.1 The ordering problem |
| 569 | static evaluation [dataflow](#g-dataflow) | static [execution order](#g-execution-order) |
| 609 | (the compiled execution form of the dataflow) | (the compiled form of the stage execution order) |
| 724 | stage roles, dataflow and step boundaries | stage roles, execution order and step boundaries |
| 728–729 | orders the stages into a dataflow, then puts that dataflow inside a step boundary | orders the stages, then puts that order inside a step boundary |
| 771 | contribute to the [dataflow](#g-dataflow). They break would-be loops. | contribute to the [feedthrough](#g-feedthrough) graph. They break would-be loops. |
| 803 | #### The dataflow | #### The execution order |
| 805 | The dataflow runs all stage-1 functions in any order, then stage 2 | Execution runs all stage-1 functions in any order, then stage 2 |
| 829 | the dataflow where no fresh `y` | the position in the execution order where no fresh `y` (read the sentence; keep its subject) |
| 831 | unique in that dataflow position | unique in that position of the execution order |
| 877 | adding a checked dataflow | adding checked ordering |
| 953 | creates a dataflow edge | creates a feedthrough edge |
| 979 | Dataflow correctness | Ordering correctness |
| 986, 1141, 2072, 2560, 7281, 7348, 7522, 8311 | structure, dataflow, activation | structure, execution order, activation |
| 995 | Classification needs no [dataflow](#g-dataflow). | Classification needs no [execution order](#g-execution-order). |
| 996 | where no dataflow exists | where no execution order exists |
| 1016, 3395 | dataflow-free | order-free |
| 1359 | [dataflow](#g-dataflow) positions of §5.3 | positions in the [execution order](#g-execution-order) of §5.3 |
| 1382 | (the compiled execution form of the dataflow) | (the compiled form of the stage execution order) |
| 1660 | minus the checked dataflow | minus the checked ordering |
| 1684 | both of its §5.3 [dataflow](#g-dataflow) positions | both of its §5.3 positions in the [execution order](#g-execution-order) |
| 1894–1895 | the compiled execution form of the dataflow | the compiled form of the stage execution order |
| 2560–2561 | the compiled execution form of the dataflow | the compiled form of the stage execution order |
| 2956 | evaluation [dataflow](#g-dataflow) | [execution order](#g-execution-order) |
| 3053 | #### Stratum B: dataflow | #### Stratum B: execution order |
| 3056 | It computes the [dataflow](#g-dataflow): | It computes the [execution order](#g-execution-order): |
| 3178 | [dataflow](#g-dataflow) and root inputs | [execution order](#g-execution-order) and root inputs |
| 3381 | Structure and [dataflow](#g-dataflow) are | Structure and [execution order](#g-execution-order) are |
| 3454–3455 | the compiled execution form of the dataflow | the compiled form of the stage execution order |
| 3550 | both of the [dataflow](#g-dataflow) positions | both of the positions in the [execution order](#g-execution-order) |
| 3625 | The [dataflow](#g-dataflow) exists in two representations | The [execution order](#g-execution-order) exists in two representations |
| 3735 | Dataflow tuples are built | Entry tuples are built |
| 3737 | inference traps at dataflow length | inference traps at the entry list's length |
| 3799 | assumes the dataflow rather than deriving it | assumes the execution order rather than deriving it |
| 4319 | subsets of the [dataflow](#g-dataflow) | subsets of the [execution order](#g-execution-order) |
| 5242 | sources to the build-time dataflow | sources to the build-time ordering |
| 7575 | execution form of the [dataflow](#g-dataflow)) | (rewrite the gloss as) the compiled form of the stage [execution order](#g-execution-order)) |
| 7577 | where in the compiled dataflow execution is | where execution stands in the compiled order |
| 7578 | as a dataflow index | as an index into the execution order |
| 7592 | component path (dataflow … | component path (execution-order index … (read the comment; keep its shape) |
| 9999 | the [dataflow](#g-dataflow) stays acyclic | the [feedthrough](#g-feedthrough) graph stays acyclic |
| 10461 | face table with provenance, dataflow, | face table with provenance, execution order, |
| 10923 | **Dataflow and contract conformance** | **Execution order and contract conformance** |
| 11157 | for the dataflow, and retained | for ordering, and retained |
| 11217 | face table, dataflow and root inputs | face table, execution order and root inputs |
| 11336 | the producer's dataflow position | the producer's position in the execution order |
| 11403 | `<a id="g-dataflow"></a>**dataflow** — the static evaluation order computed once at build time from` | `<a id="g-execution-order"></a>**execution order** — the order in which the stage functions run, fixed once at build time from` (then read on and keep the rest of the entry coherent) |
| 11422 | the only two dataflow positions | the only two positions in the execution order |
| 11426 | one execution of the dataflow against the current state | one pass through the execution order against the current state |
| 11587 | subsets of the dataflow | subsets of the execution order |
| 11613 | Structure and dataflow are | Structure and execution order are |
| 11624 | with provenance, dataflow and root inputs | with provenance, execution order and root inputs |
| 11638 | the compiled execution form of the dataflow | the compiled form of the stage execution order |
| 11696 | B dataflow (the single | B execution order (the single |
| 12059 | compiled dataflow execution is | execution stands in the compiled order, as |  (read the entry; the parenthetical list that follows stays) |
| 12066 | never an input to the dataflow | never an input to the ordering |

Leave: 3695, 9287, 9288, 9499. After the table, `rg -n -i 'dataflow' docs/design/spec.md`
must show only those four body lines plus mentions of the `Dataflow` type if
any (there are none today). Read each remaining hit before declaring it
generic.

## Other edits

- **Anchor.** `#g-dataflow` becomes `#g-execution-order` at every link and at
  the entry. The entry stays where it is in D.3; "execution order" sorts in
  the same slot between "algebraic loop" and "flow".
- **Headings** by hand (four, in the table). Do not edit the `## Contents`
  block or the definitions block; `linkify.jl` regenerates both.
- **`docs/design/tools/gloss_table.md`.** The dataflow row becomes
  "execution order", anchor `g-execution-order`, gloss "the order in which the
  stage functions run, fixed at build time from the feedthrough graph". The
  sweep, `Build`, executor, stratum and execution cursor rows take the new
  wording. Leave the `n` counts alone.
- **Not in scope.** `decisions.md`, `implementation.md`, `pending.md`,
  `extensions.md`, `companions/`, the briefs and the register. Renaming only;
  no sentence gains or loses a norm. If a replacement reads badly in its
  sentence, apply the closest of the three spellings and flag the line.

## Battery, then commit

From the repository root, after the edits and before the commit:

    julia docs/design/tools/linkify.jl
    julia docs/design/tools/check_refs.jl
    julia docs/design/tools/check_rows.jl
    julia docs/design/tools/check_glossary.jl --strict
    julia docs/design/tools/linkify.jl        # must be a no-op

`linkify.jl` regenerates the definitions blocks of the rostered files that
cite §5.1 or §5.3; they join the commit. Commit with `git add` **by path**,
never `-A` or `.`; the uncommitted audit refresh under `docs/reports` stays
out. Single-sentence subject, no body, no attribution:

    Rename the evaluation order from dataflow to execution order across the spec

Let the post-commit PDF hook run. Never stash, reset or check out the working
tree. Do not run the Julia test suite.

## Report

- Sites applied per spelling ("execution order", "ordering", "order"/position,
  feedthrough graph, entry tuples), and the four left.
- Every line where the table's replacement did not fit its sentence and what
  you did instead.
- The battery's output and the files `linkify.jl` regenerated.
- The commit hash.
