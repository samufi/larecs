from testing import *
from world import World
from entity import Entity
from component import ComponentType, ComponentInfo
from test_utils import *


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


def test_entity_get():
    world = World[Position, Velocity]()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    entity = world.new_entity(pos, vel)
    assert_equal(world.get[Position](entity).x, pos.x)
    world.get[Position](entity).x = 123
    assert_equal(world.get[Position](entity).x, 123)


def test_entity_get_ptr():
    world = World[Position, Velocity]()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    entity = world.new_entity(pos, vel)
    assert_equal(world.get[Position](entity).x, pos.x)
    entity_pos = world.get_ptr[Position](entity)
    entity_pos[].x = 123
    assert_equal(world.get[Position](entity).x, 123)


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
            world._component_manager.get_id_arr[T1, T2](),
            start_node_index=start,
        )

    assert_equal(get_index[Position](), 1)
    assert_equal(get_index[Velocity](), 2)
    assert_equal(get_index[Velocity, Position](), 3)
    assert_equal(get_index[Position, Velocity](), 3)
    assert_equal(get_index[Velocity, Position](1), 2)
    assert_equal(get_index[Velocity, Position](2), 1)


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


def test_remove_entity():
    world = World[Position, Velocity]()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    entity = world.new_entity(pos, vel)
    world.remove_entity(entity)

    with assert_raises():
        _ = world.get[Position](entity)
    with assert_raises():
        _ = world.get[Velocity](entity)
    assert_equal(len(world._archetypes[1]._entities), 0)
    assert_equal(len(world._entity_pool), 0)


def test_remove_archetype():
    world = World[Position, Velocity]()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    entity1 = world.new_entity(pos, vel)
    entity2 = world.new_entity(pos, vel)
    world.remove_entity(entity1)

    with assert_raises():
        _ = world.get[Position](entity1)
    with assert_raises():
        _ = world.get[Velocity](entity1)
    assert_equal(len(world._archetypes), 2)
    assert_equal(len(world._archetypes[1]._entities), 1)
    assert_equal(len(world._entity_pool), 1)

    world.remove_entity(entity2)
    assert_equal(len(world._archetypes), 2)
    assert_equal(len(world._archetypes[1]._entities), 0)
    assert_equal(len(world._entity_pool), 0)


def test_world_has_component():
    world = World[Position, Velocity]()
    pos = Position(1.0, 2.0)
    entity = world.new_entity(pos)
    assert_true(world.has[Position](entity))
    assert_false(world.has[Velocity](entity))


def test_world_add():
    world = World[Position, Velocity]()
    pos = Position(1.0, 2.0)
    entity = world.new_entity(pos)
    assert_true(world.has[Position](entity))
    assert_false(world.has[Velocity](entity))
    world.add(entity, Velocity(0.1, 0.2))
    assert_true(world.has[Velocity](entity))
    assert_equal(world.get[Velocity](entity).dx, 0.1)
    assert_equal(world.get[Velocity](entity).dy, 0.2)

    with assert_raises():
        world.add(entity, Velocity(0.3, 0.4))


def test_world_remove():
    world = World[Position, Velocity]()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    entity = world.new_entity(pos, vel)
    assert_true(world.has[Position](entity))
    assert_true(world.has[Velocity](entity))
    world.remove[Position](entity)
    assert_false(world.has[Position](entity))
    with assert_raises():
        _ = world.get[Position](entity)

    assert_equal(len(world._archetypes), 3)

    with assert_raises():
        world.remove[Position](entity)

    entity = world.new_entity(pos, vel)
    assert_equal(len(world._archetypes), 3)
    world.remove[Position, Velocity](entity)
    assert_equal(len(world._archetypes), 3)
    assert_equal(len(world._archetypes[0]._entities), 1)

    # Test swapping
    entity1 = world.new_entity(pos, vel)
    entity2 = world.new_entity(pos, vel)
    index1 = world._entities[int(entity1.id)].index
    index2 = world._entities[int(entity2.id)].index
    assert_not_equal(index1, index2)
    world.remove[Position](entity1)
    assert_equal(index1, world._entities[int(entity2.id)].index)


def test_remove_and_add():
    world = World[Position, Velocity]()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    entity = world.new_entity(pos)
    assert_true(world.has[Position](entity))
    assert_false(world.has[Velocity](entity))

    _ = world.remove_and[Velocity]()
    assert_true(world.has[Position](entity))
    assert_false(world.has[Velocity](entity))

    world.remove_and[Position]().add(entity, vel)
    assert_false(world.has[Position](entity))
    assert_true(world.has[Velocity](entity))

    with assert_raises():
        world.remove_and[Position]().add(entity, vel)

    assert_equal(world.get[Velocity](entity).dx, vel.dx)
    assert_equal(world.get[Velocity](entity).dy, vel.dy)


def main():
    print("Running additional tests...")
    test_new_entity()
    test_new_entity_with_components()
    test_set_component()
    test_get_archetype_index()
    test_entity_get()
    test_entity_get_ptr()
    test_remove_entity()
    test_remove_archetype()
    test_world_has_component()
    test_world_add()
    test_world_remove()
    test_remove_and_add()
    print("All additional tests passed.")
