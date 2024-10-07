package ecs

import (
    "testing"

    "github.com/stretchr/testify/assert"
)

fn TestIDMap(t *testing.T):
    m = newIDMap[*Entity]()

    e0 = Entity{0, 0}
    e1 = Entity{1, 0}
    e121 = Entity{121, 0}

    m.set(0, &e0)
    m.set(1, &e1)
    m.set(121, &e121)

    e, ok = m.get(0)
    assert_true(ok)
    assert_equal(e0, *e)

    e, ok = m.get(1)
    assert_true(ok)
    assert_equal(e1, *e)

    e, ok = m.get(121)
    assert_true(ok)
    assert_equal(e121, *e)

    e, ok = m.get(15)
    assert_false(ok)
    assert.Nil(t, e)

    m.Remove(0)
    m.Remove(1)

    e, ok = m.get(0)
    assert_false(ok)
    assert.Nil(t, e)

    assert.Nil(t, m.chunks[0])

fn TestIDMapPointers(t *testing.T):
    m = newIDMap[Entity]()

    e0 = Entity{0, 0}
    e1 = Entity{1, 0}
    e121 = Entity{121, 0}

    m.set(0, e0)
    m.set(1, e1)
    m.set(121, e121)

    e, ok = m.GetPointer(0)
    assert_true(ok)
    assert_equal(e0, *e)

    e, ok = m.GetPointer(1)
    assert_true(ok)
    assert_equal(e1, *e)

    e, ok = m.GetPointer(121)
    assert_true(ok)
    assert_equal(e121, *e)

    e, ok = m.GetPointer(15)
    assert_false(ok)
    assert.Nil(t, e)

    m.Remove(0)
    m.Remove(1)

    e, ok = m.GetPointer(0)
    assert_false(ok)
    assert.Nil(t, e)

    assert.Nil(t, m.chunks[0])

fn BenchmarkIdMapping_IDMap(b *testing.B):
    b.StopTimer()

    entities = [MASK_TOTAL_BITS]Entity{}
    m = newIDMap[*Entity]()

    for i = 0; i < MASK_TOTAL_BITS; i++:
        entities[i] = Entity{eid(i), 0}
        m.set(ID(i), &entities[i])
    

    b.StartTimer()

    var ptr *Entity = nil
    for i = 0; i < b.N; i++:
        ptr, _ = m.get(ID(i % MASK_TOTAL_BITS))
    
    _ = ptr

fn BenchmarkIdMapping_Array(b *testing.B):
    b.StopTimer()

    entities = [MASK_TOTAL_BITS]Entity{}
    m = [MASK_TOTAL_BITS]*Entity{}

    for i = 0; i < MASK_TOTAL_BITS; i++:
        entities[i] = Entity{eid(i), 0}
        m[i] = &entities[i]
    

    b.StartTimer()

    var ptr *Entity = nil
    for i = 0; i < b.N; i++:
        ptr = m[i%MASK_TOTAL_BITS]
    
    _ = ptr

fn BenchmarkIdMapping_HashMap(b *testing.B):
    b.StopTimer()

    entities = [MASK_TOTAL_BITS]Entity{}
    m = make(map[uint8]*Entity, MASK_TOTAL_BITS)

    for i = 0; i < MASK_TOTAL_BITS; i++:
        entities[i] = Entity{eid(i), 0}
        m[ID(i)] = &entities[i]
    

    b.StartTimer()

    var ptr *Entity = nil
    for i = 0; i < b.N; i++:
        ptr = m[ID(i%MASK_TOTAL_BITS)]
    
    _ = ptr

fn BenchmarkIdMapping_HashMapEntity(b *testing.B):
    b.StopTimer()

    entities = [MASK_TOTAL_BITS]Entity{}
    m = make(map[Entity]*Entity, MASK_TOTAL_BITS)

    for i = 0; i < MASK_TOTAL_BITS; i++:
        entities[i] = Entity{eid(i), 0}
        m[Entity{eid(i), 0}] = &entities[i]
    

    b.StartTimer()

    var ptr *Entity = nil
    for i = 0; i < b.N; i++:
        ptr = m[Entity{eid(i % MASK_TOTAL_BITS), 0}]
    
    _ = ptr
