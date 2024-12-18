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

    fn __init__[
        T: ComponentType
    ](inout self, id: Self.Id, ref [origin]value: T):
        self._id = id
        self._data = UnsafePointer.address_of(value).bitcast[UInt8]()

    fn __moveinit__(inout self, owned existing: Self):
        self._id = existing._id
        self._data = existing._data

    fn __copyinit__(inout self, existing: Self):
        self._id = existing._id
        self._data = existing._data

    @always_inline
    fn unsafe_get_value[
        T: ComponentType
    ](self) raises -> ref [__origin_of(self)] T:
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


fn _contains_type[T: AnyType, *Ts: AnyType]() -> Bool:
    @parameter
    for i in range(len(VariadicList(Ts))):

        @parameter
        if _type_is_eq[T, Ts[i]]():
            return True
    return False


struct ComponentManager[*component_types: AnyType]:
    """ComponentManager is a manager for ECS components.

    It is used to assign IDs to types and to create
    references for passing them around.
    """

    alias dType = BitMask.IndexDType
    alias Id = SIMD[Self.dType, 1]
    alias max_size = get_max_uint_size[Self.Id]()

    fn __init__(inout self):
        constrained[
            Self.dType.is_integral(),
            "dType needs to be an integral type.",
        ]()
        constrained[
            len(VariadicList(component_types)) <= Self.max_size,
            "At most " + str(Self.max_size) + " component types are allowed.",
        ]()

    @always_inline
    fn get_id[T: ComponentType](inout self) -> Self.Id:
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

    @always_inline
    fn get_info[T: ComponentType](inout self) -> ComponentInfo:
        """Get the info of a component type.

        If the component does not yet have an ID, register the component.
        """
        return ComponentInfo.new[T](self.get_id[T]())

    @always_inline
    fn get_info_arr[
        *Ts: ComponentType
    ](
        inout self,
    ) raises -> InlineArray[
        ComponentInfo,
        VariadicPack[MutableAnyOrigin, ComponentType, *Ts].__len__(),
    ] as ids:
        """Get the IDs of multiple component types.

        If a component does not yet have an ID, register the component.

        Parameters:
            Ts: The component types.

        Returns:
            An InlineArray with the IDs of the component types.

        Raises:
            Error: If the component was not registered and the maximum number of components has been reached.
        """
        alias size = VariadicPack[
            MutableAnyOrigin, ComponentType, *Ts
        ].__len__()

        ids = InlineArray[ComponentInfo, size](unsafe_uninitialized=True)

        @parameter
        for i in range(size):
            ids[i] = self.get_info[Ts[i]]()

    @always_inline
    fn get_ref[
        is_mutable: Bool, //,
        T: ComponentType,
        origin: Origin[is_mutable],
    ](inout self, ref [origin]value: T) -> ComponentReference[origin]:
        """Get a type-agnostic reference to a component.

        If the component does not yet have an ID, register the component.

        Parameters:
            is_mutable: Infer-only. Whether the reference is mutable.
            T: The component type.
            origin: The origin of the reference.

        Args:
            value: The value of the component to be passed around.
        """
        return ComponentReference(self.get_id[T](), value)
