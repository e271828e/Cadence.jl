using Test, StaticArrays, LinearAlgebra, ForwardDiff, BenchmarkTools
using Cadence

# The framework names the suite calls or extends. `import` rather than `using`
# because a fixture declaring `h_x(::MyComp, …)` is extending Cadence's generic,
# and only an imported binding can be extended. Generated from the names
# Cadence defines that the test files mention; nothing else is in scope.
import Cadence: ASSEMBLY, Absolute, AbstractBinding, AbstractComponent,
    AbstractDevice, AlgebraicCycle, AlreadyAttached, ArgumentInvalid,
    AttachUnknownFace, Authored, BindingContractMismatch, Build, BuildError,
    CONTINUOUS, CallerTaskConflict, ChatteringBudget, ChildNameCollision,
    ClaimConflict, ClaimedFaceEntry, Class, ClassMixed, ClassUnreadable,
    Combined, ConditionNode, ConditionNodeMisuse, ConditionResolution,
    ConditionShapeDrift, ConformanceFailure, ContainerMixed,
    ControlRequestedStop, CursorFrame, DIAG_RING, DISCRETE,
    DeclarationOnWrongTier, DeclaredNotProduced, DeploymentInvalid,
    DeviceContractMismatch, DeviceCrash, DeviceHandle, DeviceJoinTimeout,
    DiagCell, Diagnostic, DuplicateConditionLeaf, EMPTY_DIAG, EmptyGreedyClaim,
    EndTimeReached, EntryTypeMismatch, Event, EventHalfMissing, ExecutionCursor,
    Executor, FaceDirectionConflict, FaceNameCollision, FaceNameIllegal,
    FiringBudget, Fragment, Gated, GetDeriv, Group, GuardForm, HandlerReturnKey,
    Heun, Hz, IllegalPortType, InternalInvariant, KindCounts, LoopError,
    MalformedDatum, MissingInit, ModelRequestedStop, NonfiniteState,
    NotAttached, OutOfClaimEntry, PRIMITIVE, PathResolution, Period,
    ProducedByTwoStages, RK4, RatesViolation, ReadBindingUnresolved,
    ReadSetMisuse, Relative, ReplayDiscardedStaging, ReplayFeed,
    ReplayHeaderMismatch, ReplaySchemaMismatch, ReplayUnknownFace,
    RootInputTypeConflict, Scoped, ServiceLifecycle, Simulation, Snapshot,
    SpecializedPlan, StepError, StopFaceInvalid, StoreBundle,
    StoreWithoutUpdate, TableBinding, TapResolution, TerminationRecord, Tier,
    TierUnreadable, Trace, TraceBatch, TransparentContainerUnknown,
    TrimCommitEvents, TrimCommitResiduals, TrimProblem, TrimProblemInvalid,
    TrimTag, TwoProducers, UnconnectedInput, UndeclaredReturnField,
    UninitializedInputs, UnknownFaceSelection, UnknownPort, WireTypeMismatch,
    _bump, _cell_key, _compile_feed, _compile_reads, _heartbeat, _report!,
    _reschema, _saturated, _take!, _total, activation, apply!, at, attach!,
    binding, boundary!, build, bundle_names, capture, child_connections,
    children, claims, classify, classify_tier, combine, compile, compile_plan,
    declarations, detach!, drain!, evaluate!, events, f, fragment, frame!, g,
    gather, get_deriv, get_face, get_input, get_output, get_state, h_s, h_su,
    h_x, h_xu, index_of, init!, init_m, init_s, init_x, input_connections,
    input_faces, input_passthrough, input_types, is_greedy, is_input, is_output,
    kinds, latest, lifecycle, live!, logged, logline, loop, map_input,
    map_output, message, mode, modes, needs_calling_task, offtick_boundary!,
    output_connections, output_faces, output_passthrough, output_types,
    override, path, period, phase_bodies, port, project, publish!, reads,
    replay!, report!, resolve, resolve_condition, resolve_terminal, retype,
    retype_value, run!, running, sample_times, scatter!, severity, shutdown!,
    solve, stage!, stale, state, step!, stop!, termination, trace,
    transparent_container, trim!, unblock!, wait_next_snapshot, workspace

include("fixtures.jl")
include("utils.jl")
include("test_continuous.jl")
include("test_structure.jl")
include("test_discrete.jl")
include("test_hierarchy.jl")
include("test_multirate.jl")
include("test_events.jl")
include("test_localization.jl")
include("test_stepper.jl")
include("test_dataplane.jl")
include("test_roster.jl")
include("test_log.jl")
include("test_devices.jl")
include("test_bindings.jl")
include("test_diagnostics.jl")
include("test_lifecycle.jl")
include("test_conditions.jl")
include("test_readers.jl")
include("test_trim.jl")
include("test_trace.jl")
include("test_failures.jl")
