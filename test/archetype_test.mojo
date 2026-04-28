from std.testing import *

from larecs.archetype import Archetype as _Archetype
from larecs.bitmask import BitMask
from larecs.component import ComponentManager
from larecs.entity import Entity
from larecs.pool import EntityPool
from larecs.test_utils import *


# ToDo: Remove this when the benchmark tools
# are updated
@fieldwise_init
struct LargerComponent(ComponentType):
    var x: Float64
    var y: Float64
    var z: Float64


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
    component_manager=ComponentManager[
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
    ](),
]

comptime id2Arr: InlineArray[Int, 2] = [1, 2]
comptime id3Arr: InlineArray[Int, 3] = [1, 2, 3]

comptime size2Arr: InlineArray[UInt32, 2] = [4, 8]
comptime size3Arr: InlineArray[UInt32, 3] = [4, 8, 8]


def test_archetype_init() raises:
    var archetype = Archetype(4, id2Arr, capacity=10)

    assert_equal(archetype._capacity, 10)
    assert_equal(len(archetype), 0)
    assert_equal(archetype.get_node_index(), 4)
    assert_equal(archetype._component_count, 2)
    assert_equal(archetype._item_sizes[1], 24)
    assert_equal(archetype._item_sizes[2], 16)


def test_archetype_reserve() raises:
    var archetype = Archetype(0, id2Arr)

    assert_equal(len(archetype), 0)
    assert_equal(archetype._component_count, 2)
    assert_equal(archetype._item_sizes[1], 24)
    assert_equal(archetype._item_sizes[2], 16)

    archetype.reserve(50)
    assert_equal(archetype._capacity, 64)
    assert_equal(len(archetype), 0)
    assert_equal(archetype._component_count, 2)
    assert_equal(archetype._item_sizes[1], 24)
    assert_equal(archetype._item_sizes[2], 16)

    archetype.reserve(5)
    assert_equal(archetype._capacity, 64)
    assert_equal(len(archetype), 0)
    assert_equal(archetype._component_count, 2)
    assert_equal(archetype._item_sizes[1], 24)
    assert_equal(archetype._item_sizes[2], 16)

    archetype.reserve(70)
    assert_equal(archetype._capacity, 128)
    assert_equal(len(archetype), 0)
    assert_equal(archetype._component_count, 2)
    assert_equal(archetype._item_sizes[2], 16)


def test_archetype_get_entity() raises:
    var archetype = Archetype(0, id2Arr)

    var entity = Entity(0, 0)
    idx = archetype.add(entity)
    assert_equal(archetype.get_entity(idx), entity)


def test_archetype_remove() raises:
    var archetype = Archetype(0, id2Arr)

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
    var archetype = Archetype(0, id2Arr)

    assert_true(archetype.has_component(1))
    assert_true(archetype.has_component(2))
    assert_false(archetype.has_component(3))


def test_archetype_get_component_ptr() raises:
    var archetype = Archetype(0, id2Arr)

    var entity = Entity(0, 0)
    archetype._entities.append(entity)
    archetype._size = 1

    var ptr = archetype._get_component_ptr(0, 1)
    assert_true(ptr != UnsafePointer[UInt8, MutExternalOrigin]())


def test_archetype_move() raises:
    # TODO: not all fields are tested
    var archetype = Archetype(0, id2Arr)

    idx = archetype.add(Entity())

    ptr1 = archetype._get_component_ptr(idx, 1)
    ptr2 = archetype._get_component_ptr(idx, 5)
    id1 = archetype._ids[0]
    id2 = archetype._ids[1]

    var archetype2 = archetype^

    assert_equal(ptr1, archetype2._get_component_ptr(idx, 1))
    assert_equal(ptr2, archetype2._get_component_ptr(idx, 5))
    assert_equal(id1, archetype2._ids[0])
    assert_equal(id2, archetype2._ids[1])


def test_archetype_copy() raises:
    # TODO: not all fields are tested
    var archetype = Archetype(0, id2Arr)
    idx = archetype.add(Entity())

    var archetype2 = archetype.copy()

    assert_not_equal(
        archetype._get_component_ptr(idx, 1),
        archetype2._get_component_ptr(idx, 1),
    )
    assert_not_equal(
        archetype._get_component_ptr(idx, 2),
        archetype2._get_component_ptr(idx, 2),
    )
    assert_equal(archetype._ids[0], archetype2._ids[0])
    assert_equal(archetype._ids[1], archetype2._ids[1])


def test_archetype_shallow_copy() raises:
    var archetype1 = Archetype(0, id2Arr)
    entity_idx = archetype1.add(Entity(10, 3))
    entity1 = archetype1.get_entity_accessor(entity_idx)
    comp = LargerComponent(1.0, 2.0, 3.0)
    entity1.set(comp.copy())

    assert_equal(
        entity1.get[LargerComponent]().x,
        comp.x,
        "Component value should be correct before copy",
    )

    var archetype2 = Archetype(0, id3Arr)
    archetype2.unsafe_take_data_from_parts(
        archetype1._ids,
        archetype1._data,
        archetype1._item_sizes,
        archetype1._component_count,
        archetype1._capacity,
    )
    archetype1.unsafe_reinit_components(archetype2._ids)

    assert_true(
        archetype2.has_component(3),
        (
            "Destination-only component storage should remain valid after"
            " taking data"
        ),
    )
    assert_equal(archetype2._item_sizes[3], 16)

    entity_idx = archetype2.add(Entity(10, 3))
    entity2 = archetype2.get_entity_accessor(entity_idx)

    assert_equal(
        entity2.get[LargerComponent]().x,
        comp.x,
        "Component value should be correct after copy",
    )


def test_archetype_add() raises:
    var archetype = Archetype(0, id2Arr)

    var entity = Entity(10, 3)
    var index = archetype.add(entity)

    assert_equal(index, 0)
    assert_equal(len(archetype), 1)
    assert_equal(archetype.get_entity(0), entity)


def test_archetype_extend() raises:
    var archetype = Archetype(0, id2Arr)
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
    var archetype = Archetype(0, id3Arr)

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
