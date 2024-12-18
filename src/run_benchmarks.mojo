import bitmask_benchmark
import world_benchmark
import component_benchmark
from custom_benchmark import DefaultBench


def main():
    bench = DefaultBench()
    bitmask_benchmark.run_all_bitmask_benchmarks(bench)
    world_benchmark.run_all_world_benchmarks(bench)
    component_benchmark.run_all_component_benchmarks(bench)
    bench.dump_report()
