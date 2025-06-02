from .component import ComponentType
from .resource import Resources
from .world import World
from .unsafe_box import UnsafeBox


fn _update_system[
    S: System, *ComponentTypes: ComponentType
](mut system: UnsafeBox, mut world: World[*ComponentTypes]) raises:
    """Updates the system with the given world.

    Parameters:
        S: The type of the system.
        ComponentTypes: The types of the components in the world.

    Args:
        system: The system to update.
        world: The world to use for the update.
    """
    system.unsafe_get[S]().update(world)


fn _initialize_system[
    S: System, *ComponentTypes: ComponentType
](mut system: UnsafeBox, mut world: World[*ComponentTypes]) raises:
    """Initializes the system with the given world.

    Parameters:
        S: The type of the system.
        ComponentTypes: The types of the components in the world.

    Args:
        system: The system to initialize.
        world: The world to use for the initialization.
    """
    system.unsafe_get[S]().initialize(world)


fn _finalize_system[
    S: System, *ComponentTypes: ComponentType
](mut system: UnsafeBox, mut world: World[*ComponentTypes]) raises:
    """Finalizes the system with the given world.

    Parameters:
        S: The type of the system.
        ComponentTypes: The types of the components in the world.

    Args:
        system: The system to finalize.
        world: The world to use for the finalization.
    """
    system.unsafe_get[S]().finalize(world)


struct Scheduler[*ComponentTypes: ComponentType]:
    """
    Manages the execution of systems in a world.

    The systems must implement [.System].
    Usage example:

    Example:

    ```mojo {doctest="scheduler" global=true hide=true}
    from larecs import World, Scheduler, System

    @fieldwise_init
    struct Position:
        var x: Float64
        var y: Float64

    @fieldwise_init
    struct Velocity:
        var x: Float64
        var y: Float64
    ```

    ```mojo {doctest="scheduler" global=true}
    @fieldwise_init
    struct MySystem(System):
        var internal_variable: Int

        # This is executed once at the beginning
        fn initialize(mut self, mut world: World) raises:
            _ = world.add_entities(Position(0.0, 0.0), Velocity(1.0, 1.0), count=10)

        # This is executed in each step
        fn update(mut self, mut world: World) raises:
            for entity in world.query[Position, Velocity]():
                entity.get[Position]().x += entity.get[Velocity]().x
                entity.get[Position]().y += entity.get[Velocity]().y

        # This is executed at the end
        fn finalize(mut self, mut world: World) raises:
            print("Final positions")
            for entity in world.query[Position]():
                print(entity.get[Position]().x, entity.get[Position]().y)
    ```

    ```mojo {doctest="scheduler"}
    scheduler = Scheduler[Position, Velocity]()
    scheduler.add_system(MySystem(internal_variable=42))
    scheduler.run(10)
    ```

    """

    alias World = World[*ComponentTypes]
    """The world type used by the scheduler."""

    alias FunctionType = fn (
        mut system: UnsafeBox, mut world: Self.World
    ) raises
    """The type of system functions."""

    alias _system_index = 0
    """The index of the system in the systems storage."""

    alias _initialize_index = 1
    """The index of the initialize function in the systems storage."""

    alias _update_index = 2
    """The index of the update function in the systems storage."""

    alias _finalize_index = 3
    """The index of the finalize function in the systems storage."""

    var world: Self.World
    var _systems: List[
        Tuple[
            UnsafeBox, Self.FunctionType, Self.FunctionType, Self.FunctionType
        ]
    ]

    fn __init__(out self) raises:
        """
        Initializes the scheduler, creating a new world.
        """
        self._systems = List[
            Tuple[
                UnsafeBox,
                Self.FunctionType,
                Self.FunctionType,
                Self.FunctionType,
            ]
        ]()
        self.world = Self.World()

    fn __init__(out self, owned world: Self.World):
        """
        Initializes the scheduler with a given world.

        Args:
            world: The world to use.
        """
        self._systems = List[
            Tuple[
                UnsafeBox,
                Self.FunctionType,
                Self.FunctionType,
                Self.FunctionType,
            ]
        ]()
        self.world = world^

    fn add_system[S: System](mut self, owned system: S):
        """Adds a system to the scheduler.

        Args:
            system: The system to add.
        """
        self._systems.append(
            (
                UnsafeBox(system^),
                _initialize_system[S, *ComponentTypes],
                _update_system[S, *ComponentTypes],
                _finalize_system[S, *ComponentTypes],
            )
        )

    fn initialize(mut self) raises:
        """Initializes all systems in the scheduler."""
        for ref system_info in self._systems:
            system_info[Self._initialize_index](
                system_info[Self._system_index], self.world
            )

    fn update(mut self, steps: Int = 1) raises:
        """Updates all systems in the scheduler repeatedly.

        Args:
            steps: How often the systems should be updated.
        """
        for _ in range(steps):
            for ref system_info in self._systems:
                system_info[Self._update_index](
                    system_info[Self._system_index], self.world
                )

    fn finalize(mut self) raises:
        """Finalizes all systems in the scheduler."""
        for ref system_info in self._systems:
            system_info[Self._finalize_index](
                system_info[Self._system_index], self.world
            )

    fn run(mut self, steps: Int) raises:
        """Runs the scheduler for a given number of steps.

        This is the main entry point for running the scheduler.
        It calls the `initialize`, `update`, and `finalize` methods in order.
        The `update` method is called `steps` times.
        The `initialize` method is called once at the beginning, and the
        `finalize` method is called once at the end.

        Args:
            steps: The number of steps to run.
        """
        self.initialize()
        self.update(steps)
        self.finalize()


trait System(Copyable, Movable):
    """Trait for systems in the scheduler."""

    fn initialize(mut self, mut world: World) raises:
        """Initializes the system with the given world.

        Args:
            world: The world to use for initialization.
        """
        ...

    fn update(mut self, mut world: World) raises:
        """Updates the system with the given world.

        Args:
            world: The world to use for the update.
        """
        ...

    fn finalize(mut self, mut world: World) raises:
        """Finalizes the system with the given world.

        Args:
            world: The world to use for the finalization.
        """
        ...
