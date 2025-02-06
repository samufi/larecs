from collections import InlineArray
from python import Python
from time import perf_counter_ns

import larecs as lx


@value
struct BenchResult:
    var components: Int
    var entities: Int
    var nanos_ecs: Float64
    var nanos_aos: Float64


fn main() raises:
    results = run_benchmarks(6)

    for result in results:
        print(
            result[].entities,
            result[].components,
            result[].nanos_ecs,
            result[].nanos_aos,
        )

    results = List[BenchResult]()
    plot(results)


def plot(results: List[BenchResult]):
    pd = Python.import_module("pandas")
    plt = Python.import_module("matplotlib.pyplot")
    figure = Python.import_module("matplotlib.figure")


fn run_benchmarks(maxEntityExp: Int) raises -> List[BenchResult]:
    results = List[BenchResult]()

    for entExp in range(1, maxEntityExp, 1):
        target_iters = 10**8
        entities = 10**entExp
        rounds = target_iters // entities

        @parameter
        for compExp in range(1, 6, 1):
            result = benchmark[compExp](rounds, entities)
            results.append(result)

    return results


fn benchmark[Exp: Int](rounds: Int, entities: Int) raises -> BenchResult:
    w1 = createEcsWorld[Exp](entities)
    var start_ecs: Float64 = perf_counter_ns()
    for _ in range(rounds):
        for entity in w1.query[Position, Velocity]():
            position = entity.get_ptr[Position]()
            velocity = entity.get[Velocity]()
            position[].x += velocity.x
            position[].y += velocity.y
    dur_ecs = (perf_counter_ns() - start_ecs) / (entities * rounds)

    w2 = AosWorld[Exp](entities)
    var start_aos: Float64 = perf_counter_ns()
    for _ in range(rounds):
        w2.update()
    dur_aos = (perf_counter_ns() - start_aos) / (entities * rounds)

    return BenchResult(
        entities=entities,
        components=2**Exp,
        nanos_ecs=dur_ecs,
        nanos_aos=dur_aos,
    )


fn createEcsWorld[Exp: Int](entities: Int) raises -> World:
    w = World()
    for _ in range(entities):
        _ = createEcsEntity[Exp](w)

    return w^


fn createEcsEntity[Exp: Int](mut w: World) raises -> lx.Entity:
    e = w.add_entity(Position(1, 2), Velocity(1, 2))

    @parameter
    for i in range(2**Exp):
        w.add(e, PayloadComponent[i](1.0, 2.0))

    return e


struct AosWorld[Exp: Int]:
    var entities: List[AosEntity[Exp]]

    fn __init__(out self, entities: Int):
        self.entities = List[AosEntity[Exp]]()
        for _ in range(entities):
            self.entities.append(AosEntity[Exp]())

    @always_inline
    fn update(mut self):
        for entity in self.entities:
            entity[].update()


@value
struct AosEntity[Exp: Int]:
    var comps: InlineArray[Position, 2**Exp]

    fn __init__(out self):
        self.comps = InlineArray[Position, 2**Exp](Position(1.0, 2.0))

    @always_inline
    fn update(mut self):
        self.comps[0].x += self.comps[1].x
        self.comps[0].y += self.comps[1].y


@value
struct Position(lx.ComponentType):
    var x: Float64
    var y: Float64


@value
struct Velocity(lx.ComponentType):
    var x: Float64
    var y: Float64


@value
struct PayloadComponent[i: UInt](lx.ComponentType):
    var x: Float64
    var y: Float64


alias World = lx.World[
    Position,
    Velocity,
    PayloadComponent[0],
    PayloadComponent[1],
    PayloadComponent[2],
    PayloadComponent[3],
    PayloadComponent[4],
    PayloadComponent[5],
    PayloadComponent[6],
    PayloadComponent[7],
    PayloadComponent[8],
    PayloadComponent[9],
    PayloadComponent[10],
    PayloadComponent[11],
    PayloadComponent[12],
    PayloadComponent[13],
    PayloadComponent[14],
    PayloadComponent[15],
    PayloadComponent[16],
    PayloadComponent[17],
    PayloadComponent[18],
    PayloadComponent[19],
    PayloadComponent[20],
    PayloadComponent[21],
    PayloadComponent[22],
    PayloadComponent[23],
    PayloadComponent[24],
    PayloadComponent[25],
    PayloadComponent[26],
    PayloadComponent[27],
    PayloadComponent[28],
    PayloadComponent[29],
    PayloadComponent[30],
    PayloadComponent[31],
    resources_type = lx.Resources,
]
