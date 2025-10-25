from benchmark import Bench, BenchConfig, Bencher, keep, BenchId
from custom_benchmark import DefaultBench
from larecs.world import World
from larecs.entity import Entity
from larecs.component import ComponentType
from larecs.test_utils import *
from larecs import MutableEntityAccessor
from sys.info import simdwidthof
from algorithm import vectorize


fn benchmark_add_entity_1_000_000(mut bencher: Bencher) raises capturing:
    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        for _ in range(1_000_000):
            keep(world.add_entity().get_id())

    bencher.iter[bench_fn]()


fn benchmark_query_1_comp_1_000_000(
    mut bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        for _ in range(1000):
            _ = world.add_entity(pos)
        for _ in range(1000):
            for entity in world.query[Position]():
                keep(entity.get[Position]().x)

    bencher.iter[bench_fn]()


fn benchmark_vel_pos_add_1_000_000(
    mut bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        for _ in range(1000):
            _ = world.add_entity(pos, vel)
        for _ in range(1000):
            for entity in world.query[Position]():
                ref pos = entity.get[Position]()
                ref vel = entity.get[Velocity]()
                pos.x += vel.dx
                pos.y += vel.dy

    bencher.iter[bench_fn]()


fn benchmark_vel_pos_add_aos_1_000_000(
    mut bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        l1 = List[Position](length=1000, fill=pos)
        l2 = List[Velocity](length=1000, fill=vel)
        for _ in range(1000):
            for i in range(len(l1)):
                ref pos = l1[i]
                ref vel = l2[i]
                pos.x += vel.dx
                pos.y += vel.dy

    bencher.iter[bench_fn]()


# fn benchmark_vel_pos_add_aos_vec_1_000_000(
#     mut bencher: Bencher,
# ) raises capturing:
#     pos2 = Position(1.0, 2.0)
#     vel2 = Velocity(0.1, 0.2)
#     alias stride = 2


#     alias simd_width = simdwidthof[Float64]()

#     @always_inline
#     @parameter
#     fn bench_fn() capturing raises:
#         l1 = List[Position](length=1000, fill=pos2)
#         l2 = List[Velocity](length=1000, fill=vel2)

#         @parameter
#         fn move[simd_width: Int](i: Int):
#             try:
#                 pos = Pointer(to=l1[i])
#                 vel = Pointer(to=l2[i])
#             except:
#                 return

#             pos_x_ptr = UnsafePointer(to=pos[].x)
#             pos_y_ptr = UnsafePointer(to=pos[].y)
#             vel_x_ptr = UnsafePointer(to=vel[].dx)
#             vel_y_ptr = UnsafePointer(to=vel[].dy)

#             pos_x = pos_x_ptr.strided_load[width=simd_width](stride)
#             pos_y = pos_y_ptr.strided_load[width=simd_width](stride)
#             vel_x = vel_x_ptr.strided_load[width=simd_width](stride)
#             vel_y = vel_y_ptr.strided_load[width=simd_width](stride)

#             pos_x += vel_x
#             pos_y += vel_y
#             pos_x_ptr.strided_store[width=simd_width](pos_x, stride)
#             pos_y_ptr.strided_store[width=simd_width](pos_y, stride)

#         for _ in range(1000):
#             vectorize[move, simd_width](len(l1))

#     bencher.iter[bench_fn]()


fn benchmark_vel_pos_add_aos_vec_1_000_000(
    mut bencher: Bencher,
) raises capturing:
    pos2 = Position(1.0, 2.0)
    vel2 = Velocity(0.1, 0.2)
    alias stride = 2

    alias simd_width = simdwidthof[Float64]()

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        l1 = List[Position](length=1000, fill=pos2)
        l2 = List[Velocity](length=1000, fill=vel2)

        @parameter
        fn move[simd_width: Int](i: Int):
            # var pos_ptr = l1.unsafe_ptr().offset(i).bitcast[Float64]()
            var pos_ptr = UnsafePointer(to=l1[i]).bitcast[Float64]()
            var pos = pos_ptr.load[width=simd_width]()
            var vel = (
                l2.unsafe_ptr()
                .offset(i)
                .bitcast[Float64]()
                .load[width=simd_width]()
            )

            pos_ptr.store(pos + vel)

        for _ in range(1000):
            vectorize[move, simd_width // 2](len(l1))

    bencher.iter[bench_fn]()


@fieldwise_init
struct PosX(Copyable, Movable):
    var x: Float64


@fieldwise_init
struct PosY(Copyable, Movable):
    var y: Float64


@fieldwise_init
struct VelX(Copyable, Movable):
    var dx: Float64


@fieldwise_init
struct VelY(Copyable, Movable):
    var dy: Float64


fn benchmark_vel_pos_add_vec_optimized_1_000_000(
    mut bencher: Bencher,
) raises capturing:
    @parameter
    fn move[simd_width: Int](entity: MutableEntityAccessor):
        try:
            var pos_ptr = UnsafePointer(to=entity.get[Position]()).bitcast[
                Float64
            ]()
            var vel = (
                UnsafePointer(to=entity.get[Velocity]())
                .bitcast[Float64]()
                .load[width=simd_width]()
            )
            var pos = pos_ptr.load[width=simd_width]()
            pos_ptr.store(pos + vel)
        except:
            return

    alias simd_width = simdwidthof[Float64]()

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        _ = world.add_entities(
            Position(1.0, 2.0), Velocity(0.1, 0.2), count=1000
        )
        for _ in range(1000):
            world.apply[move, simd_width = simd_width // 2](
                world.query[Position, Velocity]()
            )

    bencher.iter[bench_fn]()


fn benchmark_vel_pos_add_vec_1_000_000(
    mut bencher: Bencher,
) raises capturing:
    @parameter
    fn move[simd_width: Int](entity: MutableEntityAccessor):
        try:
            var posX_ptr = UnsafePointer(to=entity.get[PosX]().x)
            var posX = posX_ptr.load[width=simd_width]()
            var velX = UnsafePointer(to=entity.get[VelX]().dx).load[
                width=simd_width
            ]()
            posX_ptr.store(posX + velX)

            var posY_ptr = UnsafePointer(to=entity.get[PosY]().y)
            var posY = posY_ptr.load[width=simd_width]()
            var velY = UnsafePointer(to=entity.get[VelY]().dy).load[
                width=simd_width
            ]()
            posY_ptr.store(posY + velY)

        except:
            return

    alias simd_width = simdwidthof[Float64]()

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[PosX, VelX, PosY, VelY]()
        _ = world.add_entities(
            PosX(1.0), VelX(0.1), PosY(2.0), VelY(0.2), count=1000
        )
        for _ in range(1000):
            world.apply[move, simd_width=simd_width](
                world.query[PosX, VelX, PosY, VelY]()
            )

    bencher.iter[bench_fn]()


fn benchmark_query_2_comp_1_000_000(
    mut bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)
    vel = Velocity(0.1, 0.2)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = SmallWorld()
        for _ in range(1000):
            _ = world.add_entity(pos, vel)
        for _ in range(1000):
            for entity in world.query[Position, Velocity]():
                keep(entity.get[Position]().x)
                keep(entity.get[Velocity]().dx)

    bencher.iter[bench_fn]()


fn benchmark_query_5_comp_1_000_000(
    mut bencher: Bencher,
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
            _ = world.add_entity(c1, c2, c3, c4, c5)
        for _ in range(1000):
            for entity in world.query[
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


fn benchmark_query_get_iter_1_000_000(
    mut bencher: Bencher,
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
        _ = world.add_entity(c1, c2, c3, c4, c5)
        for _ in range(1_000_000):
            keep(world.query[FlexibleComponent[1]]().__iter__()._lock)

    bencher.iter[bench_fn]()


fn benchmark_query_has_1_000_000(
    mut bencher: Bencher,
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
        _ = world.add_entity(c1, c2, c3, c4, c5)
        for entity in world.query[FlexibleComponent[1]]():
            for _ in range(1_000_000):
                keep(entity.has[FlexibleComponent[1]]())

    bencher.iter[bench_fn]()


fn run_all_query_benchmarks() raises:
    bench = DefaultBench()
    run_all_query_benchmarks(bench)
    bench.dump_report()


fn run_all_query_benchmarks(mut bench: Bench) raises:
    bench.bench_function[benchmark_query_has_1_000_000](
        BenchId("10^6 * query has")
    )
    bench.bench_function[benchmark_query_1_comp_1_000_000](
        BenchId("10^6 * query & get 1 comp")
    )
    bench.bench_function[benchmark_query_2_comp_1_000_000](
        BenchId("10^6 * query & get 2 comp")
    )
    bench.bench_function[benchmark_query_5_comp_1_000_000](
        BenchId("10^6 * query & get 5 comp")
    )
    bench.bench_function[benchmark_query_get_iter_1_000_000](
        BenchId("10^6 * get query iter")
    )
    bench.bench_function[benchmark_vel_pos_add_aos_1_000_000](
        BenchId("10^3 * 10^3 * pos vel add aos")
    )
    bench.bench_function[benchmark_vel_pos_add_1_000_000](
        BenchId("10^3 * 10^3 * pos vel add")
    )
    bench.bench_function[benchmark_vel_pos_add_aos_vec_1_000_000](
        BenchId("10^3 * 10^3 * pos vel add aos vec optimized")
    )
    bench.bench_function[benchmark_vel_pos_add_vec_1_000_000](
        BenchId("10^3 * 10^3 * pos vel add vec")
    )
    bench.bench_function[benchmark_vel_pos_add_vec_optimized_1_000_000](
        BenchId("10^3 * 10^3 * pos vel add vec optimized")
    )


def main():
    run_all_query_benchmarks()
