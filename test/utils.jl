# --- helpers shared across the test files ---------------------------------------

const D8 = ForwardDiff.Dual{Nothing,Float64,8}

# The entries a phase body walks, per variant (§10.5): the boundary variant is
# the full list — its discrete entries wearing their `Gated` wrapper, unwrapped
# here — the interior one the continuous entries alone.
walked(body, variant = :boundary) =
    [e isa Gated ? e.entry : e for c in getfield(body, variant) for e in c.entries]

# The gated entries of a body's boundary variant.
gated(body) = count(e isa Gated for c in body.boundary for e in c.entries)

# A model of one component under a wrapper assembly — kept where a fixture wants
# a named face; a bare leaf builds too (D-208).
single(c) = Group((; c = c))

# The same, with the component's one input face handed up to a root input `in`.
fed(c, face) = Group((; c = c); inputs = ("in" => "c/$face",))

# Every `at` prefix in a condition tree, outermost first: what a service authored
# is what the service walk sees, one prefix at a time (§14.2).
prefixes(n::Scoped) = vcat([n.prefix], prefixes(n.node))
prefixes(n::Combined) = reduce(vcat, map(prefixes, n.nodes); init = String[])
prefixes(::ConditionNode) = String[]

# The drain's counterfactual: the same value written straight into a root
# input's cell at a stopped point, reaching under the data plane on purpose.
# The framework's own write paths are `init!`'s condition (stopped) and
# `stage!` (running), and neither can express a *mid-trajectory* poke — which
# is exactly what the drain-equivalence tests need as their reference. Not
# framework API, and used nowhere else.
poke!(sim, face, v) =
    (scatter_cell!(sim.exec.store, sim.exec.act.layout.addr[("", Symbol(face))], v);
     nothing)

# The structure's component paths in walk order, off its rows.
paths(structure::Structure) = [entry.path for entry in structure.components]

# The error a build raises, for the tests that read the diagnostics.
failure(f) =
    try
        f()
        nothing
    catch err
        err
    end

# The diagnostic a passed `@test_throws DiagnosticError{K}` carried: `Test.Pass`
# keeps the throw in `value`. Defined on `Pass` alone, so a failed `@test_throws`
# — already recorded by the testset — stops the body at a `MethodError` rather
# than asserting fields of nothing.
carried(p::Test.Pass) = diagnostic(p.value)

# One writer's record in a snapshot's framework status (§11.8), by name: the
# devices as "device 1 (Pad)", the harness writer as "harness", the loop as
# "loop".
writer_status(snapshot, who::String) =
    only(w for w in snapshot.status.writers if w.who == who)

# A device-task diagnostic's single account, wherever timing put it (§11.8,
# §12.4): the reporting task may or may not beat the run's last frame top, so
# the record is either in the terminal status's totals or presented by the
# run's-end sweep — exactly one of the two, never both, never neither.
accounted(sim, logs, who::String, field::Symbol, kind::String) =
    (getfield(writer_status(latest(sim), who).totals, field) ≥ 1) ⊻
    any(occursin("$kind from $who, past the final", string(l.message)) for l in logs)

crash_accounted(sim, logs, who::String) = accounted(sim, logs, who, :crash, "DeviceCrash")
