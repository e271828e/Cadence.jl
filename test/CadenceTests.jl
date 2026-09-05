module CadenceTests

using Test, StaticArrays, LinearAlgebra, ForwardDiff, BenchmarkTools
using Cadence

import Cadence: ASSEMBLY, Absolute, AbstractBinding, AbstractComponent,
    AbstractDevice, AlgebraicCycle, AlreadyAttached, ArgumentInvalid,
    AttachUnknownFace, Authored, BindingContractMismatch, Build,
    CONTINUOUS, CallerTaskConflict, ChatteringBudget, ChildNameCollision,
    ClaimConflict, ClaimedFaceEntry, Class, ClassMixed, ClassUnreadable,
    Combined, ConditionNode, ConditionNodeMisuse, ConditionResolution,
    ConditionShapeDrift, ConformanceFailure, ContainerMixed,
    ControlRequestedStop, CursorFrame, DIAG_RING, DISCRETE,
    DeclarationOnWrongTier, DeclaredNotProduced, DeploymentInvalid,
    DeviceContractMismatch, DeviceCrash, DeviceHandle, DeviceJoinTimeout,
    DiagCell, Diagnostic, DiagnosticError, DuplicateConditionLeaf, EMPTY_DIAG,
    EmptyGreedyClaim, EndTimeReached, EntryTypeMismatch, EventHalfMissing,
    Executor, FaceDirectionConflict, FaceNameCollision, FaceNameIllegal,
    FiringBudget, Fragment, Gated, GetDeriv, Group, GuardForm,
    HandlerReturnKey, Heun, Hz, IllegalPortType, InternalInvariant,
    KindCounts, LoopError, MalformedDatum, MissingInit, ModelRequestedStop,
    NonfiniteState, NotAttached, OutOfClaimEntry, PRIMITIVE, PathResolution,
    Period, ProducedByTwoStages, RK4, RatesViolation, ReadBindingUnresolved,
    ReadSetMisuse, Relative, ReplayDiscardedStaging, ReplayFeed,
    ReplayHeaderMismatch, ReplaySchemaMismatch, ReplayUnknownFace,
    RootInputTypeConflict, Scoped, ServiceLifecycle, Simulation, Snapshot,
    SpecializedPlan, StateEvent, StepError, StopFaceInvalid, StoreBundle,
    StoreWithoutUpdate, TableBinding, TapResolution, TerminationRecord, Tier,
    TierUnreadable, Trace, TraceBatch, TransparentContainerUnknown,
    TrimCommitEvents, TrimCommitResiduals, TrimProblem, TrimProblemInvalid,
    TrimTag, TwoProducers, UnconnectedInput, UndeclaredReturnField,
    UninitializedInputs, UnknownFaceSelection, UnknownPort, WireTypeMismatch,
    _bump, _cell_key, _compile_feed, _compile_reads, _heartbeat,
    _mflatten_expr, _mreconstruct_expr, _report!, _reschema, _saturated,
    _take!, _total, activation, apply!, at, attach!, binding, boundary!,
    build, bundle_names, capture, child_connections, children, claims,
    classify, classify_tier, combine, compile, compile_plan, declarations,
    detach!, diagnostic, diagnostics, drain!, evaluate!, flatten!, fragment,
    frame!, gather, get_deriv, get_face, get_input, get_output, get_state,
    index_of, init!, init_m, init_s, init_workspace, init_x,
    input_connections, input_faces, input_passthrough, input_types,
    is_greedy, is_input, is_output, kinds,
    latest, leaf_eltypes, leaf_names, leaf_types, lifecycle, live!, logged,
    logline, loop, map_input, map_output, message, mode, modes,
    needs_calling_task, nleaves, offtick_boundary!, output_connections,
    output_direct, output_faces, output_passthrough, output_state,
    output_types, override, path, period, phase_bodies, port, publish!, reads,
    reconstruct, replay!, report!, resolve, resolve_condition,
    resolve_terminal, retype, retype_value, run!, running, sample_times,
    scatter!, severity, shutdown!, solve, stage!, stale, state,
    state_derivative, state_events, state_projection, state_update, step!,
    stop!, termination, trace, transparent_container, trim!, unblock!,
    wait_next_snapshot

include("fixtures.jl")
include("utils.jl")

include("test_leaves.jl")
include("test_declare.jl")
include("test_assembly.jl")
include("test_store.jl")
include("test_build.jl")

include("test_executor.jl")
include("test_continuous.jl")
include("test_discrete.jl")
include("test_stepper.jl")
include("test_events.jl")
include("test_localization.jl")

include("test_dataplane.jl")
include("test_roster.jl")
include("test_bindings.jl")
include("test_devices.jl")
include("test_log.jl")
include("test_trace.jl")
include("test_readers.jl")

include("test_conditions.jl")
include("test_trim.jl")

include("test_diagnostics.jl")
include("test_failures.jl")
include("test_lifecycle.jl")

"""
Run one file's tests in a testset named `name` and print its summary as soon as
it completes. A nested testset stays silent until the root prints the whole
tree, so the summary is printed here by hand. The results still reach the
parent, so the final hierarchy is unchanged.
"""
function live(name, f)
    ts = @testset "$name" begin f() end
    Test.print_test_results(ts)
end

"""
Run the whole suite. Each file's summary prints as the file completes. The root
prints the total at the end, and expands only where something failed. One
file's tests are callable on their own: `test_trace()`.
"""
function runall()
    @testset "Cadence" begin
        live("leaves",       test_leaves)
        live("declare",      test_declare)
        live("assembly",     test_assembly)
        live("store",        test_store)
        live("build",        test_build)
        live("executor",     test_executor)
        live("continuous",   test_continuous)
        live("discrete",     test_discrete)
        live("stepper",      test_stepper)
        live("events",       test_events)
        live("localization", test_localization)
        live("dataplane",    test_dataplane)
        live("roster",       test_roster)
        live("bindings",     test_bindings)
        live("devices",      test_devices)
        live("log",          test_log)
        live("trace",        test_trace)
        live("readers",      test_readers)
        live("conditions",   test_conditions)
        live("trim",         test_trim)
        live("diagnostics",  test_diagnostics)
        live("failures",     test_failures)
        live("lifecycle",    test_lifecycle)
    end
end

"""
    runonly("trace", "devices")

Run only the named files' tests — the loop between commits, where the whole
suite is too slow to run per edit. `runall` names them all. A cold process
costs about 30 s before the first file's tests run and little per file after
that, so name a generous set rather than the minimal one.
"""
function runonly(names::AbstractString...)
    fs = map(names) do n                       # resolve first: a typo costs no run
        s = Symbol("test_", n)
        isdefined(@__MODULE__, s) || error("no tests named `$n` (`runall` names them)")
        getfield(@__MODULE__, s)
    end
    @testset "selected" begin
        for (n, f) in zip(names, fs)
            live(n, f)
        end
    end
end

end # module CadenceTests
