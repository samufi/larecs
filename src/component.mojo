from sys.info import sizeof
from collections import (
    InlineArray,
)  # Dict,
from stupid_dict import SimdDict, StupidDict as Dict
from types import get_max_uint_size, TrivialIntable
from memory import UnsafePointer
from bitmask import BitMask
from sys.intrinsics import _type_is_eq


trait IdentifiableType:
    """IdentifiableType is a trait for types that have a unique identifier."""

    @staticmethod
    @always_inline
    fn get_type_identifier() -> Int:
        ...


trait ComponentType(Movable):
    pass


trait ComponentInformable(Intable):
    """ComponentInformable is a trait for
    classes representing component information.
    """

    @always_inline
    fn get_id(self) -> UInt8:
        ...

    @always_inline
    fn get_size(self) -> UInt32:
        ...


@value
@register_passable("trivial")
struct ComponentInfo(ComponentInformable):
    """ComponentInfo is a class representing information on componnets."""

    alias dType = DType.uint8
    alias Id = SIMD[Self.dType, 1]
    var id: Self.Id
    var size: UInt32

    @staticmethod
    fn new[T: AnyType](id: Self.Id) -> ComponentInfo:
        return ComponentInfo(id, sizeof[T]())

    @always_inline
    fn __int__(self) -> Int:
        return int(self.id)

    @always_inline
    fn get_id(self) -> Self.Id:
        return self.id

    @always_inline
    fn get_size(self) -> UInt32:
        return self.size


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
struct ComponentManager[*component_types: ComponentType]:
    """ComponentManager is a manager for ECS components.

    It is used to assign IDs to types and to create
    references for passing them around.
    """

    alias dType = BitMask.IndexDType
    alias Id = SIMD[Self.dType, 1]
    alias max_size = get_max_uint_size[Self.Id]()
    alias component_count = len(VariadicList(component_types))

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
    fn get_info[T: ComponentType]() -> ComponentInfo:
        """Get the info of a component type."""
        return ComponentInfo.new[T](Self.get_id[T]())

    @staticmethod
    @always_inline
    fn get_info_arr[
        *Ts: ComponentType
    ](
        out ids: InlineArray[
            ComponentInfo,
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

        ids = InlineArray[ComponentInfo, size](unsafe_uninitialized=True)

        @parameter
        for i in range(size):
            ids[i] = Self.get_info[Ts[i]]()

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

        # @parameter
        # if _type_is_eq[Int, component_types[i]]():
        #     return i
        # return 0
        @parameter
        for j in range(len(VariadicList(component_types))):

            @parameter
            if i == j:
                return sizeof[component_types[j]]()
        return 0
