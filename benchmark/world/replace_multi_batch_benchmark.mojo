from std.benchmark import Bench, Bencher, BenchId
from custom_benchmark import DefaultBench
from larecs.test_utils import *
from larecs.entity import Entity


def benchmark_replace_5_comp_batch_1_000_000(
    mut bencher: Bencher,
):
    @always_inline
    def bench_fn():
        try:
            world = SmallWorld()
            _ = world.add_entities(
                FlexibleComponent[0](1.0, 2.0),
                FlexibleComponent[1](3.0, 4.0),
                FlexibleComponent[2](5.0, 6.0),
                FlexibleComponent[3](7.0, 8.0),
                FlexibleComponent[4](9.0, 10.0),
                count=1_000_000,
            )

            _ = world.replace[
                FlexibleComponent[0],
                FlexibleComponent[1],
                FlexibleComponent[2],
                FlexibleComponent[3],
                FlexibleComponent[4],
            ]().by(
                world.query[
                    FlexibleComponent[0],
                    FlexibleComponent[1],
                    FlexibleComponent[2],
                    FlexibleComponent[3],
                    FlexibleComponent[4],
                ](),
                FlexibleComponent[5](11.0, 12.0),
                FlexibleComponent[6](13.0, 14.0),
                FlexibleComponent[7](15.0, 16.0),
                FlexibleComponent[8](17.0, 18.0),
                FlexibleComponent[9](19.0, 20.0),
            )
        except e:
            print(e)

    bencher.iter(bench_fn)


def benchmark_replace_5_comp_1_000_batch_1_000(
    mut bencher: Bencher,
):
    @always_inline
    def bench_fn():
        try:
            world = SmallWorld()
            _ = world.add_entities(
                FlexibleComponent[0](1.0, 2.0),
                FlexibleComponent[1](3.0, 4.0),
                FlexibleComponent[2](5.0, 6.0),
                FlexibleComponent[3](7.0, 8.0),
                FlexibleComponent[4](9.0, 10.0),
                count=1_000,
            )

            for _ in range(500):
                entity56789 = world.add_entity(
                    FlexibleComponent[5](11.0, 12.0),
                    FlexibleComponent[6](13.0, 14.0),
                    FlexibleComponent[7](15.0, 16.0),
                    FlexibleComponent[8](17.0, 18.0),
                    FlexibleComponent[9](19.0, 20.0),
                )  # make sure target archetype has already one entity to not take optimized path for empty archetype
                _ = world.replace[
                    FlexibleComponent[0],
                    FlexibleComponent[1],
                    FlexibleComponent[2],
                    FlexibleComponent[3],
                    FlexibleComponent[4],
                ]().by(
                    world.query[
                        FlexibleComponent[0],
                        FlexibleComponent[1],
                        FlexibleComponent[2],
                        FlexibleComponent[3],
                        FlexibleComponent[4],
                    ](),
                    FlexibleComponent[5](11.0, 12.0),
                    FlexibleComponent[6](13.0, 14.0),
                    FlexibleComponent[7](15.0, 16.0),
                    FlexibleComponent[8](17.0, 18.0),
                    FlexibleComponent[9](19.0, 20.0),
                )
                world.remove_entity(
                    entity56789
                )  # cleanup deoptimization entity to not increase amount of entities moved during replace in next iterations
                entity01234 = world.add_entity(
                    FlexibleComponent[0](1.0, 2.0),
                    FlexibleComponent[1](3.0, 4.0),
                    FlexibleComponent[2](5.0, 6.0),
                    FlexibleComponent[3](7.0, 8.0),
                    FlexibleComponent[4](9.0, 10.0),
                )  # make sure target archetype has already one entity to not take optimized path for empty archetype
                _ = world.replace[
                    FlexibleComponent[5],
                    FlexibleComponent[6],
                    FlexibleComponent[7],
                    FlexibleComponent[8],
                    FlexibleComponent[9],
                ]().by(
                    world.query[
                        FlexibleComponent[5],
                        FlexibleComponent[6],
                        FlexibleComponent[7],
                        FlexibleComponent[8],
                        FlexibleComponent[9],
                    ](),
                    FlexibleComponent[0](1.0, 2.0),
                    FlexibleComponent[1](3.0, 4.0),
                    FlexibleComponent[2](5.0, 6.0),
                    FlexibleComponent[3](7.0, 8.0),
                    FlexibleComponent[4](9.0, 0.0),
                )
                world.remove_entity(
                    entity01234
                )  # cleanup deoptimization entity to not increase amount of entities moved during replace in next iterations
        except e:
            print(e)

    bencher.iter(bench_fn)


def benchmark_replace_1_comp_1_000_000_extra(
    mut bencher: Bencher,
):
    pos = Position(1.0, 2.0)

    @always_inline
    def bench_fn() {read}:
        try:
            world = SmallWorld()
            entities = List[Entity]()
            for _ in range(1000):
                entities.append(world.add_entity(pos))
        except e:
            print(e)

    bencher.iter(bench_fn)


def run_all_world_replace_multi_batch_benchmarks() raises:
    bench = DefaultBench()
    run_all_world_replace_multi_batch_benchmarks(bench)
    bench.dump_report()


def run_all_world_replace_multi_batch_benchmarks(mut bench: Bench) raises:
    bench.bench_function(
        benchmark_replace_5_comp_batch_1_000_000,
        BenchId("10^0 * replace 5 components 10^6 batch"),
    )
    bench.bench_function(
        benchmark_replace_5_comp_1_000_batch_1_000,
        BenchId("10^3 * replace 5 components 10^3 batch"),
    )


def main() raises:
    run_all_world_replace_multi_batch_benchmarks()
