# from collections import Dict
import random
from bitmask import BitMask
from memory import UnsafePointer
from testing import *
from stupid_dict import StupidDict
from bitmask_lookup import BitMaskLookup
from custom_benchmark import Bencher, keep, Bench, BenchId, BenchConfig


fn get_random_bitmask_list(
    count: Int, range_start: Int = 0, range_end: Int = 1000
) -> List[BitMask] as list:
    list = List[BitMask]()
    list.reserve(count)
    for _ in range(count):
        bytes = SIMD[DType.uint64, 4]()
        bytes[0] = int(random.random_ui64(range_start, range_end))
        list.append(
            BitMask(
                bytes=UnsafePointer.address_of(bytes).bitcast[
                    SIMD[DType.uint8, 32]
                ]()[]
            )
        )


def test_dict():
    correct_dict = StupidDict[BitMask, Int]()
    test_dict = BitMaskLookup[Int]()
    n = 10000
    bitmasks = get_random_bitmask_list(n)
    for i in range(n):
        mask = bitmasks[i]
        correct_dict[mask] = i
        test_dict[mask] = i
        assert_equal(len(test_dict), len(correct_dict))

    bitmasks = get_random_bitmask_list(n, 0, 2000)
    for mask_ in bitmasks:
        mask = mask_[]
        assert_equal(mask in correct_dict, mask in test_dict)

        if mask in correct_dict:
            assert_equal(correct_dict[mask], test_dict[mask])
        else:
            with assert_raises():
                _ = test_dict[mask]


fn benchmark_dict_insert(inout bencher: Bencher) capturing:
    bitmasks = get_random_bitmask_list(10000)
    bitmask_count = len(bitmasks)
    dict = StupidDict[BitMask, Int]()

    @always_inline
    @parameter
    fn bench_fn(calls: Int) capturing -> Int:
        min_calls = min(bitmask_count, calls)
        for i in range(min_calls):
            dict[bitmasks[i]] = i
        return min_calls

    bencher.iter_custom[bench_fn]()


fn benchmark_dict_get(inout bencher: Bencher) capturing:
    bitmasks = get_random_bitmask_list(1000)
    bitmask_count = len(bitmasks)

    dict = StupidDict[BitMask, Int]()
    for i in range(bitmask_count):
        dict[bitmasks[i]] = i

    bitmasks = get_random_bitmask_list(10000, 0, 2000)
    bitmask_count = len(bitmasks)

    @always_inline
    @parameter
    fn bench_fn(calls: Int) capturing -> Int:
        min_calls = min(bitmask_count, calls)
        for i in range(min_calls):
            try:
                keep(dict[bitmasks[i]])
            except:
                pass
        return min_calls

    bencher.iter_custom[bench_fn]()


fn benchmark_dict_contains(inout bencher: Bencher) capturing:
    bitmasks = get_random_bitmask_list(1000)
    bitmask_count = len(bitmasks)

    dict = StupidDict[BitMask, Int]()
    for i in range(bitmask_count):
        dict[bitmasks[i]] = i

    bitmasks = get_random_bitmask_list(10000, 0, 2000)
    bitmask_count = len(bitmasks)

    @always_inline
    @parameter
    fn bench_fn(calls: Int) capturing -> Int:
        min_calls = min(bitmask_count, calls)
        for i in range(min_calls):
            keep(bitmasks[i] in dict)
        return min_calls

    bencher.iter_custom[bench_fn]()


fn run_all_dict_benchmarks() raises:
    print("Running all dict benchmarks...")
    config = BenchConfig(
        initial_batch_size=10_000, min_runtime_secs=2, show_progress=True
    )
    bench = Bench(config)
    bench.bench_function[benchmark_dict_insert](
        BenchId("benchmark_dict_insert")
    )
    bench.bench_function[benchmark_dict_get](
        BenchId("benchmark_dict_get")
    )
    bench.bench_function[benchmark_dict_contains](
        BenchId("benchmark_dict_contains")
    )
    bench.dump_report()


def main():
    test_dict()
    run_all_dict_benchmarks()
