+++
type = "docs"
title = "Changing entities"
weight = 30
+++

## Accessing and manipulating components

The values of an entity's component can be 
accessed and changed via the {{< api World.get get >}} and {{< api World.get_ptr get_ptr >}}
methods of world. Here, `get` returns a reference, 
which can be changed in-place only and `get_ptr`
returns a pointer, which can be changed later 
down the line.

```mojo {doctest="guide_change_entities" global=true hide=true}
from larecs import World

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

```mojo {doctest="guide_change_entities"}
# Add an entity and get its representation
entity = world.add_entity(Position(0, 0))

# Get a copy of the position
pos = world.get[Position](entity)

# This does not change the entity's state!
pos.x = 5 
print(world.get[Position](entity).x == pos.x) # False

# Changing the reference in-place works, though.
world.get[Position](entity).x = 5

# Similarly, replacing the component completely 
# works as well.
world.get[Position](entity) = Position(5, 0)

# For later access of the position, use a pointer
pos_ptr = world.get_ptr[Position](entity)

# Now, changing the value via the local pointer variable works.
pos_ptr[].x = 10 # Use the `[]` operator to dereference the pointer
print(world.get[Position](entity).x == 10) # True
```

## Setting multiple components at once

We can set multiple components at once using the {{< api World.set set >}}` 
method. This method takes a tuple of components and sets them 
all in one go.

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
> Replacing components way in one go is significantly 
> more efficient than removing and adding components separately. 

