from memory import UnsafePointer
from collections import InlineArray

from .component import (
    ComponentType,
    ComponentManager,
    get_max_size,
    constrain_components_unique,
)

alias ResourceManager = ComponentManager
"""The mapper of resource types to resource IDs."""


@value
struct _Nothing:
    """A type that represents nothing."""

    pass


alias NoResource = Resources[_Nothing]
"""A resource container that does not contain any resources."""


trait ResourceContaining(CollectionElement, ExplicitlyCopyable, Sized):
    fn __init__(out self):
        """Constructs the resource container."""
        ...

    fn add[*Ts: CollectionElement](mut self, owned *resources: *Ts) raises:
        """Adds resources.

        Parameters:
            Ts: The Types of the resources to add.

        Args:
            resources: The resources to add.

        Raises:
            Error: If the resource already exists.
        """
        ...

    fn remove[*Ts: CollectionElement](mut self) raises:
        """Removes resources.

        Parameters:
            Ts: The types of the resources to remove.

        Raises:
            Error: If one of the resources does not exist.
        """
        ...

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
        ...

    fn get[T: CollectionElement](ref self) raises -> ref [self] T:
        """Gets a resource.

        Parameters:
            T: The type of the resource to get.

        Returns:
            A reference to the resource.
        """
        ...

    fn get_ptr[
        T: CollectionElement
    ](ref self) raises -> Pointer[T, __origin_of(self)]:
        """Gets a pointer to a resource.

        Parameters:
            T: The type of the resource to get.

        Returns:
            A pointer to the resource.
        """
        ...

    fn has[T: CollectionElement](self) -> Bool:
        """Checks if the resource is present.

        Parameters:
            T: The type of the resource to check.

        Returns:
            True if the resource is present, otherwise False.
        """
        ...


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


@value
struct Resources[*resource_types: CollectionElement](ResourceContaining):
    """Manages resources.

    Some code was taken from Mojo's `Tuple` implementation.
    See [here](https://github.com/modular/mojo/blob/main/stdlib/src/builtin/tuple.mojo).

    Parameters:
        resource_types: The types of resources to manage. All types must be different
                       from each other.
    """

    alias size = len(VariadicList(resource_types))
    """The number of resources managed."""

    alias dType = get_dtype[Self.size]()
    """The data type to use as index."""

    alias resource_manager = ResourceManager[
        *resource_types, dType = Self.dType
    ]()
    """The resource manager that maps types to resource IDs."""

    alias _mlir_type = __mlir_type[
        `!kgen.pack<:!kgen.variadic<`,
        CollectionElement,
        `> `,
        resource_types,
        `>`,
    ]
    """The type of the internal storage."""

    var _storage: Self._mlir_type

    var _initialized_flags: InlineArray[Bool, max(Self.size, 1)]

    @always_inline
    fn __init__(out self):
        """Constructs an empty resource container."""

        # Mark 'self.storage' as being initialized so we can work on it.
        __mlir_op.`lit.ownership.mark_initialized`(
            __get_mvalue_as_litref(self._storage)
        )
        self._initialized_flags = InlineArray[Bool, max(Self.size, 1)](False)

    fn __init__[*Ts: CollectionElement](out self, owned *args: *Ts):
        """Constructs the resource container and initializes given values.

        Parameters:
            Ts: The types of the resources to add.

        Args:
            args: The provided initial values.

        Returns:
            The constructed resource container.
        """

        self = Self()
        try:
            self._add_or_set(args^)
        except:
            pass

    @always_inline
    fn __init__(out self, owned *args: *resource_types):
        """Constructs the resource container initializing all values.

        The types of the resources may be inferred from the provided values.

        Args:
            args: Initial values.
        """
        self = Self()

        try:
            self._add_or_set(args^)
        except:
            pass

    fn __del__(owned self):
        """Destructor that destroys all of the stored resources."""

        # Run the destructor on each member, the destructor of !kgen.pack is
        # trivial and won't do anything.
        @parameter
        for i in range(Self.size):
            if self._initialized_flags[i]:
                self._unsafe_get_ptr[i]().destroy_pointee()

    @always_inline("nodebug")
    fn __copyinit__(out self, existing: Self):
        """Copy constructs the resources.

        Args:
            existing: The value to copy from.
        """

        # Mark 'storage' as being initialized so we can work on it.
        __mlir_op.`lit.ownership.mark_initialized`(
            __get_mvalue_as_litref(self._storage)
        )

        self._initialized_flags = existing._initialized_flags

        @parameter
        for i in range(Self.size):
            if self._initialized_flags[i]:
                self._unsafe_get_ptr[i]().init_pointee_copy(
                    existing._unsafe_get_ptr[i]()[]
                )

    @always_inline
    fn copy(self) -> Self:
        """Explicitly constructs a copy of self.

        Returns:
            A copy of this value.
        """
        return self

    @always_inline
    fn __moveinit__(out self, owned existing: Self):
        """Move constructs the resources.

        Args:
            existing: The value to move from.
        """

        # Mark 'storage' as being initialized so we can work on it.
        __mlir_op.`lit.ownership.mark_initialized`(
            __get_mvalue_as_litref(self._storage)
        )

        self._initialized_flags = existing._initialized_flags

        @parameter
        for i in range(Self.size):
            if existing._initialized_flags[i]:
                existing._unsafe_get_ptr[i]().move_pointee_into(
                    self._unsafe_get_ptr[i]()
                )
        # Note: The destructor on `existing` is auto-disabled in a moveinit.

    @always_inline("nodebug")
    fn __len__(self) -> Int:
        """Gets the number of stored resources.

        Returns:
            The number of stored resources.
        """
        return Self.size

    @always_inline
    fn _unsafe_get_ptr[
        idx: Int
    ](ref self) -> UnsafePointer[resource_types[idx.value]]:
        """Gets an unsafe pointer to a resource.

        Paramters:
            idx: The index of the resource to get.

        Returns:
            An unsafe pointer to the resource.
        """
        var storage_kgen_ptr = UnsafePointer.address_of(self._storage).address

        # KGenPointer to the element.
        var elt_kgen_ptr = __mlir_op.`kgen.pack.gep`[index = idx.value](
            storage_kgen_ptr
        )
        return UnsafePointer(elt_kgen_ptr)

    fn add[*Ts: CollectionElement](mut self, owned *resources: *Ts) raises:
        """Adds resources.

        Parameters:
            Ts: The Types of the resources to add.

        Args:
            resources: The resources to add.

        Raises:
            Error: If the resource already exists.
        """
        self._add_or_set[raise_if_found=True](resources^)

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
        self._add_or_set[raise_if_not_found = not add_if_not_found](resources^)

    @always_inline
    fn _add_or_set[
        *Ts: CollectionElement,
        raise_if_found: Bool = False,
        raise_if_not_found: Bool = False,
    ](
        mut self, owned resources: VariadicPack[_, CollectionElement, *Ts]
    ) raises:
        """Sets the resources.

        Parameters:
            Ts: The types of the resources to set.
            raise_if_found: If true, raises an error if a resource already exists.
            raise_if_not_found: If true, raises an error if a resource does not exist.

        Args:
            resources: The values to set.
        """

        constrain_components_unique[*Ts]()

        @parameter
        for i in range(resources.__len__()):
            alias idx = Self.resource_manager.get_id[Ts[i]]()

            if self._initialized_flags[idx]:

                @parameter
                if raise_if_found:
                    raise Error(
                        "The resource already exists. Use `set` to update it."
                    )
                else:
                    self._unsafe_get_ptr[Int(idx)]().destroy_pointee()
            else:

                @parameter
                if raise_if_not_found:
                    raise Error(
                        "The resource does not exist. Use `add` to add it."
                    )
                else:
                    self._initialized_flags[idx] = True

            UnsafePointer.address_of(
                rebind[resource_types[Int(idx).value]](resources[i])
            ).move_pointee_into(self._unsafe_get_ptr[Int(idx)]())

        __disable_del resources

    fn remove[*Ts: CollectionElement](mut self) raises:
        """Removes resources.

        Parameters:
            Ts: The types of the resources to remove.

        Raises:
            Error: If one of the resources does not exist.
        """

        @parameter
        for i in range(len(VariadicList(Ts))):
            self._assert_has[Ts[i]]()
            self._unsafe_get_ptr[
                index(Self.resource_manager.get_id[Ts[i]]())
            ]().destroy_pointee()
            self._initialized_flags[
                Self.resource_manager.get_id[Ts[i]]()
            ] = False

    @always_inline
    fn get[T: CollectionElement](ref self) raises -> ref [self] T:
        """Gets a resource.

        Parameters:
            T: The type of the resource to get.

        Returns:
            A reference to the resource.
        """
        self._assert_has[T]()
        return rebind[T](
            self._unsafe_get_ptr[index(Self.resource_manager.get_id[T]())]()[]
        )

    @always_inline
    fn get_ptr[
        T: CollectionElement
    ](ref self) raises -> Pointer[T, __origin_of(self)]:
        """Gets a pointer to a resource.

        Parameters:
            T: The type of the resource to get.

        Returns:
            A pointer to the resource.
        """
        return Pointer.address_of(self.get[T]())

    @always_inline
    fn has[T: CollectionElement](self) -> Bool:
        """Checks if the resource is present.

        Parameters:
            T: The type of the resource to check.

        Returns:
            True if the resource is present, otherwise False.
        """
        return self._initialized_flags[Self.resource_manager.get_id[T]()]

    @always_inline
    fn _assert_has[T: CollectionElement](self) raises:
        """Asserts that the resource is present.

        Parameters:
            T: The type of the resource to check.
        """
        if not self._initialized_flags[Self.resource_manager.get_id[T]()]:
            raise Error(
                "The requested resource does not exist. Use `add` to add it."
            )
