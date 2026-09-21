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

const MULTIRATE_DATAFLOW = """
Dataflow: execution order over 4 components
  position  component  stage 1  stage 2  feedthrough
  1         #1         out      —        —
  2         #2         —        out      —
  3         #4         —        out      —
  4         #3         —        out      in ← #4.out"""

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
        @test compact(multirate.dataflow) == "Dataflow(4 components)"
        @test compact(multirate.events) == "Events(no events over 4 components)"
        @test compact(build(Motor(1.0)).events) == "Events(1 event over 1 component)"
        @test compact(deployed.schedule) == "Schedule(3 rows, hyperperiod 10 base ticks)"
        @test compact(pendulum_deployed.schedule) == "Schedule(no rows)"
        @test compact(multirate) == "Build(4 components, activations: Float64)"
        @test compact(deployed) == "Deployment(h = 0.002, N_base = 1, Δt_base = 0.002, RK4)"
        for x in (multirate.structure, multirate.dataflow, multirate.events, deployed.schedule,
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

    @testset "Dataflow: the execution order with the stage-2 dependencies (§9.2, D-257)" begin
        @test plain(multirate.dataflow) == MULTIRATE_DATAFLOW
        # The one feedthrough edge is `fcs/outer`'s, fed by `gnss`'s stage-2 port;
        # `fcs/inner` and `gnss` read `src.out`, a stage-1 port, so they carry none.
        lines = split(MULTIRATE_DATAFLOW, '\n')[3:end]
        @test count(endswith("  in ← #4.out"), lines) == 1 && count(endswith("  —"), lines) == 3
        # Inside the `Build` the same table carries paths.
        @test occursin("\n  Dataflow: execution order over 4 components\n" *
                       "    position  component  stage 1  stage 2  feedthrough\n" *
                       "    1         src        out      —        —\n" *
                       "    2         fcs/inner  —        out      —\n" *
                       "    3         gnss       —        out      —\n" *
                       "    4         fcs/outer  —        out      in ← gnss.out\n", plain(multirate))
    end

    @testset "Events: one row per declaring component (§9.2, D-257)" begin
        @test plain(multirate.events) == "Events: no events over 4 components"
        @test plain(build(Motor(1.0)).events) ==
              "Events: 1 event over 1 component\n" *
              "  component  events             bundle\n" *
              "  #1         start => boundary  (x, m, u, y, t)"
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
        L = lcm([row.D for row in rows])
        @test L == 10
        for (row, line) in zip(rows, lines[end-2:end])
            chart = collect(last(split(line)))
            @test length(chart) == L
            @test [k for k in 0:L-1 if chart[k+1] == '●'] == [k for k in 0:L-1 if (k - row.Φ) % row.D == 0]
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
        @test startswith(plain(pendulum), "Build: 1 component (1 continuous, 0 discrete); activations: Float64; no warnings\n")
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

    @testset "every REPL form ends without a newline and carries no trailing whitespace (D-257)" begin
        for x in (multirate.structure, multirate.dataflow, multirate.events, deployed.schedule,
                  multirate, deployed, pendulum.structure, pendulum_deployed.schedule, pendulum,
                  pendulum_deployed, group.schedule, group, build(Motor(1.0)).events)
            text = plain(x)
            @test !endswith(text, '\n')
            @test all(line == rstrip(line) for line in split(text, '\n'))
        end
    end
end
