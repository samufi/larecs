from testing import *
from larecs.test_utils import *


def test_query_exclusive():
    world = SmallWorld()
    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)

    n = 10

    for _ in range(n):
        _ = world.add_entity(c0)
        _ = world.add_entity(c0, c1)

    query = world.query[FlexibleComponent[0]]().exclusive()

    count = 0
    for entity in query:
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_false(entity.has[FlexibleComponent[1]]())
        assert_true(world.is_locked())
        count += 1


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
        _ = world.add_entity(c2)

    query = world.query[FlexibleComponent[0]]().without[FlexibleComponent[1]]()

    count = 0
    for _ in query:
        count += 1
    assert_equal(count, n)

    for _ in range(n):
        _ = world.add_entity(c0, c2)

    count = 0
    for _ in query:
        count += 1
    assert_equal(count, 2 * n)


def main():
    test_query_exclusive()
    test_query_without()
