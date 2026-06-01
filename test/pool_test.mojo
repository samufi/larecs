from std.testing import *
from std.random import random_float64


from std.collections import Dict
from larecs.pool import EntityPool, BitPool, IntPool
from larecs.entity import Entity


def test_entity_pool_constructor() raises:
    _ = EntityPool()


def test_entity_pool() raises:
    p = EntityPool()

    expected_all: List[Entity] = [
        Entity(0),
        Entity(1),
        Entity(2),
        Entity(3),
        Entity(4),
        Entity(5),
    ]
    expected_all[0]._generation = UInt32(UInt16.MAX)

    for _ in range(5):
        _ = p.get()

    assert_equal(expected_all, p._entities, "Wrong initial entities")

    with assert_raises():
        p.recycle(p._entities[0])

    e0 = p._entities[1]
    p.recycle(e0)
    assert_false(p.is_alive(e0), "Dead entity should not be alive")

    e0_old = e0
    e0 = p.get()
    expected_all[1]._generation += 1
    assert_true(
        p.is_alive(e0), "Recycled entity of new generation should be alive"
    )
    assert_false(
        p.is_alive(e0_old),
        "Recycled entity of old generation should not be alive",
    )

    assert_equal(expected_all, p._entities, "Wrong _entities after get/recycle")

    e0_old = p._entities[1]
    for i in range(5):
        p.recycle(p._entities[i + 1])
        expected_all[i + 1]._generation += 1

    assert_false(
        p.is_alive(e0_old),
        "Recycled entity of old generation should not be alive",
    )

    for _ in range(5):
        _ = p.get()

    assert_false(
        p.is_alive(e0_old),
        "Recycled entity of old generation should not be alive",
    )
    assert_false(p.is_alive(Entity()), "Zero entity should not be alive")


def test_entity_pool_stochastic() raises:
    p = EntityPool()

    for _ in range(10):
        p.reset()
        assert_equal(0, len(p))
        assert_equal(0, p.available())

        alive = Dict[Entity, Bool]()
        for _ in range(10):
            e = p.get()
            alive[e] = True

        for item in alive.items():
            e, isAlive = item.key, item.value
            assert_equal(
                isAlive,
                p.is_alive(e),
                "Wrong alive state of entity "
                + String(e)
                + " after initialization",
            )
            if random_float64() > 0.75:
                continue

            p.recycle(e)
            alive[e] = False

        for item in alive.items():
            e, isAlive = item.key, item.value
            assert_equal(
                isAlive,
                p.is_alive(e),
                "Wrong alive state of entity "
                + String(e)
                + " after 1st removal. Entity is "
                + String(p._entities[e.get_id()]),
            )

        for _ in range(10):
            e = p.get()
            alive[e] = True

        for item in alive.items():
            e, isAlive = item.key, item.value
            assert_equal(
                isAlive,
                p.is_alive(e),
                "Wrong alive state of entity "
                + String(e)
                + " after 1st recycling. Entity is "
                + String(p._entities[e.get_id()]),
            )

        assert_equal(0, p._available, "No more _entities should be available")

        for item in alive.items():
            e, isAlive = item.key, item.value
            if not isAlive or random_float64() > 0.75:
                continue

            p.recycle(e)
            alive[e] = False

        for item in alive.items():
            e, a = item.key, item.value
            assert_equal(
                a,
                p.is_alive(e),
                "Wrong alive state of entity "
                + String(e)
                + " after 2nd removal. Entity is "
                + String(p._entities[e.get_id()]),
            )


def test_bit_pool_constructor() raises:
    p = BitPool()

    assert_equal(p.capacity, 256)
    assert_equal(p._length, 0)
    assert_equal(p._available, 0)


def test_bit_pool_fresh_allocation() raises:
    p = BitPool()

    for i in range(p.capacity):
        assert_equal(i, p.get())


def test_bit_pool_exhaustion() raises:
    p = BitPool()

    for _ in range(p.capacity):
        _ = p.get()

    with assert_raises():
        _ = p.get()


def test_bit_pool_recycle_lifo() raises:
    p = BitPool()

    for _ in range(10):
        _ = p.get()

    for i in range(10):
        p.recycle(i)

    for i in range(9, -1, -1):
        assert_equal(i, p.get())


def test_bit_pool_recycle_full_capacity() raises:
    p = BitPool()

    for i in range(p.capacity):
        assert_equal(i, p.get())

    for i in range(p.capacity):
        p.recycle(i)

    for i in range(p.capacity - 1, -1, -1):
        assert_equal(i, p.get())

    with assert_raises():
        _ = p.get()


def test_bit_pool_reset() raises:
    p = BitPool()

    for i in range(32):
        assert_equal(i, p.get())

    for i in range(10):
        p.recycle(i)

    p.reset()

    assert_equal(p._length, 0)
    assert_equal(p._available, 0)

    for i in range(p.capacity):
        assert_equal(i, p.get())

    with assert_raises():
        _ = p.get()


def test_bit_pool_recycle_after_reset() raises:
    p = BitPool()

    for _ in range(p.capacity):
        _ = p.get()

    p.reset()

    for i in range(10):
        assert_equal(i, p.get())

    for i in range(10):
        p.recycle(i)

    for i in range(9, -1, -1):
        assert_equal(i, p.get())


def test_int_pool() raises:
    p = IntPool()

    for i in range(32):
        assert_equal(i, p.get())

    assert_equal(32, len(p._pool))

    p.recycle(3)
    p.recycle(4)
    assert_equal(4, p.get())
    assert_equal(3, p.get())

    p.reset()


comptime functions = __functions_in_module()


def main() raises:
    TestSuite.discover_tests[functions]().run()
