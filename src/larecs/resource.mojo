from collections import Dict

from .component import (
    ComponentType,
    ComponentManager,
    get_max_size,
    constrain_components_unique,
)
from .unsafe_box import UnsafeBox

alias ResourceManager = ComponentManager
"""The mapper of resource types to resource IDs."""


fn get_dtype[size: Int]() -> DType:
    """Gets the data type for the given size.

    Parameters:
        size: The size of the data type.
    """

    @parameter
    if size <= get_max_size[DType.uint8]():
        return DType.uint8
    elif size <= get_max_size[DType.uint16]():
        return DType.uint16
    elif size <= get_max_size[DType.uint32]():
        return DType.uint32
    else:
        return DType.uint64


trait TypeMapping(CollectionElement):
    fn get_id[T: ComponentType](self) -> Int:
        """Gets the ID of the type.

        Parameters:
            T: The type to get the ID for.

        Returns:
            The ID of the type.
        """
        ...

    fn __init__(out self):
        """Constructs a new type mapping."""
        pass


@value
struct StaticTypeMap[*Ts: CollectionElement](TypeMapping):
    """Maps types to resource IDs.

    Parameters:
        Ts: The types to map.
    """

    alias manager = ResourceManager[*Ts]()

    fn get_id[T: ComponentType](self) -> Int:
        return Int(self.manager.get_id[T]())


@value
struct Resources[TypeMapper: TypeMapping = StaticTypeMap]:
    """Manages resources.

    Parameters:
        TypeMapper: A mapping from types to resource IDs.
    """

    var _type_mapper: TypeMapper
    var _storage: Dict[Int, UnsafeBox]

    @always_inline
    fn __init__(out self):
        """Constructs an empty resource container."""
        self._type_mapper = TypeMapper()
        self._storage = Dict[Int, UnsafeBox]()

    @always_inline
    fn __init__(out self, owned type_mapper: TypeMapper):
        """
        Constructs an empty resource container with a given type mapper.

        Args:
            type_mapper: The type mapper to use.
        """
        self._type_mapper = type_mapper^
        self._storage = Dict[Int, UnsafeBox]()

    @always_inline
    fn copy(self) -> Self:
        """Explicitly constructs a copy of self.

        Returns:
            A copy of this value.
        """
        return self

    @always_inline("nodebug")
    fn __len__(self) -> Int:
        """Gets the number of stored resources.

        Returns:
            The number of stored resources.
        """
        return len(self._storage)

    fn add[*Ts: CollectionElement](mut self, owned *resources: *Ts) raises:
        """Adds resources.

        Parameters:
            Ts: The Types of the resources to add.

        Args:
            resources: The resources to add.

        Raises:
            Error: If the resource already exists.
        """

        @parameter
        for i in range(resources.__len__()):
            id = self._type_mapper.get_id[Ts[i]]()
            if id in self._storage:
                raise Error("Resource already exists.")
            self._storage[id] = UnsafeBox(resources[i])

    fn set[
        *Ts: CollectionElement, add_if_not_found: Bool = False
    ](mut self, owned *resources: *Ts) raises:
        """Sets the values of resources.

        Parameters:
            Ts: The types of the resources to set.
            add_if_not_found: If true, adds resources that do not exist.

        Args:
            resources: The resources to set.

        Raises:
            Error: If one of the resources does not exist.
        """

        @parameter
        for i in range(resources.__len__()):
            ptr = self._storage.get_ptr(self._type_mapper.get_id[Ts[i]]())

            if not ptr:

                @parameter
                if add_if_not_found:
                    self.add(resources[i])
                else:
                    raise Error("Resource not found.")
            else:
                ptr.value()[].unsafe_get[Ts[i.value]]() = resources[i.value]

    fn remove[*Ts: CollectionElement](mut self) raises:
        """Removes resources.

        Parameters:
            Ts: The types of the resources to remove.

        Raises:
            Error: If one of the resources does not exist.
        """

        @parameter
        for i in range(len(VariadicList(Ts))):
            id = self._type_mapper.get_id[Ts[i]]()
            if id not in self._storage:
                raise Error("The resource does not exist.")
            _ = self._storage.pop(id)

    @always_inline
    fn get[
        T: CollectionElement
    ](ref self) raises -> ref [self.get_ptr[T]()[]] T:
        """Gets a resource.

        Parameters:
            T: The type of the resource to get.

        Returns:
            A reference to the resource.
        """
        return self.get_ptr[T]()[]

    @always_inline
    fn get_ptr[
        T: CollectionElement
    ](ref self) raises -> Pointer[
        T, __origin_of(self._storage.get_ptr(0).value()[].unsafe_get_ptr[T]()[])
    ]:
        """Gets a pointer to a resource.

        Parameters:
            T: The type of the resource to get.

        Returns:
            A pointer to the resource.
        """
        ptr = self._storage.get_ptr(self._type_mapper.get_id[T]())
        if not ptr:
            raise Error("Resource not found.")

        return ptr.value()[].unsafe_get_ptr[T]()

    @always_inline
    fn has[T: CollectionElement](self) -> Bool:
        """Checks if the resource is present.

        Parameters:
            T: The type of the resource to check.

        Returns:
            True if the resource is present, otherwise False.
        """
        return self._type_mapper.get_id[T]() in self._storage
