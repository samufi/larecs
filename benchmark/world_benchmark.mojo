from benchmark import Bench, BenchConfig, Bencher, keep, BenchId
from custom_benchmark import DefaultBench
from larecs.test_utils import *
from larecs.world import World
from larecs.entity import Entity
from larecs.component import ComponentType
from larecs import MutableEntityAccessor


fn benchmark_add_entity_1_000_000(mut bencher: Bencher) raises capturing:
    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        for _ in range(1_000_000):
            keep(world.add_entity().get_id())

    bencher.iter[bench_fn]()


fn benchmark_add_entities_1_000_batch_1_000(
    mut bencher: Bencher,
) raises capturing:
    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        for _ in range(1_000):
            keep(Bool(world.add_entities(count=1000)))

    bencher.iter[bench_fn]()


fn benchmark_add_entity_1_comp_1_000_000(
    mut bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        for _ in range(1_000_000):
            keep(world.add_entity(pos).get_id())

    bencher.iter[bench_fn]()


fn benchmark_add_entities_1_comp_1_000_batch_1_000(
    mut bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        for _ in range(1_000):
            keep(Bool(world.add_entities(pos, count=1000)))

    bencher.iter[bench_fn]()


fn prevent_inlining_add_entity_1_comp() raises:
    pos = Position(1.0, 2.0)
    world = SmallWorld()
    _ = world.add_entity(pos)
    _ = world.add_entities(pos, count=1)


fn benchmark_add_entities_5_comp_1_000_000(
    mut bencher: Bencher,
) raises capturing:
    c1 = FlexibleComponent[1](1.0, 2.0)
    c2 = FlexibleComponent[2](1.0, 2.0)
    c3 = FlexibleComponent[3](1.0, 2.0)
    c4 = FlexibleComponent[4](1.0, 2.0)
    c5 = FlexibleComponent[5](1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        for _ in range(1_000_000):
            keep(world.add_entity(c1, c2, c3, c4, c5).get_id())

    bencher.iter[bench_fn]()


fn benchmark_add_entity_5_comp_1_000_batch_1_000(
    mut bencher: Bencher,
) raises capturing:
    c1 = FlexibleComponent[1](1.0, 2.0)
    c2 = FlexibleComponent[2](1.0, 2.0)
    c3 = FlexibleComponent[3](1.0, 2.0)
    c4 = FlexibleComponent[4](1.0, 2.0)
    c5 = FlexibleComponent[5](1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        for _ in range(1_000):
            keep(Bool(world.add_entities(c1, c2, c3, c4, c5, count=1000)))

    bencher.iter[bench_fn]()


fn prevent_inlining_add_entity_5_comp() raises:
    c1 = FlexibleComponent[1](1.0, 2.0)
    c2 = FlexibleComponent[2](1.0, 2.0)
    c3 = FlexibleComponent[3](1.0, 2.0)
    c4 = FlexibleComponent[4](1.0, 2.0)
    c5 = FlexibleComponent[5](1.0, 2.0)
    world = SmallWorld()
    _ = world.add_entity(c1, c2, c3, c4, c5)
    _ = world.add_entities(c1, c2, c3, c4, c5, count=1)


fn benchmark_get_1_000_000(mut bencher: Bencher) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        entity = world.add_entity(pos, vel)
        for _ in range(1_000_000):
            keep(world.get[Position](entity).x)

    bencher.iter[bench_fn]()


fn prevent_inlining_get() raises:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    world = SmallWorld()
    entity = world.add_entity(pos, vel)
    keep(world.get[Position](entity).x)


fn benchmark_get_ptr_1_000_000(mut bencher: Bencher) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        entity = world.add_entity(pos, vel)
        for _ in range(1_000_000):
            keep(world.get_ptr[Position](entity)[].x)

    bencher.iter[bench_fn]()


fn prevent_inlining_get_ptr() raises:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    world = SmallWorld()
    entity = world.add_entity(pos, vel)
    keep(world.get_ptr[Position](entity)[].x)


fn benchmark_set_1_comp_1_000_000(mut bencher: Bencher) raises capturing:
    pos = Position(1.0, 2.0)
    pos2 = Position(2.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        entity = world.add_entity(pos, vel)
        for _ in range(500_000):
            world.set(entity, pos2)
            world.set(entity, pos)

    bencher.iter[bench_fn]()


fn prevent_inlining_set_1_comp() raises:
    pos = Position(1.0, 2.0)
    pos2 = Position(2.0, 2.0)
    vel = Velocity(0.1, 0.2)
    world = SmallWorld()
    entity = world.add_entity(pos, vel)
    world.set(entity, pos2)
    world.set(entity, pos)


fn benchmark_set_5_comp_1_000_000(
    mut bencher: Bencher,
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
        world = SmallWorld()
        entity = world.add_entity(c1, c2, c3, c4, c5)
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

    world = SmallWorld()
    entity = world.add_entity(c1, c2, c3, c4, c5)
    world.set(entity, c1_2, c2_2, c3_2, c4_2, c5_2)
    world.set(entity, c1, c2, c3, c4, c5)


from math import exp


fn benchmark_apply_expexp_1_comp_100_000(
    mut bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        for _ in range(1_000):
            _ = world.add_entity(pos, vel)

        @always_inline
        @parameter
        fn operation_plus(accessor: MutableEntityAccessor) capturing:
            try:
                pos2 = accessor.get_ptr[Position]()
                pos2[].x = exp(1 - exp(pos2[].x))
                pos2[].y = exp(1 - exp(pos2[].y))
            except:
                pass

        for _ in range(100):
            world.apply[operation_plus, unroll_factor=3](
                world.query[Position]()
            )

    bencher.iter[bench_fn]()


fn benchmark_apply_simd_expexp_1_comp_100_000(
    mut bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        for _ in range(1_000):
            _ = world.add_entity(pos, vel)

        @always_inline
        @parameter
        fn operation_plus[
            simd_width: Int
        ](accessor: MutableEntityAccessor) capturing:
            alias _load = load2[simd_width]
            alias _store = store2[simd_width]

            try:
                pos2 = accessor.get_ptr[Position]()

                _store(pos2[].x, exp(1 - exp(_load(pos2[].x))))
                _store(pos2[].y, exp(1 - exp(_load(pos2[].y))))
            except:
                pass

        for _ in range(100):
            world.apply[
                operation_plus,
                simd_width=16,
                unroll_factor=3,
            ](world.query[Position, Velocity]())

    bencher.iter[bench_fn]()


fn benchmark_add_remove_entity_1_comp_1_000_000(
    mut bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        entities = List[Entity]()
        for _ in range(1000):
            for _ in range(1000):
                entities.append(world.add_entity(pos))
            for entity in entities:
                world.remove_entity(entity[])
            entities.clear()

    bencher.iter[bench_fn]()


fn benchmark_add_remove_entities_1_comp_1_000_batch_1000(
    mut bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        for _ in range(1000):
            _ = world.add_entities(pos, count=1000)
            world.remove_entities(world.query[Position]())

    bencher.iter[bench_fn]()


fn prevent_inlining_add_remove_entity_1_comp() raises:
    pos = Position(1.0, 2.0)
    world = SmallWorld()
    entity = world.add_entity(pos)
    world.remove_entity(entity)
    world.remove_entities(world.query[Position]())


fn benchmark_add_remove_entity_5_comp_1_000_000(
    mut bencher: Bencher,
) raises capturing:
    c1 = LargerComponent(1.0, 2.0, 3.0)
    c2 = FlexibleComponent[2](1.0, 2.0)
    c3 = FlexibleComponent[3](1.0, 2.0)
    c4 = FlexibleComponent[4](1.0, 2.0)
    c5 = FlexibleComponent[5](1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        _ = world.add_entity(c3, c5)
        # world = FullWorld()

        entities = List[Entity]()
        for _ in range(1000):
            for _ in range(1000):
                entities.append(world.add_entity(c1, c2, c3, c4, c5))
            e = world.add_entity(c3, c5)
            for entity in entities:
                world.remove_entity(entity[])
            world.remove_entity(e)
            entities.clear()

    bencher.iter[bench_fn]()


fn benchmark_add_remove_entities_5_comp_1_000_batch_1_000(
    mut bencher: Bencher,
) raises capturing:
    c1 = LargerComponent(1.0, 2.0, 3.0)
    c2 = FlexibleComponent[2](1.0, 2.0)
    c3 = FlexibleComponent[3](1.0, 2.0)
    c4 = FlexibleComponent[4](1.0, 2.0)
    c5 = FlexibleComponent[5](1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        for _ in range(1000):
            _ = world.add_entities(c1, c2, c3, c4, c5, count=1000)
            world.remove_entities(
                world.query[
                    LargerComponent,
                    FlexibleComponent[2],
                    FlexibleComponent[3],
                    FlexibleComponent[4],
                    FlexibleComponent[5],
                ]()
            )

    bencher.iter[bench_fn]()


fn prevent_inlining_add_remove_entity_5_comp() raises:
    c1 = FlexibleComponent[1](1.0, 2.0)
    c2 = FlexibleComponent[2](1.0, 2.0)
    c3 = FlexibleComponent[3](1.0, 2.0)
    c4 = FlexibleComponent[4](1.0, 2.0)
    c5 = FlexibleComponent[5](1.0, 2.0)

    world = SmallWorld()
    entity = world.add_entity(c1, c2, c3, c4, c5)
    world.remove_entity(entity)
    entity = world.add_entity(c1, c2, c3, c4, c5)
    world.remove_entities(
        world.query[
            LargerComponent,
            FlexibleComponent[2],
            FlexibleComponent[3],
            FlexibleComponent[4],
            FlexibleComponent[5],
        ]()
    )


fn benchmark_has_1_000_000(mut bencher: Bencher) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        entity = world.add_entity(pos, vel)
        for _ in range(1_000_000):
            keep(world.has[Position](entity))

    bencher.iter[bench_fn]()


fn benchmark_is_alive_1_000_000(mut bencher: Bencher) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        entity = world.add_entity(pos, vel)
        for _ in range(1_000_000):
            keep(world.is_alive(entity))

    bencher.iter[bench_fn]()


fn benchmark_add_remove_1_comp_1_000_000(
    mut bencher: Bencher,
) raises capturing:
    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        for _ in range(50):
            world = FullWorld()
            entities = List[Entity]()
            component0 = FlexibleComponent[0](1.0, 2.0)
            for _ in range(1000):
                entities.append(world.add_entity(component0))

            @parameter
            for i in range(20):
                component = FlexibleComponent[i + 1](i, 2.0)
                for entity in entities:
                    world.add(entity[], component)
                for entity in entities:
                    world.remove[FlexibleComponent[i]](entity[])

    bencher.iter[bench_fn]()


fn prevent_inlining_add_remove_1_comp() raises:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)
    world = SmallWorld()
    entity = world.add_entity(pos)
    world.add(entity, vel)
    world.remove[Velocity](entity)


fn benchmark_add_remove_5_comp_1_000_000(
    mut bencher: Bencher,
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
        world = SmallWorld()
        entity = world.add_entity(pos)
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

    world = SmallWorld()
    entity = world.add_entity(pos)
    world.add(entity, c1, c2, c3, c4, c5)
    world.remove[
        FlexibleComponent[1],
        FlexibleComponent[2],
        FlexibleComponent[3],
        FlexibleComponent[4],
        FlexibleComponent[5],
    ](entity)


fn benchmark_replace_1_comp_1_000_000(
    mut bencher: Bencher,
) raises capturing:
    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        for _ in range(50):
            world = FullWorld()
            entities = List[Entity]()
            component0 = FlexibleComponent[0](1.0, 2.0)
            for _ in range(1000):
                entities.append(world.add_entity(component0))

            @parameter
            for i in range(20):
                component = FlexibleComponent[i + 1](i, 2.0)
                for entity in entities:
                    world.replace[FlexibleComponent[i]]().by(
                        entity[], component
                    )

    bencher.iter[bench_fn]()


fn benchmark_replace_1_comp_1_000_000_extra(
    mut bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        entities = List[Entity]()
        for _ in range(1000):
            entities.append(world.add_entity(pos))

    bencher.iter[bench_fn]()


fn prevent_inlining_replace() raises:
    world = FullWorld()
    entity = world.add_entity(FlexibleComponent[0](1.0, 2.0))

    @parameter
    for i in range(20):
        component = FlexibleComponent[i + 1](i, 2.0)
        world.replace[FlexibleComponent[i]]().by(entity, component)


fn run_all_world_benchmarks() raises:
    bench = DefaultBench()
    run_all_world_benchmarks(bench)
    bench.dump_report()


fn run_all_world_benchmarks(mut bench: Bench) raises:
    bench.bench_function[benchmark_add_entity_1_000_000](
        BenchId("10^6 * add_entity")
    )
    bench.bench_function[benchmark_add_entities_1_000_batch_1_000](
        BenchId("10^3 * add_entity 1000 batch")
    )
    bench.bench_function[benchmark_add_entity_1_comp_1_000_000](
        BenchId("10^6 * add_entity 1 component")
    )
    bench.bench_function[benchmark_add_entities_1_comp_1_000_batch_1_000](
        BenchId("10^3 * add_entity 1 component 1000 batch")
    )
    bench.bench_function[benchmark_add_entities_5_comp_1_000_000](
        BenchId("10^6 * add_entity 5 components")
    )
    bench.bench_function[benchmark_add_entity_5_comp_1_000_batch_1_000](
        BenchId("10^3 * add_entity 5 components 1000 batch")
    )
    bench.bench_function[benchmark_add_remove_entity_1_comp_1_000_000](
        BenchId("10^6 * add & remove entity (1 component)")
    )
    bench.bench_function[benchmark_add_remove_entities_1_comp_1_000_batch_1000](
        BenchId("10^3 * add & remove entity (1 component) 1000 batch")
    )
    bench.bench_function[benchmark_add_remove_entity_5_comp_1_000_000](
        BenchId("10^6 * add & remove entity (5 components)")
    )
    bench.bench_function[
        benchmark_add_remove_entities_5_comp_1_000_batch_1_000
    ](BenchId("10^3 * add & remove entity (5 components) 1000 batch"))
    bench.bench_function[benchmark_get_1_000_000](BenchId("10^6 * get"))
    bench.bench_function[benchmark_get_ptr_1_000_000](BenchId("10^6 * get_ptr"))
    bench.bench_function[benchmark_set_1_comp_1_000_000](
        BenchId("10^6 * set 1 component")
    )
    bench.bench_function[benchmark_set_5_comp_1_000_000](
        BenchId("10^6 * set 5 components")
    )
    bench.bench_function[benchmark_apply_expexp_1_comp_100_000](
        BenchId("10^5 * get and set exp(exp) via apply 1 component")
    )
    bench.bench_function[benchmark_apply_simd_expexp_1_comp_100_000](
        BenchId("10^5 * get and set exp(exp) via apply simd 1 component")
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
    bench.bench_function[benchmark_replace_1_comp_1_000_000](
        BenchId("10^6 * replace 1 component")
    )

    # Functions to prevent inlining
    prevent_inlining_add_remove_entity_1_comp()
    prevent_inlining_add_remove_entity_5_comp()
    prevent_inlining_add_remove_1_comp()
    prevent_inlining_add_remove_5_comp()
    prevent_inlining_add_entity_1_comp()
    prevent_inlining_add_entity_5_comp()
    prevent_inlining_get()
    prevent_inlining_get_ptr()
    prevent_inlining_set_1_comp()
    prevent_inlining_set_5_comp()
    prevent_inlining_replace()
    prevent_inlining_add_remove_5_comp()


def main():
    run_all_world_benchmarks()
