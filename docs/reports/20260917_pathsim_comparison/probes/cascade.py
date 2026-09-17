# Run from the report's probes/ directory with the venv of bench_pathsim.py.
# Event A fires at t=1 (time-based zero crossing) and sets a flag.
# Event B's guard is  +1 if flag else -1 : it jumps from not-holding to holding
# at the instant A fires. Does B ever fire?
import warnings; warnings.filterwarnings("ignore")
from pathsim import Simulation, Connection
from pathsim.blocks import Integrator, Constant
from pathsim.events import ZeroCrossing, ZeroCrossingUp
from pathsim.solvers import RK4, RKDP54

def trial(Solver, adaptive):
    flag = {"on": False}
    A = ZeroCrossing(func_evt=lambda t: t - 1.0, func_act=lambda t: flag.__setitem__("on", True))
    B = ZeroCrossingUp(func_evt=lambda t: 1.0 if flag["on"] else -1.0, func_act=lambda t: None)
    c, i = Constant(1.0), Integrator(0.0)
    sim = Simulation([c, i], [Connection(c, i)], events=[A, B], dt=0.01, Solver=Solver, log=False)
    sim.run(3.0, adaptive=adaptive)
    return list(A), list(B)

for Solver, adaptive in [(RK4, False), (RKDP54, True)]:
    a, b = trial(Solver, adaptive)
    print(f"{Solver.__name__:7s} adaptive={adaptive}:  A fired at {a}   B fired at {b}")
