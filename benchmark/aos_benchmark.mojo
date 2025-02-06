from collections import InlineArray
from time import perf_counter_ns

import larecs as lx


@value
struct BenchResult:
    var nanos_ecs: Int
    var nanos_aos: Int


fn main() raises:
    @parameter
    for exp in range(1, 6, 1):
        result = benchmark[exp, 1_000_000](100)
        print(2**exp, result.nanos_ecs / 1000, result.nanos_aos / 1000)


fn benchmark[Exp: Int, Entities: Int](rounds: Int) raises -> BenchResult:
    w1 = createEcsWorld[Exp](Entities)
    start_ecs = perf_counter_ns()
    for _ in range(rounds):
        for entity in w1.query[Position, Velocity]():
            position = entity.get_ptr[Position]()
            velocity = entity.get[Velocity]()
            position[].x += velocity.x
            position[].y += velocity.y
    dur_ecs = perf_counter_ns() - start_ecs

    w2 = AosWorld[Exp, Entities]()
    start_aos = perf_counter_ns()
    for _ in range(rounds):
        w2.update()
    dur_aos = perf_counter_ns() - start_aos

    return BenchResult(nanos_ecs=dur_ecs, nanos_aos=dur_aos)


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


struct AosWorld[Exp: Int, Entities: Int]:
    var entities: List[AosEntity[Exp]]

    fn __init__(out self):
        self.entities = List[AosEntity[Exp]]()
        for _ in range(Entities):
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
