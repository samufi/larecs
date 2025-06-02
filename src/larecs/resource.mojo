from collections import Dict
from compile.reflection import get_type_name

from .component import (
    ComponentType,
    get_max_size,
    constrain_components_unique,
    contains_type,
)
from .unsafe_box import UnsafeBox
from ._utils import unsafe_take

alias ResourceType = Copyable & Movable
"""The trait that resources must conform to."""


@value
struct Resources(ExplicitlyCopyable, Movable):
    """Manages resources."""

    alias IdType = StringSlice[StaticConstantOrigin]
    """The type of the internal type IDs."""

    var _storage: Dict[Self.IdType, UnsafeBox]

    @always_inline
    fn __init__(out self):
        """
        Constructs an empty resource container.
        """
        self._storage = Dict[Self.IdType, UnsafeBox]()

    @always_inline("nodebug")
    fn __len__(self) -> Int:
        """Gets the number of stored resources.

        Returns:
            The number of stored resources.
        """
        return len(self._storage)

    fn add[*Ts: ResourceType](mut self, owned *resources: *Ts) raises:
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
            self._add(get_type_name[Ts[i]](), unsafe_take(resources[i]))
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
    ](mut self: Resources, owned *resources: *Ts) raises:
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
                get_type_name[Ts[i]](),
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

        try:
            self._storage._find_ref(id).unsafe_get[T]() = resource^
        except:

            @parameter
            if add_if_not_found:
                self._add(id, resource^)
            else:
                raise Error("Resource " + String(id) + " not found.")

    fn remove[*Ts: ResourceType](mut self: Resources) raises:
        """Removes resources.

        Parameters:
            Ts: The types of the resources to remove.

        Raises:
            Error: If one of the resources does not exist.
        """

        @parameter
        for i in range(len(VariadicList(Ts))):
            self._remove[Ts[i]](get_type_name[Ts[i]]())

    @always_inline
    fn _remove[T: Copyable & Movable](mut self, id: Self.IdType) raises:
        """Removes resources.

        Parameters:
            T: The type of the resource to remove.

        Raises:
            Error: If the resource does not exist.
        """
        try:
            _ = self._storage.pop(id)
        except:
            raise Error("The resource does not exist.")

    @always_inline
    fn get[
        T: ResourceType
    ](mut self) raises -> ref [
        __origin_of(self._storage._find_ref("").unsafe_get_ptr[T]()[])
    ] T:
        """Gets a resource.

        Parameters:
            T: The type of the resource to get.

        Returns:
            A reference to the resource.
        """
        return self._storage._find_ref(get_type_name[T]()).unsafe_get_ptr[T]()[]

    @always_inline
    fn has[T: ResourceType](mut self) -> Bool:
        """Checks if the resource is present.

        Parameters:
            T: The type of the resource to check.

        Returns:
            True if the resource is present, otherwise False.
        """
        return get_type_name[T]() in self._storage
