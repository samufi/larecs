from larecs import World as LxWorld, Resources as LxResources
from larecs.resource import ResourceContaining
from parameters import Parameters
from systems import (
    System,
    MovementSystem,
    AccelerationSystem,
    add_satellites,
    position_to_numpy,
)
from components import Position, Velocity
from python import Python
from collections import List
from sys.ffi import OpaquePointer


fn update(mut world: LxWorld, step: Float64) raises:
    for _ in range(Int(step / world.resources.get_ptr[Parameters]()[].dt)):
        pass
        # for s in sys:
        #    s.update(World)


alias Resources = LxResources[Parameters]
alias World = LxWorld[Position, Velocity, resources_type=Resources]


fn main() raises:
    world = World(Resources())
    world.resources.add(Parameters(dt=0.1, mass=5.972e24))

    var movement = MovementSystem[
        __origin_of(world), Position, Velocity, resources_type=Resources
    ](Pointer.address_of(world))
    # var acceleration = MovementSystem[
    #    __origin_of(world), Position, Velocity, resources_type=Resources
    # ](Pointer.address_of(world))

    var systems = List[System[Position, Velocity, resources_type=Resources]](
        movement.as_system(),
        #    acceleration.as_system(),
    )
    for sys in systems:
        sys[].update()

    add_satellites(world, 50)
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
        ax.set_xlim((-scale, scale))
        ax.set_ylim((-scale, scale))
        fig.canvas.draw()
        fig.canvas.flush_events()

    print("Done")

    _ = movement
    # _ = acceleration

    plt.show(block=True)
