from archetype import Archetype
from component import ComponentInfo, ComponentReference, ComponentManager
from entitiy import Entity

@value
struct DummyComponentType:
    var x: UInt32

@value
struct DummyComponentType2:
    var x: UInt32

@value
struct DummyComponentType3:
    var x: UInt32

fn test_archetype_init():
    var component1 = ComponentInfo(id=1, size=4)
    var component2 = ComponentInfo(id=2, size=8)
    var archetype = Archetype[UInt32](capacity=10, component1, component2)
    
    assert_equal(archetype._capacity, 10)
    assert_equal(len(archetype), 0)
    assert_equal(len(archetype._ids), 2)
    assert_equal(archetype._item_sizes[1], 4)
    assert_equal(archetype._item_sizes[2], 8)

fn test_archetype_add():
    manager = ComponentManager[UInt8]()
    manager._register[DummyComponentType]()
    manager._register[DummyComponentType2]()

    var archetype = Archetype[UInt8](capacity=2, manager.get_info[DummyComponentType](), manager.get_info[DummyComponentType2]())
    var entity = Entity(id=1)
    
    idx = archetype.add(entity, manager.get_ref(DummyComponentType(123)), manager.get_ref(DummyComponentType2(456)))
    assert_equal(idx, 0)
    assert_equal(archetype._size, 1)
    assert_equal(archetype._entities[0].id, 1)

	idx = archetype.add(entity, manager.get_ref(DummyComponentType(789)), manager.get_ref(DummyComponentType2(101112)))
	assert_equal(idx, 1)
	assert_equal(archetype._size, 2)
	assert_equal(archetype._entities[1].id, 1)

	with assert_raises():
		archetype.add(entity, manager.get_ref(DummyComponentType(123)))
	
	with assert_raises():
		idx = archetype.add(entity, manager.get_ref(DummyComponentType(789)), manager.get_ref(DummyComponentType3(101112)))