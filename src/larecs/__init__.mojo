"""
Larecs🌲 is a performance-oriented archetype-based ECS for Mojo.

It is based on the ECS [Arche](https://github.com/mlange-42/arche), implemented in the Go programming language.

Larecs🌲 is still under construction, so the API might change in future versions. It can, however, already be used for 
testing purposes.

Example:

```mojo {doctest="readme" global=true}
# Import the package
from larecs import World


# Define components
@value
struct Position:
    var x: Float64
    var y: Float64


@value
struct IsStatic:
    pass


@value
struct Velocity:
    var x: Float64
    var y: Float64


# Run the ECS
fn main() raises:
    # Create a world, list all components that will / may be used
    world = World[Position, Velocity, IsStatic]()

    for _ in range(100):
        # Add an entity. The returned value is the
        # entity's ID, which can be used to access the entity later
        entity = world.add_entity(Position(0, 0), IsStatic())

        # For example, we may want to change the entity's position
        world.get[Position](entity).x = 2

        # Or we may want to replace the IsStatic component
        # of the entity by a Velocity component
        world.replace[IsStatic]().by(Velocity(2, 2), entity=entity)

    # We can query entities with specific components
    for entity in world.query[Position, Velocity]():
        # use get_ptr to get a pointer to a specific component
        position = entity.get_ptr[Position]()

        # use get to get a reference / copy of a specific component
        velocity = entity.get[Velocity]()

        position[].x += velocity.x
        position[].y += velocity.y
```

```mojo {doctest="readme" hide=true}
main()
```

Exports:
 - world.World
 - world.Replacer
 - component.ComponentType
 - archetype.MutableEntityAccessor
 - archetype.EntityAccessor
 - entity.Entity
 - query.Query
 - query.QueryInfo
 - resource.Resources
 - type_map.Identifiable
 - type_map.TypeId
 - scheduler.Scheduler
 - scheduler.System
"""
from .world import World
from .component import ComponentType
from .archetype import MutableEntityAccessor
from .resource import Resources
from .type_map import Identifiable, TypeId
from .entity import Entity
from .query import Query
from .scheduler import Scheduler, System
