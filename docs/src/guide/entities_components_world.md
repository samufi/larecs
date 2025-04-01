+++
type = "docs"
title = "Entities, components, and the world"
weight = 10
+++

## Entities, components, and the `World`

### A little bit of introduction...

Larecs🌲 provides a way to store, access and manipulate 
data belonging to computational entities efficiently.
"Entities" often represent objects or agents that have certain
properties ("objects" in the object oriented framework),
here called "Components". Which attributes an entity has 
can change at runtime, making the approach extremely flexible.
Furthermore, entities do not belong to pre-defined 
"classes" but are rather fully characterized by their attributes.
A key functionality of entity component systems is to 
query all entities that have certain components and process them
in a corresponding way. 

For example, entities that can move may be characterized 
via the components `Position` and `Velocity`, as nothing
else is required for movement with constant velocity: 
the new position can be computed from the current position, 
the velocity, and a time increment `dt`:

```
Position = Position + Velocity * dt
```

Below, we provide more details on how entities 
and components are represented in Larecs🌲 and how
an ECS can be set up with Larecs🌲.

### Components

In Larecs🌲 and other ECS, components are modelled
via structs. That is, each component is represented
by a different struct. If we want to consider position 
and velocity as in the example above, we need to 
define a struct for each of the two:

```mojo {doctest="guide_entities_components_world" global=true}
@value
struct Position:
    var x: Float64
    var y: Float64

@value
struct Velocity:
    var dx: Float64
    var dy: Float64
```

In this example, we consider a two-dimensional world.
Therefore, the two structs have an attribute for both
the `x` and the `y` dimension.

Note! Currently, only "trivial" structs are supported as 
components in Larecs🌲. That is, structs that can be
copied and moved via simple memory operations. This does
not include structs that manage heap-allocated memory
such as `List` or `Dict`. Often, it is not advisable to
use such objects in the ECS context anyway; however, 
Larecs🌲 might support "complex" structs in a future version. 

### Setting up the ECS: the `World`

The central container type of Larecs🌲 is the
`World`. The `World` stores all data and information about
the state of the entities and their surroundings.

Larecs🌲 gains a lot of its efficiency by using compile-time
programming. To that end, it needs to know which components
might turn up in the world at compile time, and the
`World` struct must be parameterized with the entities
upon creation. This also has the advantage that certain errors
can already be prevented at compile time, which makes the
program safer and faster.

To create a world, simply import it from the `larecs` package
and create a `World` as follows:

```mojo {doctest="guide_entities_components_world" global=true}
from larecs import World

def main():
    world = World[Position, Velocity]()
```

### Entities

Entities are strictly bound to the world they live in.
An entity merely contains an ID that the world can use 
to look up the entity's components. As a consequence,
entities are small in memory and can be efficiently 
stored, and their data can only be accessed via the world.

Note! Though entities can safely be stored an passed around,
their components (or pointers to them) should never be stored
externally, as they can move in memory at any time.

How entities are created and used will be discussed in the
following sections.