from collections import InlineArray
import larecs as lx


fn main() raises:
    w1 = createEcsWorld[3](10)

    w2 = AosWorld[3, 10]()

    for entity in w1.query[Position, Velocity]():
        position = entity.get_ptr[Position]()
        velocity = entity.get[Velocity]()
        position[].x += velocity.x
        position[].y += velocity.y

    w2.update()


fn createEcsWorld[Exp: Int](entities: Int) raises -> World:
    w = World()
    for _ in range(entities):
        _ = createEcsEntity[Exp](w)

    return w^


fn createEcsEntity[Exp: Int](mut w: World) raises -> lx.Entity:
    e = w.add_entity(Position(1, 2), Velocity(3, 4))

    @parameter
    for i in range(2**Exp):
        w.add(e, PayloadComponent[i](1.0, 2.0))

    return e


struct AosWorld[Exp: Int, Entities: Int]:
    var entities: List[AosEntity[Exp]]

    fn __init__(out self):
        self.entities = List[AosEntity[Exp]]()
        for _ in range(Entities):
            self.entities.append(AosEntity[Exp](1, 2, 3, 4))

    fn update(mut self):
        for entity in self.entities:
            entity[].update()


@value
struct AosEntity[Exp: Int]:
    var position: Position
    var velocity: Velocity
    var other: InlineArray[PayloadComponent[0], 2**Exp - 2]

    fn __init__(out self, x: Float64, y: Float64, dx: Float64, dy: Float64):
        self.position = Position(x, y)
        self.velocity = Velocity(dx, dy)
        self.other = InlineArray[PayloadComponent[0], 2**Exp - 2](
            PayloadComponent[0](1.0, 2.0)
        )

    fn update(mut self):
        self.position.x += self.velocity.x
        self.position.y += self.velocity.y


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
    resources_type = lx.Resources,
]
