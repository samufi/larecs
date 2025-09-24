from collections import Dict
from compile.reflection import get_type_name

from .component import (
    ComponentType,
    get_max_size,
    constrain_components_unique,
    contains_type,
)
from .unsafe_box import UnsafeBox

alias ResourceType = Copyable & Movable
"""The trait that resources must conform to."""


@fieldwise_init
struct Resources(Copyable, Movable, Sized):
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

    fn copy(self, out resources: Self):
        """Creates a copy of the resources.

        Returns:
            A copy of the resources.
        """
        resources = Resources(self._storage.copy())

    fn add[*Ts: ResourceType](mut self, var *resources: *Ts) raises:
        """Adds resources.

        Parameters:
            Ts: The Types of the resources to add.

        Args:
            resources: The resources to add.

        Raises:
            Error: If some resource already exists.
        """

        conflicting_ids = List[StringSlice[StaticConstantOrigin]]()

        @parameter
        for idx in range(resources.__len__()):
            alias id = get_type_name[Ts[idx]]()
            if id in self._storage:
                conflicting_ids.append(id)

        if len(conflicting_ids) > 0:
            raise Error("Duplicate resource: " + ", ".join(conflicting_ids))

        @parameter
        fn take_resource[idx: Int](var resource: Ts[idx]) -> None:
            self._add(get_type_name[Ts[idx]](), resource^)

        resources^.consume_elements[take_resource]()

    @always_inline
    fn _add[
        T: Copyable & Movable
    ](mut self, id: Self.IdType, var resource: Pointer[T]):
        """Adds a resource by ID.

        Parameters:
            T: The type of the resource to add.

        Args:
            id: The ID of the resource to add. It has to be not used already.
            resource: The resource to add.
        """
        self._storage[id] = UnsafeBox(resource[].copy())

    @always_inline
    fn _add[T: Copyable & Movable](mut self, id: Self.IdType, var resource: T):
        """Adds a resource by ID.

        Parameters:
            T: The type of the resource to add.

        Args:
            id: The ID of the resource to add. It has to be not used already.
            resource: The resource to add.
        """
        self._storage[id] = UnsafeBox(resource^)

    fn set[
        *Ts: ResourceType, add_if_not_found: Bool = False
    ](mut self: Resources, var *resources: *Ts) raises:
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
        if not add_if_not_found:
            conflicting_ids = List[StringSlice[StaticConstantOrigin]]()

            @parameter
            for idx in range(resources.__len__()):
                alias id = get_type_name[Ts[idx]]()
                if id not in self._storage:
                    conflicting_ids.append(id)

            if len(conflicting_ids) > 0:
                raise Error("Unknown resource: " + ", ".join(conflicting_ids))

        @parameter
        fn take_resource[idx: Int](var resource: Ts[idx]) -> None:
            self._set[add_if_not_found=add_if_not_found](
                get_type_name[Ts[idx]](),
                resource^,
            )

        resources^.consume_elements[take_resource]()

    @always_inline
    fn _set[
        T: Copyable & Movable, add_if_not_found: Bool
    ](mut self, id: Self.IdType, var resource: T):
        """Sets the values of the resources

        Parameters:
            T: The type of the resource to set.
            add_if_not_found: If true, adds resources that do not exist.

        Args:
            id: The ID of the resource to set. If add_if_not_found is false, the resource ID must be already known.
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
        __origin_of(self._storage._find_ref("").unsafe_get[T]())
    ] T:
        """Gets a resource.

        Parameters:
            T: The type of the resource to get.

        Returns:
            A reference to the resource.
        """
        return self._storage._find_ref(get_type_name[T]()).unsafe_get[T]()

    @always_inline
    fn has[T: ResourceType](mut self) -> Bool:
        """Checks if the resource is present.

        Parameters:
            T: The type of the resource to check.

        Returns:
            True if the resource is present, otherwise False.
        """
        return get_type_name[T]() in self._storage
