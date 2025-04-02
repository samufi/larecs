+++
type = "docs"
title = "Entities, components, and the world"
weight = 10
+++

Larecs🌲 provides a flexible and efficient way to store, 
access and manipulate data records organized 
around individual entities. Suppose we wanted to 
model a world with different objects and agents that each have 
certain properties. The idea of entity component systems 
(ECS) is to characterize these objects and agents 
(called "entities" in an ECS) via the set of 
attributes ("components") they possess, and to 
model the interactions between them via "systems",
functions that operate on entities 
with certain components. Larecs🌲 provides the functionality 
and tools to implement such entity component systems.

## Entities

Entities are the central unit around which the data in
an ECS is organized. Each entity can possess an arbitrary
set of components, which can also be used to characterize
an entity. That is, in an ECS, cars would not directly 
identified as "cars" but rather as everything that has 
the components `Position`, `Velocity`, `Fuel reserves`, 
`Engine power`, etc. 

In ECS, the components are not stored in individual 
objects but rather in a central container, the "world". 
Hence, an {{< api Entity >}} is merely an identifier that allows
retrieving the corresponding components from the world.
As such, entities are strictly bound to the world they live in,
but also small in memory and easy to store.

> [!NOTE] 
> Though entities can safely be stored and passed around,
> their components (or pointers to them) should never be stored
> externally, as they can move in memory at any time.

How entities are created and used is discussed in the
[next chapters](../adding_and_removing_entities).

## Components

Components, the data associated with entities, are modelled
via structs: each component is represented by a specific struct.
For example, if we want to model a world in which 
entities may have a position and a velocity, we need to 
define a `Position` and a `Velocity` struct.

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

These components can later be associated with entities,
as described in the [later chapters](../adding_and_removing_entities).

> [!Caution]
> Currently, only "trivial" structs are supported as 
> components in Larecs🌲. That is, structs that can be
> copied and moved via simple memory operations. This does
> *not* include structs that manage heap-allocated memory
> such as `List` or `Dict`. Typically, it is not advisable to
> use such objects in the ECS context anyway; however, 
> Larecs🌲 might support such "complex" structs in a future version. 

## Setting up the ECS: the `World`

The central container type of Larecs🌲 is the
{{< api World >}}. The `World` stores all data and information about
the state of the entities and their surroundings.

Larecs🌲 gains a lot of its efficiency by using compile-time
programming. To that end, it needs to know ahead of time 
which components might turn up in the world, and the `World` 
must be statically parameterized with the component types upon 
creation. This also has the advantage that certain errors
can already be prevented at compile time, which makes the
program safer and faster.

To set up a `World`, simply import it from the `larecs` package
and create a `World` instance as follows:

```mojo {doctest="guide_entities_components_world" global=true}
from larecs import World

def main():
    # Create a world with the components Position and Velocity
    world = World[Position, Velocity]()
```
