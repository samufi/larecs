from testing import *
from larecs.test_utils import *
from larecs.entity import Entity


def test_query_length():
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
    size = len(iterator)
    while iterator.__has_next__():
        _ = iterator.__next__()
        size -= 1
        assert_equal(size, len(iterator))


def test_query_result_ids():
    world = SmallWorld()

    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 50

    entities = List[Entity]()

    for i in range(n):
        entities.append(world.add_entity(FlexibleComponent[0](1.0, i), c1, c2))
    for i in range(n, 2 * n):
        entities.append(world.add_entity(FlexibleComponent[0](1.0, i), c2))

    i = 0
    for entity in world.query[FlexibleComponent[0]]():
        assert_equal(
            entity.get[FlexibleComponent[0]]().y,
            world.get[FlexibleComponent[0]](entities[i]).y,
            "Entity " + String(i) + " is incorrect.",
        )
        i += 1


def test_query_get_set():
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
        entity.get[FlexibleComponent[0]]().y = i
        i += 1

    i = 0
    for entity in world.query[FlexibleComponent[0]]():
        assert_equal(entity.get[FlexibleComponent[0]]().y, i)
        assert_equal(world.get[FlexibleComponent[0]](entities[i]).y, i)
        i += 1


def test_query_component_reference():
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
        a = entity.get_ptr[FlexibleComponent[0]]()
        a[].y = i
        i += 1

    i = 0
    for entity in world.query[FlexibleComponent[0]]():
        assert_equal(entity.get[FlexibleComponent[0]]().y, i)
        assert_equal(world.get[FlexibleComponent[0]](entities[i]).y, i)
        i += 1


def test_query_has_component():
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


def test_query_without():
    world = SmallWorld()
    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 10

    for _ in range(n):
        _ = world.add_entity(c0)
        _ = world.add_entity(c0, c1)
        _ = world.add_entity(c0, c1, c2)
        _ = world.add_entity(c0, c2)
        _ = world.add_entity(c2)

    cnt = 0
    for entity in world.query[FlexibleComponent[0]]().without[
        FlexibleComponent[1]
    ]():
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_false(entity.has[FlexibleComponent[1]]())
        cnt += 1

    assert_equal(cnt, 2 * n)


def test_query_lock():
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


def run_all_query_tests():
    test_query_lock()
    test_query_component_reference()
    test_query_result_ids()
    test_query_length()
    test_query_get_set()
    test_query_has_component()


def main():
    print("Running tests...")
    run_all_query_tests()
    print("All tests passed.")
