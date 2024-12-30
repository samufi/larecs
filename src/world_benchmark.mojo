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


@value
struct FlexibleComponent[i: Int](ComponentType):
    var x: Float32
    var y: Float32


fn benchmark_new_entity_1_000_000(inout bencher: Bencher) raises capturing:
    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[Position, Velocity]()
        for _ in range(1_000_000):
            keep(world.new_entity().id)

    bencher.iter[bench_fn]()


fn benchmark_new_entity_1_comp_1_000_000(
    inout bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[Position, Velocity]()
        for _ in range(1_000_000):
            keep(world.new_entity(pos).id)

    bencher.iter[bench_fn]()


fn prevent_inlining_new_entity_1_comp() raises:
    pos = Position(1.0, 2.0)
    world = World[Position, Velocity]()
    _ = world.new_entity(pos)


fn benchmark_new_entity_5_comp_1_000_000(
    inout bencher: Bencher,
) raises capturing:
    c1 = FlexibleComponent[1](1.0, 2.0)
    c2 = FlexibleComponent[2](1.0, 2.0)
    c3 = FlexibleComponent[3](1.0, 2.0)
    c4 = FlexibleComponent[4](1.0, 2.0)
    c5 = FlexibleComponent[5](1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[
            FlexibleComponent[1],
            FlexibleComponent[2],
            FlexibleComponent[3],
            FlexibleComponent[4],
            FlexibleComponent[5],
        ]()
        for _ in range(1_000_000):
            keep(world.new_entity(c1, c2, c3, c4, c5).id)

    bencher.iter[bench_fn]()


fn prevent_inlining_new_entity_5_comp() raises:
    c1 = FlexibleComponent[1](1.0, 2.0)
    c2 = FlexibleComponent[2](1.0, 2.0)
    c3 = FlexibleComponent[3](1.0, 2.0)
    c4 = FlexibleComponent[4](1.0, 2.0)
    c5 = FlexibleComponent[5](1.0, 2.0)
    world = World[
        FlexibleComponent[1],
        FlexibleComponent[2],
        FlexibleComponent[3],
        FlexibleComponent[4],
        FlexibleComponent[5],
    ]()
    _ = world.new_entity(c1, c2, c3, c4, c5)


fn benchmark_get_1_000_000(inout bencher: Bencher) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[Position, Velocity]()
        entity = world.new_entity(pos, vel)
        for _ in range(1_000_000):
            keep(world.get[Position](entity).x)

    bencher.iter[bench_fn]()


fn prevent_inlining_get() raises:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    world = World[Position, Velocity]()
    entity = world.new_entity(pos, vel)
    keep(world.get[Position](entity).x)


fn benchmark_set_1_comp_1_000_000(inout bencher: Bencher) raises capturing:
    pos = Position(1.0, 2.0)
    pos2 = Position(2.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[Position, Velocity]()
        entity = world.new_entity(pos, vel)
        for _ in range(500_000):
            world.set(entity, pos2)
            world.set(entity, pos)

    bencher.iter[bench_fn]()


fn prevent_inlining_set_1_comp() raises:
    pos = Position(1.0, 2.0)
    pos2 = Position(2.0, 2.0)
    vel = Velocity(0.1, 0.2)
    world = World[Position, Velocity]()
    entity = world.new_entity(pos, vel)
    world.set(entity, pos2)
    world.set(entity, pos)


fn benchmark_set_5_comp_1_000_000(
    inout bencher: Bencher,
) raises capturing:
    c1 = FlexibleComponent[1](1.0, 2.0)
    c2 = FlexibleComponent[2](1.0, 2.0)
    c3 = FlexibleComponent[3](1.0, 2.0)
    c4 = FlexibleComponent[4](1.0, 2.0)
    c5 = FlexibleComponent[5](1.0, 2.0)

    c1_2 = FlexibleComponent[1](2.0, 4.0)
    c2_2 = FlexibleComponent[2](2.0, 4.0)
    c3_2 = FlexibleComponent[3](2.0, 4.0)
    c4_2 = FlexibleComponent[4](2.0, 4.0)
    c5_2 = FlexibleComponent[5](2.0, 4.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[
            FlexibleComponent[1],
            FlexibleComponent[2],
            FlexibleComponent[3],
            FlexibleComponent[4],
            FlexibleComponent[5],
        ]()
        entity = world.new_entity(c1, c2, c3, c4, c5)
        for _ in range(500_000):
            world.set(entity, c1_2, c2_2, c3_2, c4_2, c5_2)
            world.set(entity, c1, c2, c3, c4, c5)

    bencher.iter[bench_fn]()


fn prevent_inlining_set_5_comp() raises:
    c1 = FlexibleComponent[1](1.0, 2.0)
    c2 = FlexibleComponent[2](1.0, 2.0)
    c3 = FlexibleComponent[3](1.0, 2.0)
    c4 = FlexibleComponent[4](1.0, 2.0)
    c5 = FlexibleComponent[5](1.0, 2.0)

    c1_2 = FlexibleComponent[1](2.0, 4.0)
    c2_2 = FlexibleComponent[2](2.0, 4.0)
    c3_2 = FlexibleComponent[3](2.0, 4.0)
    c4_2 = FlexibleComponent[4](2.0, 4.0)
    c5_2 = FlexibleComponent[5](2.0, 4.0)

    world = World[
        FlexibleComponent[1],
        FlexibleComponent[2],
        FlexibleComponent[3],
        FlexibleComponent[4],
        FlexibleComponent[5],
    ]()
    entity = world.new_entity(c1, c2, c3, c4, c5)
    world.set(entity, c1_2, c2_2, c3_2, c4_2, c5_2)
    world.set(entity, c1, c2, c3, c4, c5)


fn benchmark_add_remove_entity_1_comp_1_000_000(
    inout bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[Position, Velocity]()
        for _ in range(1_000_000):
            entity = world.new_entity(pos)
            world.remove_entity(entity)

    bencher.iter[bench_fn]()


fn prevent_inlining_add_remove_entity_1_comp() raises:
    pos = Position(1.0, 2.0)
    world = World[Position, Velocity]()
    entity = world.new_entity(pos)
    world.remove_entity(entity)


fn benchmark_add_remove_entity_5_comp_1_000_000(
    inout bencher: Bencher,
) raises capturing:
    c1 = FlexibleComponent[1](1.0, 2.0)
    c2 = FlexibleComponent[2](1.0, 2.0)
    c3 = FlexibleComponent[3](1.0, 2.0)
    c4 = FlexibleComponent[4](1.0, 2.0)
    c5 = FlexibleComponent[5](1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[
            FlexibleComponent[1],
            FlexibleComponent[2],
            FlexibleComponent[3],
            FlexibleComponent[4],
            FlexibleComponent[5],
        ]()
        for _ in range(1_000_000):
            entity = world.new_entity(c1, c2, c3, c4, c5)
            world.remove_entity(entity)

    bencher.iter[bench_fn]()


fn prevent_inlining_add_remove_entity_5_comp() raises:
    c1 = FlexibleComponent[1](1.0, 2.0)
    c2 = FlexibleComponent[2](1.0, 2.0)
    c3 = FlexibleComponent[3](1.0, 2.0)
    c4 = FlexibleComponent[4](1.0, 2.0)
    c5 = FlexibleComponent[5](1.0, 2.0)

    world = World[
        FlexibleComponent[1],
        FlexibleComponent[2],
        FlexibleComponent[3],
        FlexibleComponent[4],
        FlexibleComponent[5],
    ]()
    entity = world.new_entity(c1, c2, c3, c4, c5)
    world.remove_entity(entity)


fn benchmark_has_1_000_000(inout bencher: Bencher) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[Position, Velocity]()
        entity = world.new_entity(pos, vel)
        for _ in range(1_000_000):
            keep(world.has[Position](entity))

    bencher.iter[bench_fn]()


fn benchmark_is_alive_1_000_000(inout bencher: Bencher) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[Position, Velocity]()
        entity = world.new_entity(pos, vel)
        for _ in range(1_000_000):
            keep(world.is_alive(entity))

    bencher.iter[bench_fn]()


fn benchmark_add_remove_1_comp_1_000_000(
    inout bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[Position, Velocity]()
        entity = world.new_entity(pos)
        for _ in range(1_000_000):
            world.add(entity, vel)
            world.remove[Velocity](entity)

    bencher.iter[bench_fn]()


fn prevent_inlining_add_remove_1_comp() raises:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    world = World[Position, Velocity]()
    entity = world.new_entity(pos)
    world.add(entity, vel)
    world.remove[Velocity](entity)


fn benchmark_add_remove_5_comp_1_000_000(
    inout bencher: Bencher,
) raises capturing:
    c1 = FlexibleComponent[1](1.0, 2.0)
    c2 = FlexibleComponent[2](1.0, 2.0)
    c3 = FlexibleComponent[3](1.0, 2.0)
    c4 = FlexibleComponent[4](1.0, 2.0)
    c5 = FlexibleComponent[5](1.0, 2.0)
    pos = Position(1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[
            Position,
            FlexibleComponent[1],
            FlexibleComponent[2],
            FlexibleComponent[3],
            FlexibleComponent[4],
            FlexibleComponent[5],
        ]()
        entity = world.new_entity(pos)
        for _ in range(1_000_000):
            world.add(entity, c1, c2, c3, c4, c5)
            world.remove[
                FlexibleComponent[1],
                FlexibleComponent[2],
                FlexibleComponent[3],
                FlexibleComponent[4],
                FlexibleComponent[5],
            ](entity)

    bencher.iter[bench_fn]()


fn prevent_inlining_add_remove_5_comp() raises:
    c1 = FlexibleComponent[1](1.0, 2.0)
    c2 = FlexibleComponent[2](1.0, 2.0)
    c3 = FlexibleComponent[3](1.0, 2.0)
    c4 = FlexibleComponent[4](1.0, 2.0)
    c5 = FlexibleComponent[5](1.0, 2.0)
    pos = Position(1.0, 2.0)

    world = World[
        Position,
        FlexibleComponent[1],
        FlexibleComponent[2],
        FlexibleComponent[3],
        FlexibleComponent[4],
        FlexibleComponent[5],
    ]()
    entity = world.new_entity(pos)
    world.add(entity, c1, c2, c3, c4, c5)
    world.remove[
        FlexibleComponent[1],
        FlexibleComponent[2],
        FlexibleComponent[3],
        FlexibleComponent[4],
        FlexibleComponent[5],
    ](entity)


fn benchmark_exchange_1_comp_1_000_000(
    inout bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[Position, Velocity]()
        entity = world.new_entity(pos)
        for _ in range(500_000):
            world.remove_and[Position]().add(entity, vel)
            world.remove_and[Velocity]().add(entity, pos)

    bencher.iter[bench_fn]()


fn prevent_inlining_exchange() raises:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    world = World[Position, Velocity]()
    entity = world.new_entity(vel)
    world.remove_and[Velocity]().add(entity, pos)
    world.remove_and[Position]().add(entity, vel)


fn run_all_world_benchmarks() raises:
    bench = DefaultBench()
    run_all_world_benchmarks(bench)
    bench.dump_report()


fn run_all_world_benchmarks(inout bench: Bench) raises:
    bench.bench_function[benchmark_new_entity_1_000_000](
        BenchId("10^6 * new_entity")
    )
    bench.bench_function[benchmark_new_entity_1_comp_1_000_000](
        BenchId("10^6 * new_entity 1 component")
    )
    bench.bench_function[benchmark_new_entity_5_comp_1_000_000](
        BenchId("10^6 * new_entity 5 components")
    )
    bench.bench_function[benchmark_add_remove_entity_1_comp_1_000_000](
        BenchId("10^6 * add & remove entity (1 component)")
    )
    bench.bench_function[benchmark_add_remove_entity_5_comp_1_000_000](
        BenchId("10^6 * add & remove entity (5 components)")
    )
    bench.bench_function[benchmark_get_1_000_000](BenchId("10^6 * get"))
    bench.bench_function[benchmark_set_1_comp_1_000_000](
        BenchId("10^6 * set 1 component")
    )
    bench.bench_function[benchmark_set_5_comp_1_000_000](
        BenchId("10^6 * set 5 components")
    )
    bench.bench_function[benchmark_has_1_000_000](BenchId("10^6 * has"))
    bench.bench_function[benchmark_is_alive_1_000_000](
        BenchId("10^6 * is_alive")
    )
    bench.bench_function[benchmark_add_remove_1_comp_1_000_000](
        BenchId("10^6 * add & remove 1 component")
    )
    bench.bench_function[benchmark_add_remove_5_comp_1_000_000](
        BenchId("10^6 * add & remove 5 components")
    )
    bench.bench_function[benchmark_exchange_1_comp_1_000_000](
        BenchId("10^6 * exchange 1 component")
    )

    # Functions to prevent inlining
    prevent_inlining_add_remove_entity_1_comp()
    prevent_inlining_add_remove_entity_5_comp()
    prevent_inlining_add_remove_1_comp()
    prevent_inlining_add_remove_5_comp()
    prevent_inlining_new_entity_1_comp()
    prevent_inlining_new_entity_5_comp()
    prevent_inlining_get()
    prevent_inlining_set_1_comp()
    prevent_inlining_set_5_comp()
    prevent_inlining_exchange()
    prevent_inlining_add_remove_5_comp()


def main():
    run_all_world_benchmarks()
