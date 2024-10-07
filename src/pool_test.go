package ecs

import (
    "math"
    "math/rand"
    "testing"

    "github.com/stretchr/testify/assert"
)

fn TestEntityPoolConstructor(t *testing.T):
    _ = newEntityPool(128)

fn TestEntityPool(t *testing.T):
    p = newEntityPool(128)

    expectedAll = []Entity{newEntity(0), newEntity(1), newEntity(2), newEntity(3), newEntity(4), newEntity(5)}
    expectedAll[0].gen = math.MaxUint16

    for i = 0; i < 5; i++:
        _ = p.get()
    
    assert_equal(expectedAll, p.entities, "Wrong initial entities")

    assert.Panics(t, fn(): p.Recycle(p.entities[0]) })

    e0 = p.entities[1]
    p.Recycle(e0)
    assert_false(p.Alive(e0), "Dead entity should not be alive")

    e0Old = e0
    e0 = p.get()
    expectedAll[1].gen++
    assert_true(p.Alive(e0), "Recycled entity of new generation should be alive")
    assert_false(p.Alive(e0Old), "Recycled entity of old generation should not be alive")

    assert_equal(expectedAll, p.entities, "Wrong entities after get/recycle")

    e0Old = p.entities[1]
    for i = 0; i < 5; i++:
        p.Recycle(p.entities[i+1])
        expectedAll[i+1].gen++
    

    assert_false(p.Alive(e0Old), "Recycled entity of old generation should not be alive")

    for i = 0; i < 5; i++:
        _ = p.get()
    

    assert_false(p.Alive(e0Old), "Recycled entity of old generation should not be alive")
    assert_false(p.Alive(Entity{}), "Zero entity should not be alive")

fn TestEntityPoolStochastic(t *testing.T):
    p = newEntityPool(128)

    for i = 0; i < 10; i++:
        p.reset()
        assert_equal(0, p.Len())
        assert_equal(0, p.Available())

        alive = map[Entity]bool{}
        for i = 0; i < 10; i++:
            e = p.get()
            alive[e] = True
        

        for e, isAlive = range alive:
            assert_equal(isAlive, p.Alive(e), "Wrong alive state of entity %v after initialization", e)
            if rand.Float32() > 0.75:
                continue
            
            p.Recycle(e)
            alive[e] = False
        
        for e, isAlive = range alive:
            assert_equal(isAlive, p.Alive(e), "Wrong alive state of entity %v after 1st removal. Entity is %v", e, p.entities[e.id])
        
        for i = 0; i < 10; i++:
            e = p.get()
            alive[e] = True
        
        for e, isAlive = range alive:
            assert_equal(isAlive, p.Alive(e), "Wrong alive state of entity %v after 1st recycling. Entity is %v", e, p.entities[e.id])
        
        assert_equal(uint32(0), p.available, "No more entities should be available")

        for e, isAlive = range alive:
            if !isAlive or rand.Float32() > 0.75:
                continue
            
            p.Recycle(e)
            alive[e] = False
        
        for e, a = range alive:
            assert_equal(a, p.Alive(e), "Wrong alive state of entity %v after 2nd removal. Entity is %v", e, p.entities[e.id])
        
    

fn TestBitPool(t *testing.T):
    p = bitPool{}

    for i = 0; i < MASK_TOTAL_BITS; i++:
        assert_equal(i, int(p.get()))
    

    assert.Panics(t, fn(): p.get() })

    for i = 0; i < 10; i++:
        p.Recycle(uint8(i))
    
    for i = 9; i >= 0; i--:
        assert_equal(i, int(p.get()))
    

    assert.Panics(t, fn(): p.get() })

    p.reset()

    for i = 0; i < MASK_TOTAL_BITS; i++:
        assert_equal(i, int(p.get()))
    

    assert.Panics(t, fn(): p.get() })

    for i = 0; i < 10; i++:
        p.Recycle(uint8(i))
    
    for i = 9; i >= 0; i--:
        assert_equal(i, int(p.get()))
    

fn TestIntPool(t *testing.T):
    p = newIntPool[int](16)

    for n = 0; n < 3; n++:
        for i = 0; i < 32; i++:
            assert_equal(i, p.get())
        

        assert_equal(32, len(p.pool))

        p.Recycle(3)
        p.Recycle(4)
        assert_equal(4, p.get())
        assert_equal(3, p.get())

        p.reset()
    
