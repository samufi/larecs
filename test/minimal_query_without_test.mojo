from testing import *
from larecs.test_utils import *
import compile


def query_exclusive():
    world = SmallWorld()
    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)

    n = 10

    _ = world.add_entities(c0, count=n)
    _ = world.add_entities(c0, c1, count=n)

    query = world.query[FlexibleComponent[0]]().without[FlexibleComponent[3]]()

    count = 0
    for entity in query:
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_true(world.is_locked())
        count += 1


def query_without():
    world = SmallWorld()
    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 10

    _ = world.add_entities(c0, count=n)
    _ = world.add_entities(c0, c1, count=n)
    _ = world.add_entities(c0, c1, c2, count=n)
    _ = world.add_entities(c2, count=n)

    print("test_query_without")

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


def both():
    query_exclusive()
    query_without()


def test_print_asm():
    print(compile.compile_info[both, emission_kind="llvm-opt"]())

    both()


def main():
    test_print_asm()
