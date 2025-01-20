from testing import *
from random import random_float64


from collections import Dict
from larecs.pool import EntityPool, BitPool, IntPool
from larecs.entity import Entity
from larecs.constants import MAX_UINT16, MASK_TOTAL_BITS
from larecs.test_utils import assert_equal_lists


def test_entity_pool_constructor():
    _ = EntityPool()


def test_entity_pool():
    p = EntityPool()

    expected_all = List[Entity](
        Entity(0), Entity(1), Entity(2), Entity(3), Entity(4), Entity(5)
    )
    expected_all[0]._gen = MAX_UINT16

    for _ in range(5):
        _ = p.get()

    assert_equal_lists(expected_all, p._entities, "Wrong initial entities")

    with assert_raises():
        p.recycle(p._entities[0])

    e0 = p._entities[1]
    p.recycle(e0)
    assert_false(p.is_alive(e0), "Dead entity should not be alive")

    e0_old = e0
    e0 = p.get()
    expected_all[1]._gen += 1
    assert_true(
        p.is_alive(e0), "Recycled entity of new generation should be alive"
    )
    assert_false(
        p.is_alive(e0_old),
        "Recycled entity of old generation should not be alive",
    )

    assert_equal_lists(
        expected_all, p._entities, "Wrong _entities after get/recycle"
    )

    e0_old = p._entities[1]
    for i in range(5):
        p.recycle(p._entities[i + 1])
        expected_all[i + 1]._gen += 1

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


def test_entity_pool_stochastic():
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
            e, isAlive = item[].key, item[].value
            assert_equal(
                isAlive,
                p.is_alive(e),
                "Wrong alive state of entity "
                + str(e)
                + " after initialization",
            )
            if random_float64() > 0.75:
                continue

            p.recycle(e)
            alive[e] = False

        for item in alive.items():
            e, isAlive = item[].key, item[].value
            assert_equal(
                isAlive,
                p.is_alive(e),
                "Wrong alive state of entity "
                + str(e)
                + " after 1st removal. Entity is "
                + str(p._entities[e.get_id()]),
            )

        for _ in range(10):
            e = p.get()
            alive[e] = True

        for item in alive.items():
            e, isAlive = item[].key, item[].value
            assert_equal(
                isAlive,
                p.is_alive(e),
                "Wrong alive state of entity "
                + str(e)
                + " after 1st recycling. Entity is "
                + str(p._entities[e.get_id()]),
            )

        assert_equal(0, p._available, "No more _entities should be available")

        for item in alive.items():
            e, isAlive = item[].key, item[].value
            if not isAlive or random_float64() > 0.75:
                continue

            p.recycle(e)
            alive[e] = False

        for item in alive.items():
            e, a = item[].key, item[].value
            assert_equal(
                a,
                p.is_alive(e),
                "Wrong alive state of entity "
                + str(e)
                + " after 2nd removal. Entity is "
                + str(p._entities[e.get_id()]),
            )


def test_bit_pool():
    p = BitPool()

    assert_equal(p.capacity, 256)

    for i in range(p.capacity):
        assert_equal(i, Int(p.get()))

    with assert_raises():
        _ = p.get()

    for i in range(10):
        p.recycle(i)

    for i in range(9, -1, -1):
        assert_equal(i, Int(p.get()))

    with assert_raises():
        _ = p.get()

    p.reset()

    for i in range(p.capacity):
        assert_equal(i, Int(p.get()))

    with assert_raises():
        _ = p.get()

    for i in range(10):
        p.recycle(i)

    for i in range(9, -1, -1):
        assert_equal(i, Int(p.get()))


def test_int_pool():
    p = IntPool()

    for i in range(32):
        assert_equal(i, p.get())

    assert_equal(32, len(p._pool))

    p.recycle(3)
    p.recycle(4)
    assert_equal(4, p.get())
    assert_equal(3, p.get())

    p.reset()


def main():
    test_entity_pool_constructor()
    test_entity_pool()
    test_entity_pool_stochastic()
    test_bit_pool()
    test_int_pool()

    print("All tests passed")
