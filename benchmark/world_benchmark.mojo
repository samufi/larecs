import world.entity_benchmark
import world.access_benchmark
import world.component_single_benchmark
import world.component_single_batch_benchmark
import world.component_multi_benchmark
import world.component_multi_batch_benchmark
import world.replace_single_benchmark
import world.replace_single_batch_benchmark
import world.replace_multi_benchmark
import world.replace_multi_batch_benchmark
from std.benchmark import Bench
from custom_benchmark import DefaultBench


def run_all_world_benchmarks() raises:
    bench = DefaultBench()
    run_all_world_benchmarks(bench)
    bench.dump_report()


def run_all_world_benchmarks(mut bench: Bench) raises:
    world.entity_benchmark.run_all_world_entity_benchmarks(bench)
    world.access_benchmark.run_all_world_access_benchmarks(bench)
    world.component_single_benchmark.run_all_world_component_single_benchmarks(bench)
    world.component_single_batch_benchmark.run_all_world_component_single_batch_benchmarks(bench)
    world.component_multi_benchmark.run_all_world_component_multi_benchmarks(bench)
    world.component_multi_batch_benchmark.run_all_world_component_multi_batch_benchmarks(bench)
    world.replace_single_benchmark.run_all_world_replace_single_benchmarks(bench)
    world.replace_single_batch_benchmark.run_all_world_replace_single_batch_benchmarks(bench)
    world.replace_multi_benchmark.run_all_world_replace_multi_benchmarks(bench)
    world.replace_multi_batch_benchmark.run_all_world_replace_multi_batch_benchmarks(bench)


def main() raises:
    run_all_world_benchmarks()
