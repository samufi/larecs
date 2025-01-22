from sys.intrinsics import _type_is_eq
from collections import InlineArray, InlineList, Optional
from memory import memcpy, UnsafePointer
from .component import (
    ComponentReference,
    ComponentManager,
)
from .entity import Entity
from .bitmask import BitMask
from .pool import EntityPool
from .types import get_max_uint_size, TrivialIntable


alias DEFAULT_CAPACITY = 32


struct Archetype[
    *Ts: ComponentType,
    component_manager: ComponentManager[*Ts],
](CollectionElement, CollectionElementNew):
    """
    Archetype represents an ECS archetype.

    Parameters:
        Ts: The component types of the archetype.
        component_manager: The component manager.
    """

    alias dType = BitMask.IndexDType

    alias Id = SIMD[Self.dType, 1]

    alias Index = UInt32

    # The maximal number of components in the archetype.
    alias max_size = get_max_uint_size[Self.Id]()

    # Pointers to the component data.
    var _data: InlineArray[
        UnsafePointer[UInt8], Self.max_size, run_destructors=True
    ]

    # Current number of entities.
    var _size: UInt

    # Current capacity.
    var _capacity: UInt

    # number of components.
    var _component_count: UInt

    # The indices of the present components
    var _ids: SIMD[Self.dType, Self.max_size]

    # The entities in the archetype
    var _entities: List[Entity]

    # Index of the the archetype's node in the archetype graph
    var _node_index: UInt

    # Mask of the the archetype's node in the archetype graph
    var _mask: BitMask

    fn __init__(
        out self,
    ):
        """Initializes the zero archetype without any component."""
        self = Self.__init__[used_internally=True](0, BitMask(), 0)

    fn __init__[
        *, used_internally: Bool
    ](out self, node_index: UInt, mask: BitMask, capacity: UInt,):
        """Initializes the archetype without allocating memory for components.

        Note:
            Do not use this constructor directly!

        Args:
            node_index: The index of the archetype's node in the archetype graph.
            mask: The mask of the archetype's node in the archetype graph.
            capacity:   The initial capacity of the archetype.
        """
        self._size = 0
        self._mask = mask
        self._component_count = 0
        self._capacity = capacity
        self._ids = SIMD[Self.dType, Self.max_size]()
        self._data = InlineArray[
            UnsafePointer[UInt8], Self.max_size, run_destructors=True
        ](UnsafePointer[UInt8]())
        self._entities = List[Entity]()
        self._node_index = node_index

    @always_inline
    fn __init__[
        component_count: Int
    ](
        out self,
        node_index: UInt,
        component_ids: InlineArray[Self.Id, component_count] = InlineArray[
            Self.Id, component_count
        ](),
        capacity: UInt = DEFAULT_CAPACITY,
    ):
        """Initializes the archetype with given components.

        Args:
            node_index:      The index of the archetype's node in the archetype graph.
            component_ids:   The IDs of the components of the archetype.
            capacity:        The initial capacity of the archetype.
        """
        mask_ = BitMask()
        for i in range(component_count):
            mask_.set[True](component_ids[i])
        self = Self(node_index, mask_, component_ids, capacity)

    fn __init__[
        component_count: Int
    ](
        out self,
        node_index: UInt,
        mask: BitMask,
        component_ids: InlineArray[Self.Id, component_count],
        capacity: UInt = DEFAULT_CAPACITY,
    ):
        """Initializes the archetype with given components and BitMask.

        The components in the archetyoe are determined by the component_ids.
        The mask is not checked for consistency with the component IDs.

        Args:
            node_index: The index of the archetype's node in the archetype graph.
            mask: The mask of the archetype's node in the archetype graph
                  (not used in initializer; not checked for consistency with component_ids).
            component_ids: The IDs of the components of the archetype.
            capacity: The initial capacity of the archetype.
        """
        constrained[
            Self.dType.is_integral(),
            "The component identifier type needs to be an integral type.",
        ]()

        constrained[
            Self.max_size >= component_count,
            "An archetype cannot have more components than "
            + str(Self.max_size)
            + ".",
        ]()

        self = Self.__init__[used_internally=True](node_index, mask, capacity)
        self._component_count = component_count

        @parameter
        for i in range(component_count):
            id = component_ids[i]
            self._ids[i] = id
            self._data[id] = UnsafePointer[UInt8].alloc(
                self._capacity
                * index(component_manager.component_sizes[index(id)])
            )

    fn __init__(
        out self,
        node_index: UInt,
        mask: BitMask,
        capacity: UInt = DEFAULT_CAPACITY,
    ):
        """Initializes the archetype based on a given mask.

        Args:
            node_index: The index of the archetype's node in the archetype graph.
            mask: The mask of the archetype's node in the archetype graph.
            capacity: The initial capacity of the archetype.
        """
        self = Self.__init__[used_internally=True](node_index, mask, capacity)
        self._component_count = 0

        @parameter
        for i in range(component_manager.component_count):
            if mask.get(i):
                self._ids[self._component_count] = i
                self._data[i] = UnsafePointer[UInt8].alloc(
                    self._capacity * index(component_manager.component_sizes[i])
                )
                self._component_count += 1

    fn copy(self, out other: Self):
        """Initializes the archetype as a copy of another archetype."""
        other = self

    fn __moveinit__(mut self, owned existing: Self):
        self._data = existing._data^
        self._size = existing._size
        self._capacity = existing._capacity
        self._component_count = existing._component_count
        self._entities = existing._entities^
        self._ids = existing._ids
        self._node_index = existing._node_index
        self._mask = existing._mask

    fn __copyinit__(mut self, existing: Self):
        # Copy the attributes that can be trivially
        # copied via a simple assignment
        self._size = existing._size
        self._capacity = existing._capacity
        self._component_count = existing._component_count
        self._entities = existing._entities
        self._ids = existing._ids
        self._node_index = existing._node_index
        self._mask = existing._mask

        # Copy the data
        self._data = InlineArray[
            UnsafePointer[UInt8], Self.max_size, run_destructors=True
        ](UnsafePointer[UInt8]())

        for i in range(existing._component_count):
            id = existing._ids[i]
            size = existing._capacity * index(
                component_manager.component_sizes[i]
            )
            self._data[id] = UnsafePointer[UInt8].alloc(size)
            memcpy(
                self._data[id],
                existing._data[id],
                size,
            )

    fn __del__(owned self):
        for i in range(self._component_count):
            self._data[self._ids[i]].free()

    @always_inline
    fn __len__(self) -> Int:
        """Returns the number of entities in the archetype."""
        return self._size

    @always_inline
    fn __bool__(self) -> Bool:
        """Returns whether the archetype contains entities."""
        return bool(self._size)

    @always_inline
    fn get_node_index(self) -> UInt:
        """Returns the index of the archetype's node in the archetype graph."""
        return self._node_index

    @always_inline
    fn get_mask(self) -> ref [self._mask] BitMask:
        """Returns the mask of the archetype's node in the archetype graph."""
        return self._mask

    @always_inline
    fn reserve(mut self):
        """Extends the capacity of the archetype by factor 2."""
        self.reserve(self._capacity * 2)

    fn reserve(mut self, new_capacity: UInt):
        """Extends the capacity of the archetype to a given number.

        Does nothing if the new capacity is not larger than the current capacity.

        Args:
            new_capacity: The new capacity of the archetype.
        """
        if new_capacity <= self._capacity:
            return

        for i in range(self._component_count):
            id = self._ids[i]
            old_size = (
                component_manager.component_sizes[index(id)] * self._capacity
            )
            new_size = (
                component_manager.component_sizes[index(id)] * new_capacity
            )
            new_memory = UnsafePointer[UInt8].alloc(index(new_size))
            memcpy(
                new_memory,
                self._data[id],
                index(old_size),
            )
            self._data[id].free()
            self._data[id] = new_memory

        self._capacity = new_capacity

    @always_inline
    fn get_entity[T: Indexer](self, idx: T) -> ref [self._entities] Entity:
        """Returns the entity at the given index."""
        return self._entities[idx]

    @always_inline
    fn unsafe_set[
        T: Indexer
    ](mut self, idx: T, id: Self.Id, value: UnsafePointer[UInt8]):
        """Sets the component with the given id at the given index."""
        memcpy(
            self._get_component_ptr(index(idx), id),
            value,
            index(component_manager.component_sizes[index(id)]),
        )

    @always_inline
    fn set[
        T: Indexer, /, assert_has_component: Bool = True
    ](mut self, index: T, value: ComponentReference) raises:
        """Sets the component with the given id at the given index.

        Parameters:
            T: Thetype of the index.
            assert_has_component: Whether to assert that the archetype
                contains the component.

        Raises:
            Error: If assert_has_component and the archetype does not contain the component.
        """

        @parameter
        if assert_has_component:
            self.assert_has_component(value.get_id())

        self.unsafe_set(index, value.get_id(), value.get_unsafe_ptr())

    # fn get(mut self, index: UInt, id: Self.Id) -> ComponentReference[__origin_of(self)]:
    #     """Returns the component with the given id at the given index."""
    #     return ComponentReference[__origin_of(self)](id, self._get_component_ptr(index, id))

    @always_inline
    fn _get_component_ptr(self, idx: UInt, id: Self.Id) -> UnsafePointer[UInt8]:
        """Returns the component with the given id at the given index."""
        return (
            self._data[id] + idx * component_manager.component_sizes[index(id)]
        )

    fn unsafe_copy_to(self, mut other: Self, idx: UInt, other_index: UInt):
        """Copies all components of the entity at the given index to another archetype.

        Caution: This function does not check whether the other archetype
                 contains the component.

        Args:
            other: The archetype to copy the components to.
            idx: The index of the entity.
            other_index: The index of the entity in the other archetype.
        """
        for i in range(self._component_count):
            other.unsafe_set(
                other_index,
                self._ids[i],
                self._get_component_ptr(idx, self._ids[i]),
            )

    @always_inline
    fn get_component_ptr[
        T: Indexer, /, assert_has_component: Bool = True
    ](self, idx: T, id: Self.Id) raises -> UnsafePointer[UInt8]:
        """Returns the component with the given id at the given index.

        Args:
            idx:    The index of the entity.
            id:     The id of the component.

        Parameters:
            T: The type of the index.
            assert_has_component: Whether to assert that the archetype
                    contains the component.

        Raises:
            Error:  If assert_has_component and the archetype does not contain the component.
        """

        @parameter
        if assert_has_component:
            self.assert_has_component(id)
        return self._get_component_ptr(index(idx), id)

    @always_inline
    fn has_component(self, id: Self.Id) -> Bool:
        """Returns whether the archetype contains the given component id."""
        return bool(self._data[id])

    @always_inline
    fn assert_has_component(self, id: Self.Id) raises:
        """Raises if the archetype does not contain the given component id."""
        if not self.has_component(id):
            raise Error(
                "Archetype does not contain component with id " + str(id) + "."
            )

    fn remove[T: Indexer](mut self, idx: T) -> Bool:
        """Removes an entity and its components from the archetype.

        Performs a swap-remove and reports whether a swap was necessary
        (i.e. not the last entity that was removed).

        Args:
            idx: The index of the entity to remove.
        """

        self._size -= 1

        var swapped = Int(idx) != self._size

        if swapped:
            self._entities[idx] = self._entities.pop()

            for i in range(self._component_count):
                id = self._ids[i]
                size = component_manager.component_sizes[index(id)]
                if size == 0:
                    continue

                memcpy(
                    self._get_component_ptr(index(idx), id),
                    self._get_component_ptr(self._size, id),
                    index(size),
                )
        else:
            _ = self._entities.pop()

        return swapped

    fn add(mut self, entity: Entity) -> Int:
        """Adds an entity to the archetype.

        Args:
            entity: The entity to add.

        Returns:
            The index of the entity in the archetype.
        """
        if self._size == self._capacity:
            self.reserve()

        self._entities.append(entity)
        self._size += 1
        return self._size - 1

    fn extend(
        mut self,
        count: Int,
        mut entity_pool: EntityPool,
    ) -> Int:
        """Extends the archetype by `count` entities from the provided pool.

        Args:
            count: The number of entities to add.
            entity_pool: The pool to get the entities from.

        Returns:
            The index of the first newly added entity in the
            archetype. The other new entities are at consecutive
            `count` indices.
        """
        if self._size + count >= self._capacity:
            self.reserve(self._capacity + count)

        self._entities.reserve(len(self._entities) + count)
        start_index = self._size
        for _ in range(count):
            self._entities.append(entity_pool.get())
        self._size += count
        return start_index
