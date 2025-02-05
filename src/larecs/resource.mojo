from .component import ComponentType, ComponentManager, get_max_size

alias ResourceType = ComponentType
alias ResourceManager = ComponentManager


trait ResourceManaging:
    pass
    # fn get[T: ResourceType](self) -> ref [MutableAnyOrigin] T:
    #     """Gets a resource."""
    #     ...
    # fn get_ptr[T: ResourceType](self) -> Pointer[T, MutableAnyOrigin]:
    #     """Gets a resource."""
    #     ...


fn get_dtype[size: Int]() -> DType:
    """Gets the data type for the given size."""

    @parameter
    if size <= get_max_size[DType.uint8]():
        return DType.uint8
    elif size <= get_max_size[DType.uint16]():
        return DType.uint16
    elif size <= get_max_size[DType.uint32]():
        return DType.uint32
    else:
        return DType.uint64


@value
struct Resources[*Ts: ResourceType](ResourceManaging):
    """Manages resources."""

    alias size = len(VariadicList(Ts))
    alias dType = get_dtype[Self.size]()
    alias resource_manager = ResourceManager[*Ts, dType = Self.dType]()

    var _resources: Tuple[*Ts]

    fn __init__(out self, owned *values: *Ts):
        """Initializes the resources."""

        self._resources = Tuple(storage=values^)

    # fn get[T: ResourceType](self) -> T:
    #     return rebind[T](self._resources[index(Self.resource_manager.get_id[T]())])

    fn get[T: ResourceType](mut self) -> ref [self._resources[0]] T:
        """Gets a resource."""
        return rebind[T](
            self._resources[index(Self.resource_manager.get_id[T]())]
        )

    fn get_ptr[
        T: ResourceType
    ](mut self) -> Pointer[T, __origin_of(self._resources[0])]:
        """Gets a resource."""
        return Pointer.address_of(
            rebind[T](self._resources[index(Self.resource_manager.get_id[T]())])
        )
