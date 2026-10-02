# Builds §7.3's PRNG example verbatim, then with UInt64 initial words.
using Cadence, Random
import Cadence: AbstractComponent, Group, Simulation, init!, run!, state
import Cadence: s_init, ws_init, s_update, y_types, y_state

struct Noise <: AbstractComponent end
s_init(::Noise)         = (rng = (0x9e3779b9, 0x243f6a88, 0xb7e15162, 0x6a09e667),)
ws_init(::Noise, ::Type) = (rng = Xoshiro(0, 0, 0, 0),)
function s_update(c::Noise, b)
    r = b.ws.rng
    r.s0, r.s1, r.s2, r.s3 = b.s.rng
    z = randn(r)
    (rng = (r.s0, r.s1, r.s2, r.s3),)
end

struct Noise64 <: AbstractComponent end
s_init(::Noise64)         = (rng = UInt64.((0x9e3779b9, 0x243f6a88, 0xb7e15162, 0x6a09e667)),)
ws_init(::Noise64, ::Type) = (rng = Xoshiro(0, 0, 0, 0),)
function s_update(c::Noise64, b)
    r = b.ws.rng
    r.s0, r.s1, r.s2, r.s3 = b.s.rng
    z = randn(r)
    (rng = (r.s0, r.s1, r.s2, r.s3),)
end

for C in (Noise, Noise64)
    try
        sim = Simulation(Group((; n = C())); h = 1//10)
        init!(sim); run!(sim; t_end = 0.3)
        println(C, ": ran, state type ", typeof(state(sim, "n").rng))
    catch e
        println(C, ": ", typeof(e), " — ", sprint(showerror, e)[1:min(end, 600)])
    end
end
