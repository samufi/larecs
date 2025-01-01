from benchmark import Bench, BenchConfig, Bencher, keep, BenchId
from custom_benchmark import DefaultBench
from world import World
from entity import Entity
from component import ComponentType, ComponentInfo


@value
struct Position(ComponentType):
    var x: Float64
    var y: Float64


@value
struct Velocity(ComponentType):
    var dx: Float64
    var dy: Float64


@value
struct FlexibleComponent[i: Int](ComponentType):
    var x: Float64
    var y: Float64


alias FullWorld = World[
    Position,
    Velocity,
    FlexibleComponent[0],
    FlexibleComponent[1],
    FlexibleComponent[2],
    FlexibleComponent[3],
    FlexibleComponent[4],
    FlexibleComponent[5],
    FlexibleComponent[6],
    FlexibleComponent[7],
    FlexibleComponent[8],
    FlexibleComponent[9],
    FlexibleComponent[10],
    FlexibleComponent[11],
    FlexibleComponent[12],
    FlexibleComponent[13],
    FlexibleComponent[14],
    FlexibleComponent[15],
    FlexibleComponent[16],
    FlexibleComponent[17],
    FlexibleComponent[18],
    FlexibleComponent[19],
    FlexibleComponent[20],
    FlexibleComponent[21],
    FlexibleComponent[22],
    FlexibleComponent[23],
    FlexibleComponent[24],
    FlexibleComponent[25],
    FlexibleComponent[26],
    FlexibleComponent[27],
    FlexibleComponent[28],
    FlexibleComponent[29],
    FlexibleComponent[30],
    FlexibleComponent[31],
    FlexibleComponent[32],
    FlexibleComponent[33],
    FlexibleComponent[34],
    FlexibleComponent[35],
    FlexibleComponent[36],
    FlexibleComponent[37],
    FlexibleComponent[38],
    FlexibleComponent[39],
    FlexibleComponent[40],
    FlexibleComponent[41],
    FlexibleComponent[42],
    FlexibleComponent[43],
    FlexibleComponent[44],
    FlexibleComponent[45],
    FlexibleComponent[46],
    FlexibleComponent[47],
    FlexibleComponent[48],
    FlexibleComponent[49],
    FlexibleComponent[50],
    FlexibleComponent[51],
    FlexibleComponent[52],
    FlexibleComponent[53],
    FlexibleComponent[54],
    FlexibleComponent[55],
    FlexibleComponent[56],
    FlexibleComponent[57],
    FlexibleComponent[58],
    FlexibleComponent[59],
    FlexibleComponent[60],
    FlexibleComponent[61],
    FlexibleComponent[62],
    FlexibleComponent[63],
    FlexibleComponent[64],
    FlexibleComponent[65],
    FlexibleComponent[66],
    FlexibleComponent[67],
    FlexibleComponent[68],
    FlexibleComponent[69],
    FlexibleComponent[70],
    FlexibleComponent[71],
    FlexibleComponent[72],
    FlexibleComponent[73],
    FlexibleComponent[74],
    FlexibleComponent[75],
    FlexibleComponent[76],
    FlexibleComponent[77],
    FlexibleComponent[78],
    FlexibleComponent[79],
    FlexibleComponent[80],
    FlexibleComponent[81],
    FlexibleComponent[82],
    FlexibleComponent[83],
    FlexibleComponent[84],
    FlexibleComponent[85],
    FlexibleComponent[86],
    FlexibleComponent[87],
    FlexibleComponent[88],
    FlexibleComponent[89],
    FlexibleComponent[90],
    FlexibleComponent[91],
    FlexibleComponent[92],
    FlexibleComponent[93],
    FlexibleComponent[94],
    FlexibleComponent[95],
    FlexibleComponent[96],
    FlexibleComponent[97],
    FlexibleComponent[98],
    FlexibleComponent[99],
    FlexibleComponent[100],
    FlexibleComponent[101],
    FlexibleComponent[102],
    FlexibleComponent[103],
    FlexibleComponent[104],
    FlexibleComponent[105],
    FlexibleComponent[106],
    FlexibleComponent[107],
    FlexibleComponent[108],
    FlexibleComponent[109],
    FlexibleComponent[110],
    FlexibleComponent[111],
    FlexibleComponent[112],
    FlexibleComponent[113],
    FlexibleComponent[114],
    FlexibleComponent[115],
    FlexibleComponent[116],
    FlexibleComponent[117],
    FlexibleComponent[118],
    FlexibleComponent[119],
    FlexibleComponent[120],
    FlexibleComponent[121],
    FlexibleComponent[122],
    FlexibleComponent[123],
    FlexibleComponent[124],
    FlexibleComponent[125],
    FlexibleComponent[126],
    FlexibleComponent[127],
    FlexibleComponent[128],
    FlexibleComponent[129],
    FlexibleComponent[130],
    FlexibleComponent[131],
    FlexibleComponent[132],
    FlexibleComponent[133],
    FlexibleComponent[134],
    FlexibleComponent[135],
    FlexibleComponent[136],
    FlexibleComponent[137],
    FlexibleComponent[138],
    FlexibleComponent[139],
    FlexibleComponent[140],
    FlexibleComponent[141],
    FlexibleComponent[142],
    FlexibleComponent[143],
    FlexibleComponent[144],
    FlexibleComponent[145],
    FlexibleComponent[146],
    FlexibleComponent[147],
    FlexibleComponent[148],
    FlexibleComponent[149],
    FlexibleComponent[150],
    FlexibleComponent[151],
    FlexibleComponent[152],
    FlexibleComponent[153],
    FlexibleComponent[154],
    FlexibleComponent[155],
    FlexibleComponent[156],
    FlexibleComponent[157],
    FlexibleComponent[158],
    FlexibleComponent[159],
    FlexibleComponent[160],
    FlexibleComponent[161],
    FlexibleComponent[162],
    FlexibleComponent[163],
    FlexibleComponent[164],
    FlexibleComponent[165],
    FlexibleComponent[166],
    FlexibleComponent[167],
    FlexibleComponent[168],
    FlexibleComponent[169],
    FlexibleComponent[170],
    FlexibleComponent[171],
    FlexibleComponent[172],
    FlexibleComponent[173],
    FlexibleComponent[174],
    FlexibleComponent[175],
    FlexibleComponent[176],
    FlexibleComponent[177],
    FlexibleComponent[178],
    FlexibleComponent[179],
    FlexibleComponent[180],
    FlexibleComponent[181],
    FlexibleComponent[182],
    FlexibleComponent[183],
    FlexibleComponent[184],
    FlexibleComponent[185],
    FlexibleComponent[186],
    FlexibleComponent[187],
    FlexibleComponent[188],
    FlexibleComponent[189],
    FlexibleComponent[190],
    FlexibleComponent[191],
    FlexibleComponent[192],
    FlexibleComponent[193],
    FlexibleComponent[194],
    FlexibleComponent[195],
    FlexibleComponent[196],
    FlexibleComponent[197],
    FlexibleComponent[198],
    FlexibleComponent[199],
    FlexibleComponent[200],
    FlexibleComponent[201],
    FlexibleComponent[202],
    FlexibleComponent[203],
    FlexibleComponent[204],
    FlexibleComponent[205],
    FlexibleComponent[206],
    FlexibleComponent[207],
    FlexibleComponent[208],
    FlexibleComponent[209],
    FlexibleComponent[210],
    FlexibleComponent[211],
    FlexibleComponent[212],
    FlexibleComponent[213],
    FlexibleComponent[214],
    FlexibleComponent[215],
    FlexibleComponent[216],
    FlexibleComponent[217],
    FlexibleComponent[218],
    FlexibleComponent[219],
    FlexibleComponent[220],
    FlexibleComponent[221],
    FlexibleComponent[222],
    FlexibleComponent[223],
    FlexibleComponent[224],
    FlexibleComponent[225],
    FlexibleComponent[226],
    FlexibleComponent[227],
    FlexibleComponent[228],
    FlexibleComponent[229],
    FlexibleComponent[230],
    FlexibleComponent[231],
    FlexibleComponent[232],
    FlexibleComponent[233],
    FlexibleComponent[234],
    FlexibleComponent[235],
    FlexibleComponent[236],
    FlexibleComponent[237],
    FlexibleComponent[238],
    FlexibleComponent[239],
    FlexibleComponent[240],
    FlexibleComponent[241],
    FlexibleComponent[242],
    FlexibleComponent[243],
    FlexibleComponent[244],
    FlexibleComponent[245],
    FlexibleComponent[246],
    FlexibleComponent[247],
    FlexibleComponent[248],
    FlexibleComponent[249],
    FlexibleComponent[250],
    FlexibleComponent[251],
    FlexibleComponent[252],
    FlexibleComponent[253],
]


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
        entities = List[Entity]()
        for _ in range(1000):
            for _ in range(1000):
                entities.append(world.new_entity(pos))
            for entity in entities:
                world.remove_entity(entity[])
            entities.clear()

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

        entities = List[Entity]()
        for _ in range(1000):
            for _ in range(1000):
                entities.append(world.new_entity(c1, c2, c3, c4, c5))
            for entity in entities:
                world.remove_entity(entity[])
            entities.clear()

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
    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        for _ in range(50):
            world = FullWorld()
            entities = List[Entity]()
            component0 = FlexibleComponent[0](1.0, 2.0)
            for _ in range(1000):
                entities.append(world.new_entity(component0))

            @parameter
            for i in range(20):
                component = FlexibleComponent[i + 1](1.0, 2.0)
                for entity in entities:
                    world.remove_and[FlexibleComponent[i]]().add(
                        entity[], component
                    )

    bencher.iter[bench_fn]()


fn benchmark_exchange_1_comp_1_000_000_extra(
    inout bencher: Bencher,
) raises capturing:
    pos = Position(1.0, 2.0)

    @always_inline
    @parameter
    fn bench_fn() capturing raises:
        world = World[Position, Velocity]()
        entities = List[Entity]()
        for _ in range(1000):
            entities.append(world.new_entity(pos))

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
