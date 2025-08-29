from larecs.query import Query
from larecs.world import World

from testing import *
import compile


@fieldwise_init
struct Foo(Copyable, Movable):
    var val: UInt8


@fieldwise_init
struct Bar(Copyable, Movable):
    var val: UInt8


@fieldwise_init
struct Zork(Copyable, Movable):
    var val: UInt8


fn n() -> UInt:
    return 10


def without_bar():
    world = World[Foo, Bar, Zork]()
    _ = world.add_entities(Foo(0), count=n())
    _ = world.add_entities(Foo(0), Bar(0), count=n())

    query = world.query[Foo]().without[Bar]()
    count = 0
    for _ in query:
        count += 1
    assert_equal(count, n())


def without_zork():
    world = World[Foo, Bar, Zork]()
    _ = world.add_entities(Foo(0), count=n())
    _ = world.add_entities(Foo(0), Zork(0), count=n())
    _ = world.add_entities(Foo(0), Bar(0), Zork(0), count=n())

    query = world.query[Foo]().without[Zork]()
    count = 0
    for _ in query:
        count += 1
    assert_equal(count, n())

    for _ in range(n()):
        _ = world.add_entity(Foo(0), Bar(0))

    count = 0
    for _ in query:
        count += 1
    assert_equal(count, 2 * n())


def execute():
    print("Run without_bar()...")
    without_bar()
    print("Run without_zork()...")
    without_zork()


def test_execute():
    print(compile.compile_info[execute, emission_kind="llvm-opt"]())
    execute()


def main():
    test_execute()
