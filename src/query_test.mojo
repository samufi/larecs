from testing import *
from test_utils import *
from entity import Entity


def test_query_length():
    world = FullWorld()

    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)
    c3 = FlexibleComponent[3](7.0, 8.0)

    n = 50

    for _ in range(n):
        _ = world.new_entity(c0, c1, c2)
        _ = world.new_entity(c0, c1, c3)
        _ = world.new_entity(c0, c2, c3)
        _ = world.new_entity(c1, c2, c3)
        _ = world.new_entity(c0, c1, c2, c3)

    assert_equal(len(world.get_entities[FlexibleComponent[0]]()), 4 * n)
    assert_equal(len(world.get_entities[FlexibleComponent[1]]()), 4 * n)
    assert_equal(len(world.get_entities[FlexibleComponent[2]]()), 4 * n)
    assert_equal(len(world.get_entities[FlexibleComponent[3]]()), 4 * n)

    assert_equal(
        len(world.get_entities[FlexibleComponent[0], FlexibleComponent[1]]()),
        3 * n,
    )
    assert_equal(
        len(world.get_entities[FlexibleComponent[0], FlexibleComponent[2]]()),
        3 * n,
    )
    assert_equal(
        len(world.get_entities[FlexibleComponent[0], FlexibleComponent[3]]()),
        3 * n,
    )
    assert_equal(
        len(world.get_entities[FlexibleComponent[1], FlexibleComponent[2]]()),
        3 * n,
    )
    assert_equal(
        len(world.get_entities[FlexibleComponent[1], FlexibleComponent[3]]()),
        3 * n,
    )
    assert_equal(
        len(world.get_entities[FlexibleComponent[2], FlexibleComponent[3]]()),
        3 * n,
    )

    assert_equal(
        len(
            world.get_entities[
                FlexibleComponent[0], FlexibleComponent[1], FlexibleComponent[2]
            ]()
        ),
        2 * n,
    )
    assert_equal(
        len(
            world.get_entities[
                FlexibleComponent[0], FlexibleComponent[1], FlexibleComponent[3]
            ]()
        ),
        2 * n,
    )
    assert_equal(
        len(
            world.get_entities[
                FlexibleComponent[0], FlexibleComponent[2], FlexibleComponent[3]
            ]()
        ),
        2 * n,
    )
    assert_equal(
        len(
            world.get_entities[
                FlexibleComponent[1], FlexibleComponent[2], FlexibleComponent[3]
            ]()
        ),
        2 * n,
    )

    assert_equal(
        len(
            world.get_entities[
                FlexibleComponent[0],
                FlexibleComponent[1],
                FlexibleComponent[2],
                FlexibleComponent[3],
            ]()
        ),
        n,
    )
    assert_equal(len(world.get_entities()), 5 * n)


def test_query_result_ids():
    world = FullWorld()

    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 50

    entities = List[Entity]()

    for i in range(n):
        entities.append(world.new_entity(FlexibleComponent[0](1.0, i), c1, c2))
    for i in range(n, 2 * n):
        entities.append(world.new_entity(FlexibleComponent[0](1.0, i), c2))

    i = 0
    for entity in world.get_entities[FlexibleComponent[0]]():
        assert_equal(
            entity.get[FlexibleComponent[0]]().y,
            world.get[FlexibleComponent[0]](entities[i]).y,
            "Entity " + str(i) + " is incorrect.",
        )
        i += 1


def test_query_get_set():
    world = FullWorld()

    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 50

    entities = List[Entity]()

    for _ in range(n):
        entities.append(world.new_entity(c0, c1, c2))

    i = 0
    for entity in world.get_entities[FlexibleComponent[0]]():
        entity.get[FlexibleComponent[0]]().y = i
        i += 1

    i = 0
    for entity in world.get_entities[FlexibleComponent[0]]():
        assert_equal(entity.get[FlexibleComponent[0]]().y, i)
        assert_equal(world.get[FlexibleComponent[0]](entities[i]).y, i)
        i += 1


def test_query_component_reference():
    world = FullWorld()

    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 50

    entities = List[Entity]()

    for _ in range(n):
        entities.append(world.new_entity(c0, c1, c2))

    i = 0
    for entity in world.get_entities[FlexibleComponent[0]]():
        a = entity.get_ptr[FlexibleComponent[0]]()
        a[].y = i
        i += 1

    i = 0
    for entity in world.get_entities[FlexibleComponent[0]]():
        assert_equal(entity.get[FlexibleComponent[0]]().y, i)
        assert_equal(world.get[FlexibleComponent[0]](entities[i]).y, i)
        i += 1


def run_all_query_tests():
    test_query_component_reference()
    test_query_result_ids()
    test_query_length()
    test_query_get_set()


def main():
    print("Running tests...")
    run_all_query_tests()
    print("All tests passed.")
