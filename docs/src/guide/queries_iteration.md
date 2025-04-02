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

## Applying functions to entities in queries

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

> [Caution!]
> The world is locked during the iteration, and 
> accessing variables outside a locally defined
> function is an immature feature in Mojo. Do not
> attempt to access the `world` from inside the operation.

## Application of vectorized functions

A major advantage of Mojo is that it allows to use vectorized
operations via `SIMD`. The `apply` method allows us to 
use this feature but requires us to know the memory layout
of our components.

To showcase this feature, we need some further imports.

```mojo {doctest="guide_simd_apply" global=true}
from larecs import World, MutableEntityAccessor
from sys.info import simdwidthof
from memory import UnsafePointer
```

```mojo {doctest="guide_simd_apply" global=true hide=true}

@value
struct Position:
    var x: Float64
    var y: Float64

@value
struct Velocity:
    var dx: Float64
    var dy: Float64
```

```mojo {doctest="guide_simd_apply" hide=true}
world = World[Position, Velocity]()
_ = world.add_entities(Position(0, 0), Velocity(1, 0), count=10)
```

Before defining the vectorized operation, we need to gather some 
information about the memory layout of our components.
Specifically, we need to know the space in memory between
two consecutive components of the same type. This is 
needed if we want to load the same attribute of multiple components
at once. 

Consider our `Position` component. It has two attributes
`x` and `y`, which are both of type `Float64`. In memory,
an array of `Position` components would look like this:

```
Position[0].x | Position[0].y | Position[1].x | Position[1].y | ...
```
The space between two consecutive `x` attributes is
`2 * sizeof(Float64)`. Therefore, when loading the `x` attribute
of multiple `Position` components, we need to skip 
every other `Float64` in memory. Hence, loading the `x` attribute
of multiple `Position` components at once requires
a stride of `2`. The same applies to the `Velocity` component, 
which also has two `Float64` attributes `dx` and `dy`. 

We may store this information in `alias` variables.

```mojo {doctest="guide_simd_apply"}
alias stride = 2
```

Now we can define our vectorized move operation.
It needs to take an integer parameter `simd_width`,
which denotes how many entities will be processed at once.

```mojo {doctest="guide_simd_apply"}
fn move[simd_width: Int](entity: MutableEntityAccessor) capturing:
    
    try:
        pos = entity.get_ptr[Position]()
        vel = entity.get_ptr[Velocity]()
    except:
        return

    # Get an unsafe pointer to the memory
    # location of the Position and Velocity components
    pos_x_ptr = UnsafePointer.address_of(pos[].x)
    pos_y_ptr = UnsafePointer.address_of(pos[].y)
    vel_x_ptr = UnsafePointer.address_of(vel[].dx)
    vel_y_ptr = UnsafePointer.address_of(vel[].dy)

    # Now we load simd_width x and y attributes of the Position
    # and dx and dy attributes of the Velocity
    pos_x = pos_x_ptr.strided_load[width=simd_width](stride)
    pos_y = pos_y_ptr.strided_load[width=simd_width](stride)
    vel_x = vel_x_ptr.strided_load[width=simd_width](stride)
    vel_y = vel_y_ptr.strided_load[width=simd_width](stride)
    
    # Now we can apply the operation
    pos_x += vel_x
    pos_y += vel_y

    # Store the updated positions back to memory
    pos_x_ptr.strided_store[width=simd_width](pos_x, stride)
    pos_y_ptr.strided_store[width=simd_width](pos_y, stride)
```

What remains is to apply the move operation to all entities.
For the vectorized version, the {{< api World.apply apply >}} method
requires us to provide the `simd_width` parameter, which 
denotes the maximal number of entities that can be processed
at once. This is determined by the `SIMD` width of our machine.
We can get this information using the `simdwidthof` function.

```mojo {doctest="guide_simd_apply"}
# How many `Float64` values can we process at once?
alias simd_width=simdwidthof[Float64]()

# Apply the move operation to all entities with a position and a velocity
world.apply[move, simd_width=simd_width](world.query[Position, Velocity]())
```

> [Tip!]
> It can be worthwhile to define project-specific load and store 
> functions that take care of the stride and the width and
> reduce the complexity of the code. 

> [Note!]
> The overhead from
> the extra load and store operations can exceed the gain 
> from SIMD operations in simple functions such as the move 
> function defined here. Thorough benchmarking is required to
> determine whether the use of SIMD is beneficial in a specific
> case.