from sys.info import sizeof
from collections import Dict
from types import get_max_int_size

trait IdentifiableType:
    """
    IdentifiableType is a trait for types that have a unique identifier.
    """

    @parameter
    @staticmethod
    @always_inline
    fn get_type_identifier() -> Int:
        ...

trait ComponentType(IdentifiableType, Movable):
    pass

trait TrivialIntable(Intable, Copyable, Movable, Hashable):
    fn __init__(inout self, value: Int):
        ...
    fn __init__(inout self, value: UInt):
        ...

# @register_passable("trivial")
@value
struct ComponentInfo[Id: TrivialIntable]:
    var id: Id
    var size: UInt32

    @staticmethod
    fn new[T: AnyType](id: Id) -> ComponentInfo[Id]:
        return ComponentInfo[Id](id, sizeof[T]())

struct ComponentReference[is_mutable: Bool, //, Id: TrivialIntable, lifetime: AnyLifetime[is_mutable].type]:
    """
    ComponentReference is an agnostic reference to ECS components.

    The ID is used to identify the component type. However, the 
    ID is never checked for validity. Use the ComponentManager to
    create component references safely.
    """
    var _id: Id
    var _item_size: UInt32
    var _data: UnsafePointer[UInt8]

    fn __init__[T: ComponentType](inout self, id: Id, ref[lifetime] value: T):
        self._id = id
        self._item_size = sizeof[T]()
        self._data = UnsafePointer.address_of(value).bitcast[UInt8]()

    fn __moveinit__(inout self, owned existing: Self):
        self._id = existing._id
        self._item_size = existing._item_size
        self._data = existing._data

    fn __copyinit__(inout self, existing: Self):
        self._id = existing._id
        self._item_size = existing._item_size
        self._data = existing._data
    
    @always_inline
    fn get_value[T: ComponentType](self) raises -> ref [__lifetime_of(self)] T: 
        """
        Get the value of the component.
        """
        if sizeof[T]() != int(self._item_size):
            raise Error("The size of the component type does not match the size of the component.")
        return self._data.bitcast[T]()[0]

    @always_inline
    fn get_unsafe_ptr(self) -> UnsafePointer[UInt8]:
        """
        Get the unsafe pointer to the data of the component.
        """
        return self._data

struct ComponentManager[Id: TrivialIntable]:
    """
    ComponentManager is a manager for ECS components.

    It is used to assign IDs to types and to create
    references for passing them around.
    """

    var _components: Dict[Int, ComponentInfo[Id]]
    alias max_size = get_max_int_size[Id]()
    alias new_component[T: ComponentType] = Component[Id].new[T]

    fn __init__(inout self):
        self._components = Dict[Int, ComponentInfo[Id]]()

    fn register[T: ComponentType](inout self) raises:
        """
        Register a new component type.

        Parameters:
            T: The component type to register.

        Raises:
            Error: If the component type has already been registered.
            Error: If the maximum number of components has been reached.
        """
        if T.get_type_identifier() in self._components:
            raise Error("A component with hash " + str(T.get_type_identifier()) + " has already been registered.")
        
        if len(self._components) >= self.max_size:
            raise Error("We cannot register more than " + str(self.max_size) + " elements in a component manager of this type.")

        self._components[T.get_type_identifier()] = ComponentInfo[Id].new[T](Id(len(self._components)))

    fn get_id[T: ComponentType](self) raises -> Id:
        """
        Get the ID of a component type.

        Parameters:
            T: The component type.

        Raises:
            Error: If the component type has not been registered.
        """
        return self._components[T.get_type_identifier()].id

    fn get_info[T: ComponentType](self) raises -> ComponentInfo[Id]:
        """
        Get the info of a component type.

        Raises:
            Error: If the component type has not been registered.
        """
        return self._components[T.get_type_identifier()]

    fn get_ref[is_mutable: Bool, //, T: ComponentType, lifetime: AnyLifetime[is_mutable].type](self,  ref[lifetime] value: T) raises -> ComponentReference[Id, lifetime]:
        """
        Get a type-agnostic reference to a component.

        Parameters:
            T: The component type.
            lifetime: The lifetime of the reference.

        Args:
            value: The value of the component to be passed around.
        """
        return ComponentReference[Id](self.get_id[T](), value)