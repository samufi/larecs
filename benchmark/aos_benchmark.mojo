from collections import InlineArray
import larecs as lx


fn main() raises:
    print("Hello, Mojo!")
    w = createEcsWorld[8](1000)

    for entity in w.query[Position, Velocity]():
        position = entity.get_ptr[Position]()
        velocity = entity.get[Velocity]()
        position[].x += velocity.x
        position[].y += velocity.y


fn createEcsWorld[NumComps: Int](entities: Int) raises -> World:
    w = World()
    for _ in range(entities):
        _ = createEcsEntity[NumComps](w)

    return w^


fn createEcsEntity[NumComps: Int](mut w: World) raises -> lx.Entity:
    e = w.add_entity(Position(1, 2), Velocity(3, 4))

    @parameter
    for i in range(NumComps):
        w.add(e, PayloadComponent[i](1.0, 2.0))

    return e


trait HasPosVel:
    fn update(mut self):
        ...


@value
struct AosEntity[Exp: Int](lx.ComponentType, HasPosVel):
    var position: Position
    var velocity: Velocity

    @parameter
    if Exp >= 2:
        var payload0: PayloadComponent[0]
        var payload1: PayloadComponent[1]
    if Exp >= 3:
        var payload2: PayloadComponent[2]
        var payload3: PayloadComponent[3]
        var payload4: PayloadComponent[4]
        var payload5: PayloadComponent[5]
    if Exp >= 4:
        var payload6: PayloadComponent[6]
        var payload7: PayloadComponent[7]
        var payload8: PayloadComponent[8]
        var payload9: PayloadComponent[9]
        var payload10: PayloadComponent[10]
        var payload11: PayloadComponent[11]
        var payload12: PayloadComponent[12]
        var payload13: PayloadComponent[13]

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
    var y: Float32


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
