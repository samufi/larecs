from random import random
from larecs import World
from components import Position, Velocity
from parameters import Parameters, GRAVITATIONAL_CONSTANT
from python import PythonObject, Python


fn move(mut world: World, parameters: Parameters) raises:
    for properties in world.get_entities[Position, Velocity]():
        position = properties.get_ptr[Position]()
        velocity = properties.get_ptr[Velocity]()

        position[].x += velocity[].x * parameters.dt
        position[].y += velocity[].y * parameters.dt


fn accellerate(mut world: World, parameters: Parameters) raises:
    constant = -GRAVITATIONAL_CONSTANT * parameters.mass * parameters.dt

    for properties in world.get_entities[Position, Velocity]():
        position = properties.get[Position]()
        velocity = properties.get_ptr[Velocity]()

        multiplier = constant * (position.x**2 + position.y**2) ** (-1.5)

        velocity[].x += position.x * multiplier
        velocity[].y += position.y * multiplier


fn get_random_position() -> Position:
    return Position(
        x=random.random_float64(-1_000_000, 1_000_000),
        y=random.random_float64(30_000_000, 40_000_000),
    )


fn get_random_velocity() -> Velocity:
    return Velocity(
        random.random_float64(2000, 4000)
        * (random.random_si64(0, 1) * 2 - 1).cast[DType.float64](),
        random.random_float64(-500, 500),
    )


fn add_satellites(mut world: World, count: Int) raises:
    for _ in range(count):
        _ = world.new_entity(get_random_position(), get_random_velocity())


fn position_to_numpy(mut world: World, out numpy_array: PythonObject) raises:
    iterator = world.get_entities[Position]()

    np = Python.import_module("numpy")
    numpy_array = np.zeros((len(iterator), 2))

    i = 0
    for properties in iterator:
        position = properties.get[Position]()

        numpy_array[i, 0] = position.x
        numpy_array[i, 1] = position.y

        i += 1
