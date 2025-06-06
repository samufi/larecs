from benchmark import Bencher, Bench, keep, BenchId
from custom_benchmark import DefaultBench
from larecs import Resources


@value
struct TestResource[size: Int = 1000]:
    var _storage: InlineArray[Float64, size]

    fn __init__(out self, value: Float64 = 0):
        self._storage = InlineArray[Float64, size](value)


fn benchmark_add_remove_resource_1_000(mut bencher: Bencher) raises capturing:
    resources = Resources()

    @parameter
    @always_inline
    fn bench_fn() capturing:
        test_resource = TestResource()
        for _ in range(1_000):
            try:
                resources.add(test_resource)
                resources.remove[TestResource]()
            except:
                pass

    bencher.iter[bench_fn]()


fn benchmark_get_resource_1_000(mut bencher: Bencher) raises capturing:
    resources = Resources()

    resources.add(TestResource())

    @parameter
    @always_inline
    fn bench_fn() capturing:
        for _ in range(1_000):
            try:
                keep(resources.get[TestResource]()._storage[0])
            except:
                pass

    bencher.iter[bench_fn]()


fn run_all_resource_benchmarks() raises:
    bench = DefaultBench()
    run_all_resource_benchmarks(bench)
    bench.dump_report()


fn run_all_resource_benchmarks(mut bench: Bench) raises:
    bench.bench_function[benchmark_add_remove_resource_1_000](
        BenchId("10^3 * add + remove resource (1000 Float64)")
    )
    bench.bench_function[benchmark_get_resource_1_000](
        BenchId("10^3 * get resource (1000 Float64)")
    )


def main():
    run_all_resource_benchmarks()
