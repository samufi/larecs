from std.collections.check_bounds import check_bounds
from std.sys import size_of
from std.sys.intrinsics import _type_is_eq

# from collections import Dict
from std.memory import UnsafePointer

from .types import get_max_size
from .bitmask import BitMask


comptime ComponentType = Copyable & Movable & ImplicitlyDestructible
"""The trait that components must conform to."""


@always_inline
def constrain_components_unique[*Ts: ComponentType]() -> Bool:
    """Checks whether all component types are unique.

    Parameters:
        Ts: The component types to compare.

    Returns:
        True when no component type appears more than once.
    """
    comptime for i in range(len(Ts)):
        comptime for j in range(i + 1, len(Ts)):
            if _type_is_eq[Ts[i], Ts[j]]():
                return False
    return True


def constrain_valid_components[*Ts: ComponentType]() -> Bool:
    """
    Checks if the provided components are valid.

    Parameters:
        Ts: The components to check.
    """
    return len(Ts) > 0 and constrain_components_unique[*Ts]()


struct ComponentManager[
    *ComponentTypes: ComponentType,
](TrivialRegisterPassable):
    """ComponentManager is a manager for ECS components.

    It is used to assign IDs to types and to create
    references for passing them around.

    Parameters:
        ComponentTypes: The component types that the manager should handle.
    """

    comptime Id = Int
    """The type of the component ID."""

    comptime max_size = BitMask.total_bits
    """The maximal number of component types."""

    comptime component_count = len(Self.ComponentTypes)
    """The number of component types handled by this ComponentManager."""

    def __init__(out self):
        """Construct a component manager for the configured component types.

        Constraints:
            The component count must fit into the bitmask capacity.
        """
        comptime assert Self.component_count <= Int(Self.max_size)

    comptime _ContainsComponent[
        T: ComponentType
    ] = Self.ComponentTypes.contains[T]()
    """Whether a component type is registered in this manager."""

    comptime _ContainsComponents[*Ts: ComponentType] = Ts.all_satisfies[
        Self._ContainsComponent
    ]()
    """Whether all component types are registered in this manager."""

    @staticmethod
    @always_inline
    def assert_valid_components[*Ts: ComponentType]():
        """Assert that all component types are valid."""
        comptime assert Self._ContainsComponents[
            *Ts
        ], "Not all component types are valid for this component manager."

    @staticmethod
    @always_inline
    def get_id[T: ComponentType]() -> Self.Id:
        """Get the ID of a component type.

        Parameters:
            T: The component type. Constraints: Must be in the list of component types.

        Returns:
            The ID of the component type.
        """
        comptime assert Self._ContainsComponent[
            T
        ], "Component type not in component manager"

        comptime for i in range(len(Self.ComponentTypes)):
            comptime if _type_is_eq[T, Self.ComponentTypes[i]]():
                return Self.Id(i)

        # This is unreachable.
        return -1

    @staticmethod
    @always_inline
    def get_id_arr[
        *Ts: ComponentType
    ](out ids: InlineArray[Self.Id, len(Ts),]):
        """Get the IDs of multiple component types.

        Parameters:
            Ts: The component types.

        Returns:
            An InlineArray with the IDs of the component types.

        Constraints:
            The component types must be pair-wise different.
        """
        comptime assert constrain_components_unique[
            *Ts
        ](), "Duplicate component types in get_id_arr are not allowed."
        ids = InlineArray[Self.Id, len(Ts)](uninitialized=True)

        comptime for i in range(len(Ts)):
            comptime assert Self._ContainsComponent[
                Ts[i]
            ], "Component type not in component manager"
            ids[i] = Self.get_id[Ts[i]]()