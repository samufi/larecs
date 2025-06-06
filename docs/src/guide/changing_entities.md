+++
type = "docs"
title = "Changing entities"
weight = 30
+++

Entities may be changed by altering the values / attributes
of their components, adding new components, or removing
existing components. 

## Accessing and changing individual components

The values of an entity's component can be 
accessed and changed via the {{< api World.get get >}} 
method of world. 

```mojo {doctest="guide_change_entities" global=true hide=true}
from larecs import World
from testing import *

@fieldwise_init
struct Position(Copyable, Movable):
    var x: Float64
    var y: Float64

@fieldwise_init
struct Velocity(Copyable, Movable):
    var dx: Float64
    var dy: Float64
```

```mojo {doctest="guide_change_entities" hide=true}
world = World[Position, Velocity]()
```

A reference to a component can be obtained 
as follows:

```mojo {doctest="guide_change_entities"}
# Add an entity with a component
entity = world.add_entity(Position(0, 0))

# Get a reference to the position;
ref pos = world.get[Position](entity)

# We can change the reference.
pos.x = 5
assert_equal(world.get[Position](entity).x, 5)

# We can also replace the component completely. 
world.get[Position](entity) = Position(10, 0)
assert_equal(world.get[Position](entity).x, 10)
```

Of course, accessing a component only works if the entity has
the component in question. Accessing a component 
that the entity does not have will result in an error.

```mojo {doctest="guide_change_entities"}
# Add an entity without a velocity component
entity = world.add_entity(Position(0, 0))

with assert_raises():
    # This will result in an error
    _ = world.get[Velocity](entity)
```

We can check if an entity has a component using the 
{{< api World.has has >}} method. 

```mojo {doctest="guide_change_entities"}
# Check if the entity has a velocity component
if world.has[Velocity](entity):
    print("Entity has a velocity component")
else:
    print("Entity does not have a velocity component")
```

## Setting multiple components at once

We can set the values of multiple components at once 
using the {{< api World.set set >}}
method. This method takes an arbitrary number of 
components and sets them all in one go.

```mojo {doctest="guide_change_entities"}
# Add an entity with two components
entity = world.add_entity(Position(0, 0), Velocity(1, 1))

# Set multiple components at once
world.set(entity, Position(5, 5), Velocity(2, 2))
```

## Adding and removing components

Components can be added and removed from entities using the 
{{< api World.add add >}} and {{< api World.remove remove >}} methods.

```mojo {doctest="guide_change_entities"}
# Add an entity without components
entity = world.add_entity()

# Add components to the entity
world.add(entity, Position(0, 0), Velocity(1, 1))

# Remove a component from the entity
world.remove[Velocity](entity)
```

This works with arbitrary numbers of components, so we can add or remove
any number of components at once.


If we want to remove some components and replace 
them with other components directly, we can use the 
{{< api World.replace replace >}} method in combination with the 
{{< api Replacer.by by >}} method. The `replace` method takes 
Components to be removed as parameters, whereas the `by` method
takes the new components to be added. 

```mojo {doctest="guide_change_entities"}
# Replace the position component with a velocity component
world.replace[Position]().by(Velocity(2, 2), entity=entity)
```

Similar to the `add` and `remove` 
methods, this works with arbitrary numbers of
components, so we can replace any number of components with
any other number of new components.

> [!Tip]
> Replacing components in one go is significantly 
> more efficient than removing and adding components separately. 

