from .component import ComponentType
from .resource import Resources
from .type_map import DynamicTypeMap
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

    Parameters:
        ComponentTypes: The types of the components in the world.
    """

    alias World = World[*ComponentTypes]
    """The world type used by the scheduler."""

    alias FunctionType = fn (
        mut system: UnsafeBox, mut world: Self.World
    ) raises
    """The type of system functions."""

    var _world: Self.World
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
        self._world = Self.World()

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
        self._world = world^

    fn add_system[S: System](mut self, system: S):
        """Adds a system to the scheduler.

        Args:
            system: The system to add.
        """

        self._systems.append(
            (
                UnsafeBox(system),
                _initialize_system[S, *ComponentTypes],
                _update_system[S, *ComponentTypes],
                _finalize_system[S, *ComponentTypes],
            )
        )

    fn initialize(mut self) raises:
        """Initializes all systems in the scheduler."""
        for system_info in self._systems:
            system_info[][1](system_info[][0], self._world)

    fn update(mut self, steps: Int = 1) raises:
        """Updates all systems in the scheduler repeatedly.

        Args:
            steps: How often the systems should be updated.
        """
        for _ in range(steps):
            for system_info in self._systems:
                system_info[][2](system_info[][0], self._world)

    fn finalize(mut self) raises:
        """Finalizes all systems in the scheduler."""
        for system_info in self._systems:
            system_info[][3](system_info[][0], self._world)

    fn run(mut self, steps: Int) raises:
        """Runs the scheduler for a given number of steps.

        Args:
            steps: The number of steps to run.
        """
        self.initialize()
        self.update(steps)
        self.finalize()


trait System(CollectionElement):
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
