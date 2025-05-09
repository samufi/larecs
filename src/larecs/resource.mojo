from collections import Dict

from .component import (
    ComponentType,
    get_max_size,
    constrain_components_unique,
    contains_type,
)
from .type_map import (
    TypeMapping,
    TypeIdentifiable,
    TypeId,
    StaticlyTypeMapping,
    DynamicTypeMap,
)
from .unsafe_box import UnsafeBox
from ._utils import unsafe_take

alias ResourceType = Copyable & Movable & TypeIdentifiable
"""The trait that resources must conform to."""


@value
struct Resources[TypeMap: TypeMapping = DynamicTypeMap]:
    """Manages resources.

    Parameters:
        TypeMap: A mapping from types to resource IDs.
    """

    alias IdType = TypeId
    """The type of the internal type IDs."""

    var _type_map: TypeMap
    var _storage: Dict[TypeId, UnsafeBox]

    @always_inline
    fn __init__(out self):
        """
        Constructs an empty resource container.
        """
        self._type_map = TypeMap()
        self._storage = Dict[Self.IdType, UnsafeBox]()

    @always_inline
    fn __init__(out self, owned type_map: TypeMap):
        """
        Constructs an empty resource container.

        Args:
            type_map: The type map to use.
        """
        self._type_map = type_map^
        self._storage = Dict[Self.IdType, UnsafeBox]()

    @always_inline("nodebug")
    fn __len__(self) -> Int:
        """Gets the number of stored resources.

        Returns:
            The number of stored resources.
        """
        return len(self._storage)

    @always_inline
    fn copy(self) -> Self:
        """Explicitly constructs a copy of self.

        Returns:
            A copy of this value.
        """
        return self

    fn add[
        *Ts: ResourceType
    ](mut self: Resources[DynamicTypeMap], owned *resources: *Ts) raises:
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
            self._add(self._type_map.get_id[Ts[i]](), unsafe_take(resources[i]))
        __disable_del resources

    fn add[
        *Ts: Copyable & Movable, M: StaticlyTypeMapping
    ](mut self: Resources[M], owned *resources: *Ts) raises:
        """Adds resources.

        Parameters:
            Ts: The Types of the resources to add.
            M: The type of the mapping from resources to IDs.

        Args:
            resources: The resources to add.

        Raises:
            Error: If the resource already exists.
        """

        @parameter
        for i in range(resources.__len__()):
            self._add(self._type_map.get_id[Ts[i]](), unsafe_take(resources[i]))
        __disable_del resources

    @always_inline
    fn _add[
        T: Copyable & Movable
    ](mut self, id: Self.IdType, owned resource: Pointer[T]) raises:
        """Adds a resource by ID.

        Parameters:
            T: The type of the resource to add.

        Args:
            id: The ID of the resource to add.
            resource: The resource to add.

        Raises:
            Error: If the resource already exists.
        """
        if id in self._storage:
            raise Error("Resource already exists.")
        self._storage[id] = UnsafeBox(resource[])

    @always_inline
    fn _add[
        T: Copyable & Movable
    ](mut self, id: Self.IdType, owned resource: T) raises:
        """Adds a resource by ID.

        Parameters:
            T: The type of the resource to add.

        Args:
            id: The ID of the resource to add.
            resource: The resource to add.

        Raises:
            Error: If the resource already exists.
        """
        if id in self._storage:
            raise Error("Resource already exists.")
        self._storage[id] = UnsafeBox(resource^)

    fn set[
        *Ts: ResourceType, add_if_not_found: Bool = False
    ](mut self: Resources[DynamicTypeMap], owned *resources: *Ts) raises:
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
            self._set[add_if_not_found=add_if_not_found](
                self._type_map.get_id[Ts[i]](),
                unsafe_take(resources[i]),
            )
        __disable_del resources

    fn set[
        *Ts: Copyable & Movable,
        M: StaticlyTypeMapping,
        add_if_not_found: Bool = False,
    ](mut self: Resources[M], owned *resources: *Ts) raises:
        """Sets the values of resources.

        Parameters:
            Ts: The types of the resources to set.
            M: The type of the mapping from resources to IDs.
            add_if_not_found: If true, adds resources that do not exist.

        Args:
            resources: The resources to set.

        Raises:
            Error: If one of the resources does not exist.
        """

        @parameter
        for i in range(resources.__len__()):
            self._set[add_if_not_found=add_if_not_found](
                self._type_map.get_id[Ts[i]](),
                unsafe_take(resources[i]),
            )
        __disable_del resources

    @always_inline
    fn _set[
        T: Copyable & Movable, add_if_not_found: Bool
    ](mut self, id: Self.IdType, owned resource: T) raises:
        """Sets the values of the resources

        Parameters:
            T: The type of the resource to set.
            add_if_not_found: If true, adds resources that do not exist.

        Args:
            id: The ID of the resource to set.
            resource: The resource to set.

        Raises:
            Error: If one of the resources does not exist.
        """

        ptr = self._storage.get_ptr(id)

        if not ptr:

            @parameter
            if add_if_not_found:
                self._add(id, resource^)
            else:
                raise Error("Resource " + String(id) + " not found.")
        else:
            ptr.value()[].unsafe_get[T]() = resource^

    fn remove[*Ts: ResourceType](mut self: Resources[DynamicTypeMap]) raises:
        """Removes resources.

        Parameters:
            Ts: The types of the resources to remove.

        Raises:
            Error: If one of the resources does not exist.
        """

        @parameter
        for i in range(len(VariadicList(Ts))):
            self._remove[Ts[i]](self._type_map.get_id[Ts[i]]())

    fn remove[
        *Ts: Copyable & Movable, M: StaticlyTypeMapping
    ](mut self: Resources[M]) raises:
        """Removes resources.

        Parameters:
            Ts: The types of the resources to remove.
            M: The type of the mapping from resources to IDs.

        Raises:
            Error: If one of the resources does not exist.
        """

        @parameter
        for i in range(len(VariadicList(Ts))):
            self._remove[Ts[i]](self._type_map.get_id[Ts[i]]())

    @always_inline
    fn _remove[T: Copyable & Movable](mut self, id: Self.IdType) raises:
        """Removes resources.

        Parameters:
            T: The type of the resource to remove.

        Raises:
            Error: If the resource does not exist.
        """

        ptr = self._storage.get_ptr(id)
        if not ptr:
            raise Error("The resource does not exist.")
        _ = self._storage.pop(id)

    @always_inline
    fn get[
        T: ResourceType
    ](mut self: Resources[DynamicTypeMap]) raises -> ref [
        self._get_ptr[T](Self.IdType(0))[]
    ] T:
        """Gets a resource.

        Parameters:
            T: The type of the resource to get.

        Returns:
            A reference to the resource.
        """
        return self.get_ptr[T]()[]

    @always_inline
    fn get[
        T: Copyable & Movable, M: StaticlyTypeMapping
    ](mut self: Resources[M]) raises -> ref [
        self._get_ptr[T](Self.IdType(0))[]
    ] T:
        """Gets a resource.

        Parameters:
            T: The type of the resource to get.
            M: The type of the mapping from resources to IDs.

        Returns:
            A reference to the resource.
        """
        return self.get_ptr[T, M]()[]

    @always_inline
    fn get_ptr[
        T: ResourceType
    ](mut self: Resources[DynamicTypeMap]) raises -> Pointer[
        T,
        __origin_of(
            self._storage.get_ptr(Self.IdType(0))
            .value()[]
            .unsafe_get_ptr[T]()[]
        ),
    ]:
        """Gets a pointer to a resource.

        Parameters:
            T: The type of the resource to get.

        Returns:
            A pointer to the resource.
        """
        return self._get_ptr[T](self._type_map.get_id[T]())

    @always_inline
    fn get_ptr[
        T: Copyable & Movable, M: StaticlyTypeMapping
    ](mut self: Resources[M]) raises -> Pointer[
        T,
        __origin_of(
            self._storage.get_ptr(Self.IdType(0))
            .value()[]
            .unsafe_get_ptr[T]()[]
        ),
    ]:
        """Gets a pointer to a resource.

        Parameters:
            T: The type of the resource to get.
            M: The type of the mapping from resources to IDs.

        Returns:
            A pointer to the resource.
        """
        return self._get_ptr[T](self._type_map.get_id[T]())

    @always_inline
    fn _get_ptr[
        T: Copyable & Movable
    ](mut self, id: Self.IdType) raises -> Pointer[
        T,
        __origin_of(self._storage.get_ptr(id).value()[].unsafe_get_ptr[T]()[]),
    ]:
        """Gets a pointer to a resource.

        Parameters:
            T: The type of the resource to get.

        Args:
            id: The ID of the resource to get.

        Returns:
            A pointer to the resource.
        """
        ptr = self._storage.get_ptr(id)
        if not ptr:
            raise Error("Resource " + String(id) + " not found.")

        return ptr.value()[].unsafe_get_ptr[T]()

    @always_inline
    fn has[T: ResourceType](mut self: Resources[DynamicTypeMap]) -> Bool:
        """Checks if the resource is present.

        Parameters:
            T: The type of the resource to check.

        Returns:
            True if the resource is present, otherwise False.
        """
        return self._type_map.get_id[T]() in self._storage

    @always_inline
    fn has[
        T: Copyable & Movable, M: StaticlyTypeMapping
    ](mut self: Resources[M]) -> Bool:
        """Checks if the resource is present.

        Parameters:
            T: The type of the resource to check.
            M: The type of the mapping from resources to IDs.

        Returns:
            True if the resource is present, otherwise False.
        """
        return self._type_map.get_id[T]() in self._storage
