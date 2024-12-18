import bitmask_test
import world_benchmark
import component_benchmark


def main():
    bitmask_test.run_all_bitmask_benchmarks()
    world_benchmark.run_all_world_benchmarks()
    component_benchmark.run_all_component_benchmarks()
