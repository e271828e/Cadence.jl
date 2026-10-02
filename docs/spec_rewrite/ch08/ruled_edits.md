# Chapter 8: ruled edits K2, K3, K5 and K6

All four applied as proposed in `rulings_batch.md`. Each unit's inventory
script was updated and re-run; the edited claims carry `"tag": "R"` and the
ruling's id.

## K2 (unit D)

1. Old: "`inner_connections` plus any leaf declaration on one type is a build
   error as well."
   New: "`inner_connections` plus any leaf declaration on one type is a build
   error as well, `ClassMixed`."
2. Old: "A container mixing component and non-component elements is a build
   error in this section's did-you-mean family ([D-085][d-085])."
   New: the same sentence, followed by "The error is `ContainerMixed`."
3. Old: "`transparent_container` must name a container field of the type, and
   declaring two transparent containers on one type is a declaration error
   ([D-211][d-211], [D-215][d-215])."
   New: "`transparent_container` must name a container field of the type, and
   a name that matches none is `TransparentContainerUnknown`. Declaring two
   transparent containers on one type is a declaration error ([D-211][d-211],
   [D-215][d-215])." The pair stays on the second sentence only, as proposed.

The three new names are listed in `added`.

Checker: `checks failed: 0`

## K3 (unit A)

1. Old: "The reason is how executor entries are typed ([§9.7][s9-7])."
   New: "The reason is how entries of the [executor](#g-executor) (the
   compiled form of the stage execution order) are typed ([§9.7][s9-7])."
2. Old: "An entry of the [executor](#g-executor), the compiled form of the
   stage execution order, carries what selects code in type parameters and
   what is plain data in fields."
   New: "An executor entry carries what selects code in type parameters and
   what is plain data in fields."

Checker: `checks failed: 0`

## K5 (unit B1)

The paragraph "The store names each leaf because every service reaches a leaf
by its field name. … The name a one-state component is asked for is the name
every service then uses." moved from after the "it also closes a trap"
paragraph to right after the `StoreNotNamedTuple` paragraph, before "**Every
leaf declares exactly one of `x_init` and `s_init`**". No words changed. Its
four claims are tagged R, K5.

Side effect: the moved paragraph's unlinked "store" now comes before the
section's glossary-linked "[store](#g-store) (the model's memory, …)". The
ruling says no words change, so the link stays where it was.

Checker: `checks failed: 0`

## K6 (unit E1)

Old: "They are evaluated at the [activation](#g-activation) scalar on the
continuous tier and [pinned](#g-walked) on the discrete."
New: "They are retyped at the [activation](#g-activation) scalar by the leaf
walk on the continuous tier, and [pinned](#g-walked) on the discrete."

Side effect: "leaf walk" has a glossary entry (`#g-leaf-walk`) and this is
its first use in §8.6. The proposal adds no link, so none was added.

Checker: `checks failed: 0`

## Follow-ups

These follow the style guide's rule of one glossary link at first use, so they
need no ruling.

### B1: the store's link moves to its new first use

Old: "The store names each leaf because every service reaches a leaf by its
field name." and "The [store](#g-store) (the model's memory, declared by
initial value) is the tier marker."
New: "The [store](#g-store) (the model's memory, declared by initial value)
names each leaf because every service reaches a leaf by its field name." and
"The store is the tier marker."

Checker: `checks failed: 0`

### E1: "leaf walk" linked at its first use in §8.6

Old: "They are retyped at the [activation](#g-activation) scalar by the leaf
walk on the continuous tier, and [pinned](#g-walked) on the discrete."
New: "They are retyped at the [activation](#g-activation) scalar by the
[leaf walk](#g-leaf-walk) (the framework's derivation of per-activation types)
on the continuous tier, and [pinned](#g-walked) on the discrete." The gloss
shortens the glossary entry's first clause.

Checker: `checks failed: 0`
