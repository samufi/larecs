@fieldwise_init
@register_passable("trivial")
struct Position(ImplicitlyCopyable, Movable):
    var x: Float64
    var y: Float64


@fieldwise_init
@register_passable("trivial")
struct Velocity(ImplicitlyCopyable, Movable):
    var x: Float64
    var y: Float64
