from memory import UnsafePointer
from collections import InlineArray
from testing import *

from larecs.archetype import Archetype
from larecs.bitmask import BitMask
from larecs.component import ComponentReference, ComponentManager
from larecs.entity import Entity
from larecs.pool import EntityPool


@value
struct DummyComponentType:
    var x: UInt32


@value
struct DummyComponentType2:
    var x: UInt32


@value
struct DummyComponentType3:
    var x: UInt32


alias id2Arr = InlineArray[UInt8, 2](1, 2)
alias id3Arr = InlineArray[UInt8, 3](1, 2, 3)

alias size2Arr = InlineArray[UInt32, 2](4, 8)
alias size3Arr = InlineArray[UInt32, 3](4, 8, 8)


def test_archetype_init():
    var archetype = Archetype(4, id2Arr, size2Arr, capacity=10)

    assert_equal(archetype._capacity, 10)
    assert_equal(len(archetype), 0)
    assert_equal(archetype.get_node_index(), 4)
    assert_equal(archetype._component_count, 2)
    assert_equal(archetype._item_sizes[1], 4)
    assert_equal(archetype._item_sizes[2], 8)


def test_archetype_reserve():
    var archetype = Archetype(0, id2Arr, size2Arr)

    assert_equal(len(archetype), 0)
    assert_equal(archetype._component_count, 2)
    assert_equal(archetype._item_sizes[1], 4)
    assert_equal(archetype._item_sizes[2], 8)

    archetype.reserve(50)
    assert_equal(archetype._capacity, 50)
    assert_equal(len(archetype), 0)
    assert_equal(archetype._component_count, 2)
    assert_equal(archetype._item_sizes[1], 4)
    assert_equal(archetype._item_sizes[2], 8)

    archetype.reserve(5)
    assert_equal(archetype._capacity, 50)
    assert_equal(len(archetype), 0)
    assert_equal(archetype._component_count, 2)
    assert_equal(archetype._item_sizes[1], 4)
    assert_equal(archetype._item_sizes[2], 8)

    archetype.reserve(60)
    assert_equal(archetype._capacity, 60)
    assert_equal(len(archetype), 0)
    assert_equal(archetype._component_count, 2)
    assert_equal(archetype._item_sizes[2], 8)


def test_archetype_get_entity():
    var archetype = Archetype(0, id2Arr, size2Arr)

    var entity = Entity(0, 0)
    archetype._entities.append(entity)
    assert_equal(archetype.get_entity(0), entity)


def test_archetype_remove():
    var archetype = Archetype(0, id2Arr, size2Arr)

    var entity1 = Entity(0, 0)
    var entity2 = Entity(1, 0)
    archetype._entities.append(entity1)
    archetype._entities.append(entity2)
    archetype._size = 2

    assert_equal(len(archetype), 2)
    assert_equal(archetype._entities[0], entity1)
    assert_equal(archetype._entities[1], entity2)

    var swapped = archetype.remove(0)
    assert_equal(swapped, True)
    assert_equal(len(archetype), 1)
    assert_equal(archetype._entities[0], entity2)

    swapped = archetype.remove(0)
    assert_equal(swapped, False)
    assert_equal(len(archetype), 0)
    assert_equal(len(archetype._entities), 0)


def test_archetype_has_component():
    var archetype = Archetype(0, id2Arr, size2Arr)

    assert_equal(archetype.has_component(1), True)
    assert_equal(archetype.has_component(2), True)
    assert_equal(archetype.has_component(3), False)


def test_archetype_get_component_ptr():
    var archetype = Archetype(0, id2Arr, size2Arr)

    var entity = Entity(0, 0)
    archetype._entities.append(entity)
    archetype._size = 1

    var ptr = archetype._get_component_ptr(0, 1)
    assert_equal(ptr != UnsafePointer[UInt8](), True)


def test_archetype_move():
    # TODO: not all fields are tested
    var archetype = Archetype(0, id2Arr, size2Arr)

    ptr1 = archetype._get_component_ptr(0, 1)
    ptr2 = archetype._get_component_ptr(0, 5)
    id1 = archetype._ids[0]
    id2 = archetype._ids[1]

    var archetype2 = archetype^

    assert_equal(ptr1, archetype2._get_component_ptr(0, 1))
    assert_equal(ptr2, archetype2._get_component_ptr(0, 5))
    assert_equal(id1, archetype2._ids[0])
    assert_equal(id2, archetype2._ids[1])


def test_archetype_copy():
    # TODO: not all fields are tested
    var archetype = Archetype(0, id2Arr, size2Arr)

    var archetype2 = archetype.copy()

    assert_not_equal(
        archetype._get_component_ptr(0, 1), archetype2._get_component_ptr(0, 1)
    )
    assert_not_equal(
        archetype._get_component_ptr(0, 2), archetype2._get_component_ptr(0, 2)
    )
    assert_equal(archetype._ids[0], archetype2._ids[0])
    assert_equal(archetype._ids[1], archetype2._ids[1])


def test_archetype_add():
    var archetype = Archetype(0, id2Arr, size2Arr)

    var entity = Entity(10, 3)
    var index = archetype.add(entity)

    assert_equal(index, 0)
    assert_equal(len(archetype), 1)
    assert_equal(archetype.get_entity(0), entity)


def test_archetype_extend():
    var archetype = Archetype(0, id2Arr, size2Arr)
    var entity_pool = EntityPool()

    var start_index = archetype.extend(5, entity_pool)

    assert_equal(start_index, 0)
    assert_equal(len(archetype), 5)

    start_index = archetype.extend(5, entity_pool)

    assert_equal(start_index, 5)
    assert_equal(len(archetype), 10)
    for i in range(10):
        assert_equal(archetype.get_entity(i)._id, i + 1)


def test_archetype_get_mask():
    var archetype = Archetype(0, id3Arr, size3Arr)

    var entity = Entity(10, 3)
    _ = archetype.add(entity)

    var mask = archetype.get_mask()
    assert_equal(mask, BitMask(1, 2, 3))

    var mask2 = BitMask(1, 2, 3)
    assert_equal(mask == mask2, True)

    mask2 = BitMask(1, 2, 4)
    assert_equal(mask == mask2, False)

    mask2 = BitMask(1, 2)
    assert_equal(mask == mask2, False)


def main():
    print("Running tests...")
    test_archetype_get_mask()
    test_archetype_init()
    test_archetype_reserve()
    test_archetype_get_entity()
    test_archetype_remove()
    test_archetype_has_component()
    test_archetype_get_component_ptr()
    test_archetype_move()
    test_archetype_copy()
    test_archetype_add()
    test_archetype_extend()
    print("All tests passed!")
