@fieldwise_init
@register_passable("trivial")
struct Position:
    var x: Float64
    var y: Float64


@fieldwise_init
@register_passable("trivial")
struct Velocity:
    var x: Float64
    var y: Float64
