from std.benchmark import Bench, Bencher, BenchId
from custom_benchmark import DefaultBench
from larecs.test_utils import *


def prevent_inlining_add_remove_batch() raises:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    world = SmallWorld()
    _ = world.add_entities(pos, count=1)
    query = world.query[Position]().without[Velocity]()
    _ = world.add(query, vel)
    _ = world.remove[Position](query)


def benchmark_add_remove_1_comp_batch_1_000_000(
    mut bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)
    comp = FlexibleComponent[1](1.0, 42.0)

    @always_inline
    @parameter
    def bench_fn() capturing raises:
        world = SmallWorld()

        # create 1_000_000 entities that initially do not have FlexibleComponent[1]
        _ = world.add_entities(pos, count=1_000_000)

        _ = world.add(
            world.query[Position]().without[FlexibleComponent[1]](), comp
        )
        _ = world.remove[FlexibleComponent[1]](
            world.query[Position, FlexibleComponent[1]]()
        )

    bencher.iter[bench_fn]()


def benchmark_add_remove_1_comp_1_000_batch_1_000(
    mut bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)
    comp1 = FlexibleComponent[1](1.0, 42.0)

    @always_inline
    @parameter
    def bench_fn() capturing raises:
        world = SmallWorld()

        # create 1_000 entities that initially do not have FlexibleComponent[1]
        _ = world.add_entities(pos, count=1_000)
        # then 1_000 x add component and remove it afterwards
        for _ in range(1000):
            _ = world.add(
                world.query[Position]().without[FlexibleComponent[1]](),
                comp1,
            )
            _ = world.remove[FlexibleComponent[1]](
                world.query[Position, FlexibleComponent[1]]()
            )

    bencher.iter[bench_fn]()


def run_all_world_component_single_batch_benchmarks() raises:
    bench = DefaultBench()
    run_all_world_component_single_batch_benchmarks(bench)
    bench.dump_report()


def run_all_world_component_single_batch_benchmarks(mut bench: Bench) raises:
    bench.bench_function[benchmark_add_remove_1_comp_batch_1_000_000](
        BenchId("10^0 * add & remove 1 component 10^6 batch")
    )
    bench.bench_function[benchmark_add_remove_1_comp_1_000_batch_1_000](
        BenchId("10^3 * add & remove 1 component 10^3 batch")
    )
    prevent_inlining_add_remove_batch()


def main() raises:
    run_all_world_component_single_batch_benchmarks()
