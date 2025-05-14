+++
type = "docs"
title = "Resources"
weight = 50
+++

Not all data in a world is associated with 
specific entities. This often applies to 
parameters (such as a time step), 
global state variables (such as the current time),
or spatial data structures (such as a grid displaying 
entity positions). These data are called resources.

## Defining resources

Similar to components, resources are defined via
structs. That is, each resource has a specific 
type, and having two resources of the same type is not 
possible.

However, in contrast to components, the (potentially) 
used resources do not need to be known at compile time
but can be dynamically added to the world. Due to
the current limitation that Mojo does not support
reflections, the resource type needs to be specified
via a unique {{< api TypeId >}} identifier, which in turn is
constructed from a string identifier. This requirement
is enforced via the {{< api TypeIdentifiable >}} trait, which
is part of the `ResourceType` trait composition.

By convention, to avoid name clashes, the string identifier should
include the package, module, and type name of the resource.
For example, if we define a resource `Time` 
in the module `my_module` in the package `my_package`, 
the resource identifier would read `my_package.my_module.Time`.

```mojo {doctest="guide_resources" global=true}
from larecs import World, Entity, ResourceType, TypeId

@value
struct Time(ResourceType):
    # The type ID must be specified via an alias `id`
    alias id = TypeId("larecs.resources.Time")
    var time: Float64
```

## Adding and accessing resources

Resources can be accessed and added via the `resources` field
of {{< api World >}}. Adding a resource is done via the 
{{< api Resources.add resources.add >}} method:

```mojo {doctest="guide_resources" global=true hide=true}

@value
struct Position:
    var x: Float64
    var y: Float64

@value
struct Velocity:
    var dx: Float64
    var dy: Float64
```

```mojo {doctest="guide_resources" hide=true}
world = World[Position, Velocity]()
```

```mojo {doctest="guide_resources"}
# Add the `Time resource
world.resources.add(Time(0.0))
```
The `resources` attribute also allows us to access and
change resources via {{< api Resources.get get >}}, 
{{< api Resources.get_ptr get_ptr >}} and 
{{< api Resources.set set >}} methods resembling their
[component-related counterparts](../changing_entities) of `World`.

```mojo {doctest="guide_resources"}
# Change a resource value via a reference
world.resources.get[Time]().time = 1.0

# Get a pointer to a resource
time_ptr = world.resources.get_ptr[Time]()

# Change the resource value via the pointer
time_ptr[].time = 2.0
```

The {{< api Resources.add add >}} and the {{< api Resources.set set >}}
methods also allow to add or set multiple resources at once.
For example, consider the additional entities `Temperature`
and `SelectedEntities`.

```mojo {doctest="guide_resources" global=true}
@value
struct Temperature(ResourceType):
    # The type ID must be specified via an alias `id`
    alias id = TypeId("larecs.resources.Temperature")
    var temperature: Float64

@value
struct SelectedEntities(ResourceType):
    # The type ID must be specified via an alias `id`
    alias id = TypeId("larecs.resources.SelectedEntities")
    var entities: List[Entity]
```

We can add and set them as follows:

```mojo {doctest="guide_resources"}
# Add multiple resources
world.resources.add(
    Temperature(20.0),
    SelectedEntities(List[Entity]())
)

# Set multiple resources
world.resources.set(
    Temperature(30.0),
    Time(2.0) 
)
```

In contrast to components, resources can
be "complex" types with heap-allocated memory,
as demonstrated above with `SelectedEntities`. 
We can use them to store arbitrary amounts of data.

```mojo {doctest="guide_resources"}
# Create entities and add them to the selected entities
for i in range(10):
    entity = world.add_entity(Position(i, i))
    world.resources.get[SelectedEntities]().entities.append(entity)
```

## Removing resources

One or multiple resources can be removed via the 
{{< api Resources.remove remove >}} method. The existence
of a resource is checked via the {{< api Resources.has has >}} method.

```mojo {doctest="guide_resources"}	
# Remove the `Time` and the `Temperature` resource
world.resources.remove[Time, Temperature]()

# Check if the `Time` resource exists
if world.resources.has[Time]():
    print("Time resource exists")
else:
    print("Time resource does not exist")
```