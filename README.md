![CodeQL](https://github.com/samufi/larecs/workflows/CodeQL/badge.svg)

# Larecs🌲 – Lightweight archetype-based ECS

Larecs🌲 is a performance-oriented archetype-based ECS for [Mojo](https://www.modular.com/mojo)🔥. 
Its architecture is based on the Go ECS [Arche](https://github.com/mlange-42/arche). The package is still under construction, so be aware that parts of the API might change in future versions.


## Features

- Clean and simple API
- High performance due to archetypes and Mojo's compile-time programming
- Support for SIMD via a [`vectorize`](https://docs.modular.com/mojo/stdlib/algorithm/functional/vectorize/)-like syntax
- Compile-time checks thanks to usage of parameters
- Native support for [resources](https://mlange-42.github.io/arche/guide/resources/) and scheduling.
- Tested and benchmarked
- No external dependencies
- More features coming soon... 


## Installation

This package is written in and for [Mojo](https://docs.modular.com/mojo/manual/get-started)🔥, which needs to be installed in order to compile, test, or use the software. You can build Larecs🌲 as a package as follows:

1. Clone the repository / download the files.
2. Navigate to the `src/` subfolder.
3. Execute `mojo package larecs`.
4. Move the newly created file `larecs.mojopkg` to your project's source directory.

### Include source directly for compiler and language server

To access the source while debugging and to adjust the Larecs🌲 
source code, you can include it into run commands of your own
projects as follows:

```
mojo run -I "path/to/larecs/src" example.mojo
```

To let VSCode and the language server know of Larecs🌲, include it as follows:

1. Go to VSCode's `File -> Preferences -> Settings` page.
2. Go to the `Extensions -> Mojo` section.
3. Look for the setting `Lsp: Include Dirs`.
4. Click on `add item` and insert the path to the `src/` subdirectory.

## Usage

Refer to the [API docs](https://samufi.github.io/larecs/) for details
on how to use Larecs🌲. 

Below there is a simple example covering the most important functionality.
Have a look at the `examples` subdirectory for more elaborate examples. 

```python
# Import the package
from larecs import World, Resources


# Define components
@fieldwise_init
struct Position(Copyable, Movable):
    var x: Float64
    var y: Float64


@fieldwise_init
struct IsStatic(Copyable, Movable):
    pass


@fieldwise_init
struct Velocity(Copyable, Movable):
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
        # Get references to specific components
        ref position = entity.get[Position]()
        ref velocity = entity.get[Velocity]()

        position.x += velocity.x
        position.y += velocity.y
```


## Limitations

### Only trivial types can be components

Larecs🌲 currently only supports trivial types as components, i.e., structs 
that have a fixed size in memory and can be copied and moved via a
simple memory copy operation. Using types with heap-allocated memory will
result in memory leaks and / or undefined behaviour, and as of now there is no
good way to enforce that only compatible types are used. 
Hence, it is up to the users to take care of this.

Note that using types with heap-allocated memory is typically a bad idea for
ECS and should be avoided anyway.

### Inefficient dictionary for first-time archetype lookup

Due to a [bug](https://github.com/modularml/mojo/issues/3781) in Mojo🔥, Larecs🌲 uses a very 
inefficient dict implementation for first-time archetype lookup. 
As long as the number of component combinations (archetypes) is limited,
this issue is insignificant. The problem will be fixed as soon as possible.

## Next steps

The goal of Larecs🌲 is to provide a user-friendly ECS with maximal efficiency. 
In the near future, Larecs🌲 will take the following steps:
- [x] Add functionality for adding and removing multiple entities at once.
- [ ] Add functionality for setting, adding and removing components of multiple entities at once.
- [x] Improve the documentation
- [x] Add a scheduler for easy setup of ECS. 
- [ ] Add built-in support for [event systems](https://mlange-42.github.io/arche/guide/events/index.html).
- [x] Add further options to filter entities (e.g. "does not have component").
- [ ] Add possibilities for parallel execution
- [ ] Improve the API for systems (e.g. allow systems to stop the execution)
- [ ] Add GPU support 
- [ ] Improve the usability by switching to value unpacking in queries as soon as this is available in Mojo🔥.
- [ ] Fix the dictionary issue mentioned above.

## License

This project is distributed under the [LGPL3](LICENSE) license.
