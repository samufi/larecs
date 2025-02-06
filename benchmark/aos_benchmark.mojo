import larecs as lx


fn main() raises:
    print("Hello, Mojo!")
    w = createWorld[8](1000)

    for entity in w.query[Position, Velocity]():
        position = entity.get_ptr[Position]()
        velocity = entity.get[Velocity]()
        position[].x += velocity.x
        position[].y += velocity.y


fn createWorld[NumComps: Int](entities: Int) raises -> World:
    w = World()
    for _ in range(entities):
        _ = createEntity[NumComps](w)

    return w^


fn createEntity[NumComps: Int](mut w: World) raises -> lx.Entity:
    e = w.add_entity(Position(1, 2), Velocity(3, 4))

    @parameter
    for i in range(NumComps):
        w.add(e, PayloadComponent[i](1.0, 2.0))

    return e


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
