from sys.info import sizeof
from sys.intrinsics import _type_is_eq
from collections import (
    InlineArray,
)  # Dict,
from memory import UnsafePointer

from .stupid_dict import SimdDict, StupidDict as Dict
from .types import get_max_size
from .bitmask import BitMask


alias ComponentType = CollectionElement


fn constrain_valid_components[*Ts: ComponentType]() -> Bool:
    """
    Checks if the provided components are valid.

    Parameters:
        Ts: The components to check.
    """
    constrained[
        len(VariadicList(Ts)) > 0,
        "The world needs at least one component.",
    ]()
    constrain_components_unique[*Ts]()

    return True


fn get_sizes[
    *Ts: ComponentType
]() -> InlineArray[UInt32, len(VariadicList(Ts))]:
    constrained[
        len(VariadicList(Ts)) > 0,
        "At least one component is needed.",
    ]()
    sizes = InlineArray[UInt32, len(VariadicList(Ts))](0)

    @parameter
    for i in range(len(VariadicList(Ts))):
        sizes[i] = sizeof[Ts[i]]()

    return sizes


@always_inline
fn _contains_type[T: ComponentType, *Ts: ComponentType]() -> Bool:
    @parameter
    for i in range(len(VariadicList(Ts))):

        @parameter
        if _type_is_eq[T, Ts[i]]():
            return True
    return False


@always_inline
fn constrain_components_unique[*Ts: ComponentType]():
    alias size = len(VariadicList(Ts))

    @parameter
    for i in range(size):

        @parameter
        for j in range(i + 1, size):
            constrained[
                not _type_is_eq[Ts[i], Ts[j]](),
                "The component types need to be unique.",
            ]()


@register_passable("trivial")
struct ComponentManager[
    *component_types: ComponentType, dType: DType = BitMask.IndexDType
]():
    """ComponentManager is a manager for ECS components.

    It is used to assign IDs to types and to create
    references for passing them around.

    Parameters:
        component_types: The component types that the manager should handle.
        dType: The data type to use for the component IDs.
    """

    alias Id = SIMD[dType, 1]
    alias max_size = get_max_size[dType]()
    alias component_count = len(VariadicList(component_types))
    alias component_sizes = get_sizes[*component_types]()

    fn __init__(mut self):
        constrained[
            dType.is_integral(),
            "dType needs to be an integral type.",
        ]()
        constrained[
            len(VariadicList(component_types)) <= Self.max_size,
            "At most "
            + String(Self.max_size)
            + " component types are allowed.",
        ]()

    @staticmethod
    @always_inline
    fn get_id[T: ComponentType]() -> Self.Id:
        """Get the ID of a component type.

        Parameters:
            T: The component type.
        """

        @parameter
        for i in range(len(VariadicList(component_types))):

            @parameter
            if _type_is_eq[T, component_types[i]]():
                return i

        # This constraint will fail if the component type is not in the list.
        constrained[
            _contains_type[T, *component_types](),
            "The used component is not in the component parameter list.",
        ]()

        # This is unreachable.
        return -1

    @staticmethod
    @always_inline
    fn get_id_arr[
        *Ts: ComponentType
    ](
        out ids: InlineArray[
            Self.Id,
            VariadicPack[MutableAnyOrigin, ComponentType, *Ts].__len__(),
        ]
    ):
        """Get the IDs of multiple component types.

        Parameters:
            Ts: The component types.

        Returns:
            An InlineArray with the IDs of the component types.
        """
        alias size = VariadicPack[
            MutableAnyOrigin, ComponentType, *Ts
        ].__len__()

        constrain_components_unique[*Ts]()

        ids = InlineArray[Self.Id, size](unsafe_uninitialized=True)

        @parameter
        for i in range(size):
            ids[i] = Self.get_id[Ts[i]]()

    @staticmethod
    @always_inline
    fn get_size[i: Int]() -> UInt32:
        """Get the size of a component type.

        Parameters:
            i: The ID of the component type.
        """
        return sizeof[component_types[i]]()

    @staticmethod
    @always_inline
    fn get_size(i: Int) -> UInt32:
        """Get the size of a component type.

        Args:
            i: The ID of the component type.
        """
        return Self.component_sizes[i]
