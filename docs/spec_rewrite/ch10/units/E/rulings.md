# Unit E (§10.7): rulings

Log line numbers are `docs/design/decisions.md` lines in the working tree on
2026-10-02. Old spec lines are at the base commit `08f5dff`.

## Corrections proposed

None beyond the ruled edit applied.

- **F11 (R8), applied.** Old spec 5786–5787, "The wait interval is the
  natural staging slot for externally injected inputs, applied at the next
  boundary." Staged inputs are drained at the next frame top, never at a `t*`
  boundary (old spec 5064–5066; D-081 Rejected). New text: "..., which are
  drained at the next frame top."
- **F12, left as written.** Old spec 5762–5764 names the coarse phase's
  primitive, while §12.2 (spec 7500) says §10.7 "left the coarse phase's
  primitive open". Per the brief, §12.2's framing is fixed outside this
  rewrite.

## Citations added or replaced

All are additions. None replaces an old citation.

- **D-021**, at "Pacing is outside the semantics". Position (log 718):
  "Pacing outside the semantics (bit-identical paced/unpaced trajectories)".
- **D-021**, at "The wall-clock map is piecewise affine, re-anchored at every
  knee". Position (log 719–720): "piecewise-affine wall-clock map, anchor
  re-established at pace change and un-pause (debt cleared, counted)".
- **D-021**, at "The wait mechanism is a hybrid sleep-then-spin with one
  knob". Position (log 722): "hybrid sleep-then-spin toward
  `deadline − margin`, with `margin` the single knob".
- **D-021**, at "`margin` is a single constant calibrated to cover the
  primitive's granularity plus typical overshoot". Position (log 722):
  "`margin` the single knob". "There is no second threshold" rests on the
  Rejected list only (see below).
- **D-021**, at "The knob spans the whole design space". Position (log
  722–723): "(0 = pure sleep, ∞ = pure busy-wait = FlightCore)". Rejected
  (log 736): "Dedicated busy-wait mode flag: subsumed by `margin = ∞`".
- **D-080**, at "Event localization runs identically paced or unpaced", now
  bold. Position (log 2312–2314): "localization runs identically in every
  execution mode, its sweep cost absorbed as §10.7 pacer debt like any other
  expensive frame". The old text cited D-080 only in the next sentence.
  D-080 is repeated after "like any other expensive frame", so it covers
  both sentences of the split.
- **D-133**, at "Debt beyond a threshold of five frames' worth of budget,
  `5·h/p`, is forgiven by re-anchor plus a warning". Position (log 4004):
  "debt forgiveness at five frames' worth of budget, `5·h/p` (§10.7, ...)".
  The re-anchor plus warning is D-021's "re-anchor on excess" (log 721),
  cited in the same paragraph's neighbour.
- **D-133**, at "The default `margin` is 2 ms". Position (log 4005–4006):
  "`margin` = 2 ms (§10.7's own arithmetic)".
- **D-027**, at "The coarse phase uses task-yielding `sleep`, with `margin`
  absorbing its overshoot". Position (log 856–857): "Pacer coarse phase =
  task-yielding `sleep` (`margin` covers its overshoot)". Not bold, since
  §12.2 is the home and bolds it.
- **D-132**, at "The wait is an unmask point". Rationale only, see below.

## Rationale-only rulings

- **D-021, Rejected (log 737–738).** "Separate primitive-resolution
  threshold: absorbed into `margin` calibration" carries "There is no second
  threshold". The Position says only "`margin` the single knob".
- **"The wait sits at the frame top, after the control plane is consulted":
  no entry.** D-269 Position bullet 3 (log 10703–10705) says only that the
  control plane is consulted at frame top alone. No field rules where the
  wait sits. The sentence is now plain, with no citation. D-269 stays on the
  next sentence, which it carries. The log owes a Position stating it.
- **D-132, Rationale (log 3939–3943).** "the loop masks delivery across the
  boundary macro-sequence ... and takes the deferred raise at the unmask
  points — frame top, wait and pause blocks". The wait as an unmask point is
  stated nowhere in a Position.
- **D-269, Annotation (log 10773–10776), already cited.** "A live switch to
  `pace = Inf` is a pace change like any other: it re-anchors and forgives
  the debt, counted". The old citation stays.
- **D-269, Annotation (log 10779–10782), no citation possible.** The spin's
  `GC.safepoint()`, "a safepoint, never a yield", sits in a code comment.
- **D-133, Rationale (log 4026–4031), reasons only.** Why `5·h/p` and why
  2 ms. The rulings themselves are in D-133's Position.

## Other edits after cold verification

- The forgiveness bold is trimmed to its headline clause, "Debt beyond a
  threshold of five frames' worth of budget, `5·h/p`, is forgiven".
- The old "Forward pointers" paragraph has its own label, "#### Where
  staging and concurrency live", and the context sentence names it.
- Reader-cold symbols: the map now says that $p$ is the pace, $\tau$
  wall-clock time, and the anchor pair the sim time and wall-clock time at
  the most recent anchor (old text: "pace change", "the current `(t, τ)`",
  "the anchor pair as its reference point"; D-021 "piecewise-affine
  wall-clock map"). "control plane" links `#g-control-plane` with a gloss
  taken from the glossary. The framework-status gloss says "the signal
  table" for "the table".

## Inbound citations affected

None. No heading or sentence that an inbound citation relies on was removed.
The name "deadline law" survives as "The deadline law is ...". The staging
slot that spec 7513 cites survives. The three `####` labels are new and
nothing links them.

## Open questions

- **D-268 against D-269 on where the loop checks the pause flag.** D-268
  Position bullet 1 (log 10567–10568) says the loop consults the flag "at
  frame top and inside its wait and pause blocks". D-269 Position bullet 3
  (log 10703–10706) says the control plane is consulted "at frame top alone",
  with the pause block the one wait woken at once. §10.7 follows D-269 and is
  kept as written. D-268 wants an annotation in the log's repair track.
- **Two glossary links to `#g-pacing`.** The section links both "pacing" and
  "debt" to it, as the old text did. The glossary entry names both terms
  ("pacing / pacer debt"), so the pair was kept. The debt link moved to the
  first use of "debt", in the detection-policy paragraph, with a gloss.
- **Bold added on a ruling the old text left plain.** "Event localization
  runs identically paced or unpaced" now carries bold and D-080, since D-080's
  Position states it. Flagged in case the owner prefers the old marking.
