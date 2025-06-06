from larecs import World, Resources
from parameters import Parameters
from systems import move, accelerate, add_satellites, position_to_numpy
from components import Position, Velocity
from python import Python
from sys import argv


fn update(mut world: World, step: Float64) raises:
    for _ in range(Int(step / world.resources.get[Parameters]().dt)):
        move(world)
        accelerate(world)


fn main() raises:
    world = World[Position, Velocity]()

    world.resources.add(Parameters(dt=0.1, mass=5.972e24))

    add_satellites(world, 300)
    plt = Python.import_module("matplotlib.pyplot")
    fig = plt.figure()
    ax = plt.gca()
    plt.show(block=False)

    for _ in range(1000):
        # Update every 600s = 10 minutes
        update(world, 600)
        data = position_to_numpy(world)

        ax.clear()
        ax.scatter(data.T[0], data.T[1], s=0.1)
        scale = 1e8
        ax.set_xlim(Python.tuple(-scale, scale))
        ax.set_ylim(Python.tuple(-scale, scale))
        fig.canvas.draw()
        fig.canvas.flush_events()

    print("Done")

    plt.show(block=True)
