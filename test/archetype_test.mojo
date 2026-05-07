from std.testing import *
from std.memory import memcpy
from std.sys.info import size_of

from larecs.archetype import Archetype as _Archetype
from larecs.bitmask import BitMask
from larecs.component import ComponentManager
from larecs.entity import Entity
from larecs.pool import EntityPool
from larecs.test_utils import *


comptime Archetype = _Archetype[
    FlexibleComponent[0],
    LargerComponent,
    FlexibleComponent[1],
    FlexibleComponent[2],
    FlexibleComponent[3],
    FlexibleComponent[4],
    FlexibleComponent[5],
    FlexibleComponent[6],
    FlexibleComponent[7],
    FlexibleComponent[9],
    FlexibleComponent[10],
]

comptime mask2 = BitMask(1, 2)
comptime mask3 = BitMask(1, 2, 3)


def test_archetype_init() raises:
    var archetype = Archetype(4, mask2, capacity=10)

    assert_equal(archetype._storage.capacity, 10)
    assert_equal(len(archetype), 0)
    assert_equal(archetype.get_node_index(), 4)
    assert_equal(archetype._storage.get_component_count(), 2)


def test_archetype_reserve() raises:
    var archetype = Archetype(0, mask2)

    assert_equal(len(archetype), 0)
    assert_equal(archetype._storage.get_component_count(), 2)

    archetype.reserve(50)
    assert_equal(archetype._storage.capacity, 64)
    assert_equal(len(archetype), 0)
    assert_equal(archetype._storage.get_component_count(), 2)

    archetype.reserve(5)
    assert_equal(archetype._storage.capacity, 64)
    assert_equal(len(archetype), 0)
    assert_equal(archetype._storage.get_component_count(), 2)

    archetype.reserve(70)
    assert_equal(archetype._storage.capacity, 128)
    assert_equal(len(archetype), 0)
    assert_equal(archetype._storage.get_component_count(), 2)


def test_archetype_get_entity() raises:
    var archetype = Archetype(0, mask2)

    var entity = Entity(0, 0)
    idx = archetype.add(entity)
    assert_equal(archetype.get_entity(idx), entity)


def test_archetype_remove() raises:
    var archetype = Archetype(0, mask2)

    var entity1 = Entity(0, 0)
    var entity2 = Entity(1, 0)
    _ = archetype.add(entity1)
    _ = archetype.add(entity2)

    assert_equal(len(archetype), 2)
    assert_equal(archetype._entities[0], entity1)
    assert_equal(archetype._entities[1], entity2)

    var swapped = archetype.remove(0)
    assert_true(swapped)
    assert_equal(len(archetype), 1)
    assert_equal(archetype._entities[0], entity2)

    swapped = archetype.remove(0)
    assert_false(swapped)
    assert_equal(len(archetype), 0)
    assert_equal(len(archetype._entities), 0)


def test_archetype_has_component() raises:
    var archetype = Archetype(0, mask2)

    assert_true(archetype.has_component[Archetype.ComponentTypes[1]]())
    assert_true(archetype.has_component[Archetype.ComponentTypes[2]]())
    assert_false(archetype.has_component[Archetype.ComponentTypes[3]]())


def test_archetype_move() raises:
    var archetype = Archetype(0, mask2)

    idx = archetype.add(Entity())
    archetype.set_components(
        idx,
        LargerComponent(1.0, 2.0, 3.0),
        FlexibleComponent[1](4.0, 5.0),
    )

    storage_ptr_large = (
        archetype._storage.get_component_ptr[LargerComponent]() + idx
    )
    storage_ptr_flex = (
        archetype._storage.get_component_ptr[FlexibleComponent[1]]() + idx
    )

    var archetype2 = archetype^

    assert_equal(
        storage_ptr_large,
        archetype2._storage.get_component_ptr[LargerComponent]() + idx,
    )
    assert_equal(
        storage_ptr_flex,
        archetype2._storage.get_component_ptr[FlexibleComponent[1]]() + idx,
    )
    assert_equal(archetype2.get_component[LargerComponent](idx).x, 1.0)
    assert_equal(archetype2.get_component[FlexibleComponent[1]](idx).x, 4.0)


def test_archetype_copy() raises:
    var archetype = Archetype(0, mask2)
    idx = archetype.add(Entity())
    archetype.set_components(
        idx,
        LargerComponent(1.0, 2.0, 3.0),
        FlexibleComponent[1](4.0, 5.0),
    )

    var archetype2 = archetype.copy()

    assert_not_equal(
        archetype._storage.get_component_ptr[LargerComponent]() + idx,
        archetype2._storage.get_component_ptr[LargerComponent]() + idx,
    )
    assert_not_equal(
        archetype._storage.get_component_ptr[FlexibleComponent[1]]() + idx,
        archetype2._storage.get_component_ptr[FlexibleComponent[1]]() + idx,
    )
    assert_equal(archetype2.get_component[LargerComponent](idx).x, 1.0)
    assert_equal(archetype2.get_component[FlexibleComponent[1]](idx).x, 4.0)


def test_entity_accessor_set_components() raises:
    var archetype = Archetype(0, mask2)
    entity_idx = archetype.add(Entity(10, 3))
    entity = archetype.get_entity_accessor(entity_idx)

    entity.set(
        LargerComponent(1.0, 2.0, 3.0),
        FlexibleComponent[1](4.0, 5.0),
    )

    assert_equal(entity.get[LargerComponent]().x, 1.0)
    assert_equal(entity.get[LargerComponent]().y, 2.0)
    assert_equal(entity.get[FlexibleComponent[1]]().x, 4.0)
    assert_equal(entity.get[FlexibleComponent[1]]().y, 5.0)


def test_archetype_add() raises:
    var archetype = Archetype(0, mask2)

    var entity = Entity(10, 3)
    var index = archetype.add(entity)

    assert_equal(index, 0)
    assert_equal(len(archetype), 1)
    assert_equal(archetype.get_entity(0), entity)


def test_archetype_extend() raises:
    var archetype = Archetype(0, mask2)
    var entity_pool = EntityPool()

    var start_index = archetype.extend(5, entity_pool)

    assert_equal(start_index, 0)
    assert_equal(len(archetype), 5)

    start_index = archetype.extend(5, entity_pool)

    assert_equal(start_index, 5)
    assert_equal(len(archetype), 10)
    for i in range(10):
        assert_equal(archetype.get_entity(i)._id, i + 1)


def test_archetype_get_mask() raises:
    var archetype = Archetype(0, mask3)

    var entity = Entity(10, 3)
    _ = archetype.add(entity)

    var mask = archetype.get_mask()
    assert_equal(mask, BitMask(1, 2, 3))

    var mask2 = BitMask(1, 2, 3)
    assert_equal(mask, mask2)

    mask2 = BitMask(1, 2, 4)
    assert_not_equal(mask, mask2)

    mask2 = BitMask(1, 2)
    assert_not_equal(mask, mask2)


comptime functions = __functions_in_module()


def main() raises:
    TestSuite.discover_tests[functions]().run()
