from collections import InlineArray, Optional

from .entity import Entity
from .bitmask import BitMask
from .component import ComponentType, ComponentManager
from .archetype import Archetype as _Archetype
from .world import World
from .lock import LockMask
from .resource import ResourceContaining
from .debug_utils import debug_warn


struct Query[
    mut: MutableOrigin,
    *component_types: ComponentType,
    resources_type: ResourceContaining,
    component_manager: ComponentManager[*component_types],
    has_without_mask: Bool = False,
]:
    """Query builder for entities with and without specific components."""

    var _world: Pointer[
        World[*component_types, resources_type=resources_type], mut
    ]
    var _mask: BitMask
    var _without_mask: Optional[BitMask]

    fn __init__(
        out self,
        world: Pointer[World[*component_types, resources_type=resources_type], mut],
        owned mask: BitMask,
    ) raises:
        """
        Creates a new query.

        This should not be used directly, but through the [..world.World.query] method:

        ```mojo {doctest="query_init" global=true hide=true}
        from larecs import World, Resources, MutableEntityAccessor
        ```

        ```mojo {doctest="query_init"}
        world = World[Float64, Float32, Int](Resources())
        _ = world.add_entity(Float64(1.0), Float32(2.0), 3)
        _ = world.add_entity(Float64(1.0), 3)

        for entity in world.query[Float64, Int]():
            f = entity.get_ptr[Float64]()
            f[] += 1
        ```

        Args:
            world: A pointer to the world.
            mask: The mask of the components to iterate over.
        """
        self._world = world
        self._mask = mask^
        self._without_mask = None

    @always_inline
    fn __iter__(
        self,
        out iterator: _EntityIterator[
            __origin_of(self._world[]._archetypes),
            __origin_of(self._world[]._locks),
            *component_types,
            component_manager = ComponentManager[*component_types](),
            has_without_mask = Self.has_without_mask,
        ],
    ) raises:
        """
        Creates an iterator over all entities that match the query.

        Returns:
            An iterator over all entities that match the query.

        Raises:
            Error: If the lock cannot be acquired (more than 256 locks exist).
        """
        iterator = self._world[]._get_iterator[has_without_mask](
            self._mask,
            self._without_mask
        )

    @always_inline
    fn without[
        *Ts: ComponentType
    ](
        owned self,
        out result: Query[
            mut,
            *component_types,
            resources_type=resources_type,
            component_manager = component_manager,
            has_without_mask=True,
        ],
    ) raises:
        """
        Excludes the given components from the query.

        ```mojo {doctest="query_without" global=true hide=true}
        from larecs import World, Resources, MutableEntityAccessor
        ```

        ```mojo {doctest="query_without"}
        world = World[Float64, Float32, Int](Resources())
        _ = world.add_entity(Float64(1.0), Float32(2.0), 3)
        _ = world.add_entity(Float64(1.0), 3)

        for entity in world.query[Float64, Int]().without[Float32]():
            f = entity.get_ptr[Float64]()
            f[] += 1
        ```

        Parameters:
            Ts: The types of the components to exclude.

        Returns:
            The query, exclusing the given components.
        """
        result = Query[
            self.mut,
            *self.component_types,
            resources_type=resources_type,
            component_manager = component_manager,
            has_without_mask=True,
            ](
            self._world,
            self._mask,
        )
        result._without_mask = BitMask(Self.component_manager.get_id_arr[*Ts]())


@value
struct _EntityIterator[
    archetype_mutability: Bool, //,
    archetype_origin: Origin[archetype_mutability],
    lock_origin: MutableOrigin,
    *component_types: ComponentType,
    component_manager: ComponentManager[*component_types],
    has_without_mask: Bool,
]:
    """Iterator over all entities corresponding to a mask.

    Locks the world while it exisist.

    Parameters:
        archetype_mutability: Whether the reference to the list is mutable.
        archetype_origin: The lifetime of the List
        lock_origin: The lifetime of the LockMask
        component_types: The types of the components.
        component_manager: The component manager.
        has_without_mask: Whether the iterator has excluded components.
    """

    alias buffer_size = 8
    alias Archetype = _Archetype[
        *component_types, component_manager=component_manager
    ]
    var _archetypes: Pointer[List[Self.Archetype], archetype_origin]
    var _archetype_index_buffer: SIMD[DType.int32, Self.buffer_size]
    var _current_archetype: Pointer[Self.Archetype, archetype_origin]
    var _lock_ptr: Pointer[LockMask, lock_origin]
    var _lock: UInt8
    var _mask: BitMask
    var _without_mask: BitMask
    var _entity_index: Int
    var _last_entity_index: Int
    var _archetype_size: Int
    var _archetype_count: Int
    var _buffer_index: Int
    var _max_buffer_index: Int

    fn __init__(
        out self,
        archetypes: Pointer[List[Self.Archetype], archetype_origin],
        lock_ptr: Pointer[LockMask, lock_origin],
        owned mask: BitMask,
        owned without_mask: Optional[BitMask],
    ) raises:
        """
        Args:
            archetypes: a pointer to the world's archetypes.
            lock_ptr: a pointer to the world's locks.
            mask: The mask of the components to iterate over.
            without_mask: The mask for components to exclude.

        Raises:
            Error: If the lock cannot be acquired (more than 256 locks exist).
        """

        if Self.has_without_mask == (without_mask is None):
            raise Error(
                "has_without_mask and without_mask do not match.",
                Self.has_without_mask,
                without_mask is None,
            )

        # TODO: replace above check by constraint.
        # Can't use dynamic `without_mask` i constraint,
        # so no idea how that was intendend to work.
        # if without_mask == None:
        #    constrained[
        #        Self.has_without_mask,
        #        "has_without_mask is True, but no without_mask was provided.",
        #    ]()
        # else:
        #    constrained[
        #        not Self.has_without_mask,
        #        "has_without_mask is False, but a without_mask was provided.",
        #    ]()

        self._archetypes = archetypes
        self._lock_ptr = lock_ptr
        self._lock = self._lock_ptr[].lock()
        self._archetype_count = len(self._archetypes[])
        self._mask = mask^
        self._without_mask = without_mask^.or_else(BitMask())
        
        self._entity_index = 0
        self._archetype_size = 0
        self._buffer_index = 0
        self._last_entity_index = 0
        self._max_buffer_index = Self.buffer_size

        self._current_archetype = Pointer.address_of(self._archetypes[][0])
        self._archetype_index_buffer = SIMD[DType.int32, Self.buffer_size](-1)

        self._fill_archetype_buffer()
        # If the iterator is not empty
        if self._archetype_index_buffer[0] >= 0:
            self._last_entity_index = Int.MAX
            self._buffer_index = -1
            self._next_archetype()

            # We need to reset the index to -1, because the
            # first call to __next__ will increment it.
            self._entity_index = -1

    fn __moveinit__(
        out self,
        owned other: Self,
    ):
        self._archetypes = other._archetypes
        self._archetype_index_buffer = other._archetype_index_buffer
        self._mask = other._mask^
        self._without_mask = other._without_mask^
        self._lock_ptr = other._lock_ptr
        self._lock = other._lock
        self._current_archetype = other._current_archetype

        self._last_entity_index = other._last_entity_index
        self._entity_index = other._entity_index
        self._archetype_size = other._archetype_size
        self._archetype_count = other._archetype_count
        self._buffer_index = other._buffer_index
        self._max_buffer_index = other._max_buffer_index

    fn __del__(owned self):
        """
        Releases the lock.
        """
        try:
            self._lock_ptr[].unlock(self._lock)
        except Error:
            debug_warn("Failed to unlock the lock. This should not happen.")

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
            @parameter
            if has_without_mask:
                has_excluded = self._archetypes[][i]
                    .get_mask()
                    .contains_any(self._without_mask)
            else:
                has_excluded = False

            if (
                self._archetypes[][i].get_mask().contains(self._mask)
                and (not has_excluded)
                and self._archetypes[][i]
            ):
                self._archetype_index_buffer[buffer_index] = i
                buffer_index += 1
                if buffer_index >= Self.buffer_size:
                    return

        # If the buffer is not full, we
        # note the last index that is still valid.
        self._max_buffer_index = buffer_index - 1

    @always_inline
    fn __iter__(owned self, out iterator: Self):
        iterator = self^

    @always_inline
    fn _next_archetype(mut self):
        """
        Moves to the next archetype.
        """
        self._entity_index = 0
        self._buffer_index += 1
        self._current_archetype = Pointer.address_of(
            self._archetypes[][self._archetype_index_buffer[self._buffer_index]]
        )
        # TODO: crashes here
        self._archetype_size = len(self._current_archetype[])
        if self._buffer_index >= Self.buffer_size - 1:
            self._fill_archetype_buffer()
            self._buffer_index = -1  # Will be incremented to 0

        # If we arrived at the last archetype, we
        # reset the last entity index so that the iterator
        # stops at the last entity of the last archetype.
        if self._buffer_index >= self._max_buffer_index:
            self._last_entity_index = self._archetype_size - 1

    @always_inline
    fn __next__(
        mut self,
        out accessor: Self.Archetype.EntityAccessor[
            archetype_mutability,
            __origin_of(self._current_archetype[]),
        ],
    ):
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

        # Elements in the remaining archetypes in the buffer
        # Note that if we are at the last archetype in the buffer,
        # we need to start at the beginning of the buffer,
        # because the buffer is refilled as soon as we reach its
        # last element, because we always need to know if there
        # is another "next" element.
        for i in range(
            self._buffer_index + 1 % Self.buffer_size,
            min(self._max_buffer_index + 1, Self.buffer_size),
        ):
            size += len(self._archetypes[][self._archetype_index_buffer[i]])

        # If all remaining archetypes were in the buffer, we
        # can return the size.
        if self._max_buffer_index < Self.buffer_size:
            return size

        # If there are more archetypes than the buffer size, we
        # need to iterate over the remaining archetypes.
        for i in range(
            self._archetype_index_buffer[Self.buffer_size - 1] + 1,
            len(self._archetypes[]),
        ):
        
            @parameter
            if has_without_mask:
                has_excluded = self._archetypes[][i]
                    .get_mask()
                    .contains_any(self._without_mask)
            else:
                has_excluded = False
            
            if (
                self._archetypes[][i].get_mask().contains(self._mask)
                and (not has_excluded)
                and self._archetypes[][i]
            ):
                size += len(self._archetypes[][i])

        return size

    @always_inline
    fn __has_next__(self) -> Bool:
        return self._entity_index < self._last_entity_index

    @always_inline
    fn __bool__(self) -> Bool:
        return self.__has_next__()
