from sys.info import sizeof

trait HashableType:

    @parameter
    @staticmethod
    @always_inline
    fn get_type_hash() -> UInt:
        ...

trait ComponentType(HashableType, Movable):
    pass

@value
@register_passable("trivial")
struct ComponentInfo[Id: IntLike]:
    var id: Id
    var size: UInt32

    @staticmethod
    fn new[T: AnyType](id: Id) -> ComponentInfo:
        return ComponentInfo(id, sizeof[T]())

struct Component[Id: IntLike]:
    """
    Component is an agnostic type representing an ECS component value.

    The ID is used to identify the component type. However, the 
    ID is never checked for validity. 

    Caution: This type only works if the component type is 'trivial',
    i.e., all its data are in-line and it does not contain a pointer
    to some other point in memory. If used with non-trivial types,
    they may not be properly deallocated, copied, or moved.

    ToDo: once available, constrain the type to 'trivial'.
    """
    var _id: Id
    var _item_size: UInt32
    var _data: UnsafePointer[UInt8]

    fn __init__(inout self, id: Id, item_size: UInt32):
        self._id = id
        self._item_size = item_size
        self._data = UnsafePointer[UInt8].alloc(item_size)

    fn __moveinit__(inout self, owned existing: Self):
        self._id = existing._id
        self._item_size = existing._item_size
        self._data = existing._data

    fn __copyinit__(inout self, existing: Self):
        self._id = existing._id
        self._item_size = existing._item_size
        self._data = UnsafePointer[UInt8].alloc(self._item_size)
        memcpy(self._data, existing._data, self._item_size)

    @staticmethod
    fn new[T: ComponentType](id: Id, owned value: T) -> Component[Id] as component:
        """
        Create a new component with a given id and value.
        """
        component = Component[Id](id, sizeof[T]())
        component._data.bitcast[T].init_pointee_move(UnsafePointer.address_of(value)())

    fn set_value[T: ComponentType](self) raises:
        """
        Set the value of the component.

        Raises:
            Error: If the size of the component type does not match the size of the component.
        """
        if sizeof[T]() != self._item_size:
            raise Error("The size of the component type does not match the size of the component.")
        self._data.bitcast[T].init_pointee_move(UnsafePointer.address_of(value)())

    @always_inline
    fn get_value[T: ComponentType](self) -> ref[__lifetime_of(self)] T raises:
        """
        Get the value of the component.
        """
        if sizeof[T]() != self._item_size:
            raise Error("The size of the component type does not match the size of the component.")
        return self._data.bitcast[T]()

    @always_inline
    fn get_unsafe_ptr(self) -> UnsafePointer[UInt8]:
        """
        Get the unsafe pointer to the data of the component.
        """
        return self._data

    fn __del__(self):
        self._data.free()

alias NewComponent[Id: IntLike, T: ComponentType] = Component[Id].new[T]

struct ComponentManager[Id: IntLike]:

    var _components: Dict[UInt, ComponentInfo[Id]]
    alias max_size = 2 ** (sizeof(Id) - 1)
    alias new_component[T: ComponentType] = Component[Id].new[T]

    fn __init__(inout self):
        self._components = Dict[UInt, ComponentInfo[Id]]()

    fn register[component_type: HashableType](inout self) raises:
        if component_type.get_type_hash() in self._components:
            raise Error("A component with hash " + str(component_type.get_type_hash()) + " has already been registered.")
        
        if len(_components) >= max_size:
            raise Error("We cannot register more than " + str(max_size) + " elements in a component manager of this type.")

        self._components[component_type.get_type_hash()] = len(_components)

    fn get_id[component_type: HashableType](self) -> UInt raises:
        return self._components[component_type.get_type_hash()]