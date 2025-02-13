from random import random
from larecs import World, ComponentType
from larecs.resource import ResourceContaining
from components import Position, Velocity
from parameters import Parameters, GRAVITATIONAL_CONSTANT
from python import PythonObject, Python
from sys.ffi import OpaquePointer
from memory import UnsafePointer


fn move[
    *component_types: ComponentType,
    resources_type: ResourceContaining,
](mut world: World[*component_types, resources_type=resources_type,]) raises:
    parameters = world.resources.get_ptr[Parameters]()

    for entity in world.query[Position, Velocity]():
        position = entity.get_ptr[Position]()
        velocity = entity.get_ptr[Velocity]()

        position[].x += velocity[].x * parameters[].dt
        position[].y += velocity[].y * parameters[].dt


@value
struct System[
    *component_types: ComponentType,
    resources_type: ResourceContaining,
](CollectionElement):
    alias World = World[
        *component_types,
        resources_type=resources_type,
    ]

    var impl: OpaquePointer
    var update_fn: fn (ptr: OpaquePointer) raises -> None

    fn update(self) raises:
        self.update_fn(self.impl)


@value
struct MovementSystem[
    origin: MutableOrigin,
    *component_types: ComponentType,
    resources_type: ResourceContaining,
]:
    alias World = World[
        *component_types,
        resources_type=resources_type,
    ]
    alias System = System[
        *component_types,
        resources_type=resources_type,
    ]

    var world: Pointer[Self.World, origin]

    fn update(self) raises:
        parameters = self.world[].resources.get_ptr[Parameters]()

        for entity in self.world[].query[Position, Velocity]():
            position = entity.get_ptr[Position]()
            velocity = entity.get_ptr[Velocity]()

            position[].x += velocity[].x * parameters[].dt
            position[].y += velocity[].y * parameters[].dt

    fn as_system(
        self,
    ) -> Self.System:
        fn _update(ptr: OpaquePointer) raises:
            ptr.bitcast[Self]()[].update()

        return Self.System(
            impl=UnsafePointer.address_of(self).bitcast[NoneType](),
            update_fn=_update,
        )


@value
struct AccelerationSystem[
    origin: MutableOrigin,
    *component_types: ComponentType,
    resources_type: ResourceContaining,
]:
    alias World = World[
        *component_types,
        resources_type=resources_type,
    ]
    alias System = System[
        *component_types,
        resources_type=resources_type,
    ]

    var world: Pointer[Self.World, origin]

    fn update(self) raises:
        parameters = self.world[].resources.get_ptr[Parameters]()
        constant = -GRAVITATIONAL_CONSTANT * parameters[].mass * parameters[].dt

        for entity in self.world[].query[Position, Velocity]():
            position = entity.get[Position]()
            velocity = entity.get_ptr[Velocity]()

            multiplier = constant * (position.x**2 + position.y**2) ** (
                -1.5
            )

            velocity[].x += position.x * multiplier
            velocity[].y += position.y * multiplier

    fn as_system(
        self,
    ) -> Self.System:
        fn _update(ptr: OpaquePointer) raises:
            ptr.bitcast[Self]()[].update()

        return Self.System(
            impl=UnsafePointer.address_of(self).bitcast[NoneType](),
            update_fn=_update,
        )


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
        _ = world.add_entity(get_random_position(), get_random_velocity())


fn position_to_numpy(mut world: World, out numpy_array: PythonObject) raises:
    iterator = world.query[Position]()

    np = Python.import_module("numpy")
    numpy_array = np.zeros((len(iterator), 2))

    i = 0
    for entity in iterator:
        position = entity.get[Position]()

        numpy_array[i, 0] = position.x
        numpy_array[i, 1] = position.y

        i += 1
