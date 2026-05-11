from std.testing import *

from larecs.test_utils import *
from larecs import Entity, Query
from larecs.archetype import Archetype as _Archetype
from larecs.query import QueryError, _ArchetypeByMaskIterator


def test_query_length() raises:
    world = SmallWorld()

    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)
    c3 = FlexibleComponent[3](7.0, 8.0)

    n = 50

    for _ in range(n):
        _ = world.add_entity(c0, c1, c2)
        _ = world.add_entity(c0, c1, c3)
        _ = world.add_entity(c0, c2, c3)
        _ = world.add_entity(c1, c2, c3)
        _ = world.add_entity(c0, c1, c2, c3)

    assert_equal(len(world.query[FlexibleComponent[0]]()), 4 * n)
    assert_equal(len(world.query[FlexibleComponent[1]]()), 4 * n)
    assert_equal(len(world.query[FlexibleComponent[2]]()), 4 * n)
    assert_equal(len(world.query[FlexibleComponent[3]]()), 4 * n)

    assert_equal(
        len(world.query[FlexibleComponent[0], FlexibleComponent[1]]()),
        3 * n,
    )
    assert_equal(
        len(world.query[FlexibleComponent[0], FlexibleComponent[2]]()),
        3 * n,
    )
    assert_equal(
        len(world.query[FlexibleComponent[0], FlexibleComponent[3]]()),
        3 * n,
    )
    assert_equal(
        len(world.query[FlexibleComponent[1], FlexibleComponent[2]]()),
        3 * n,
    )
    assert_equal(
        len(world.query[FlexibleComponent[1], FlexibleComponent[3]]()),
        3 * n,
    )
    assert_equal(
        len(world.query[FlexibleComponent[2], FlexibleComponent[3]]()),
        3 * n,
    )

    assert_equal(
        len(
            world.query[
                FlexibleComponent[0], FlexibleComponent[1], FlexibleComponent[2]
            ]()
        ),
        2 * n,
    )
    assert_equal(
        len(
            world.query[
                FlexibleComponent[0], FlexibleComponent[1], FlexibleComponent[3]
            ]()
        ),
        2 * n,
    )
    assert_equal(
        len(
            world.query[
                FlexibleComponent[0], FlexibleComponent[2], FlexibleComponent[3]
            ]()
        ),
        2 * n,
    )
    assert_equal(
        len(
            world.query[
                FlexibleComponent[1], FlexibleComponent[2], FlexibleComponent[3]
            ]()
        ),
        2 * n,
    )

    assert_equal(
        len(
            world.query[
                FlexibleComponent[0],
                FlexibleComponent[1],
                FlexibleComponent[2],
                FlexibleComponent[3],
            ]()
        ),
        n,
    )
    assert_equal(len(world.query()), 5 * n)

    iterator = world.query[FlexibleComponent[0]]()
    iter = iterator.__iter__()
    size = len(iter)
    while iter.__has_next__():
        _ = iter.__next__()
        size -= 1
        assert_equal(size, len(iter))


def test_query_result_ids() raises:
    world = SmallWorld()

    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 50

    entities = List[Entity]()

    for i in range(n):
        entities.append(
            world.add_entity(FlexibleComponent[0](1.0, Float32(i)), c1, c2)
        )
    for i in range(n, 2 * n):
        entities.append(
            world.add_entity(FlexibleComponent[0](1.0, Float32(i)), c2)
        )

    i = 0
    for var entity in world.query[FlexibleComponent[0]]():
        assert_equal(
            entity.get_entity(),
            entities[i],
            "Entity " + String(i) + " is incorrect.",
        )
        entity.set(FlexibleComponent[0](1.0, Float32(i)))
        i += 1

    for i in range(2 * n):
        assert_equal(world.get[FlexibleComponent[0]](entities[i]).y, Float32(i))

def test_query_get_set() raises:
    world = SmallWorld()

    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 50

    entities = List[Entity]()

    for _ in range(n):
        entities.append(world.add_entity(c0, c1, c2))

    i = 0
    for entity in world.query[FlexibleComponent[0]]():
        entity.get[FlexibleComponent[0]]().y = Float32(i)
        i += 1

    i = 0
    for entity in world.query[FlexibleComponent[0]]():
        assert_equal(entity.get[FlexibleComponent[0]]().y, Float32(i))
        assert_equal(world.get[FlexibleComponent[0]](entities[i]).y, Float32(i))
        i += 1


def test_query_component_reference() raises:
    world = SmallWorld()

    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 50

    entities = List[Entity]()

    for _ in range(n):
        entities.append(world.add_entity(c0, c1, c2))

    i = 0
    for entity in world.query[FlexibleComponent[0]]():
        ref a = entity.get[FlexibleComponent[0]]()
        a.y = Float32(i)
        i += 1

    i = 0
    for entity in world.query[FlexibleComponent[0]]():
        assert_equal(entity.get[FlexibleComponent[0]]().y, Float32(i))
        assert_equal(world.get[FlexibleComponent[0]](entities[i]).y, Float32(i))
        i += 1


def test_query_has_component() raises:
    world = SmallWorld()

    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 50

    entities = List[Entity]()

    for _ in range(n):
        entities.append(world.add_entity(c0, c1, c2))

    for entity in world.query[FlexibleComponent[0]]():
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_true(entity.has[FlexibleComponent[1]]())
        assert_true(entity.has[FlexibleComponent[2]]())
        assert_false(entity.has[FlexibleComponent[3]]())


def test_query_empty() raises:
    world = SmallWorld()
    query = world.query[FlexibleComponent[0]]()
    cnt = 0
    for entity in query:
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_true(world.is_locked())
        cnt += 1
    assert_equal(cnt, 0)


def test_query_without() raises:
    world = SmallWorld()
    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 10

    for _ in range(n):
        _ = world.add_entity(c0)
        _ = world.add_entity(c0, c1)
        _ = world.add_entity(c0, c1, c2)
        _ = world.add_entity(c2)

    query = world.query[FlexibleComponent[0]]().without[FlexibleComponent[1]]()
    query2 = world.query[FlexibleComponent[0]]()

    assert_equal(len(query), n)

    count = 0
    for entity in query:
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_false(entity.has[FlexibleComponent[1]]())
        assert_true(world.is_locked())
        count += 1
    assert_equal(count, n)
    assert_false(world.is_locked())

    for entity in query2:
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_true(world.is_locked())

    for _ in range(n):
        _ = world.add_entity(c0, c2)

    count = 0
    for entity in query:
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_false(entity.has[FlexibleComponent[1]]())
        assert_true(world.is_locked())
        count += 1
    assert_equal(count, 2 * n)

    assert_false(world.is_locked())


def test_query_exclusive() raises:
    world = SmallWorld()
    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)

    n = 10

    for _ in range(n):
        _ = world.add_entity(c0)
        _ = world.add_entity(c0, c1)

    query = world.query[FlexibleComponent[0]]().exclusive()
    assert_equal(len(query), n)

    count = 0
    for entity in query:
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_false(entity.has[FlexibleComponent[1]]())
        assert_true(world.is_locked())
        count += 1

    assert_equal(count, n)
    assert_false(world.is_locked())


def test_query_lock() raises:
    world = SmallWorld()

    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    _ = world.add_entity(c0, c1)
    entity = world.add_entity(c0, c1)

    first = True
    for _ in world.query[FlexibleComponent[0]]():
        if not first:
            break
        assert_true(world.is_locked())
        with assert_raises():
            _ = world.add_entity(c0, c1, c2)
        with assert_raises():
            _ = world.add(entity, c2)
        with assert_raises():
            _ = world.remove[FlexibleComponent[0]](entity)

        for _ in world.query[FlexibleComponent[0]]():
            if not first:
                break
            assert_true(world.is_locked())
            with assert_raises():
                _ = world.add_entity(c0, c1, c2)
            with assert_raises():
                _ = world.add(entity, c2)
            with assert_raises():
                _ = world.remove[FlexibleComponent[0]](entity)

    assert_false(world.is_locked())
    _ = world.add_entity(c0, c1, c2)
    _ = world.add(entity, c2)
    _ = world.remove[FlexibleComponent[1]](entity)

    try:
        for _ in world.query[FlexibleComponent[0]]():
            _ = world.add_entity(c0, c1, c2)
    except:
        assert_false(world.is_locked())
        _ = world.add_entity(c0, c1, c2)


def test_query_requires_available_lock() raises:
    world = SmallWorld()

    c0 = FlexibleComponent[0](1.0, 2.0)
    _ = world.add_entity(c0)

    locks = List[Int]()
    for _ in range(world._locks.bit_pool.capacity):
        locks.append(world._lock())

    with assert_raises(contains=QueryError.could_not_create_iterator.msg()):
        for _ in world.query[FlexibleComponent[0]]():
            pass

    for i in range(len(locks)):
        world._unlock(locks[i])

    assert_false(world.is_locked())

    count = 0
    for _ in world.query[FlexibleComponent[0]]():
        count += 1

    assert_equal(count, 1)


def test_query_archetype_iterator() raises:
    comptime Archetype = _Archetype[FlexibleComponent[0]]

    a1 = Archetype(0, BitMask(0))
    a2 = Archetype(0, BitMask(0))
    a3 = Archetype(2, BitMask(0, 1))
    _ = a1.add(Entity(0, 0))
    _ = a2.add(Entity(0, 0))
    _ = a3.add(Entity(0, 0))
    archetypes: List[Archetype] = [a1^, a2^, a3^]
    var count = 0

    for _ in _ArchetypeByMaskIterator(Pointer(to=archetypes), BitMask()):
        count += 1

    assert_equal(count, 3)


comptime functions = __functions_in_module()


def main() raises:
    TestSuite.discover_tests[functions]().run()
