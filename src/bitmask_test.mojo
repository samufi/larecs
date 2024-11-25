from bitmask import BitMask
import random
import benchmark
from time import now
from memory import UnsafePointer
from testing import *
from custom_benchmark import Bencher, keep, Bench, BenchId, BenchConfig


# ------ Helper functions ------


@always_inline
fn get_random_bitmask() -> BitMask as mask:
    mask = BitMask()
    for i in range(BitMask.total_bits):
        if random.random_float64() < 0.5:
            mask.set(UInt8(i), True)


@always_inline
fn get_random_uint8_list(size: Int) -> List[UInt8] as vals:
    vals = List[UInt8](capacity=size)
    for _ in range(size):
        vals.append(
            random.random_ui64(0, BitMask.total_bits).cast[DType.uint8]()
        )


@always_inline
fn get_random_1_true_bitmasks(size: Int) -> List[BitMask] as vals:
    vals = List[BitMask](capacity=size)
    for _ in range(size):
        vals.append(
            BitMask(
                random.random_ui64(0, BitMask.total_bits).cast[DType.uint8]()
            )
        )


# ------ Tests ------


fn run_all_bitmask_tests() raises:
    print("Running all bitmask tests...")
    test_bit_mask()
    test_bit_mask_without_exclusive()
    test_bit_mask_256()
    test_bit_mask_eq()
    print("Done")


fn test_bit_mask() raises:
    var mask = BitMask(UInt8(1), UInt8(2), UInt8(13), UInt8(27))

    assert_equal(4, mask.total_bits_set())

    assert_true(mask.get(1))
    assert_true(mask.get(2))
    assert_true(mask.get(13))
    assert_true(mask.get(27))

    assert_equal(
        str(mask),
        "[0110000000000100000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000]",
    )

    assert_false(mask.get(0))
    assert_false(mask.get(3))

    mask.set(UInt8(0), True)
    mask.set(UInt8(1), False)

    assert_true(mask.get(0))
    assert_false(mask.get(1))

    mask.flip(UInt8(0))
    mask.flip(UInt8(1))

    assert_false(mask.get(0))
    assert_true(mask.get(1))

    mask.flip(UInt8(0))
    mask.flip(UInt8(1))

    var other1 = BitMask(UInt8(1), UInt8(2), UInt8(32))
    var other2 = BitMask(UInt8(0), UInt8(2))

    assert_false(mask.contains(other1))
    assert_true(mask.contains(other2))

    mask.reset()
    assert_equal(0, mask.total_bits_set())

    mask = BitMask(UInt8(1), UInt8(2), UInt8(13), UInt8(27))
    other1 = BitMask(UInt8(1), UInt8(32))
    other2 = BitMask(UInt8(0), UInt8(32))

    assert_true(mask.contains_any(other1))
    assert_false(mask.contains_any(other2))


fn test_bit_mask_without_exclusive() raises:
    mask = BitMask(UInt8(1), UInt8(2), UInt8(13))
    assert_true(mask.matches(BitMask(UInt8(1), UInt8(2), UInt8(13))))
    assert_true(mask.matches(BitMask(UInt8(1), UInt8(2), UInt8(13), UInt8(27))))

    assert_false(mask.matches(BitMask(UInt8(1), UInt8(2))))

    without = mask.without(UInt8(3))

    assert_true(without.matches(BitMask(UInt8(1), UInt8(2), UInt8(13))))
    assert_true(
        without.matches(BitMask(UInt8(1), UInt8(2), UInt8(13), UInt8(27)))
    )

    assert_false(
        without.matches(BitMask(UInt8(1), UInt8(2), UInt8(3), UInt8(13)))
    )
    assert_false(without.matches(BitMask(UInt8(1), UInt8(2))))

    excl = mask.exclusive()

    assert_true(excl.matches(BitMask(UInt8(1), UInt8(2), UInt8(13))))
    assert_false(
        excl.matches(BitMask(UInt8(1), UInt8(2), UInt8(13), UInt8(27)))
    )
    assert_false(excl.matches(BitMask(UInt8(1), UInt8(2), UInt8(3), UInt8(13))))


fn test_bit_mask_eq() raises:
    mask1 = get_random_bitmask()
    mask2 = mask1

    assert_true(mask1 == mask2)

    mask2.flip(3)

    assert_false(mask1 == mask2)


fn test_bit_mask_256() raises:
    for i in range(BitMask.total_bits):
        mask = BitMask(UInt8(i))
        assert_equal(1, mask.total_bits_set())
        assert_true(mask.get(UInt8(i)))

    mask = BitMask()
    assert_equal(0, mask.total_bits_set())

    for i in range(BitMask.total_bits):
        mask.set(UInt8(i), True)
        assert_equal(i + 1, mask.total_bits_set())
        assert_true(mask.get(UInt8(i)))

    mask = BitMask(
        UInt8(1),
        UInt8(2),
        UInt8(13),
        UInt8(27),
        UInt8(63),
        UInt8(64),
        UInt8(65),
    )

    assert_true(
        mask.contains(BitMask(UInt8(1), UInt8(2), UInt8(63), UInt8(64)))
    )
    assert_false(
        mask.contains(BitMask(UInt8(1), UInt8(2), UInt8(63), UInt8(90)))
    )

    assert_true(mask.contains_any(BitMask(UInt8(6), UInt8(65), UInt8(111))))
    assert_false(mask.contains_any(BitMask(UInt8(6), UInt8(66), UInt8(90))))


# ------ Benchmarking ------


fn run_all_bitmask_benchmarks() raises:
    print("Running all bitmask benchmarks...")
    config = BenchConfig(
        initial_batch_size=1000_000_000, min_runtime_secs=2, show_progress=True
    )
    bench = Bench(config)
    bench.bench_function[benchmark_bitmask_get](
        BenchId("benchmark_bitmask_get")
    )
    # bench.bench_function[benchmark_bitmask_set](
    #     BenchId("benchmark_bitmask_set")
    # )
    # bench.bench_function[benchmark_bitmask_flip](
    #     BenchId("benchmark_bitmask_flip")
    # )
    # bench.bench_function[benchmark_bitmask_contains](
    #     BenchId("benchmark_bitmask_contains")
    # )
    # bench.bench_function[benchmark_bitmask_contains_any](
    #     BenchId("benchmark_bitmask_contains_any")
    # )
    # bench.bench_function[benchmark_bitmask_eq](BenchId("benchmark_bitmask_eq"))
    # bench.bench_function[benchmark_mask_filter](
    #     BenchId("benchmark_mask_filter")
    # )
    bench.dump_report()

    # mask = get_random_bitmask()
    # val = random.random_ui64(0, BitMask.total_bits).cast[DType.uint8]()


fn benchmark_bitmask_get(inout bencher: Bencher) capturing:
    @always_inline
    @parameter
    fn bench_fn(calls: Int) capturing -> Int:
        v = 0
        for _ in range(calls):
            v += 1
        print(v)
        return calls

    bencher.iter_custom[bench_fn]()

    # v = mask.get(val)


fn benchmark_bitmask_set(inout bencher: Bencher) capturing:
    mask = get_random_bitmask()
    val = random.random_ui64(0, BitMask.total_bits).cast[DType.uint8]()

    @always_inline
    @parameter
    fn bench_fn(calls: Int) capturing -> Int:
        bit_val = True
        for _ in range(calls):
            mask.set(val, bit_val)
            keep(mask._bytes)
            bit_val = not bit_val
        return calls

    bencher.iter_custom[bench_fn]()


fn benchmark_bitmask_flip(inout bencher: Bencher) capturing:
    mask = get_random_bitmask()
    val = random.random_ui64(0, BitMask.total_bits).cast[DType.uint8]()

    @always_inline
    @parameter
    fn bench_fn(calls: Int) capturing -> Int:
        for _ in range(calls):
            mask.flip(val)
            keep(mask._bytes)
        return calls

    bencher.iter_custom[bench_fn]()


fn benchmark_bitmask_contains(inout bencher: Bencher) capturing:
    mask = get_random_bitmask()
    val = BitMask(random.random_ui64(0, BitMask.total_bits).cast[DType.uint8]())

    @always_inline
    @parameter
    fn bench_fn(calls: Int) capturing -> Int:
        for _ in range(calls):
            keep(mask.contains(val))
        return calls

    bencher.iter_custom[bench_fn]()


fn benchmark_bitmask_contains_any(inout bencher: Bencher) capturing:
    mask = get_random_bitmask()
    val = BitMask(random.random_ui64(0, BitMask.total_bits).cast[DType.uint8]())

    @always_inline
    @parameter
    fn bench_fn(calls: Int) capturing -> Int:
        for _ in range(calls):
            keep(mask.contains_any(val))
        return calls

    bencher.iter_custom[bench_fn]()


fn benchmark_mask_filter(inout bencher: Bencher) capturing:
    mask = BitMask(0, 1, 2).without()
    bits = BitMask(0, 1, 2)

    @always_inline
    @parameter
    fn bench_fn(calls: Int) capturing -> Int:
        for _ in range(calls):
            keep(mask.matches(bits))
        return calls

    bencher.iter_custom[bench_fn]()


fn benchmark_bitmask_eq(inout bencher: Bencher) capturing:
    mask1 = get_random_bitmask()
    mask2 = mask1
    mask3 = get_random_bitmask()

    @always_inline
    @parameter
    fn bench_fn(calls: Int) capturing -> Int:
        for _ in range(calls / 2):
            keep(mask1 == mask2)
            keep(mask1 == mask3)
        return int(calls / 2) * 2

    bencher.iter_custom[bench_fn]()


# fn BenchmarkMaskFilterNoPointer(b *testing.B):
#     b.StopTimer()
#     mask = maskFilterPointer{BitMask(0, 1, 2), BitMask()
#     bits = BitMask(0, 1, 2)
#     b.StartTimer()
#     var v: Bool
#     for i = 0; i < b.N; i++:
#         v = mask.matches(bits)

#     b.StopTimer()
#     v = !v
#     _ = v


# fn BenchmarkMaskPointer(b *testing.B):
#     b.StopTimer()
#     mask = maskPointer(BitMask(0, 1, 2))
#     bits = BitMask(0, 1, 2)
#     b.StartTimer()
#     var v: Bool
#     for i = 0; i < b.N; i++:
#         v = mask.matches(bits)

#     b.StopTimer()
#     v = !v
#     _ = v


# fn BenchmarkMask(b *testing.B):
#     b.StopTimer()
#     mask = BitMask(0, 1, 2)
#     bits = BitMask(0, 1, 2)
#     b.StartTimer()
#     var v: Bool
#     for i = 0; i < b.N; i++:
#         v = mask.matches(bits)

#     b.StopTimer()
#     v = !v
#     _ = v


fn main() raises:
    run_all_bitmask_benchmarks()
    run_all_bitmask_tests()
