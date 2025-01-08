from benchmark import Bench, BenchConfig, Bencher, keep, BenchId
import random

from custom_benchmark import DefaultBench
from bitmask_benchmark import get_random_bitmask
from larecs.archetype import Archetype
from larecs.bitmask import BitMask


fn benchmark_archetype_bitmask_contains_1_000_000(
    mut bencher: Bencher,
) capturing:
    mask = get_random_bitmask()

    archetype = Archetype(0, mask, 10)

    @always_inline
    @parameter
    fn bench_fn() capturing:
        for _ in range(1_000_000):
            keep(archetype.get_mask().contains(mask))

    bencher.iter[bench_fn]()


fn run_all_archetype_benchmarks() raises:
    bench = DefaultBench()
    run_all_archetype_benchmarks(bench)
    bench.dump_report()


fn run_all_archetype_benchmarks(mut bench: Bench) raises:
    bench.bench_function[benchmark_archetype_bitmask_contains_1_000_000](
        BenchId("10^6 * archetype bitmask contains")
    )


fn main() raises:
    run_all_archetype_benchmarks()
