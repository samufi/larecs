from entity import Entity
from bitmask import BitMask
from component import ComponentType, ComponentManager
from chained_array_list import ChainedArrayList
from archetype import Archetype
from world import World
from lock import LockMask
from debug_utils import debug_warn


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
    fn get[T: ComponentType](inout self) raises -> ref [self._archetype] T:
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
    ](inout self) raises -> Pointer[T, __origin_of(self._archetype)]:
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

    Locks the world while iterating.

    Parameters:
        archetype_mutability: Whether the reference to the list is mutable.
        archetype_origin: The lifetime of the List
        lock_origin: The lifetime of the LockMask
        component_types: The types of the components.
    """

    var _archetypes: Pointer[ChainedArrayList[Archetype], archetype_origin]
    var _current_archetype: Pointer[Archetype, archetype_origin]
    var _next_archetype_index: Int
    var _entity_index: Int
    var _mask: BitMask
    var _has_next: Bool
    var _component_manager: ComponentManager[*component_types]
    var _lock_ptr: Pointer[LockMask, lock_origin]
    var _lock: UInt8

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
        self._archetypes = archetypes
        self._component_manager = component_manager
        self._lock_ptr = lock_ptr
        self._lock = self._lock_ptr[].lock()

        # We start indexing at -1, because we want that the
        # index after returning __next__ always
        # corresponds to the last returned entity.
        self._next_archetype_index = -1
        self._entity_index = -1

        self._mask = mask^
        self._current_archetype = self._archetypes[].get_ptr(0)
        self._has_next = False
        self._find_next_archetype()
        if self._next_archetype_index < len(self._archetypes[]):
            self._has_next = True
            self._next_archetype()

            # We need to reset the index to -1, because the
            # first call to __next__ will increment it.
            self._entity_index = -1

    fn __moveinit__(
        out self,
        owned other: Self,
    ):
        self._archetypes = other._archetypes
        self._current_archetype = other._current_archetype
        self._has_next = other._has_next
        self._next_archetype_index = other._next_archetype_index
        self._entity_index = other._entity_index
        self._mask = other._mask^
        self._component_manager = other._component_manager
        self._lock_ptr = other._lock_ptr
        self._lock = other._lock

    fn __del__(owned self):
        try:
            self._lock_ptr[].unlock(self._lock)
        except Error:
            debug_warn("Failed to unlock the lock. This should not happen.")

    @always_inline
    fn __iter__(owned self) -> Self as iterator:
        iterator = self^

    @always_inline
    fn _find_next_archetype(inout self):
        """
        Find the next archetype that contains the mask.

        Fills the _next_archetype_index attribute.
        """
        for i in range(self._next_archetype_index + 1, len(self._archetypes[])):
            if (
                self._archetypes[][i].get_mask().contains(self._mask)
                and self._archetypes[][i]
            ):
                self._next_archetype_index = i
                return

        self._next_archetype_index = len(self._archetypes[])

    @always_inline
    fn _next_archetype(inout self):
        """
        Moves to the next archetype.
        """
        self._entity_index = 0
        self._current_archetype = self._archetypes[].get_ptr(
            self._next_archetype_index
        )
        self._find_next_archetype()

    fn __next__(
        inout self,
    ) -> _EntityAccessor[
        __origin_of(self._current_archetype[]), *component_types
    ]:
        self._entity_index += 1
        if self._entity_index >= len(self._current_archetype[]) - 1:
            if self._next_archetype_index >= len(self._archetypes[]):
                self._has_next = False
            elif self._entity_index >= len(self._current_archetype[]):
                self._next_archetype()
        return _EntityAccessor(
            self._component_manager,
            self._current_archetype,
            self._entity_index,
        )

    fn __len__(self) -> Int:
        if not self._has_next:
            return 0
        size = len(self._current_archetype[]) - self._entity_index - 1
        for i in range(self._next_archetype_index, len(self._archetypes[])):
            if (
                self._archetypes[][i].get_mask().contains(self._mask)
                and self._archetypes[][i]
            ):
                size += len(self._archetypes[][i])

        return size

    @always_inline
    fn __has_next__(self) -> Bool:
        return self._has_next

    @always_inline
    fn __bool__(self) -> Bool:
        return self._has_next
