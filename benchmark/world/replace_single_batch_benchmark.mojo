from std.benchmark import Bench, Bencher, BenchId
from custom_benchmark import DefaultBench
from larecs.test_utils import *


def prevent_inlining_replace_batch() raises:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    world = SmallWorld()
    entity = world.add_entity(pos)
    _ = world.replace[Position]().by(vel, entity=entity)
    query = world.query[Position]().without[Velocity]()
    _ = world.replace[Position]().by(vel, query=query)


def benchmark_replace_1_comp_batch_1_000_000(
    mut bencher: Bencher,
):
    world = SmallWorld()
    _ = world.add_entities(FlexibleComponent[0](1.0, 2.0), count=1_000_000)

    @always_inline
    def bench_fn() {read, mut world}:
        try:
            _ = world.replace[FlexibleComponent[0]]().by(
                world.query[FlexibleComponent[0]](),
                FlexibleComponent[1](3.0, 4.0),
            )

            _ = world.replace[FlexibleComponent[1]]().by(
                world.query[FlexibleComponent[1]](),
                FlexibleComponent[0](1.0, 2.0),
            )

        except e:
            print(e)

    bencher.iter(bench_fn)


def benchmark_replace_1_comp_1_000_batch_1_000(
    mut bencher: Bencher,
):
    world = SmallWorld()
    _ = world.add_entities(FlexibleComponent[0](1.0, 2.0), count=1_000)

    @always_inline
    def bench_fn() {read, mut world}:
        try:
            for _ in range(500):
                _ = world.replace[FlexibleComponent[0]]().by(
                    world.query[FlexibleComponent[0]](),
                    FlexibleComponent[1](3.0, 4.0),
                )
                _ = world.replace[FlexibleComponent[1]]().by(
                    world.query[FlexibleComponent[1]](),
                    FlexibleComponent[0](1.0, 2.0),
                )

        except e:
            print(e)

    bencher.iter(bench_fn)


def run_all_world_replace_single_batch_benchmarks() raises:
    bench = DefaultBench()
    run_all_world_replace_single_batch_benchmarks(bench)
    bench.dump_report()


def run_all_world_replace_single_batch_benchmarks(mut bench: Bench) raises:
    bench.bench_function(
        benchmark_replace_1_comp_batch_1_000_000,
        BenchId("10^0 * replace 1 component 10^6 batch"),
    )
    bench.bench_function(
        benchmark_replace_1_comp_1_000_batch_1_000,
        BenchId("10^3 * replace 1 component 10^3 batch"),
    )
    prevent_inlining_replace_batch()
