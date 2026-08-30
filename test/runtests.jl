using Test, StaticArrays, LinearAlgebra, ForwardDiff, BenchmarkTools
using Cadence

# The framework names the suite calls or extends. `import` rather than `using`
# because a fixture declaring `h_x(::MyComp, …)` is extending Cadence's generic,
# and only an imported binding can be extended. Generated from the names
# Cadence defines that the test files mention; nothing else is in scope.
import Cadence: ASSEMBLY, Absolute, AbstractBinding, AbstractComponent, AbstractDevice,
    AlgebraicCycle, AlreadyAttached, ArgumentInvalid, AttachUnknownFace,
    Authored, BindingContractMismatch, Bouncer, Build, BuildError, CONTINUOUS,
    CallerTaskConflict, Chatterer, ChatteringBudget, ChildNameCollision,
    ClaimConflict, ClaimedFaceEntry, Class, ClassMixed, ClassUnreadable,
    Combined, ConditionNode, ConditionNodeMisuse, ConditionResolution,
    ConditionShapeDrift, ConformanceFailure, ContainerMixed,
    ControlRequestedStop, CursorFrame, DIAG_RING, DISCRETE,
    DeclarationOnWrongTier, DeclaredNotProduced, DeploymentInvalid,
    Detonated, DeviceContractMismatch, DeviceCrash, DeviceHandle, DeviceJoinTimeout,
    DiagCell, Diagnostic, DiscreteIntegrator, DuplicateConditionLeaf,
    EMPTY_DIAG, EmptyGreedyClaim, EndTimeReached, EntryTypeMismatch, Enumerated,
    Event, EventHalfMissing, ExecutionCursor, Executor, Exploded, Exploder,
    FaceDirectionConflict, FaceNameCollision, FaceNameIllegal, FiringBudget,
    Follower, Fragment, Gain, Gated, GatedStamper, GetDeriv, Greedy, Group,
    GuardForm, HandlerReturnKey, Heun, Hz, IllegalPortType, InternalInvariant,
    Interrupter, KindCounts, Landmine, LoopError, MalformedDatum, Mine,
    MissingInit, ModedSource, ModelRequestedStop, MultiRate, NotAttached,
    OutOfClaimEntry, Overload, PRIMITIVE, Pad, Panel, PathResolution, Pendulum,
    Period, Plant, Preempted, Primer, ProducedByTwoStages, RK4, Ramp,
    RatesViolation, ReadBindingUnresolved, ReadSetMisuse, Readout, Relative,
    Relaxer, ReplayDiscardedStaging, ReplayFeed, ReplayHeaderMismatch,
    ReplaySchemaMismatch, ReplayUnknownFace, RootInputTypeConflict, Rotor,
    SampledLoop, Sapper, Sawtooth, Scoped, ServiceLifecycle, Simulation,
    Smoother, Snapshot, SpecializedPlan, Stamper, StepError, StopFaceInvalid,
    StoreBundle, StoreWithoutUpdate, Sum, TableBinding, TapResolution,
    TerminationRecord, TickCounter, Tier, TierUnreadable, Trace, TraceBatch,
    TransparentContainerUnknown, Trigger, TrimCommitEvents, TrimCommitResiduals,
    TrimProblem, TrimProblemInvalid, TrimTag, Tripped, Tripwire, TwoProducers,
    TwoShot, UnconnectedInput, UndeclaredReturnField, UninitializedInputs,
    UnknownFaceSelection, UnknownPort, Vehicle, WireTypeMismatch, WorkGain, ZOH,
    _bump, _cell_key, _compile_feed, _compile_reads, _heartbeat, _report!,
    _reschema, _saturated, _take!, _total, activation, apply!, at, attach!,
    binding, boundary!, build, bundle_names, capture, child_connections,
    children, claims, classify, classify_tier, combine, compile, compile_plan,
    condition, declarations, detach!, drain!, evaluate!, events, f,
    feedback_model, fragment, frame!, g, gather, get_deriv, get_face, get_input,
    get_output, get_state, h_s, h_su, h_x, h_xu, index_of, init!, init_m,
    init_s, init_x, input_connections, input_faces, input_passthrough,
    input_types, is_greedy, is_input, is_output, kinds, latest, lifecycle,
    logged, logline, loop, map_input, map_output, message, modes,
    needs_calling_task, offtick_boundary!, output_connections, output_faces,
    output_passthrough, output_types, override, path, period, phase_bodies,
    port, project, publish!, reads, replay!, report!, resolve,
    resolve_condition, resolve_terminal, retype, retype_value, run!, running,
    sample_times, sampled_loop, scatter!, severity, shutdown!, solve, stage!,
    stale, state, step!, stop!, termination, trace, transparent_container,
    trim!, unblock!, wait_next_snapshot, workspace

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
