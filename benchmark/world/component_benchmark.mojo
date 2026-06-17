import world_component_single_benchmark
import world_component_single_batch_benchmark
import world_component_multi_benchmark
import world_component_multi_batch_benchmark
from std.benchmark import Bench
from custom_benchmark import DefaultBench


def run_all_world_component_benchmarks() raises:
    bench = DefaultBench()
    run_all_world_component_benchmarks(bench)
    bench.dump_report()


def run_all_world_component_benchmarks(mut bench: Bench) raises:
    world_component_single_benchmark.run_all_world_component_single_benchmarks(
        bench
    )
    world_component_single_batch_benchmark.run_all_world_component_single_batch_benchmarks(
        bench
    )
    world_component_multi_benchmark.run_all_world_component_multi_benchmarks(
        bench
    )
    world_component_multi_batch_benchmark.run_all_world_component_multi_batch_benchmarks(
        bench
    )


def main() raises:
    run_all_world_component_benchmarks()
