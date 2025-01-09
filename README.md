# Larecs - lucid archetype-based ECS

This is a performance-oriented archetype-based ECS for Mojo. 

Larecs is based on the ECS [Arche](https://github.com/mlange-42/arche), implemented in the Go programming language.

Larecs is still under construction, so the API might change in future versions. It can, however, already be used for 
testing purposes.

## Installation

### Prerequisites

This package is written in and for [Mojo](https://docs.modular.com/mojo/manual/get-started), which needs to be installed in order to compile, test, or use the software.
If Mojo and the command line interface [Magic](https://docs.modular.com/magic/) are available, dependencies can be installed by navigating to the project directory and executing the following command: 

```
magic install
```

If parts of the program should be executed afterwards, execute the following command in the project folder, making `mojo` available on the command line:

```
magic shell
```

This includes `magic install`, so it is okay to omit the former step.

### Build the package

You can build larecs as a package as follows:

1. Clone the repository / download the files.
2. Navigate to the `src/` subfolder.
3. Execute `mojo package larecs`.
4. Move the newly created file `larecs.mojopkg` to your project's source directory.

### Include source directly for compiler and LSP

To better see what larecs does, access the source while debugging, and adjust the larecs 
source, you can include it into the run command as follows:

```
mojo run -I "path/to/larecs/src" example.mojo
```

To let VSCode and the LSP know of larecs, include it as follows:

1. Go to VSCode's `File -> Preferences -> Settings` page.
2. Go to the `Extensions -> Mojo` section.
3. Look for the setting `Lsp: Include Dirs`.
4. Click on `add item` and insert the path to the `src/` subdirectory.

## Usage

Below there is a simple example covering the most important functionality.
Have a look at the `examples` subdirectory for more elaborate examples. 
A full API reference is still in the making.

```python
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

        # Or we may want to remove the IsStatic component
        # and add a velocity component to the entity
        world.remove_and[IsStatic]().add(entity, Velocity(2, 2))

    # We can query entiteis with specific components
    for entity in world.query[Position, Velocity]():
        # use get_ptr to get a pointer to a specific component
        position = entity.get_ptr[Position]()

        # use get to get a reference / copy of a specific component
        velocity = entity.get[Velocity]()

        position[].x += velocity.x
        position[].y += velocity.y
```


## Limitations

### Only trivial types can be components

Larecs currently only supports trivial types as components, i.e., structs 
that have a fixed size in memory. Using types with heap-allocated memory will
result in memory leaks and / or undefined behaviour, and as of now there is no
good way to enforce that only compatible types are used. 
Hence, it is to the user to take care of this.

Note that using types with heap-allocated memory is typically a bad idea for
ECS and should be avoided anyway.

### Inefficient dictionary for first-time archetype lookup

Due to a [bug](https://github.com/modularml/mojo/issues/3781) in Mojo, larecs uses a very 
inefficient dict implementation for first-time archetype lookup. 
As long as the number of component combinations (archetypes) is limited,
this issue is insignificant. The problem will be fixed as soon as possible.

## Next steps

The goal of larecs is to provide a user-friendly ECS with maximal efficiency. 
In the near future, larecs will take the following steps:
- Add built-in support for [resources](https://mlange-42.github.io/arche/guide/resources/) 
  and [event systems](https://mlange-42.github.io/arche/guide/events/index.html).
- Build an online API documentation.
- Add further useful functionality for working with multiple entities at once, e.g. via [batches](https://mlange-42.github.io/arche/guide/batch-ops/index.html).
- Add further options to filter entities (e.g. "does not have component").
- Improve the usability by switching to value unpacking in queries as soon as this is available in Mojo.
- Improve performance by locking in to components as parameters.
- Add possibilities to exploit the benefits of SIMD (discussion needed).
- Fix the dictionary issue mentioned above.
- Add a versioning scheme.

## License

This project is distributed under the [LGPL3](LICENSE) license.
