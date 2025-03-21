from testing import *

from larecs.world import World
from larecs.entity import Entity
from larecs.component import ComponentType
from larecs.resource import Resources
from larecs.archetype import MutableEntityAccessor

from larecs.test_utils import *


def test_add_entity():
    world = SmallWorld()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    entity = world.add_entity()
    assert_true(entity.get_id() == 1)
    assert_false(entity.is_zero())

    entity = world.add_entity(pos, vel)
    assert_equal(world.get[Position](entity).x, pos.x)
    assert_equal(world.get[Position](entity).y, pos.y)
    assert_equal(world.get[Velocity](entity).dx, vel.dx)
    assert_equal(world.get[Velocity](entity).dy, vel.dy)
    for _ in range(10_000):
        _ = world.add_entity(pos, vel)


def test_add_entities():
    world = SmallWorld()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    i = 0
    for entity in world.add_entities(pos, vel, count=23):
        assert_equal(entity.get[Position]().x, pos.x)
        assert_equal(entity.get[Position]().y, pos.y)
        assert_equal(entity.get[Velocity]().dx, vel.dx)
        assert_equal(entity.get[Velocity]().dy, vel.dy)
        assert_false(entity.has[FlexibleComponent[0]]())
        assert_false(entity.has[FlexibleComponent[1]]())
        assert_false(entity.has[FlexibleComponent[2]]())
        i += 1
    assert_equal(i, 23)

    i = 0
    for entity in world.add_entities(count=25):
        assert_false(entity.has[Velocity]())
        assert_false(entity.has[Position]())
        assert_false(entity.has[FlexibleComponent[0]]())
        assert_false(entity.has[FlexibleComponent[1]]())
        assert_false(entity.has[FlexibleComponent[2]]())
        i += 1
    assert_equal(i, 25)


def test_world_len():
    world = SmallWorld()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    entity_count = 0
    entity_count += len(world.add_entities(pos, vel, count=12))
    assert_equal(len(world), entity_count)
    entity_count += len(
        world.add_entities(pos, vel, FlexibleComponent[0](0, 0), count=10)
    )
    assert_equal(len(world), entity_count)
    entity_count += len(
        world.add_entities(pos, vel, FlexibleComponent[1](0, 0), count=11)
    )
    assert_equal(len(world), entity_count)


def test_world_remove_entities():
    world = SmallWorld()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    entity_count = 0
    entity_count += len(world.add_entities(pos, vel, count=12))
    entity_count += len(
        world.add_entities(pos, vel, FlexibleComponent[0](0, 0), count=10)
    )
    entity_count += len(
        world.add_entities(pos, vel, FlexibleComponent[1](0, 0), count=11)
    )

    assert_equal(len(world), entity_count)

    _ = world.add_entities(pos, count=13)
    world.remove_entities(world.query[Position, Velocity]().exclusive())

    assert_equal(len(world.query[Position, Velocity]().exclusive()), 0)
    assert_equal(len(world.query[Position, Velocity]()), entity_count - 12)
    assert_equal(len(world), entity_count - 12 + 13)

    world.remove_entities(world.query[Position, Velocity]())
    assert_equal(len(world.query[Position, Velocity]()), 0)
    assert_equal(len(world.query[Position]()), 13)
    assert_equal(len(world), 13)

    entity = world.add_entity(pos, vel)
    assert_equal(entity.get_id(), entity_count)
    assert_equal(entity.get_generation(), 1)
    entity = world.add_entity(pos, vel)
    assert_equal(entity.get_id(), entity_count - 1)
    assert_equal(entity.get_generation(), 1)


def test_entity_get():
    world = SmallWorld()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    entity = world.add_entity(pos, vel)
    assert_equal(world.get[Position](entity).x, pos.x)
    world.get[Position](entity).x = 123
    assert_equal(world.get[Position](entity).x, 123)


def test_entity_get_ptr():
    world = SmallWorld()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    entity = world.add_entity(pos, vel)
    assert_equal(world.get[Position](entity).x, pos.x)
    entity_pos = world.get_ptr[Position](entity)
    entity_pos[].x = 123
    assert_equal(world.get[Position](entity).x, 123)


def test_get_archetype_index():
    world = SmallWorld()
    pos = Position(12, 654)
    vel = Velocity(0.1, 0.2)
    _ = world.add_entity(pos)
    _ = world.add_entity(vel)
    _ = world.add_entity(pos, vel)

    fn get_index[T: ComponentType](mut world: World) raises -> Int:
        return world._get_archetype_index(
            world.component_manager.get_id_arr[T]()
        )

    fn get_index[
        T1: ComponentType, T2: ComponentType
    ](mut world: World, start: Int = 0) raises -> Int:
        return world._get_archetype_index(
            world.component_manager.get_id_arr[T1, T2](),
            start_node_index=start,
        )

    assert_equal(get_index[Position](world), 1)
    assert_equal(get_index[Velocity](world), 2)
    assert_equal(get_index[Velocity, Position](world), 3)
    assert_equal(get_index[Position, Velocity](world), 3)
    assert_equal(get_index[Velocity, Position](world, 1), 2)
    assert_equal(get_index[Velocity, Position](world, 2), 1)


def test_set_component():
    world = SmallWorld()
    pos = Position(3.0, 4.0)
    entity = world.add_entity(pos)
    pos = Position(2.0, 7.0)
    world.set(entity, pos)
    assert_equal(world.get[Position](entity).x, pos.x)
    assert_equal(world.get[Position](entity).y, pos.y)

    vel = Velocity(0.3, 0.4)
    entity = world.add_entity(pos, vel)
    pos = Position(12, 654)
    vel = Velocity(0.1, 0.2)
    world.set(entity, vel, pos)
    assert_equal(world.get[Position](entity).x, pos.x)
    assert_equal(world.get[Position](entity).y, pos.y)
    assert_equal(world.get[Velocity](entity).dx, vel.dx)
    assert_equal(world.get[Velocity](entity).dy, vel.dy)


def test_remove_entity():
    world = SmallWorld()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    entity = world.add_entity(pos, vel)
    world.remove_entity(entity)

    with assert_raises():
        _ = world.get[Position](entity)
    with assert_raises():
        _ = world.get[Velocity](entity)
    assert_equal(len(world._archetypes[1]._entities), 0)
    assert_equal(len(world._entity_pool), 0)


def test_remove_archetype():
    world = SmallWorld()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    entity1 = world.add_entity(pos, vel)
    entity2 = world.add_entity(pos, vel)
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
    world = SmallWorld()
    pos = Position(1.0, 2.0)
    entity = world.add_entity(pos)
    assert_true(world.has[Position](entity))
    assert_false(world.has[Velocity](entity))


def test_world_add():
    world = SmallWorld()
    pos = Position(1.0, 2.0)
    entity = world.add_entity(pos)
    assert_true(world.has[Position](entity))
    assert_false(world.has[Velocity](entity))
    world.add(entity, Velocity(0.1, 0.2))
    assert_true(world.has[Velocity](entity))
    assert_equal(world.get[Velocity](entity).dx, 0.1)
    assert_equal(world.get[Velocity](entity).dy, 0.2)

    with assert_raises():
        world.add(entity, Velocity(0.3, 0.4))


def test_world_remove():
    world = SmallWorld()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    entity = world.add_entity(pos, vel)
    assert_true(world.has[Position](entity))
    assert_true(world.has[Velocity](entity))
    world.remove[Position](entity)
    assert_false(world.has[Position](entity))
    with assert_raises():
        _ = world.get[Position](entity)

    assert_equal(len(world._archetypes), 3)

    with assert_raises():
        world.remove[Position](entity)

    entity = world.add_entity(pos, vel)
    assert_equal(len(world._archetypes), 3)
    world.remove[Position, Velocity](entity)
    assert_equal(len(world._archetypes), 3)
    assert_equal(len(world._archetypes[0]._entities), 1)

    # Test swapping
    entity1 = world.add_entity(pos, vel)
    entity2 = world.add_entity(pos, vel)
    index1 = world._entities[entity1._id].index
    index2 = world._entities[entity2._id].index
    assert_not_equal(index1, index2)
    world.remove[Position](entity1)
    assert_equal(index1, world._entities[entity2._id].index)


def test_remove_and_add():
    world = SmallWorld()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    entity = world.add_entity(pos)
    assert_true(world.has[Position](entity))
    assert_false(world.has[Velocity](entity))

    _ = world.replace[Velocity]()
    assert_true(world.has[Position](entity))
    assert_false(world.has[Velocity](entity))

    world.replace[Position]().by(entity, vel)
    assert_false(world.has[Position](entity))
    assert_true(world.has[Velocity](entity))

    with assert_raises():
        world.replace[Position]().by(entity, vel)

    assert_equal(world.get[Velocity](entity).dx, vel.dx)
    assert_equal(world.get[Velocity](entity).dy, vel.dy)


@value
struct Resource1:
    var value: Int


@value
struct Resource2:
    var value: Int


def test_world_reseource_access():
    resources = Resources(Resource1(2), Resource2(4))
    world = World[Position, Velocity](resources)
    assert_equal(world.resources.get[Resource1]().value, 2)
    assert_equal(world.resources.get[Resource2]().value, 4)
    assert_equal(world.resources.has[Resource1](), True)

    world.resources.set[Resource1](Resource1(10))
    assert_equal(world.resources.get[Resource1]().value, 10)

    world.resources.remove[Resource1]()
    assert_equal(world.resources.has[Resource1](), False)

    world.resources.add[Resource1](Resource1(30))
    assert_equal(world.resources.get[Resource1]().value, 30)


def test_world_apply():
    world = SmallWorld()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    new_pos = pos.copy()
    new_pos.x += vel.dx
    new_pos.y += vel.dy

    for _ in range(100):
        _ = world.add_entity(pos, vel)

    fn operation(accessor: MutableEntityAccessor) capturing:
        try:
            pos2 = accessor.get_ptr[Position]()
            vel2 = accessor.get_ptr[Velocity]()
            pos2[].x += vel2[].dx
            pos2[].y += vel2[].dy
        except:
            pass

    world.apply[operation, Position, Velocity, unroll_factor=3]()

    for entity in world.query[Position, Velocity]():
        assert_equal(entity.get[Position]().x, new_pos.x)
        assert_equal(entity.get[Position]().y, new_pos.y)


def test_world_lock():
    world = SmallWorld()
    _ = world.add_entity(Position(1.0, 2.0))
    assert_false(world.is_locked())

    try:
        with world._locked():
            assert_true(world.is_locked())
            raise Error("Test")
    except Error:
        pass

    assert_false(world.is_locked())


def test_world_apply_SIMD():
    world = SmallWorld()
    pos = Position(0.0, 2.0)
    vel = Velocity(0.1, 0.2)

    comparison = List[Position](capacity=100)

    for _ in range(100):
        pos.x += 1
        _ = world.add_entity(pos, vel)
        new_pos = pos.copy()
        new_pos.x += vel.dx
        new_pos.y += vel.dy
        comparison.append(new_pos)

    fn operation[simd_width: Int](accessor: MutableEntityAccessor) capturing:
        try:
            pos2 = accessor.get_ptr[Position]()
            vel2 = accessor.get_ptr[Velocity]()

            alias _load = load2[simd_width]
            alias _store = store2[simd_width]

            x = _load(pos2[].x)
            y = _load(pos2[].y)

            x += _load(vel2[].dx)
            y += _load(vel2[].dy)

            _store(pos2[].x, x)
            _store(pos2[].y, y)
        except:
            pass

    world.apply[operation, Position, Velocity, simd_width=4, unroll_factor=3]()

    i = 0
    for entity in world.query[Position, Velocity]():
        new_pos = comparison[i]
        assert_equal(entity.get[Position]().x, new_pos.x)
        assert_equal(entity.get[Position]().y, new_pos.y)
        i += 1


def main():
    print("Running tests...")
    test_add_entity()
    test_add_entities()
    test_world_len()
    test_world_remove_entities()
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
    test_world_reseource_access()
    test_world_apply()
    test_world_apply_SIMD()
    test_world_lock()
    print("All tests passed.")
