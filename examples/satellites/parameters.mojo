from larecs import TypeId

@value
struct Parameters:
    alias id = TypeId("satellites.parameters.Parameters")
    var dt: Float64
    var mass: Float64


alias GRAVITATIONAL_CONSTANT = 6.67430e-11
