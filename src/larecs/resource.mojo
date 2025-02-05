from memory import UnsafePointer

from .component import ComponentType, ComponentManager, get_max_size

alias ResourceType = ComponentType
alias ResourceManager = ComponentManager


trait ResourceManaging(CollectionElement):
    fn get[T: ResourceType](ref self) -> ref [self] T:
        """Gets a resource."""
        ...

    fn get_ptr[T: ResourceType](ref self) -> Pointer[T, __origin_of(self)]:
        """Gets a resource."""
        ...


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

    alias _mlir_type = __mlir_type[
        `!kgen.pack<:!kgen.variadic<`,
        CollectionElement,
        `> `,
        Ts,
        `>`,
    ]

    var _storage: Self._mlir_type

    @always_inline("nodebug")
    fn __init__(out self, owned *args: *Ts):
        """Construct the tuple.

        Args:
            args: Initial values.
        """
        self = Self(storage=args^)

    @always_inline("nodebug")
    fn __init__(
        mut self,
        *,
        owned storage: VariadicPack[_, CollectionElement, *Ts],
    ):
        """Construct the tuple from a low-level internal representation.

        Args:
            storage: The variadic pack storage to construct from.
        """

        # Mark 'self.storage' as being initialized so we can work on it.
        __mlir_op.`lit.ownership.mark_initialized`(
            __get_mvalue_as_litref(self._storage)
        )

        # Move each element into the tuple storage.
        @parameter
        for i in range(Self.size):
            UnsafePointer.address_of(storage[i]).move_pointee_into(
                self._unsafe_get_ptr[i]()
            )

        # Do not destroy the elements when 'storage' goes away.
        __disable_del storage

    fn __del__(owned self):
        """Destructor that destroys all of the elements."""

        # Run the destructor on each member, the destructor of !kgen.pack is
        # trivial and won't do anything.
        @parameter
        for i in range(Self.size):
            self._unsafe_get_ptr[i]().destroy_pointee()

    @always_inline("nodebug")
    fn __copyinit__(out self, existing: Self):
        """Copy construct the tuple.

        Args:
            existing: The value to copy from.
        """
        # Mark 'storage' as being initialized so we can work on it.
        __mlir_op.`lit.ownership.mark_initialized`(
            __get_mvalue_as_litref(self._storage)
        )

        @parameter
        for i in range(Self.size):
            self._unsafe_get_ptr[i]().init_pointee_copy(
                existing._unsafe_get_ptr[i]()[]
            )

    @always_inline
    fn copy(self) -> Self:
        """Explicitly construct a copy of self.

        Returns:
            A copy of this value.
        """
        return self

    @always_inline
    fn __moveinit__(out self, owned existing: Self):
        """Move construct the tuple.

        Args:
            existing: The value to move from.
        """

        # Mark 'storage' as being initialized so we can work on it.
        __mlir_op.`lit.ownership.mark_initialized`(
            __get_mvalue_as_litref(self._storage)
        )

        @parameter
        for i in range(Self.size):
            existing._unsafe_get_ptr[i]().move_pointee_into(
                self._unsafe_get_ptr[i]()
            )
        # Note: The destructor on `existing` is auto-disabled in a moveinit.

    @always_inline("nodebug")
    fn __len__(self) -> Int:
        """Get the number of elements in the tuple.

        Returns:
            The number of stored resources.
        """
        return Self.size

    @always_inline
    fn _unsafe_get_ptr[idx: Int](ref self) -> UnsafePointer[Ts[idx.value]]:
        """Gets an unsafe pointer to an element."""
        var storage_kgen_ptr = UnsafePointer.address_of(self._storage).address

        # KGenPointer to the element.
        var elt_kgen_ptr = __mlir_op.`kgen.pack.gep`[index = idx.value](
            storage_kgen_ptr
        )
        return UnsafePointer(elt_kgen_ptr)

    @always_inline
    fn get[T: ResourceType](ref self) -> ref [self] T:
        """Gets a resource."""

        return rebind[T](
            self._unsafe_get_ptr[index(Self.resource_manager.get_id[T]())]()[]
        )

    @always_inline
    fn get_ptr[T: ResourceType](ref self) -> Pointer[T, __origin_of(self)]:
        """Gets a pointer to a resource."""
        return Pointer.address_of(self.get[T]())
