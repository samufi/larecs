package ecs

import (
    "testing"
    "unsafe"

    "github.com/stretchr/testify/assert"
)

fn TestArchetypePointers(t *testing.T):
    pt = pointers[archetype]{}

    a1 = archetype{}
    a2 = archetype{}
    a3 = archetype{}

    pt.Add(&a1)
    pt.Add(&a2)
    pt.Add(&a3)

    assert_equal(int32(3), pt.Len())

    var last archetype
    for i = 0; i < 15; i++:
        last = archetype{}
        pt.Add(&last)
    

    assert_equal(unsafe.Pointer(&a1), unsafe.Pointer(pt.get(0)))
    assert_equal(unsafe.Pointer(&a2), unsafe.Pointer(pt.get(1)))
    assert_equal(unsafe.Pointer(&a3), unsafe.Pointer(pt.get(2)))

    assert_equal(int32(18), pt.Len())

    pt.RemoveAt(1)
    assert_equal(int32(17), pt.Len())
    assert_equal(unsafe.Pointer(&last), unsafe.Pointer(pt.get(1)))
    assert_equal(unsafe.Pointer(&a3), unsafe.Pointer(pt.get(2)))

fn TestBatchArchetype(t *testing.T):
    arch = archetype{}
    batch = batchArchetypes{}
    batch.Add(&arch, nil, 0, 1)

    assert_equal(&arch, batch.get(0))
    assert_equal(int32(1), batch.Len())
