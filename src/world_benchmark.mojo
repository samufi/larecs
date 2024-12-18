from benchmark import Bench, BenchConfig, Bencher, keep, BenchId
from custom_benchmark import DefaultBench
from world import World
from component import ComponentType, ComponentInfo


@value
struct Position(ComponentType):
    var x: Float32
    var y: Float32


@value
struct Velocity(ComponentType):
    var dx: Float32
    var dy: Float32


# fn benchmark_new_entities_10_000(inout bencher: Bencher) capturing:
#     try:
#         world = World()
#     except:
#         print("Error")
#     pos = Position(1.0, 2.0)
#     vel = Velocity(0.1, 0.2)

#     @always_inline
#     @parameter
#     fn bench_fn(calls: Int) capturing -> Int:
#         try:
#             for _ in range(10_000):
#                 keep(world.new_entity(pos, vel).id)
#         except:
#             print("Error")
#         return 10_000

#     bencher.iter_custom[bench_fn]()


fn benchmark_new_entities_1_000_000(inout bencher: Bencher) raises capturing:
    world = World[Position, Velocity]()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        for _ in range(1_000_000):
            # keep(world.new_entity().id)
            # keep(world.new_entity(pos, vel).id)
            entity = world.new_entity(pos, vel)
            keep(world.get[Position](entity).x)

    bencher.iter[bench_fn]()


fn run_all_world_benchmarks() raises:
    bench = DefaultBench()
    run_all_world_benchmarks(bench)
    bench.dump_report()


fn run_all_world_benchmarks(inout bench: Bench) raises:
    # bench.bench_function[benchmark_new_entities_10_000](
    #     BenchId("benchmark_new_entities_10_000")
    # )
    bench.bench_function[benchmark_new_entities_1_000_000](
        BenchId("10^6 * new_entities")
    )


def main():
    run_all_world_benchmarks()
