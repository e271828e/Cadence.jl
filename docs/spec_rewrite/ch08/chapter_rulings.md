# Chapter 8: the orchestrator's rulings on the chapter pass

Rulings on `chapter_pass.md`'s RULING items, P43 to P47, plus P48, which
the inbound check and unit B4's open questions raised. Line numbers are
`chapter_new.md` lines as the chapter pass read them.

- **P43: accepted, (a).** §8.2's criterion paragraph states the arity rule
  and says it is stated once there. Completeness (794–796) cuts to "No arity
  carries a tier (above)". Each cut claim maps to its span in B1's text,
  which holds it in full, with R13's `ws_init` exception included.
- **P44: accepted, (a).** Completeness keeps what is new there: the
  update-law announcement, `StatelessWithoutOutputs` and the bundle note.
  Its copies of the store-as-tier-marker rule (771, 781–783, 805–809)
  become a pointer to "The stores", and each cut claim maps to its span in
  B1's text. A claim with no identical span in B1 stays.
- **P45: (b), both bolds stay.** D-236's Position states the clause pair as
  its own ruling ("Both clauses of §6.1 are this relation"), and §8.2 is
  where it is stated. "Entries are face bounds …" rests on D-263's bullet 2
  and D-078.
- **P46: accepted, (a) for both kinds.** §8.5 names `ClassUnreadable` at
  the rule that states it (961–962) and `ChildNameCollision` at the
  collision bullet (1047–1052). Appendix C cites §8.5 for both, and §8.1's
  pointers send the reader there. Naming changes no claim. Check each kind's
  Appendix C entry and its `src/diagnostics.jl` definition first: name it
  only where the sentence states exactly that kind's condition.
  `TierUnreadable`'s §8.5 citation in Appendix C is the inbound check's
  PREEXISTING row, for track 2.
- **P47: left as written.** "its satellite-function representation" dates
  from the axis-7 design (commit `6ec1209`), where it described how the
  dead `unlisted` flag was represented. No entry carries it, so the
  style's rule ("enrich the entry first") forbids the cut. It goes to the
  owner's list as an unsourced phrase.
- **P48: name `StoreWithoutUpdate` and `EventHalfMissing` in §8.2,** on
  the same terms as P46. Appendix C cites §8.2 for both, and §8.1's pointer
  sends the reader to §8.2 for `StoreWithoutUpdate`. Name each only where
  §8.2 states exactly its condition; if §8.2 states no such condition,
  leave the text and list the row for track 2.
