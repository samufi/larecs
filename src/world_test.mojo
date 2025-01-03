from testing import *
from world import World
from entity import Entity
from component import ComponentType, ComponentInfo


@value
struct Position(ComponentType):
    var x: Float32
    var y: Float32

    @staticmethod
    @always_inline
    fn get_type_identifier() -> Int:
        return 1


@value
struct Velocity(ComponentType):
    var dx: Float32
    var dy: Float32

    @staticmethod
    @always_inline
    fn get_type_identifier() -> Int:
        return 2


def test_new_entity():
    world = World()
    entity = world.new_entity()
    assert_true(entity.id == 1)
    assert_false(entity.is_zero())


def test_new_entity_with_components():
    world = World[Position, Velocity]()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    entity = world.new_entity(pos, vel)
    assert_equal(world.get[Position](entity).x, pos.x)
    assert_equal(world.get[Position](entity).y, pos.y)
    assert_equal(world.get[Velocity](entity).dx, vel.dx)
    assert_equal(world.get[Velocity](entity).dy, vel.dy)
    for _ in range(10_000):
        _ = world.new_entity(pos, vel)


def test_get_archetype_index():
    world = World[Position, Velocity]()
    pos = Position(12, 654)
    vel = Velocity(0.1, 0.2)
    _ = world.new_entity(pos)
    _ = world.new_entity(vel)
    _ = world.new_entity(pos, vel)

    fn get_index[T: ComponentType]() capturing raises -> Int:
        return world._get_archetype_index(
            world._component_manager.get_info_arr[T]()
        )

    fn get_index[
        T1: ComponentType, T2: ComponentType
    ](start: Int = 0) capturing raises -> Int:
        return world._get_archetype_index(
            world._component_manager.get_info_arr[T1, T2](),
            start_node_index=start,
        )

    assert_equal(get_index[Position](), 1)
    assert_equal(get_index[Velocity](), 2)
    assert_equal(get_index[Position, Velocity](), 3)
    assert_equal(get_index[Velocity, Position](1), 3)
    assert_equal(get_index[Velocity, Position](2), 3)


def test_set_component():
    world = World[Position, Velocity]()
    pos = Position(3.0, 4.0)
    entity = world.new_entity(pos)
    pos = Position(2.0, 7.0)
    world.set(entity, pos)
    assert_equal(world.get[Position](entity).x, pos.x)
    assert_equal(world.get[Position](entity).y, pos.y)

    vel = Velocity(0.3, 0.4)
    entity = world.new_entity(pos, vel)
    pos = Position(12, 654)
    vel = Velocity(0.1, 0.2)
    world.set(entity, vel, pos)
    assert_equal(world.get[Position](entity).x, pos.x)
    assert_equal(world.get[Position](entity).y, pos.y)
    assert_equal(world.get[Velocity](entity).dx, vel.dx)
    assert_equal(world.get[Velocity](entity).dy, vel.dy)


def main():
    print("Running tests...")
    test_new_entity()
    test_new_entity_with_components()
    test_set_component()
    test_get_archetype_index()
    print("All tests passed.")
