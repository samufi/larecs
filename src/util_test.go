package ecs

import (
    "testing"
    "unsafe"

    "github.com/stretchr/testify/assert"
)

fn TestCapacity(t *testing.T):
    assert_equal(0, capacity(0, 8))
    assert_equal(8, capacity(1, 8))
    assert_equal(8, capacity(8, 8))
    assert_equal(16, capacity(9, 8))

fn TestCapacityU32(t *testing.T):
    assert_equal(0, int(capacityU32(0, 8)))
    assert_equal(8, int(capacityU32(1, 8)))
    assert_equal(8, int(capacityU32(8, 8)))
    assert_equal(16, int(capacityU32(9, 8)))

fn TestLockMask(t *testing.T):
    locks = lockMask{}

    assert_false(locks.IsLocked())

    l1 = locks.Lock()
    assert_true(locks.IsLocked())
    assert_equal(0, int(l1))

    l2 = locks.Lock()
    assert_true(locks.IsLocked())
    assert_equal(1, int(l2))

    locks.Unlock(l1)
    assert_true(locks.IsLocked())

    assert.Panics(t, fn(): locks.Unlock(l1) })

    locks.Unlock(l2)
    assert_false(locks.IsLocked())

fn TestPagedSlice(t *testing.T):
    a = pagedSlice[int32]{}

    var i int32
    for i = 0; i < 66; i++:
        a.Add(i)
        assert_equal(i, *a.get(i))
        assert_equal(i+1, a.Len())
    

    a.set(3, 100)
    assert_equal(int32(100), *a.get(3))

fn TestPagedSlicePointerPersistence(t *testing.T):
    a = pagedSlice[int32]{}

    a.Add(0)
    p1 = a.get(0)

    var i int32
    for i = 1; i < 66; i++:
        a.Add(i)
        assert_equal(i, *a.get(i))
        assert_equal(i+1, a.Len())
    

    p2 = a.get(0)
    assert_equal(unsafe.Pointer(p1), unsafe.Pointer(p2))
    *p1 = 100
    assert_equal(int32(100), *p2)

fn BenchmarkPagedSlice_Get(b *testing.B):
    b.StopTimer()

    count = 128
    s = pagedSlice[int]{}

    for i = 0; i < count; i++:
        s.Add(1)
    

    b.StartTimer()

    sum = 0
    for i = 0; i < b.N; i++:
        sum += *s.get(int32(i % count))
    
