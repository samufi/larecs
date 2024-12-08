from custom_benchmark import Bencher, keep, Bench, BenchId, BenchConfig
from world import World
from component import ComponentType, ComponentInfo
import benchmark


@value
struct Position(ComponentType):
    var x: Float32
    var y: Float32

    @staticmethod
    @always_inline
    fn get_type_identifier() -> Int:
        return 1


@value
struct Velocity(ComponentType):
    var dx: Float32
    var dy: Float32

    @staticmethod
    @always_inline
    fn get_type_identifier() -> Int:
        return 2


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


fn benchmark_new_entities_10_000() raises:
    world = World()
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    for _ in range(10_000):
        # keep(world.new_entity().id)
        keep(world.new_entity(pos, vel).id)


fn run_all_bitmask_benchmarks() raises:
    print("Running all bitmask benchmarks...")
    config = BenchConfig(min_runtime_secs=2, show_progress=True)
    bench = Bench(config)
    # bench.bench_function[benchmark_new_entities_10_000](
    #     BenchId("benchmark_new_entities_10_000")
    # )
    bench.dump_report()


def main():
    # run_all_bitmask_benchmarks()
    report = benchmark.run[benchmark_new_entities_10_000]()
    report.print()
