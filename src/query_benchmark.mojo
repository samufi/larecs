from benchmark import Bench, BenchConfig, Bencher, keep, BenchId
from custom_benchmark import DefaultBench
from world import World
from entity import Entity
from component import ComponentType, ComponentInfo
from test_utils import *


fn benchmark_new_entity_1_000_000(inout bencher: Bencher) raises capturing:
    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[Position, Velocity]()
        for _ in range(1_000_000):
            keep(world.new_entity().id)

    bencher.iter[bench_fn]()


fn benchmark_query_1_comp_1_000_000(
    inout bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[Position, Velocity]()
        for _ in range(1000):
            _ = world.new_entity(pos)
        for _ in range(1000):
            for entity in world.get_entities[Position]():
                keep(entity.get[Position]().x)

    bencher.iter[bench_fn]()


fn benchmark_query_2_comp_1_000_000(
    inout bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[Position, Velocity]()
        for _ in range(1000):
            _ = world.new_entity(pos, vel)
        for _ in range(1000):
            for entity in world.get_entities[Position, Velocity]():
                keep(entity.get[Position]().x)
                keep(entity.get[Velocity]().dx)

    bencher.iter[bench_fn]()


fn benchmark_query_5_comp_1_000_000(
    inout bencher: Bencher,
) raises capturing:
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)
    c3 = FlexibleComponent[3](7.0, 8.0)
    c4 = FlexibleComponent[4](9.0, 10.0)
    c5 = FlexibleComponent[5](11.0, 12.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = FullWorld()
        for _ in range(1000):
            _ = world.new_entity(c1, c2, c3, c4, c5)
        for _ in range(1000):
            for entity in world.get_entities[
                FlexibleComponent[1],
                FlexibleComponent[2],
                FlexibleComponent[3],
                FlexibleComponent[4],
                FlexibleComponent[5],
            ]():
                keep(entity.get[FlexibleComponent[1]]().x)
                keep(entity.get[FlexibleComponent[2]]().x)
                keep(entity.get[FlexibleComponent[3]]().x)
                keep(entity.get[FlexibleComponent[4]]().x)
                keep(entity.get[FlexibleComponent[5]]().x)

    bencher.iter[bench_fn]()


fn run_all_query_benchmarks() raises:
    bench = DefaultBench()
    run_all_query_benchmarks(bench)
    bench.dump_report()


fn run_all_query_benchmarks(inout bench: Bench) raises:
    bench.bench_function[benchmark_query_1_comp_1_000_000](
        BenchId("10^6 * query & get 1 comp")
    )
    bench.bench_function[benchmark_query_2_comp_1_000_000](
        BenchId("10^6 * query & get 2 comp")
    )
    bench.bench_function[benchmark_query_5_comp_1_000_000](
        BenchId("10^6 * query & get 5 comp")
    )


def main():
    run_all_query_benchmarks()
