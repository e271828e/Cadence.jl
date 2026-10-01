# Notes on new5.md

## (a) Sentences that assert nothing traced to a claim

- "It redoes five things:" (list lead-in; carries the count from K7, so it
  arguably traces to K7).
- "It is invoked as follows:" and "It is defined as follows:" (code-block
  lead-ins for K57 and K67).
- "The call above names `ProbeDual`." (transition to the ProbeDual paragraph;
  it only points at the code already shown).

## (b) Ambiguous claims and how I read them

- K48/K49. K49 is typed CONSEQUENCE without naming its cause. I read it as the
  price K48 announces, and wrote "The price is that a successful `build` does
  not certify that the model is linearizable."
- K28. "A `Dual` activation, of the kind linearization and gradient trim use"
  became two sentences. The first says linearization and gradient trim use a
  `Dual` activation; I took that as the content of the "of the kind" clause.
- K7 vs. K16. K7 lists five redone items, K16 (buffer layout) is unnumbered.
  I folded K16 into item 3 beside the state type, since buffers are laid out
  after the types they hold. This placement asserts no ordering.
- K57/K58. Near duplicates. I kept both: K57 introduces the mode and the call,
  K58 says the call runs the exhaustive set.
- K79 and K113 restate the same purity fact for two different conclusions. I
  kept both, each beside the conclusion it supports.
- K94 vs. K95. Julia caches compiled code, yet the framework cache saves
  "Julia's compilation of the `Dual` chain". I stated both as given and added
  no reconciling link.
- K108 is a FACT with "must never". I kept the modal but did not bold it.
- K111. "A guard around cache insertion suffices to exclude torn state" became
  "A guard around cache insertion suffices", right after the sentence about
  the mechanism that excludes torn state.
- K5 names four topics. I used four #### subheadings matching them, and kept
  K5 as the opening's last sentence. ProbeDual sits under the laziness/CI part
  and concurrency under the cache part, since neither is a fifth K5 topic.
- No link reference definitions are included; I assume the spec's shared
  link block resolves [s8-2], [d-052] and the rest.
