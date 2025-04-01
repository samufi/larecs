+++
type = "docs"
title = "Queries and iteration"
weight = 40
+++

## Queries

Queries allow to iterate over all entities with or without a specific 
set of components. To create a query, we can use 
the {{< api World.query query >}} method of 
{{< api World >}}. The parameters used in this method are the components
that each entity we look for must have. For example, if we want to
iterate over all entities with a `Position` and a `Velocity` component,
we can do this as follows:

```mojo {doctest="guide_queries_iteration" global=true hide=true}
from larecs import World, MutableEntityAccessor

@value
struct Position:
    var x: Float64
    var y: Float64

@value
struct Velocity:
    var dx: Float64
    var dy: Float64
```

```mojo {doctest="guide_queries_iteration" hide=true}
world = World[Position, Velocity]()
```

```mojo {doctest="guide_queries_iteration"}
# Add entities with different components
_ = world.add_entity()
_ = world.add_entity(Position(0, 0))
_ = world.add_entity(Velocity(1, 0))
_ = world.add_entity(Position(1, 0), Velocity(1, 0))

# Query all entities that have a position
query = world.query[Position]()

# Of the entities we have just added,
# two have a position component
print(len(query)) # "2"

# Now let us iterate over the queried entities
for entity in query:
    pos = entity.get_ptr[Position]()
    print(
        "Entity at position: (" 
        + String(pos[].x) + ", " + String(pos[].y) + ")"
    )
```

Queries can be adjusted to also exclude entities that have
certain components. For example, if we want to iterate
over all entities that have a `Position` component
but not a `Velocity` component, we can do this 
using the {{< api Query.without without >}} method:

```mojo {doctest="guide_queries_iteration"}
excluding_query = world.query[Position]().without[Velocity]()
print(len(excluding_query)) # "1"
```

Furthermore, we can also query for entities that have
exactly the components we are looking for but no more.
This can be done using the {{< api Query.exclusive exclusive >}} 
method. For example, if we want to iterate
over all entities that have only a `Position` component,
we can do this as follows:

```mojo {doctest="guide_queries_iteration"}
excluding_query = world.query[Position]().exclusive()
print(len(excluding_query)) # "1"
```

> [Note!] 
> Determining the length of a query is not a trivial operation
> and can be expensive if the ECS is involves many components.
> Therefore, it is advisable to avoid applying the `len` function
> on queries in "hot" code.

## Iterating over queries

As we have seen, we can iterate over queries using a for loop.
Here, the control variable ("entity") is an {{< api EntityAccessor >}} 
object, i.e., not technically an {{< api Entity >}}, which is
merely an identifier of an entity. Instead, the `EntityAccessor`
directly provides methods to get, set, and check the existence
of components, so that we do not need to call the world's 
methods for this.

```mojo {doctest="guide_queries_iteration"}
for entity in world.query[Position]():
    pos = entity.get_ptr[Position]()
    print(
        "Entity at position: (" 
        + String(pos[].x) + ", " + String(pos[].y) + ")"
    )
    if entity.has[Velocity]():
        # Reset position and velocity
        entity.set(Position(0, 0), Velocity(0, 0))
```

> [Note!]
> The `EntityAccessor` is a temporary object that is
> created for each iteration. Therefore, should not be
> stored in a container.

> [Note!]
> Adding or removing entities or components to/from entities
> would invalidate the iterator. Therefore, the world is 
> locked during the iteration. This means that the forbidden
> operations will raise an exception during iterations.

## Applying (vectorized) functions to entities in queries

We may want to apply a certain operation to all entities
that have certain components. This can be achieved with 
the {{< api World.apply apply >}} method. This method
iterates over all entities conforming to a query and
calls the provided function with the entities as arguments.
The function must take a {{< api MutableEntityAccessor >}} 
as its only argument.

For example, if we want to apply a function that moves all entities
with a `Position` and a `Velocity` component, we can do this as follows:

```mojo {doctest="guide_queries_iteration"}
# Define the move function
fn move(entity: MutableEntityAccessor) capturing:
    try:
        move_pos = entity.get_ptr[Position]()
        move_vel = entity.get_ptr[Velocity]()
        move_pos[].x += move_vel[].dx
        move_pos[].y += move_vel[].dy
    except:
        # We could do proper error handling here
        # but for now, we just ignore the error
        pass

# Apply the move function to all entities with a position and a velocity
world.apply[move](world.query[Position, Velocity]())
```

> [Note!]
> Currently, the applied operation can not raise exceptions.
> Therefore, we need to catch exceptions in the function
> itself. This is due to current limitations of Mojo and
> will be changed as soon as possible.

A major advantage of Mojo is that it allows to use vectorized
operations via `SIMD`. The `apply` method allows us to 
use this feature but requires us to know the memory layout
of our components.

...