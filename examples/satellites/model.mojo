from larecs import World, Resources
from parameters import Parameters
from systems import move, accellerate, add_satellites, position_to_numpy
from components import Position, Velocity
from python import Python
from sys import argv


fn update(mut world: World, parameters: Parameters, step: Float64) raises:
    for _ in range(Int(step / parameters.dt)):
        move(world, parameters)
        accellerate(world, parameters)


fn main() raises:
    world = World[Position, Velocity](Resources())

    parameters = Parameters(dt=0.1, mass=5.972e24)

    add_satellites(world, 300)
    plt = Python.import_module("matplotlib.pyplot")
    fig = plt.figure()
    ax = plt.gca()
    plt.show(block=False)

    for _ in range(1000):
        # Update every 600s = 10 minutes
        update(world, parameters, 600)
        data = position_to_numpy(world)

        ax.clear()
        ax.scatter(data.T[0], data.T[1], s=0.1)
        scale = 1e8
        ax.set_xlim((-scale, scale))
        ax.set_ylim((-scale, scale))
        fig.canvas.draw()
        fig.canvas.flush_events()

    print("Done")

    # Show the plot if not in the CI
    args = argv()
    if len(args) < 2 or args[1] != "CI":
        plt.show(block=True)
