# --- the artifacts' renderings (§9.2, §13.7, D-257; increment 48) --------------
# Each build-side and deployment artifact prints itself: the compact form on
# `show(io, x)` and the tables on `MIME"text/plain"`. The exact blocks below are
# `MultiRate`'s at `h = 1//500`, whose rows and hyperperiod §9.2's worked example
# fixes; the anchored `Hz(500)`/`Hz(10), 1//150` group is the guard's long case.

# The REPL form.
plain(x) = sprint(show, MIME("text/plain"), x)

# The one-line form: what a container or `repr` prints.
compact(x) = sprint(show, x)

# The anchored group of `test_discrete.jl`'s attribution test, derived at
# `h = 1//1500`: `lcm(Dᵢ) = 150`, past the chart guard.
function anchored_group()
    comp = Group((; a = TickCounter(), b = TickCounter());
                 rates = (; a = Absolute(Hz(500)), b = Absolute(Hz(10), 1//150)))
    @test_logs (:info, r"derived") (:warn, r"^GridUtilization") Deployment(
        build(comp); h = 1//1500, Δt_base = :derive)
end

# The framework status built by hand (§11.8), no run needed: a counter record
# holding `number` `MalformedDatum`s and nothing else.
malformed_counts(number::Int) =
    KindCounts((f === :malformed ? number : 0 for f in fieldnames(KindCounts))...)

# A device's record with `total` occurrences in all, the last ones this
# boundary's: `retained` in the ring, then `suppressed` refused past it. The
# retained ones are numbered by their place in the run's account.
function malformed_record(total::Int, retained::Int, suppressed::Int)
    first_retained = total - suppressed - retained + 1
    WriterStatus("device 1 (Parser)",
                 [MalformedDatum("datum $k") for k in first_retained:first_retained + retained - 1],
                 malformed_counts(suppressed), malformed_counts(total), 1.0e9, :running)
end

# A writer with no task and no occurrences: the harness's and the loop's shape.
quiet_record(who::String) = WriterStatus(who, MalformedDatum[], KindCounts(), KindCounts(),
                                         nothing, nothing)

hand_status(device::WriterStatus; pacer = PacerStatus(nothing)) =
    FrameworkStatus([device, quiet_record("harness"), quiet_record("loop")], pacer)

const QUIET_STATUS = """
FrameworkStatus: 3 writers, no occurrences, unpaced
  device 1 (Parser): running, heartbeat 1.0e9, no occurrences
  harness: no occurrences
  loop: no occurrences
  pacer: unpaced, debt 0.0 s, peak 0.0 s, no overruns, no reanchors, 0.0 s forgiven, no waits, 0.0 s waited"""

const MULTIRATE_STRUCTURE = """
Structure: 4 components, 1 anchor, 1 rate scope; root inputs: none
  components:
    path       tier        anchor  m  c  rates
    src        continuous  A₀      1  0  —
    fcs/inner  discrete    A₀      1  0  fcs = Relative(1, 0) → inner = Relative(1, 0)
    fcs/outer  discrete    A₀      5  2  fcs = Relative(1, 0) → outer = Relative(5, 2)
    gnss       discrete    A₁      1  0  gnss = Absolute(1//50, 0//1)
  rate scopes:
    path  key  anchor  m  c
    fcs   fcs  A₀      1  0
  anchors:
    anchor  T        τ     scope  key
    A₀      Δt_base  0//1  —      —
    A₁      1//50    0//1  root   gnss"""

const MULTIRATE_OUTPUTS = """
Outputs: execution order over 4 components
  component  stage 1  stage 2
  src        out      —
  fcs/inner  —        out
  gnss       —        out
  fcs/outer  —        out"""

const MULTIRATE_SCHEDULE = """
Schedule: 3 rows, 1 rate scope, hyperperiod 10 base ticks
  path       anchor  D   Φ  Δt     rates
  fcs/inner  A₀      1   0  0.002  fcs = Relative(1, 0) → inner = Relative(1, 0)
  fcs/outer  A₀      5   2  0.01   fcs = Relative(1, 0) → outer = Relative(5, 2)
  gnss       A₁      10  0  0.02   gnss = Absolute(1//50, 0//1)
  rate scopes:
    path  key  anchor  D  Φ
    fcs   fcs  A₀      1  0
  hyperperiod chart, 10 base ticks:
               0
    fcs/inner  ●●●●●●●●●●
    fcs/outer  ··●····●··
    gnss       ●·········"""

function test_show()
    multirate = build(MultiRate())
    deployed = Deployment(multirate; h = 1//500)
    pendulum = build(Pendulum())
    pendulum_deployed = Deployment(pendulum; h = 1//100)
    group = anchored_group()

    @testset "the compact forms are one line with the counts (§9.2, D-257)" begin
        @test compact(multirate.structure) == "Structure(4 components, 1 anchor, 1 rate scope)"
        @test compact(pendulum.structure) == "Structure(1 component, no anchors, no rate scopes)"
        @test compact(multirate.outputs) == "Outputs(4 components)"
        @test compact(multirate.events) == "Events(no events over 4 components)"
        @test compact(build(Motor(1.0)).events) == "Events(1 event over 1 component)"
        @test compact(deployed.schedule) == "Schedule(3 rows, hyperperiod 10 base ticks)"
        @test compact(pendulum_deployed.schedule) == "Schedule(no rows)"
        @test compact(multirate) == "Build(4 components, activations: Float64)"
        # A second activation lists after the nominal one, whatever the dictionary's
        # order; on its own build, since the others print the shared one.
        activated = build(MultiRate())
        activation(activated, D8)
        @test compact(activated) == "Build(4 components, activations: Float64, $(D8))"
        @test compact(deployed) == "Deployment(h = 0.002, N_base = 1, Δt_base = 0.002, RK4)"
        for x in (multirate.structure, multirate.outputs, multirate.events, deployed.schedule,
                  multirate, deployed)
            @test !occursin('\n', compact(x))
            @test repr(x) == compact(x)
        end
    end

    @testset "Structure: the component, rate-scope and anchor tables (§9.2, D-257)" begin
        @test plain(multirate.structure) == MULTIRATE_STRUCTURE
        # The `m` and `c` columns are the fold's timing, row by row.
        for (entry, line) in zip(multirate.structure.components, split(MULTIRATE_STRUCTURE, '\n')[4:7])
            columns = split(line)
            @test columns[1] == entry.path && parse.(Int, columns[4:5]) == [entry.timing.m, entry.timing.c]
        end
        # The `A₀` row is always present, `Δt_base` symbolic and no declaring scope.
        @test occursin("\n    A₀      Δt_base  0//1  —      —", plain(multirate.structure))
        # A primitive at the root is the one component, at path `root`, with no
        # rate-scope block and its root input on the heading.
        text = plain(pendulum.structure)
        @test startswith(text, "Structure: 1 component, no anchors, no rate scopes; root inputs: u\n")
        @test occursin("\n    root  continuous  A₀      1  0  —\n", text)
        @test !occursin("rate scopes:", text)
        @test occursin("\n  anchors:\n    anchor  T        τ     scope  key\n    A₀      Δt_base  0//1  —      —", text)
        @test count('\n', text) == 6
    end

    @testset "Outputs: the execution order with each stage's ports (§9.2, D-257, D-261)" begin
        @test plain(multirate.outputs) == MULTIRATE_OUTPUTS
        # Inside the `Build` the same table, indented, and under it the one
        # feedthrough edge, `fcs/outer`'s, fed by `gnss`'s stage-2 port;
        # `fcs/inner` and `gnss` read `src.out`, a stage-1 port, so they add none.
        text = plain(multirate)
        @test occursin("\n" * join("  " .* split(MULTIRATE_OUTPUTS, '\n'), "\n") * "\n", text)
        @test occursin("\n  feedthrough: gnss.out → fcs/outer.in\n", text)
    end

    @testset "Events: one row per declaring component (§9.2, D-257)" begin
        @test plain(multirate.events) == "Events: no events over 4 components"
        @test plain(build(Motor(1.0)).events) ==
              "Events: 1 event over 1 component\n" *
              "  component  events             bundle\n" *
              "  root       start => boundary  (x, m, u, y, t)"
        @test occursin("\n  Events: 1 event over 1 component\n" *
                       "    component  events             bundle\n" *
                       "    root       wrap => localized  (x, y, t)\n", plain(build(Sawtooth(1.0))))
    end

    @testset "Schedule: the rows and the hyperperiod chart (§9.2, D-257)" begin
        @test plain(deployed.schedule) == MULTIRATE_SCHEDULE
        lines = split(plain(deployed.schedule), '\n')
        @test lines[end-2:end] == ["    fcs/inner  ●●●●●●●●●●",
                                   "    fcs/outer  ··●····●··",
                                   "    gnss       ●·········"]
        # The gate, computed here: `●` exactly where `(k − Φ) % D == 0`.
        rows = deployed.schedule.rows
        hyperperiod = lcm([row.D for row in rows])
        @test hyperperiod == 10
        for (row, line) in zip(rows, lines[end-2:end])
            chart = collect(last(split(line)))
            @test length(chart) == hyperperiod
            @test [k for k in 0:hyperperiod-1 if chart[k+1] == '●'] ==
                  [k for k in 0:hyperperiod-1 if (k - row.Φ) % row.D == 0]
        end
        # The guard is binary: past 100 base ticks the chart's place holds one line.
        text = plain(group.schedule)
        @test startswith(text, "Schedule: 2 rows, hyperperiod 150 base ticks\n")
        @test endswith(text, "\n  hyperperiod: 150 base ticks, chart omitted")
        @test !occursin("●", text) && !occursin("hyperperiod chart", text)
        # No rows: the heading alone, no chart line at all.
        @test plain(pendulum_deployed.schedule) == "Schedule: no rows"
    end

    @testset "Build: the summary and its parts (§9.2, D-257)" begin
        text = plain(multirate)
        @test startswith(text, "Build: 4 components (1 continuous, 3 discrete); activations: Float64; no warnings\n")
        @test occursin("\n" * join("  " .* split(MULTIRATE_STRUCTURE, '\n'), "\n") * "\n", text)
        @test endswith(text, "\n  Events: no events over 4 components\n  warnings: none")
        # The feedthrough line lists every edge, consumers in execution order,
        # or `none`.
        @test occursin("\n  feedthrough: sum.e → ctl.e, ctl.out → plant.u\n", plain(build(feedback_model())))
        text = plain(pendulum)
        @test startswith(text, "Build: 1 component (1 continuous, 0 discrete); activations: Float64; no warnings\n")
        @test occursin("\n  feedthrough: none\n", text)
        # A build with a warning names it on the heading and lists its logline.
        warned = @test_logs (:warn, r"^EmptyFaceSelection") build(SelectedNothing(Gain(2.0), Gain(3.0)))
        text = plain(warned)
        @test startswith(text, "Build: 2 components (2 continuous, 0 discrete); activations: Float64; 1 warning\n")
        @test endswith(text, "\n  warnings:\n    " * logline(only(warnings(warned))))
    end

    @testset "Deployment: the parameters, the schedule, the grid and the warnings (§9.2, D-257)" begin
        text = plain(deployed)
        @test startswith(text, "Deployment: h = 0.002, N_base = 1, Δt_base = 0.002, RK4; " *
                               "firing_budget = 4, localization_tol = 1.0e-6, localization_budget = 8\n" *
                               "  build: Build(4 components, activations: Float64)\n")
        @test occursin("\n" * join("  " .* split(MULTIRATE_SCHEDULE, '\n'), "\n") * "\n  grid:\n", text)
        @test endswith(text, "\n  warnings: none")
        # The grid block's lines re-indented under `grid:`, for an anchored model.
        text = plain(group)
        @test occursin("\n  grid:\n    admissible: gcd(pool)/k, coarsest 1//1500\n    pool:\n" *
                       "      `sample_times` at the root component, key `a`  period 1//500  ×10\n", text)
        @test occursin("\n  warnings:\n    GridUtilization: Δt_base derived as 1//1500 s: the grid is 3× finer", text)
        # No anchor declares a constraint: the grid line says so.
        text = plain(pendulum_deployed)
        @test occursin("\n  build: Build(1 component, activations: Float64)\n  Schedule: no rows\n" *
                       "  grid: no constraint\n  warnings: none", text)
    end

    @testset "the status's compact form is one line with the counts (§11.8, D-257)" begin
        @test compact(hand_status(malformed_record(0, 0, 0))) ==
              "FrameworkStatus(3 writers, no occurrences, unpaced)"
        @test compact(hand_status(malformed_record(21, 16, 5))) ==
              "FrameworkStatus(3 writers, 21 occurrences, unpaced)"
        paced = hand_status(malformed_record(0, 0, 0);
                            pacer = PacerStatus(2.0, 0.0, 0.0, 0, 0, 0.0, 3, 0.25))
        @test compact(paced) == "FrameworkStatus(3 writers, no occurrences, pace = 2.0)"
        for x in (hand_status(malformed_record(21, 16, 5)), paced)
            @test !occursin('\n', compact(x))
            @test repr(x) == compact(x)
        end
    end

    @testset "the status renders each writer, the pacer's line last (§11.8, §10.7)" begin
        # A quiet status: every writer's heading says so, and the device's alone
        # carries a task state and a heartbeat, the raw value and no verdict.
        @test plain(hand_status(malformed_record(0, 0, 0))) == QUIET_STATUS
        paced = hand_status(malformed_record(0, 0, 0);
                            pacer = PacerStatus(2.0, 0.5, 0.75, 1, 1, 0.5, 3, 0.25))
        @test last(split(plain(paced), '\n')) ==
              "  pacer: pace = 2.0, debt 0.5 s, peak 0.75 s, 1 overrun, 1 reanchor, " *
              "0.5 s forgiven, 3 waits, 0.25 s waited"

        # Under the cap, the kind's count line and every retained occurrence.
        lines = split(plain(hand_status(malformed_record(3, 3, 0))), '\n')
        @test lines[2] == "  device 1 (Parser): running, heartbeat 1.0e9"
        @test lines[3] == "    MalformedDatum: 3 occurrences"
        @test lines[4:6] == ["      " * logline(MalformedDatum("datum $k")) for k in 1:3]
        @test lines[7] == "  harness: no occurrences"
    end

    @testset "a writer × kind prints in full up to 25 occurrences, then count-only (§11.8, D-136)" begin
        @test STATUS_MAXLOG == 25
        # Total 30 with ten retained and none suppressed: occurrences 21–30 are
        # this boundary's, and the first five of them fill the cap.
        lines = split(plain(hand_status(malformed_record(30, 10, 0))), '\n')
        @test lines[3] == "    MalformedDatum: 30 occurrences"
        @test lines[4:8] == ["      " * logline(MalformedDatum("datum $k")) for k in 21:25]
        @test lines[9] == "  harness: no occurrences"

        # Far past the cap: the count line and this boundary's suppressed count
        # alone, no occurrence printed.
        lines = split(plain(hand_status(malformed_record(1482, 16, 100))), '\n')
        @test lines[3:5] == ["    MalformedDatum: 1482 occurrences",
                             "      100 suppressed this boundary",
                             "  harness: no occurrences"]

        # A live status renders the same way: the occurrence in full on the
        # snapshot whose delta carries it, its count line on every later one.
        sim = Simulation(two_root_inputs(); h = 1//10)
        handle = attach!(sim, Pad("p"), Enumerated("a"))
        init!(sim, fragment(inputs = (a = 0.0, b = 0.0)))
        report!(handle, MalformedDatum("one"))       # folded at frame 1's top
        run!(sim; t_end = 0.5)
        first_frame, final = plain(logged(sim)[2].status), plain(latest(sim).status)
        rendered = logline(MalformedDatum("one"))
        @test occursin("\n    MalformedDatum: 1 occurrence\n      $rendered\n", first_frame)
        @test occursin("\n    MalformedDatum: 1 occurrence\n", final) && !occursin(rendered, final)
    end

    @testset "every REPL form ends without a newline and carries no trailing whitespace (D-257)" begin
        for x in (multirate.structure, multirate.outputs, multirate.events, deployed.schedule,
                  multirate, deployed, pendulum.structure, pendulum_deployed.schedule, pendulum,
                  pendulum_deployed, group.schedule, group, build(Motor(1.0)).events,
                  hand_status(malformed_record(0, 0, 0)), hand_status(malformed_record(30, 10, 0)),
                  hand_status(malformed_record(1482, 16, 100)))
            text = plain(x)
            @test !endswith(text, '\n')
            @test all(line == rstrip(line) for line in split(text, '\n'))
        end
    end
end
