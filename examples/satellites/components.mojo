@fieldwise_init
@register_passable("trivial")
struct Position(Copyable, Movable):
    var x: Float64
    var y: Float64


@fieldwise_init
@register_passable("trivial")
struct Velocity(Copyable, Movable):
    var x: Float64
    var y: Float64
