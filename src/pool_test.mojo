from testing import *

from pool import EntityPool
from entity import Entity
from constants import MAX_UINT16
from test_utils import assert_equal_lists

def test_entity_pool_constructor():
    _ = EntityPool()

def test_entity_pool():
    p = EntityPool()

    expected_all = List[Entity](Entity(0), Entity(1), Entity(2), Entity(3), Entity(4), Entity(5))
    expected_all[0].gen = MAX_UINT16

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
    expected_all[1].gen += 1
    assert_true(p.is_alive(e0), "Recycled entity of new generation should be alive")
    assert_false(p.is_alive(e0_old), "Recycled entity of old generation should not be alive")

    assert_equal_lists(expected_all, p._entities, "Wrong _entities after get/recycle")

    e0_old = p._entities[1]
    for i in range(5):
        p.recycle(p._entities[i+1])
        expected_all[i+1].gen += 1
    

    assert_false(p.is_alive(e0_old), "Recycled entity of old generation should not be alive")

    for _ in range(5):
        _ = p.get()
    
    assert_false(p.is_alive(e0_old), "Recycled entity of old generation should not be alive")
    assert_false(p.is_alive(Entity()), "Zero entity should not be alive")



# fn TestEntityPoolStochastic(t *testing.T):
#     p = newEntityPool(128)

#     for i = 0; i < 10; i++:
#         p.reset()
#         assert_equal(0, p.Len())
#         assert_equal(0, p.Available())

#         alive = map[Entity]bool{}
#         for i = 0; i < 10; i++:
#             e = p.get()
#             alive[e] = True
        

#         for e, isAlive = range alive:
#             assert_equal(isAlive, p.is_alive(e), "Wrong alive state of entity %v after initialization", e)
#             if rand.Float32() > 0.75:
#                 continue
            
#             p.Recycle(e)
#             alive[e] = False
        
#         for e, isAlive = range alive:
#             assert_equal(isAlive, p.is_alive(e), "Wrong alive state of entity %v after 1st removal. Entity is %v", e, p._entities[e.id])
        
#         for i = 0; i < 10; i++:
#             e = p.get()
#             alive[e] = True
        
#         for e, isAlive = range alive:
#             assert_equal(isAlive, p.is_alive(e), "Wrong alive state of entity %v after 1st recycling. Entity is %v", e, p._entities[e.id])
        
#         assert_equal(uint32(0), p.available, "No more _entities should be available")

#         for e, isAlive = range alive:
#             if !isAlive or rand.Float32() > 0.75:
#                 continue
            
#             p.Recycle(e)
#             alive[e] = False
        
#         for e, a = range alive:
#             assert_equal(a, p.is_alive(e), "Wrong alive state of entity %v after 2nd removal. Entity is %v", e, p._entities[e.id])
        
    

# fn TestBitPool(t *testing.T):
#     p = bitPool{}

#     for i = 0; i < MASK_TOTAL_BITS; i++:
#         assert_equal(i, int(p.get()))
    

#     assert.Panics(t, fn(): p.get() })

#     for i = 0; i < 10; i++:
#         p.Recycle(uint8(i))
    
#     for i = 9; i >= 0; i--:
#         assert_equal(i, int(p.get()))
    

#     assert.Panics(t, fn(): p.get() })

#     p.reset()

#     for i = 0; i < MASK_TOTAL_BITS; i++:
#         assert_equal(i, int(p.get()))
    

#     assert.Panics(t, fn(): p.get() })

#     for i = 0; i < 10; i++:
#         p.Recycle(uint8(i))
    
#     for i = 9; i >= 0; i--:
#         assert_equal(i, int(p.get()))
    

# fn TestIntPool(t *testing.T):
#     p = newIntPool[int](16)

#     for n = 0; n < 3; n++:
#         for i = 0; i < 32; i++:
#             assert_equal(i, p.get())
        

#         assert_equal(32, len(p.pool))

#         p.Recycle(3)
#         p.Recycle(4)
#         assert_equal(4, p.get())
#         assert_equal(3, p.get())

#         p.reset()
    
def main():
    test_entity_pool_constructor()
    test_entity_pool()
    print("All tests passed")