# plant: xdot = 1,  y = x*u.   loop: u = 1 + y  =>  y = x/(1-x) at every instant.
# At x0 = 0 the numerical Jacobian dy/du = x = 0, so PathSim classifies the plant
# as having no algebraic passthrough and never runs its loop solver.
import warnings; warnings.filterwarnings("ignore")
import numpy as np
from pathsim import Simulation, Connection
from pathsim.blocks import DynamicalSystem, Adder, Constant
from pathsim.solvers import RK4

def trial(x0):
    plant = DynamicalSystem(func_dyn=lambda x, u, t: np.array([1.0]),
                            func_alg=lambda x, u, t: np.array([x[0] * u[0]]),
                            initial_value=np.array([x0]))
    one, add = Constant(1.0), Adder("++")
    sim = Simulation([plant, one, add],
                     [Connection(one, add[0]), Connection(plant, add[1]), Connection(add, plant)],
                     dt=0.01, Solver=RK4, log=False)
    print(f"x0={x0}: len(plant)={len(plant)}  graph.has_loops={sim.graph.has_loops}")
    sim.run(0.5)
    x = plant.engine.state[0]; y = plant.outputs[0]
    print(f"   t={sim.time:.3f} x={x:.4f}  y={y:.5f}  exact y=x/(1-x)={x/(1-x):.5f}")

trial(0.0)
trial(0.1)
