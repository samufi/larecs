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
and {{< api World.get_ptr get_ptr >}}
methods of world. Here, `get` returns a reference, 
which becomes a copy of the component if stored in a local variable,
and `get_ptr` returns a pointer, which can write into  
the original memory even if stored locally.

```mojo {doctest="guide_change_entities" global=true hide=true}
from larecs import World
from testing import *

@value
struct Position:
    var x: Float64
    var y: Float64

@value
struct Velocity:
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
# storing this in a local variable makes it a copy
pos = world.get[Position](entity)

# This does not change the entity's state!
pos.x = 5 
print(world.get[Position](entity).x == pos.x) # False

# Changing the reference in-place works, though.
world.get[Position](entity).x = 5

# Similarly, replacing the component completely 
# works as well.
world.get[Position](entity) = Position(5, 0)
```

To access and change a component later in 
the current method, we use a pointer:

```mojo {doctest="guide_change_entities"}
# Get a pointer to the Position component
pos_ptr = world.get_ptr[Position](entity)

# Now, changing the value via the local pointer variable works.
pos_ptr[].x = 10 # Use the `[]` operator to dereference the pointer
print(world.get[Position](entity).x == 10) # True
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

