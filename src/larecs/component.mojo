from sys.info import sizeof
from sys.intrinsics import _type_is_eq
from collections import (
    InlineArray,
)  # Dict,
from memory import UnsafePointer

from .stupid_dict import SimdDict, StupidDict as Dict
from .types import get_max_uint_size, TrivialIntable
from .bitmask import BitMask


trait IdentifiableType:
    """IdentifiableType is a trait for types that have a unique identifier."""

    @staticmethod
    @always_inline
    fn get_type_identifier() -> Int:
        ...


trait ComponentType(Movable):
    pass


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
    sizes = InlineArray[UInt32, len(VariadicList(Ts))](
        unsafe_uninitialized=True
    )

    @parameter
    for i in range(len(VariadicList(Ts))):
        sizes[i] = sizeof[Ts[i]]()

    return sizes


struct ComponentReference[is_mutable: Bool, //, origin: Origin[is_mutable]]:
    """ComponentReference is an agnostic reference to ECS components.

    The ID is used to identify the component type. However, the
    ID is never checked for validity. Use the ComponentManager to
    create component references safely.
    """

    alias Id = BitMask.IndexType

    var _id: Self.Id
    var _data: UnsafePointer[UInt8]

    fn __init__[T: ComponentType](mut self, id: Self.Id, ref [origin]value: T):
        self._id = id
        self._data = UnsafePointer.address_of(value).bitcast[UInt8]()

    fn __moveinit__(mut self, owned existing: Self):
        self._id = existing._id
        self._data = existing._data

    fn __copyinit__(mut self, existing: Self):
        self._id = existing._id
        self._data = existing._data

    @always_inline
    fn unsafe_get_value[T: ComponentType](self) -> ref [__origin_of(self)] T:
        """Get the value of the component."""
        return self._data.bitcast[T]()[0]

    @always_inline
    fn get_unsafe_ptr(self) -> UnsafePointer[UInt8]:
        """Get the unsafe pointer to the data of the component."""
        return self._data

    @always_inline
    fn get_id(self) -> Self.Id:
        """Get the ID of the component."""
        return self._id


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
struct ComponentManager[*component_types: ComponentType]():
    """ComponentManager is a manager for ECS components.

    It is used to assign IDs to types and to create
    references for passing them around.

    Parameters:
        component_types: The component types that the manager should handle.
    """

    alias dType = BitMask.IndexDType
    alias Id = SIMD[Self.dType, 1]
    alias max_size = get_max_uint_size[Self.Id]()
    alias component_count = len(VariadicList(component_types))
    alias component_sizes = get_sizes[*component_types]()

    fn __init__(mut self):
        constrained[
            Self.dType.is_integral(),
            "dType needs to be an integral type.",
        ]()
        constrained[
            len(VariadicList(component_types)) <= Self.max_size,
            "At most " + str(Self.max_size) + " component types are allowed.",
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
    fn get_ref[
        is_mutable: Bool, //,
        T: ComponentType,
        origin: Origin[is_mutable],
    ](ref [origin]value: T) -> ComponentReference[origin]:
        """Get a type-agnostic reference to a component.

        If the component does not yet have an ID, register the component.

        Parameters:
            is_mutable: Infer-only. Whether the reference is mutable.
            T: The component type.
            origin: The origin of the reference.

        Args:
            value: The value of the component to be passed around.
        """
        return ComponentReference(Self.get_id[T](), value)

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
