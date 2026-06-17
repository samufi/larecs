@fieldwise_init
struct Position(ImplicitlyCopyable, Movable, TrivialRegisterPassable):
    var x: Float64
    var y: Float64


@fieldwise_init
struct Velocity(ImplicitlyCopyable, Movable, TrivialRegisterPassable):
    var x: Float64
    var y: Float64
