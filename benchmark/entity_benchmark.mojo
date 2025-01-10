from benchmark import Bencher, Bench, keep, BenchId
from custom_benchmark import DefaultBench
from larecs.entity import Entity


fn benchmark_entity_is_zero(mut bencher: Bencher) capturing:
    e = Entity()

    @parameter
    fn bench_fn(calls: Int) capturing -> Int:
        for _ in range(calls):
            keep(e.is_zero())
        return calls

    bencher.iter_custom[bench_fn]()


fn run_all_entity_benchmarks() raises:
    bench = DefaultBench()
    run_all_entity_benchmarks(bench)
    bench.dump_report()


fn run_all_entity_benchmarks(mut bench: Bench) raises:
    bench.bench_function[benchmark_entity_is_zero](
        BenchId("10^6 * entity is zero")
    )


def main():
    run_all_entity_benchmarks()
