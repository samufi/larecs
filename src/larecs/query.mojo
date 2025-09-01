from .entity import Entity
from .bitmask import BitMask
from .component import ComponentType, ComponentManager
from .archetype import Archetype as _Archetype
from .world import World
from .lock import LockMask
from .debug_utils import debug_warn
from .static_optional import StaticOptional
from .static_variant import StaticVariant


struct Query[
    world_origin: MutableOrigin,
    *ComponentTypes: ComponentType,
    has_without_mask: Bool = False,
](Copyable, ExplicitlyCopyable, Movable, SizedRaising):
    """Query builder for entities with and without specific components.

    This type should not be used directly, but through the [..world.World.query] method:

    ```mojo {doctest="query_init" global=true hide=true}
    from larecs import World, Resources, MutableEntityAccessor
    ```

    ```mojo {doctest="query_init"}
    world = World[Float64, Float32, Int]()
    _ = world.add_entity(Float64(1.0), Float32(2.0), 3)
    _ = world.add_entity(Float64(1.0), 3)

    for entity in world.query[Float64, Int]():
        ref f = entity.get[Float64]()
        f += 1
    ```

    Parameters:
        world_origin: The origin of the world.
        ComponentTypes: The types of the components to include in the query.
        has_without_mask: Whether the query has excluded components.
    """

    alias World = World[*ComponentTypes]

    alias QueryWithWithout = Query[
        world_origin,
        *ComponentTypes,
        has_without_mask=True,
    ]

    var _world: Pointer[Self.World, world_origin]
    var _mask: BitMask
    var _without_mask: StaticOptional[BitMask, has_without_mask]

    @doc_private
    fn __init__(
        out self,
        world: Pointer[Self.World, world_origin],
        owned mask: BitMask,
        owned without_mask: StaticOptional[BitMask, has_without_mask] = None,
    ):
        """
        Creates a new query.

        The constructors should not be used directly, but through the [..world.World.query] method.

        Args:
            world: A pointer to the world.
            mask: The mask of the components to iterate over.
            without_mask: The mask for components to exclude.
        """
        self._world = world
        self._mask = mask^
        self._without_mask = without_mask^

    fn __len__(self) raises -> Int:
        """
        Returns the number of entities matching the query.

        Note that this requires the creation of an iterator from the query.
        If you intend to iterate anyway, get the iterator with [.Query.__iter__],
        and call `len` on it, instead.
        """
        return len(self.__iter__())

    @always_inline
    fn __iter__(
        self,
        out iterator: self.World.Iterator[
            __origin_of(self._world[]._archetypes),
            __origin_of(self._world[]._locks),
            arch_iter_variant_idx=0,
            has_start_indices=False,
            has_without_mask=has_without_mask,
        ],
    ) raises:
        """
        Creates an iterator over all entities that match the query.

        Returns:
            An iterator over all entities that match the query.

        Raises:
            Error: If the lock cannot be acquired (more than 256 locks exist).
        """
        iterator = self._world[]._get_entity_iterator(
            self._mask, self._without_mask
        )

    @always_inline
    fn without[
        *Ts: ComponentType
    ](owned self, out query: Self.QueryWithWithout):
        """
        Excludes the given components from the query.

        ```mojo {doctest="query_without" global=true hide=true}
        from larecs import World, Resources, MutableEntityAccessor
        ```

        ```mojo {doctest="query_without"}
        world = World[Float64, Float32, Int]()
        _ = world.add_entity(Float64(1.0), Float32(2.0), 3)
        _ = world.add_entity(Float64(1.0), 3)

        for entity in world.query[Float64, Int]().without[Float32]():
            ref f = entity.get[Float64]()
            f += 1
        ```

        Parameters:
            Ts: The types of the components to exclude.

        Returns:
            The query, excluding the given components.
        """
        query = Self.QueryWithWithout(
            self._world,
            self._mask,
            BitMask(Self.World.component_manager.get_id_arr[*Ts]()),
        )

    @always_inline
    fn exclusive(owned self, out query: Self.QueryWithWithout):
        """
        Makes the query only match entities with exactly the query's components.

        ```mojo {doctest="query_without" global=true hide=true}
        from larecs import World, Resources, MutableEntityAccessor
        ```

        ```mojo {doctest="query_without"}
        world = World[Float64, Float32, Int]()
        _ = world.add_entity(Float64(1.0), Float32(2.0), 3)
        _ = world.add_entity(Float64(1.0), 3)

        for entity in world.query[Float64, Int]().exclusive():
            ref f = entity.get[Float64]()
            f += 1
        ```

        Returns:
            The query, made exclusive.
        """
        query = Self.QueryWithWithout(
            self._world,
            self._mask,
            self._mask.invert(),
        )


@fieldwise_init
struct QueryInfo[
    has_without_mask: Bool = False,
](Copyable, ExplicitlyCopyable, Movable):
    """
    Class that holds the same information as a query but no reference to the world.

    This struct can be constructed implicitly from a [.Query] instance.
    Therefore, [.Query] instances can be used instead of QueryInfo in function
    arguments.

    Parameters:
        has_without_mask: Whether the query has excluded components.
    """

    var mask: BitMask
    var without_mask: StaticOptional[BitMask, has_without_mask]

    @implicit
    fn __init__(
        out self,
        query: Query[has_without_mask=has_without_mask],
    ):
        """
        Takes the query info from an existing query.

        Args:
            query: The query the information should be taken from.
        """
        self.mask = query._mask
        self.without_mask = query._without_mask


struct _ArchetypeByMaskIterator[
    archetype_mutability: Bool, //,
    archetype_origin: Origin[archetype_mutability],
    *ComponentTypes: ComponentType,
    component_manager: ComponentManager[*ComponentTypes],
    has_without_mask: Bool = False,
](Boolable, ExplicitlyCopyable, Iterator, Movable, Sized):
    """
    Iterator over non-empty archetypes corresponding to given include and exclude masks.

    Note: For internal use only! Do not expose to users. Does not lock the world.

    Parameters:
        archetype_mutability: Whether the reference to the archetypes is mutable.
        archetype_origin: The origin of the archetypes.
        ComponentTypes: The types of the components.
        component_manager: The component manager.
        has_without_mask: Whether the iterator has excluded components.
    """

    alias buffer_size = 8
    alias Archetype = _Archetype[
        *ComponentTypes, component_manager=component_manager
    ]
    alias Element = Pointer[Self.Archetype, archetype_origin]
    var _archetypes: Pointer[List[Self.Archetype], archetype_origin]
    var _archetype_index_buffer: SIMD[DType.int32, Self.buffer_size]
    var _mask: BitMask
    var _without_mask: StaticOptional[BitMask, has_without_mask]
    var _archetype_count: Int
    var _buffer_index: Int
    var _max_buffer_index: Int

    fn __init__(
        out self,
        archetypes: Pointer[List[Self.Archetype], archetype_origin],
        owned mask: BitMask,
        owned without_mask: StaticOptional[BitMask, has_without_mask] = None,
    ):
        """
        Creates an entity iterator.

        Args:
            archetypes: a pointer to the world's archetypes.
            mask: The mask of the archetypes to iterate over.
            without_mask: An optional mask for archetypes to exclude.
        """

        self._archetypes = archetypes
        self._archetype_count = len(self._archetypes[])
        self._mask = mask^
        self._without_mask = without_mask^

        self._buffer_index = 0
        self._max_buffer_index = Self.buffer_size
        self._archetype_index_buffer = SIMD[DType.int32, Self.buffer_size](-1)

        self._fill_archetype_buffer()

        # If the buffer is not empty, we set the buffer index to -1
        # so that it is incremented to 0 in the first call to __next__.
        if self._archetype_index_buffer[0] >= 0:
            self._buffer_index = -1

    @doc_private
    @always_inline
    fn __init__(
        out self,
        archetypes: Pointer[List[Self.Archetype], archetype_origin],
        archetype_index_buffer: SIMD[DType.int32, Self.buffer_size],
        owned mask: BitMask,
        owned without_mask: StaticOptional[BitMask, has_without_mask],
        archetype_count: Int,
        buffer_index: Int,
        max_buffer_index: Int,
    ):
        """
        Initializes the iterator based on given field values.

        Args:
            archetypes: A pointer to the world's archetypes.
            archetype_index_buffer: The buffer of valid archetypes indices.
            mask: The mask of the archetypes to iterate over.
            without_mask: An optional mask for archetypes to exclude.
            archetype_count: The number of archetypes in the world.
            buffer_index: Current index in the archetype buffer.
            max_buffer_index: Maximal valid index in the archetype buffer.
        """
        self._archetypes = archetypes
        self._archetype_index_buffer = archetype_index_buffer
        self._mask = mask^
        self._without_mask = without_mask^
        self._archetype_count = archetype_count
        self._buffer_index = buffer_index
        self._max_buffer_index = max_buffer_index

    fn _fill_archetype_buffer(mut self):
        """
        Find the next archetypes that contain the mask.

        Fills the _archetype_index_buffer with the
        archetypes' indices.
        """
        buffer_index = 0
        for i in range(
            self._archetype_index_buffer[self._buffer_index] + 1,
            self._archetype_count,
        ):
            is_valid = self._archetypes[].unsafe_get(i).get_mask().contains(
                self._mask
            ) and self._archetypes[].unsafe_get(i)

            @parameter
            if has_without_mask:
                is_valid &= (
                    not self._archetypes[]
                    .unsafe_get(i)
                    .get_mask()
                    .contains_any(self._without_mask[])
                )

            if is_valid:
                self._archetype_index_buffer[buffer_index] = i
                buffer_index += 1
                if buffer_index >= Self.buffer_size:
                    return

        # If the buffer is not full, we
        # note the last index that is still valid.
        self._max_buffer_index = buffer_index - 1

    @always_inline
    fn __iter__(owned self, out iterator: Self):
        """
        Returns self as an iterator usable in for loops.

        Returns:
            Self as an iterator usable in for loops.
        """
        iterator = self^

    @always_inline
    fn __next__(mut self, out archetype: Self.Element):
        """
        Returns the next archetype in the iteration.

        Returns:
            The next archetype as a pointer.
        """
        self._buffer_index += 1
        archetype = Pointer(
            to=self._archetypes[].unsafe_get(
                index(self._archetype_index_buffer[self._buffer_index])
            )
        )
        if self._buffer_index >= Self.buffer_size - 1:
            self._fill_archetype_buffer()
            self._buffer_index = -1  # Will be incremented to 0

    fn __len__(self) -> Int:
        """
        Returns the number of archetypes remaining in the iterator.

        Note that this requires iterating over all archetypes
        and may be a complex operation.
        """

        if self._max_buffer_index < Self.buffer_size:
            return self._max_buffer_index - self._buffer_index

        size = Self.buffer_size

        # If there are more archetypes than the buffer size, we
        # need to iterate over the remaining archetypes.
        for i in range(
            self._archetype_index_buffer[Self.buffer_size - 1] + 1,
            len(self._archetypes[]),
        ):
            is_valid = self._archetypes[].unsafe_get(i).get_mask().contains(
                self._mask
            ) and self._archetypes[].unsafe_get(i)

            @parameter
            if has_without_mask:
                is_valid &= (
                    not self._archetypes[]
                    .unsafe_get(i)
                    .get_mask()
                    .contains_any(self._without_mask[])
                )

            size += is_valid

        return size

    fn copy(self, out other: Self):
        """
        Copies the iterator.

        Returns:
            A copy of the iterator
        """
        other = Self(
            self._archetypes,
            self._archetype_index_buffer,
            self._mask,
            self._without_mask,
            self._archetype_count,
            self._buffer_index,
            self._max_buffer_index,
        )

    @always_inline
    fn __has_next__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        return self._buffer_index < self._max_buffer_index

    @always_inline
    fn __bool__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        return self.__has_next__()


struct _ArchetypeListIterator[
    archetype_mutability: Bool, //,
    archetype_origin: Origin[archetype_mutability],
    *ComponentTypes: ComponentType,
    component_manager: ComponentManager[*ComponentTypes],
](Boolable, ExplicitlyCopyable, Iterator, Movable, Sized):
    """
    Iterator over non-empty archetypes corresponding to given array of Archetype IDs.

    Note: For internal use only! Do not expose to users. Does not lock the world.

    Parameters:
        archetype_mutability: Whether the reference to the archetypes is mutable.
        archetype_origin: The origin of the archetypes.
        ComponentTypes: The types of the components.
        component_manager: The component manager.
    """

    alias buffer_size = 8
    alias Archetype = _Archetype[
        *ComponentTypes, component_manager=component_manager
    ]
    alias Element = Pointer[Self.Archetype, archetype_origin]
    var _archetypes: Pointer[List[Self.Archetype], archetype_origin]
    var _archetype_indices: List[Int, hint_trivial_type=True]
    var _archetype_count: Int
    var _buffer_index: Int

    fn __init__(
        out self,
        archetypes: Pointer[List[Self.Archetype], archetype_origin],
        archetype_indices: List[Int, hint_trivial_type=True],
    ):
        """
        Creates an archetype array iterator.

        Args:
            archetypes: A list of pointers to the archetypes that are being iterated over.
            archetype_indices: The indices of the archetypes in the list that are being iterated over.
        """

        self._archetypes = archetypes
        self._archetype_indices = archetype_indices
        self._archetype_count = len(self._archetype_indices)
        self._buffer_index = 0

    @doc_private
    @always_inline
    fn __init__(
        out self,
        archetypes: Pointer[List[Self.Archetype], archetype_origin],
        archetype_indices: List[Int, hint_trivial_type=True],
        archetype_count: Int,
        buffer_index: Int,
    ):
        """
        Initializes the iterator based on given field values.

        Args:
            archetypes: A list of pointers to the archetypes that are being iterated over.
            archetype_indices: The indices of the archetypes in the list that are being iterated over.
            archetype_count: The number of archetypes that are being iterated over.
            buffer_index: Current index in the archetype buffer.
        """
        self._archetypes = archetypes
        self._archetype_indices = archetype_indices
        self._archetype_count = archetype_count
        self._buffer_index = buffer_index

    @always_inline
    fn __iter__(owned self, out iterator: Self):
        """
        Returns self as an iterator usable in for loops.

        Returns:
            Self as an iterator usable in for loops.
        """
        iterator = self^

    @always_inline
    fn __next__(mut self, out archetype: Self.Element):
        """
        Returns the next archetype in the iteration.

        Returns:
            The next archetype as a pointer.
        """
        archetype = Pointer(
            to=self._archetypes[].unsafe_get(
                self._archetype_indices.unsafe_get(self._buffer_index)
            )
        )
        self._buffer_index += 1

    fn __len__(self) -> Int:
        """
        Returns the number of archetypes remaining in the iterator.

        Note that this requires iterating over all archetypes
        and may be a complex operation.
        """
        return self._archetype_count - self._buffer_index

    fn copy(self, out other: Self):
        """
        Copies the iterator.

        Returns:
            A copy of the iterator
        """
        other = Self(
            self._archetypes,
            self._archetype_indices,
            self._archetype_count,
            self._buffer_index,
        )

    @always_inline
    fn __has_next__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        return self._buffer_index < self._archetype_count

    @always_inline
    fn __bool__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        return self.__has_next__()


# TODO: If parameters on traits get implemented, use them to implement a generic Iterator[Archetype[*Ts]]!
alias _ArchetypeIterator[
    archetype_mutability: Bool, //,
    archetype_origin: Origin[archetype_mutability],
    *ComponentTypes: ComponentType,
    component_manager: ComponentManager[*ComponentTypes],
    arch_iter_variant_idx: Int,
    has_without_mask: Bool = False,
] = StaticVariant[
    arch_iter_variant_idx,
    _ArchetypeByMaskIterator[
        archetype_origin,
        *ComponentTypes,
        component_manager=component_manager,
        has_without_mask=has_without_mask,
    ],
    _ArchetypeListIterator[
        archetype_origin,
        *ComponentTypes,
        component_manager=component_manager,
    ],
]


# TODO: Use generic ArchetypeIterator trait when parameters on traits are implemented.
struct _EntityIterator[
    archetype_mutability: Bool, //,
    archetype_origin: Origin[archetype_mutability],
    lock_origin: MutableOrigin,
    *ComponentTypes: ComponentType,
    component_manager: ComponentManager[*ComponentTypes],
    arch_iter_variant_idx: Int = 0,
    has_start_indices: Bool = False,
    has_without_mask: Bool = False,
](Boolable, Movable, Sized):
    """Iterator over all entities corresponding to a mask.

    Locks the world while it exists.

    Parameters:
        archetype_mutability: Whether the reference to the archetypes is mutable.
        archetype_origin: The origin of the archetypes.
        lock_origin: The origin of the LockMask.
        ComponentTypes: The types of the components.
        component_manager: The component manager.
        arch_iter_variant_idx: The index of the variant that holds the archetype iterator.
        has_start_indices: Whether the iterator starts iterating the
                           archetypes at given indices.
        has_without_mask: Whether the iterator has excluded components.
    """

    alias buffer_size = 8
    alias Archetype = _Archetype[
        *ComponentTypes, component_manager=component_manager
    ]
    alias StartIndices = StaticOptional[
        List[UInt, hint_trivial_type=True], has_start_indices
    ]

    alias ArchetypeIterator = _ArchetypeIterator[
        archetype_origin,
        *ComponentTypes,
        component_manager=component_manager,
        arch_iter_variant_idx=arch_iter_variant_idx,
        has_without_mask=has_without_mask,
    ]

    alias ArchetypeMaskIterator = _ArchetypeByMaskIterator[
        archetype_origin,
        *ComponentTypes,
        component_manager=component_manager,
        has_without_mask=has_without_mask,
    ]

    alias ArchetypeListIterator = _ArchetypeListIterator[
        archetype_origin,
        *ComponentTypes,
        component_manager=component_manager,
    ]

    var _current_archetype: Pointer[Self.Archetype, archetype_origin]
    var _lock_ptr: Pointer[LockMask, lock_origin]
    var _lock: UInt8
    var _entity_index: Int
    var _last_entity_index: Int
    var _archetype_size: Int
    var _start_indices: Self.StartIndices
    var _processed_archetypes_count: StaticOptional[Int, has_start_indices]
    var _archetype_iterator: Self.ArchetypeIterator

    fn __init__(
        out self,
        lock_ptr: Pointer[LockMask, lock_origin],
        owned archetype_iterator: Self.ArchetypeIterator,
        owned start_indices: Self.StartIndices = None,
    ) raises:
        """
        Creates an entity iterator with or without excluded components.

        Args:
            lock_ptr: a pointer to the world's locks.
            archetype_iterator: The iterator over the archetypes to iterate.
            start_indices: The indices where the iterator starts iterating the
                           archetypes. Caution: the index order must
                           match the order of the archetypes that
                           are iterated.

        Raises:
            Error: If the lock cannot be acquired (more than 256 locks exist).
        """

        self._archetype_iterator = archetype_iterator^
        self._lock_ptr = lock_ptr
        self._lock = self._lock_ptr[].lock()
        self._start_indices = start_indices^

        self._entity_index = 0
        self._archetype_size = 0
        self._last_entity_index = 0

        @parameter
        if has_start_indices:
            self._processed_archetypes_count = 0
        else:
            self._processed_archetypes_count = None

        # NOTE: This is a workaround! Accessing common members of a static variant is awkward, because the compiler
        #       does not check the variants for similarities. To do this properly, we would need to implement a generic
        #       Iterator[Archetype[*Ts]] trait. But this is not possible yet, because parameters on traits are not
        #       implemented. This should be fixed in the future.

        # If the iterator is not empty
        @parameter
        if Self.ArchetypeIterator.isa[Self.ArchetypeMaskIterator]():
            self._current_archetype = Pointer(
                to=rebind[Self.ArchetypeMaskIterator](
                    self._archetype_iterator[]
                )._archetypes[][0]
            )
            is_empty = Bool(
                rebind[Self.ArchetypeMaskIterator](self._archetype_iterator[])
            )
        else:
            constrained[
                Self.ArchetypeIterator.isa[Self.ArchetypeListIterator](),
                "The archetype iterator must be an ArchetypeListIterator.",
            ]()
            self._current_archetype = Pointer(
                to=rebind[Self.ArchetypeListIterator](
                    self._archetype_iterator[]
                )._archetypes[][0]
            )
            is_empty = Bool(
                rebind[Self.ArchetypeListIterator](self._archetype_iterator[])
            )

        if is_empty:
            self._last_entity_index = Int.MAX
            self._next_archetype()
            # We need to reduce the index by 1, because the
            # first call to __next__ will increment it.
            self._entity_index -= 1

    fn __del__(owned self):
        """
        Releases the lock.
        """
        try:
            self._lock_ptr[].unlock(self._lock)
        except Error:
            debug_warn("Failed to unlock the lock. This should not happen.")

    @always_inline
    fn __iter__(owned self, out iterator: Self):
        """
        Returns self as an iterator usable in for loops.

        Returns:
            Self as an iterator usable in for loops.
        """
        iterator = self^

    @always_inline
    fn _next_archetype(mut self):
        """
        Moves to the next archetype.
        """

        @parameter
        if Self.ArchetypeIterator.isa[Self.ArchetypeMaskIterator]():
            self._current_archetype = rebind[Self.ArchetypeMaskIterator](
                self._archetype_iterator[]
            ).__next__()
        elif Self.ArchetypeIterator.isa[Self.ArchetypeListIterator]():
            self._current_archetype = rebind[Self.ArchetypeListIterator](
                self._archetype_iterator[]
            ).__next__()
        self._archetype_size = len(self._current_archetype[])

        @parameter
        if has_start_indices:
            self._entity_index = self._start_indices[][
                self._processed_archetypes_count[]
            ]
            self._processed_archetypes_count[] += 1
        else:
            self._entity_index = 0

        # If we arrived at the last archetype, we
        # reset the last entity index so that the iterator
        # stops at the last entity of the last archetype.
        @parameter
        if Self.ArchetypeIterator.isa[Self.ArchetypeMaskIterator]():
            if not rebind[Self.ArchetypeMaskIterator](
                self._archetype_iterator[]
            ):
                self._last_entity_index = self._archetype_size - 1
        elif Self.ArchetypeIterator.isa[Self.ArchetypeListIterator]():
            if not rebind[Self.ArchetypeListIterator](
                self._archetype_iterator[]
            ):
                self._last_entity_index = self._archetype_size - 1

    @always_inline
    fn __next__(
        mut self,
        out accessor: Self.Archetype.EntityAccessor[
            archetype_mutability,
            __origin_of(self._current_archetype[]),
        ],
    ):
        """
        Returns the next entity in the iteration.

        Returns:
            An [..archetype.EntityAccessor] to the entity.
        """
        self._entity_index += 1
        if self._entity_index >= self._archetype_size:
            self._next_archetype()
        accessor = self._current_archetype[].get_entity_accessor(
            self._entity_index,
        )

    fn __len__(self) -> Int:
        """
        Returns the number of entities remaining in the iterator.

        Note that this requires iterating over all archetypes
        and may be a complex operation.
        """
        if not self.__has_next__():
            return 0

        # Elements in the current archetype
        size = len(self._current_archetype[]) - self._entity_index - 1

        # Elements in the remaining archetypes
        @parameter
        if Self.ArchetypeIterator.isa[Self.ArchetypeMaskIterator]():
            if rebind[Self.ArchetypeMaskIterator](self._archetype_iterator[]):
                for archetype in rebind[Self.ArchetypeMaskIterator](
                    self._archetype_iterator[]
                ).copy():
                    size += len(archetype[])
        elif Self.ArchetypeIterator.isa[Self.ArchetypeListIterator]():
            if rebind[Self.ArchetypeListIterator](self._archetype_iterator[]):
                for archetype in rebind[Self.ArchetypeListIterator](
                    self._archetype_iterator[]
                ).copy():
                    size += len(archetype[])

        @parameter
        if has_start_indices:
            for i in range(
                self._processed_archetypes_count[],
                len(self._start_indices[]),
            ):
                size -= self._start_indices[][i]

        return size

    @always_inline
    fn __has_next__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        return self._entity_index < self._last_entity_index

    @always_inline
    fn __bool__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        return self.__has_next__()
