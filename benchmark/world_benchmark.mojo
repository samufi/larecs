from world.entity_benchmark import run_all_world_entity_benchmarks
from world.access_benchmark import run_all_world_access_benchmarks
from world.component_single_benchmark import (
    run_all_world_component_single_benchmarks,
)
from world.component_single_batch_benchmark import (
    run_all_world_component_single_batch_benchmarks,
)
from world.component_multi_benchmark import (
    run_all_world_component_multi_benchmarks,
)
from world.replace_single_benchmark import (
    run_all_world_replace_single_benchmarks,
)
from world.replace_multi_benchmark import run_all_world_replace_multi_benchmarks
from std.benchmark import Bench
from custom_benchmark import DefaultBench


def run_all_world_benchmarks() raises:
    bench = DefaultBench()
    run_all_world_benchmarks(bench)
    bench.dump_report()


def run_all_world_benchmarks(mut bench: Bench) raises:
    run_all_world_entity_benchmarks(bench)
    run_all_world_access_benchmarks(bench)
    run_all_world_component_single_benchmarks(bench)
    run_all_world_component_single_batch_benchmarks(bench)
    run_all_world_component_multi_benchmarks(bench)
    run_all_world_replace_single_benchmarks(bench)
    run_all_world_replace_multi_benchmarks(bench)


def main() raises:
    run_all_world_benchmarks()
