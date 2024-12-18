from benchmark import Bencher, Bench, keep, BenchId

from custom_benchmark import DefaultBench
from dict_test import get_random_bitmask_list
from stupid_dict import StupidDict
from bitmask import BitMask


fn benchmark_dict_insert_1000(inout bencher: Bencher) capturing:
    bitmasks = get_random_bitmask_list(1000)
    dict = StupidDict[BitMask, Int]()

    @always_inline
    @parameter
    fn bench_fn() capturing:
        for i in range(1000):
            dict[bitmasks[i]] = i

    bencher.iter[bench_fn]()


fn benchmark_dict_get_1000(inout bencher: Bencher) capturing:
    bitmasks = get_random_bitmask_list(1000)
    bitmask_count = len(bitmasks)

    dict = StupidDict[BitMask, Int]()
    for i in range(bitmask_count):
        dict[bitmasks[i]] = i

    bitmasks = get_random_bitmask_list(10000, 0, 2000)
    bitmask_count = len(bitmasks)

    @always_inline
    @parameter
    fn bench_fn() capturing:
        for i in range(bitmask_count):
            try:
                keep(dict[bitmasks[i]])
            except:
                pass

    bencher.iter[bench_fn]()


fn benchmark_dict_contains_1000(inout bencher: Bencher) capturing:
    bitmasks = get_random_bitmask_list(1000)
    bitmask_count = len(bitmasks)

    dict = StupidDict[BitMask, Int]()
    for i in range(bitmask_count):
        dict[bitmasks[i]] = i

    bitmasks = get_random_bitmask_list(10000, 0, 2000)
    bitmask_count = len(bitmasks)

    @always_inline
    @parameter
    fn bench_fn() capturing:
        for i in range(bitmask_count):
            keep(bitmasks[i] in dict)

    bencher.iter[bench_fn]()


fn run_all_dict_benchmarks() raises:
    bench = DefaultBench()
    run_all_dict_benchmarks(bench)
    bench.dump_report()


fn run_all_dict_benchmarks(inout bench: Bench) raises:
    bench.bench_function[benchmark_dict_insert_1000](
        BenchId("10^3 * dict_insert")
    )
    bench.bench_function[benchmark_dict_get_1000](BenchId("10^3 * dict_get"))
    bench.bench_function[benchmark_dict_contains_1000](
        BenchId("10^3 * dict_contains")
    )


def main():
    run_all_dict_benchmarks()
