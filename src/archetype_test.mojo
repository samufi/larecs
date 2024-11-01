from archetype import Archetype
from component import ComponentInfo, ComponentReference, ComponentManager
from entity import Entity
from testing import assert_equal, assert_raises

@value
struct DummyComponentType:
    var x: UInt32

@value
struct DummyComponentType2:
    var x: UInt32

@value
struct DummyComponentType3:
    var x: UInt32

def test_archetype_init():
    var component1 = ComponentInfo[UInt8](id=1, size=4)
    var component2 = ComponentInfo[UInt8](id=2, size=8)
    var archetype = Archetype[UInt8](10, component1, component2)
    
    assert_equal(archetype._capacity, 10)
    assert_equal(len(archetype), 0)
    assert_equal(len(archetype._ids), 2)
    assert_equal(archetype._item_sizes[1], 4)
    assert_equal(archetype._item_sizes[2], 8)

def test_archetype_reserve():
    var component1 = ComponentInfo[UInt8](id=1, size=4)
    var component2 = ComponentInfo[UInt8](id=2, size=8)
    var archetype = Archetype[UInt8](10, component1, component2)
    
    assert_equal(archetype._capacity, 10)
    assert_equal(len(archetype), 0)
    assert_equal(len(archetype._ids), 2)
    assert_equal(archetype._item_sizes[1], 4)
    assert_equal(archetype._item_sizes[2], 8)
    
    archetype.reserve(20)
    assert_equal(archetype._capacity, 20)
    assert_equal(len(archetype), 0)
    assert_equal(len(archetype._ids), 2)
    assert_equal(archetype._item_sizes[1], 4)
    assert_equal(archetype._item_sizes[2], 8)

    archetype.reserve(5)
    assert_equal(archetype._capacity, 20)
    assert_equal(len(archetype), 0)
    assert_equal(len(archetype._ids), 2)
    assert_equal(archetype._item_sizes[1], 4)
    assert_equal(archetype._item_sizes[2], 8)

    archetype.reserve(30)
    assert_equal(archetype._capacity, 30)
    assert_equal(len(archetype), 0)
    assert_equal(len(archetype._ids), 2)
    assert_equal(archetype._item_sizes[2], 8)

def test_get_entity():
    var component1 = ComponentInfo[UInt8](id=1, size=4)
    var component2 = ComponentInfo[UInt8](id=2, size=8)
    var archetype = Archetype[UInt8](10, component1, component2)
    
    var entity = Entity(0, 0)
    archetype._entities.append(entity)
    assert_equal(archetype.get_entity(0), entity)

def test_archetype_remove():
    var component1 = ComponentInfo[UInt8](id=1, size=4)
    var component2 = ComponentInfo[UInt8](id=2, size=8)
    var archetype = Archetype[UInt8](10, component1, component2)
    
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
    var component1 = ComponentInfo[UInt8](id=1, size=4)
    var component2 = ComponentInfo[UInt8](id=2, size=8)
    var archetype = Archetype[UInt8](10, component1, component2)

    assert_equal(archetype.has_component(1), True)
    assert_equal(archetype.has_component(2), True)
    assert_equal(archetype.has_component(3), False)

def test_archetype_get_component_ptr():
    var component1 = ComponentInfo[UInt8](id=1, size=4)
    var component2 = ComponentInfo[UInt8](id=2, size=8)
    var archetype = Archetype[UInt8](10, component1, component2)

    var entity = Entity(0, 0)
    archetype._entities.append(entity)
    archetype._size = 1

    var ptr = archetype._get_component_ptr(0, 1)
    assert_equal(ptr != UnsafePointer[UInt8](), True)

def main():
    test_archetype_init()
    test_archetype_reserve()
    test_get_entity()
    test_archetype_remove()
    test_archetype_has_component()
    test_archetype_get_component_ptr()