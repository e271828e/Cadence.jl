"""Closed-loop damped oscillator: plant (2 states) <- gain <- sum(ref, -y).
Same model as Cadence's `feedback_model` fixture. RK4, fixed dt = 1e-3, 10 s.
N independent copies of the loop in one Simulation to scale component count.
"""
import sys, time
import numpy as np
from pathsim import Simulation, Connection
from pathsim.blocks import DynamicalSystem, Amplifier, Adder, Constant
from pathsim.solvers import RK4

w, z, k, r = 2.0, 0.1, 4.0, 0.7

def make(N):
    blocks, conns = [], []
    ref = Constant(r)
    blocks.append(ref)
    plants = []
    for i in range(N):
        plant = DynamicalSystem(
            func_dyn=lambda x, u, t: np.array([x[1], -w**2 * x[0] - 2*z*w*x[1] + u[0]]),
            func_alg=lambda x, u, t: np.array([x[0]]),
            initial_value=np.array([0.0, 0.0]))
        ctl = Amplifier(k)
        sm = Adder("+-")
        blocks += [plant, ctl, sm]
        conns += [Connection(ref, sm[0]),
                  Connection(plant, sm[1]),
                  Connection(sm, ctl),
                  Connection(ctl, plant)]
        plants.append(plant)
    return blocks, conns, plants

def exact(t):
    A = np.array([[0.0, 1.0], [-w**2, -2*z*w]])
    B = np.array([0.0, 1.0])
    Acl = A - np.outer(B * k, [1.0, 0.0])
    from scipy.linalg import expm, solve
    c = solve(Acl, B * k * r)
    return expm(Acl * t) @ c - c

if __name__ == "__main__":
  for N in [1, 10, 100]:
    t0 = time.perf_counter()
    blocks, conns, plants = make(N)
    sim = Simulation(blocks, conns, dt=1e-3, Solver=RK4, log=False)
    t1 = time.perf_counter()
    sim.run(10.0)
    t2 = time.perf_counter()
    x = plants[0].engine.state
    err = np.abs(x - exact(sim.time)).max()
    steps = round(sim.time / 1e-3)
    print(f"N={N:4d} blocks={len(blocks):4d}  setup={1e3*(t1-t0):8.1f} ms  "
          f"run={t2-t1:7.3f} s  per-step={1e6*(t2-t1)/steps:8.1f} us  "
          f"per-block-step={1e6*(t2-t1)/steps/len(blocks):6.2f} us  |x-exact|={err:.1e}")
