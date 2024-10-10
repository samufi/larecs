from more_testing import Test
import bitmask as ecs
import random
import benchmark
from time import now
from tensor import Tensor

fn main() raises:
    run_all_bitmask_tests()
    run_all_bitmask_benchmarks()

fn run_all_bitmask_tests() raises:
    print("Running all bitmask tests...")
    test_bit_mask()
    test_bit_mask_without_exclusive()
    test_bit_mask_128()
    print("Done")

fn run_all_bitmask_benchmarks():
    print("Running all bitmask benchmarks...")
    benchmark_bitmask_get()
    print("Done")

fn test_bit_mask() raises:
    var mask = ecs.all(UInt8(1), UInt8(2), UInt8(13), UInt8(27))
    var test = Test("test_bit_mask")

    test.assert_equal(4, mask.total_bits_set())

    test.assert_true(mask.get(1))
    test.assert_true(mask.get(2))
    test.assert_true(mask.get(13))
    test.assert_true(mask.get(27))

    test.assert_false(mask.get(0))
    test.assert_false(mask.get(3))

    mask.set(UInt8(0), True)
    mask.set(UInt8(1), False)

    test.assert_true(mask.get(0))
    test.assert_false(mask.get(1))

    var other1 = ecs.all(UInt8(1), UInt8(2), UInt8(32))
    var other2 = ecs.all(UInt8(0), UInt8(2))

    test.assert_false(mask.contains(other1))
    test.assert_true(mask.contains(other2))

    mask.reset()
    test.assert_equal(0, mask.total_bits_set())

    mask = ecs.all(UInt8(1), UInt8(2), UInt8(13), UInt8(27))
    other1 = ecs.all(UInt8(1), UInt8(32))
    other2 = ecs.all(UInt8(0), UInt8(32))

    test.assert_true(mask.contains_any(other1))
    test.assert_false(mask.contains_any(other2))


fn test_bit_mask_without_exclusive() raises:
    var test = Test("test_bit_mask_without_exclusive")
    let mask = ecs.all(UInt8(1), UInt8(2), UInt8(13))
    test.assert_true(mask.matches(ecs.all(UInt8(1), UInt8(2), UInt8(13))))
    test.assert_true(mask.matches(ecs.all(UInt8(1), UInt8(2), UInt8(13), UInt8(27))))

    test.assert_false(mask.matches(ecs.all(UInt8(1), UInt8(2))))

    let without = mask.without(UInt8(3))

    test.assert_true(without.matches(ecs.all(UInt8(1), UInt8(2), UInt8(13))))
    test.assert_true(without.matches(ecs.all(UInt8(1), UInt8(2), UInt8(13), UInt8(27))))

    test.assert_false(without.matches(ecs.all(UInt8(1), UInt8(2), UInt8(3), UInt8(13))))
    test.assert_false(without.matches(ecs.all(UInt8(1), UInt8(2))))

    let excl = mask.exclusive()

    test.assert_true(excl.matches(ecs.all(UInt8(1), UInt8(2), UInt8(13))))
    test.assert_false(excl.matches(ecs.all(UInt8(1), UInt8(2), UInt8(13), UInt8(27))))
    test.assert_false(excl.matches(ecs.all(UInt8(1), UInt8(2), UInt8(3), UInt8(13))))


fn test_bit_mask_128() raises:
    var test = Test("test_bit_mask_128")
    for i in range(ecs.MASK_TOTAL_BITS):
        let mask = ecs.all(UInt8(i))
        test.assert_equal(1, mask.total_bits_set())
        test.assert_true(mask.get(UInt8(i)))
    
    var mask = ecs.Mask(0, 0)
    test.assert_equal(0, mask.total_bits_set())

    for i in range(ecs.MASK_TOTAL_BITS):
        mask.set(UInt8(i), True)
        test.assert_equal(i+1, mask.total_bits_set())
        test.assert_true(mask.get(UInt8(i)))
    

    mask = ecs.all(UInt8(1), UInt8(2), UInt8(13), UInt8(27), UInt8(63), UInt8(64), UInt8(65))

    test.assert_true(mask.contains(ecs.all(UInt8(1), UInt8(2), UInt8(63), UInt8(64))))
    test.assert_false(mask.contains(ecs.all(UInt8(1), UInt8(2), UInt8(63), UInt8(90))))

    test.assert_true(mask.contains_any(ecs.all(UInt8(6), UInt8(65), UInt8(111))))
    test.assert_false(mask.contains_any(ecs.all(UInt8(6), UInt8(66), UInt8(90))))



fn benchmark_bitmask_get[n: Int = 100000000]():
    var mask = ecs.all()

    for i in range(ecs.MASK_TOTAL_BITS):
        if random.random_float64() < 0.5:
            mask.set(UInt8(i), True)
        
    
    var vals_ = random.rand[DType.float16](n)
    vals_ = ecs.MASK_TOTAL_BITS * vals_
    let vals = vals_.astype[DType.uint8]()
    print(n)
    print(vals.shape()[0])
    print(vals)

    let previous = now()
    for i in range(vals.shape()[0]):
        let v = mask.get(i)

    let elapsed_time = (previous - now()) * 1e-9 / n
    print(elapsed_time)



# fn BenchmarkBitmaskContains(b *testing.B):
#     b.StopTimer()
#     mask = ecs.all()
#     for i = 0; i < ecs.MASK_TOTAL_BITS; i++:
#         if rand.Float64() < 0.5:
#             mask.set(UInt8(i), True)
        
    
#     filter = ecs.all(UInt8(rand.Intn(ecs.MASK_TOTAL_BITS)))
#     b.StartTimer()

#     var v: Bool
#     for i = 0; i < b.N; i++:
#         v = mask.contains(filter)
    

#     b.StopTimer()
#     v = !v
#     _ = v


# fn BenchmarkBitmaskContainsAny(b *testing.B):
#     b.StopTimer()
#     mask = ecs.all()
#     for i = 0; i < ecs.MASK_TOTAL_BITS; i++:
#         if rand.Float64() < 0.5:
#             mask.set(UInt8(i), True)
        
    
#     filter = ecs.all(UInt8(rand.Intn(ecs.MASK_TOTAL_BITS)))
#     b.StartTimer()

#     var v: Bool
#     for i = 0; i < b.N; i++:
#         v = mask.contains_any(filter)
    

#     b.StopTimer()
#     v = !v
#     _ = v


# fn BenchmarkMaskFilter(b *testing.B):
#     b.StopTimer()
#     mask = ecs.all(0, 1, 2).without()
#     bits = ecs.all(0, 1, 2)
#     b.StartTimer()
#     var v: Bool
#     for i = 0; i < b.N; i++:
#         v = mask.matches(bits)
    
#     b.StopTimer()
#     v = !v
#     _ = v


# fn BenchmarkMaskFilterNoPointer(b *testing.B):
#     b.StopTimer()
#     mask = maskFilterPointer{ecs.all(0, 1, 2), ecs.all()
#     bits = ecs.all(0, 1, 2)
#     b.StartTimer()
#     var v: Bool
#     for i = 0; i < b.N; i++:
#         v = mask.matches(bits)
    
#     b.StopTimer()
#     v = !v
#     _ = v


# fn BenchmarkMaskPointer(b *testing.B):
#     b.StopTimer()
#     mask = maskPointer(ecs.all(0, 1, 2))
#     bits = ecs.all(0, 1, 2)
#     b.StartTimer()
#     var v: Bool
#     for i = 0; i < b.N; i++:
#         v = mask.matches(bits)
    
#     b.StopTimer()
#     v = !v
#     _ = v


# fn BenchmarkMask(b *testing.B):
#     b.StopTimer()
#     mask = ecs.all(0, 1, 2)
#     bits = ecs.all(0, 1, 2)
#     b.StartTimer()
#     var v: Bool
#     for i = 0; i < b.N; i++:
#         v = mask.matches(bits)
    
#     b.StopTimer()
#     v = !v
#     _ = v


# # bitMask64 is there just for performance comparison with the new 128 bit Mask.
# type bitMask64 uint64

# fn newBitMask64(ids ...UInt8) bitMask64:
#     var mask bitMask64
#     for _, id = range ids:
#         mask.set(id, True)
    
#     return mask

# fn (e bitMask64) get(bit UInt8): Bool:
#     mask = bitMask64(1 << bit)
#     return e&mask == mask


# fn (e *bitMask64) set(bit UInt8, value: Bool):
#     if value:
#         *e |= bitMask64(1 << bit)
#      else:
#         *e &= bitMask64(^(1 << bit))
    


# type maskFilterPointer struct:
#     Mask    ecs.Mask
#     exclude ecs.Mask


# # matches matches a filter against a mask.
# fn (f maskFilterPointer) matches(bits ecs.Mask): Bool:
#     return bits.contains(f.Mask) and
#         (f.exclude.is_zero() or !bits.contains_any(f.exclude))


# type maskPointer ecs.Mask

# # matches matches a filter against a mask.
# fn (f *maskPointer) matches(bits ecs.Mask): Bool:
#     return bits.contains(ecs.Mask(*f))


# fn ExampleMask():
#     world = ecs.NewWorld()
#     posID = ecs.ComponentID[Position](&world)
#     velID = ecs.ComponentID[Velocity](&world)

#     filter = ecs.all(posID, velID)
#     query = world.Query(filter)

#     for query.Next():
#         # ...
    
#     # Output:


# fn ExampleMask_Without():
#     world = ecs.NewWorld()
#     posID = ecs.ComponentID[Position](&world)
#     velID = ecs.ComponentID[Velocity](&world)

#     filter = ecs.all(posID).without(velID)
#     query = world.Query(&filter)

#     for query.Next():
#         # ...
    
#     # Output:


# fn ExampleMask_Exclusive():
#     world = ecs.NewWorld()
#     posID = ecs.ComponentID[Position](&world)
#     velID = ecs.ComponentID[Velocity](&world)

#     filter = ecs.all(posID, velID).exclusive()
#     query = world.Query(&filter)

#     for query.Next():
#         # ...
    
#     # Output:

