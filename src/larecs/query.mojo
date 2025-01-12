from collections import InlineArray

from .entity import Entity
from .bitmask import BitMask
from .component import ComponentType, ComponentManager
from .chained_array_list import ChainedArrayList
from .archetype import Archetype
from .world import World
from .lock import LockMask
from .debug_utils import debug_warn


struct _EntityAccessor[
    archetype_mutability: Bool, //,
    archetype_origin: Origin[archetype_mutability],
    *component_types: ComponentType,
]:
    """Accessor for an Entity.

    Caution: use this only in the context it was created in.
    In particular, do not store it anywhere.

    Parameters:
        archetype_mutability: Whether the reference to the list is mutable.
        archetype_origin: The lifetime of the List
        component_types: The types of the components.
    """

    var _component_manager: ComponentManager[*component_types]
    var _archetype: Pointer[Archetype, archetype_origin]
    var _index_in_archetype: Int

    @always_inline
    fn __init__(
        out self,
        component_manager: ComponentManager[*component_types],
        archetype: Pointer[Archetype, archetype_origin],
        index_in_archetype: Int,
    ):
        """
        Parameters:
            component_manager: The component manager.
            archetype: The archetype of the entity.
            index_in_archetype: The index of the entity in the archetype.
        """
        self._component_manager = component_manager
        self._archetype = archetype
        self._index_in_archetype = index_in_archetype

    @always_inline
    fn get[T: ComponentType](mut self) raises -> ref [self._archetype] T:
        """Returns a reference to the given component of the Entity.

        Raises:
            Error: If the entity does not have the component.
        """
        return (
            self._archetype[]
            .get_component_ptr(
                self._index_in_archetype,
                self._component_manager.get_id[T](),
            )
            .bitcast[T]()[0]
        )

    @always_inline
    fn get_ptr[
        T: ComponentType
    ](mut self) raises -> Pointer[T, __origin_of(self._archetype)]:
        """Returns a reference to the given component of the Entity.

        Raises:
            Error: If the entity does not have the component.
        """
        return Pointer[origin = __origin_of(self._archetype)].address_of(
            self._archetype[]
            .get_component_ptr(
                self._index_in_archetype,
                self._component_manager.get_id[T](),
            )
            .bitcast[T]()[0]
        )

    @always_inline
    fn has[T: ComponentType](self) -> Bool:
        """
        Returns whether an [Entity] has a given component.
        """
        return self._archetype[].has_component(
            self._component_manager.get_id[T]()
        )


@value
struct _EntityIterator[
    archetype_mutability: Bool, //,
    archetype_origin: Origin[archetype_mutability],
    lock_origin: MutableOrigin,
    *component_types: ComponentType,
]:
    """Iterator over all entities corresponding to a mask.

    Locks the world while it exisist.

    Parameters:
        archetype_mutability: Whether the reference to the list is mutable.
        archetype_origin: The lifetime of the List
        lock_origin: The lifetime of the LockMask
        component_types: The types of the components.
    """

    alias buffer_size = 8
    var _component_manager: ComponentManager[*component_types]
    var _archetypes: Pointer[ChainedArrayList[Archetype], archetype_origin]
    var _archetype_index_buffer: SIMD[DType.uint32, Self.buffer_size]
    var _current_archetype: Pointer[Archetype, archetype_origin]
    var _lock_ptr: Pointer[LockMask, lock_origin]
    var _lock: UInt8
    var _mask: BitMask
    var _entity_index: Int
    var _last_entity_index: Int
    var _archetype_size: Int
    var _archetype_count: Int
    var _buffer_index: Int
    var _max_buffer_index: Int

    fn __init__(
        out self,
        component_manager: ComponentManager[*component_types],
        owned archetypes: Pointer[
            ChainedArrayList[Archetype], archetype_origin
        ],
        lock_ptr: Pointer[LockMask, lock_origin],
        owned mask: BitMask,
    ) raises:
        """
        Parameters:
            component_manager: The component manager.
            archetypes: The archetypes to iterate over.
            mask: The mask of the components to iterate over.

        Args:
            component_manager: The component manager.
            archetypes: a pointer to the world's archetypes.
            lock_ptr: a pointer to the world's locks.
            mask: The mask of the components to iterate over.

        Raises:
            Error: If the lock cannot be acquired (more than 256 locks exist).
        """
        self._component_manager = component_manager
        self._archetypes = archetypes
        self._lock_ptr = lock_ptr
        self._lock = self._lock_ptr[].lock()
        self._archetype_count = len(self._archetypes[])
        self._mask = mask^

        self._entity_index = 0
        self._archetype_size = 0
        self._buffer_index = 0
        self._last_entity_index = 0
        self._max_buffer_index = Self.buffer_size

        self._current_archetype = self._archetypes[].get_ptr(0)
        self._archetype_index_buffer = SIMD[DType.uint32, Self.buffer_size](-1)
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
        self._component_manager = other._component_manager
        self._archetypes = other._archetypes
        self._archetype_index_buffer = other._archetype_index_buffer
        self._mask = other._mask^
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

    @always_inline
    fn __iter__(owned self, out iterator: Self):
        iterator = self^

    fn _fill_archetype_buffer(mut self):
        """
        Find the next archetypes that contain the mask.

        Fills the _archetype_index_buffer witht the
        archetypes' indices.
        """
        buffer_index = 0
        for i in range(
            self._archetype_index_buffer[self._buffer_index] + 1,
            self._archetype_count,
        ):
            if (
                self._archetypes[][i].get_mask().contains(self._mask)
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
    fn _next_archetype(mut self):
        """
        Moves to the next archetype.
        """
        self._entity_index = 0
        self._buffer_index += 1
        self._current_archetype = self._archetypes[].get_ptr(
            self._archetype_index_buffer[self._buffer_index]
        )
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
        out accessor: _EntityAccessor[
            __origin_of(self._current_archetype[]), *component_types
        ],
    ):
        self._entity_index += 1
        if self._entity_index >= self._archetype_size:
            self._next_archetype()
        accessor = _EntityAccessor(
            self._component_manager,
            self._current_archetype,
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
            if (
                self._archetypes[][i].get_mask().contains(self._mask)
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
