# Events, modes and projections past one chunk and past 32 elements: the paths
# the study's fixtures never reach. Run on base and on recommended; diff outputs.
using Cadence, StaticArrays, LinearAlgebra, ForwardDiff
const T = joinpath(ARGS[1], "test")
include(joinpath(T, "imports.jl")); include(joinpath(T, "fixtures.jl"))
include("/Users/miguel/.julia/dev/Cadence.jl/docs/reports/20261001_compile_cost_reeval/probes/fixtures.jl")
N = 40
names = Symbol[]; kids = Any[]
for i in 1:N
    push!(names, Symbol(:b, i)); push!(kids, Bouncer(1.0 + 0.01i, 0.3 + 0.001i))
    push!(names, Symbol(:m, i)); push!(kids, Motor(1.0 + 0.1i))
    push!(names, Symbol(:p, i)); push!(kids, Body())
end
root = Group(NamedTuple{Tuple(names)}(Tuple(kids));
             inputs = ("M_load" => Tuple("m$i/M_load" for i in 1:N),
                       "M" => Tuple("p$i/M" for i in 1:N)))
cond = fragment(u = (M_load = 0.05, M = V3(0.0, 0.0, 0.01)))
for cs in (16, 4)
    sim = Simulation(build(root); h = 1//1000, chunk_size = cs)
    init!(sim, cond); run!(sim; t_end = 2.0)
    ev = sim.exec.events
    println("chunk=$cs x=", hash(sim.exec.xbuf), " n_events=", length(ev.count))
    ms = [m[] for m in sim.exec.mstores if m !== nothing]
    println("chunk=$cs modes=", hash(ms), " bounces=", sum(m.count for m in ms if hasproperty(m, :count)), " running=", count(m -> hasproperty(m, :running) && m.running, ms))
    init!(sim, cond); run!(sim; t_end = 0.1)
    init!(sim, cond)
    println("chunk=$cs run_alloc_0.5s=", @allocated run!(sim; t_end = 0.5))
end

# A guard that throws mid-run, in the 37th event of 40: which component does the error name?
struct Bomb <: AbstractComponent; k::Int; end
Cadence.x_init(::Bomb) = (q = 0.0,)
Cadence.y_types(::Bomb) = (q = Float64,)
Cadence.y_state(::Bomb, (; x)) = (q = x.q,)
Cadence.x_deriv(::Bomb, (; x)) = (q = 1.0,)
bomb_guard(c::Bomb, (; x)) = (c.k == 37 && x.q > 0.25 && error("boom in guard of $(c.k)"); x.q > 10.0)
bomb_handler(::Bomb, (; x)) = (x = (q = 0.0,),)
Cadence.state_events(::Bomb) = (go = StateEvent(bomb_guard, bomb_handler),)
broot = Group(NamedTuple{Tuple(Symbol(:k, i) for i in 1:N)}(Tuple(Bomb(i) for i in 1:N)))
bsim = Simulation(build(broot); h = 1//1000)
init!(bsim, fragment())
try
    run!(bsim; t_end = 1.0)
    println("BOMB no error")
catch err
    msg = sprint(showerror, err)
    println("BOMB ", typeof(err), " :: ", first(split(msg, '\n')))
    m = match(r"k\d+", msg); println("BOMB names ", m === nothing ? "nothing" : m.match)
end
