from sys.info import sizeof
from collections import Dict
from types import get_max_uint_size, TrivialIntable
from memory import UnsafePointer


trait IdentifiableType:
    """IdentifiableType is a trait for types that have a unique identifier."""

    @parameter
    @staticmethod
    @always_inline
    fn get_type_identifier() -> Int:
        ...


trait ComponentType(IdentifiableType, Movable):
    pass


@value
@register_passable("trivial")
struct ComponentInfo[dType: DType]:
    alias Id = SIMD[dType, 1]
    var id: Self.Id
    var size: UInt32

    @staticmethod
    fn new[T: AnyType](id: Self.Id) -> ComponentInfo[dType]:
        return ComponentInfo[dType](id, sizeof[T]())


struct ComponentReference[
    is_mutable: Bool, //, Id: TrivialIntable, lifetime: Origin[is_mutable].type
]:
    """ComponentReference is an agnostic reference to ECS components.

    The ID is used to identify the component type. However, the
    ID is never checked for validity. Use the ComponentManager to
    create component references safely.
    """

    var _id: Id
    var _data: UnsafePointer[UInt8]

    fn __init__[T: ComponentType](inout self, id: Id, ref [lifetime]value: T):
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
    fn get_id(self) -> Id:
        """Get the ID of the component."""
        return self._id


struct ComponentManager[dType: DType]:
    """ComponentManager is a manager for ECS components.

    It is used to assign IDs to types and to create
    references for passing them around.
    """

    alias Id = SIMD[dType, 1]

    var _components: Dict[Int, ComponentInfo[dType]]
    alias max_size = get_max_uint_size[Self.Id]()

    fn __init__(inout self) raises:
        @parameter
        if not dType.is_integral():
            raise Error("dType needs to be an integral type.")

        self._components = Dict[Int, ComponentInfo[dType]]()

    fn _register[
        T: ComponentType, check_existent: Bool = True
    ](inout self) raises -> ComponentInfo[dType] as component_info:
        """Register a new component type.

        Parameters:
            T: The component type to register.
            check_existent: Whether to check if the component type has already been registered.

        Raises:
            Error: If check_existent and the component type has already been registered.
            Error: If the maximum number of components has been reached.
        """

        @parameter
        if check_existent:
            if T.get_type_identifier() in self._components:
                raise Error(
                    "A component with hash "
                    + str(T.get_type_identifier())
                    + " has already been registered."
                )

        if len(self._components) >= self.max_size:
            raise Error(
                "We cannot register more than "
                + str(self.max_size)
                + " elements in a component manager of this type."
            )

        component_info = ComponentInfo[dType].new[T](
            Self.Id(len(self._components))
        )
        self._components[T.get_type_identifier()] = component_info

    fn get_id[T: ComponentType](inout self) raises -> Self.Id:
        """Get the ID of a component type.

        If the component does not yet have an ID, register the component.

        Parameters:
            T: The component type.

        Raises:
            Error: If the component was not registered and the maximum number of components has been reached.
        """
        if T.get_type_identifier() in self._components:
            return self._components[T.get_type_identifier()].id
        else:
            return self._register[T, False]().id

    fn get_info[T: ComponentType](inout self) raises -> ComponentInfo[dType]:
        """Get the info of a component type.

        If the component does not yet have an ID, register the component.

        Raises:
            Error: If the component was not registered and the maximum number of components has been reached.
        """
        if T.get_type_identifier() in self._components:
            return self._components[T.get_type_identifier()]
        else:
            return self._register[T, False]()

    @always_inline
    fn get_ref[
        is_mutable: Bool, //,
        T: ComponentType,
        lifetime: Origin[is_mutable].type,
    ](inout self, ref [lifetime]value: T) raises -> ComponentReference[
        Self.Id, lifetime
    ]:
        """Get a type-agnostic reference to a component.

        If the component does not yet have an ID, register the component.

        Parameters:
            is_mutable: Infer-only. Whether the reference is mutable.
            T: The component type.
            lifetime: The lifetime of the reference.

        Args:
            value: The value of the component to be passed around.

        Raises:
            Error: If the component was not registered and the maximum number of components has been reached.
        """
        return ComponentReference[Self.Id](self.get_id[T](), value)
