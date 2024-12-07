from collections import InlineArray, InlineList
from component import (
    ComponentInfo,
    ComponentReference,
    ComponentManager,
)
from memory import memcpy, UnsafePointer
from entity import Entity
from bitmask import BitMask
from pool import EntityPool

from types import get_max_uint_size, TrivialIntable


struct Archetype(CollectionElement, CollectionElementNew):
    """Archetype represents an ECS archetype."""

    alias dType = BitMask.IndexDType

    alias Id = SIMD[Self.dType, 1]

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

    # Sizes of the component types by column
    var _item_sizes: InlineArray[UInt32, Self.max_size, run_destructors=True]

    # The indices of the present components
    var _ids: SIMD[Self.dType, Self.max_size]

    # The entities in the archetype
    var _entities: List[Entity]

    # Index of the the archetype's node in the archetype graph
    var _node_index: UInt

    fn __init__[
        component_count: Int = 0
    ](
        inout self,
        node_index: UInt,
        components: InlineArray[ComponentInfo, component_count] = InlineArray[
            ComponentInfo, component_count
        ](),
        capacity: UInt = 10,
    ):
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

        self._size = 0
        self._component_count = component_count
        self._capacity = capacity
        self._ids = SIMD[Self.dType, Self.max_size]()
        self._data = InlineArray[
            UnsafePointer[UInt8], Self.max_size, run_destructors=True
        ](UnsafePointer[UInt8]())
        self._item_sizes = InlineArray[
            UInt32, Self.max_size, run_destructors=True
        ](0)
        self._entities = List[Entity]()
        self._node_index = node_index

        @parameter
        for i in range(component_count):
            self._item_sizes[int(components[i].get_id())] = components[
                i
            ].get_size()
            self._ids[i] = components[i].get_id()
            self._data[int(components[i].get_id())] = UnsafePointer[
                UInt8
            ].alloc(self._capacity * int(components[i].get_size()))

    fn __init__(inout self, /, *, other: Self):
        # Copy the attributes that can be trivially
        # copied via a simple assignment
        self._size = other._size
        self._capacity = other._capacity
        self._component_count = other._component_count
        self._item_sizes = other._item_sizes
        self._entities = other._entities
        self._ids = other._ids
        self._node_index = other._node_index

        # Copy the data
        self._data = InlineArray[
            UnsafePointer[UInt8], Self.max_size, run_destructors=True
        ](UnsafePointer[UInt8]())

        for i in range(other._component_count):
            id = int(other._ids[i])
            size = other._capacity * int(other._item_sizes[id])
            self._data[id] = UnsafePointer[UInt8].alloc(size)
            memcpy(
                self._data[id],
                other._data[id],
                size,
            )

    fn __moveinit__(inout self, owned existing: Self):
        self._data = existing._data^
        self._size = existing._size
        self._capacity = existing._capacity
        self._component_count = existing._component_count
        self._item_sizes = existing._item_sizes^
        self._entities = existing._entities^
        self._ids = existing._ids
        self._node_index = existing._node_index

    fn __copyinit__(inout self, existing: Self):
        self._data = existing._data
        self._size = existing._size
        self._capacity = existing._capacity
        self._component_count = existing._component_count
        self._item_sizes = existing._item_sizes
        self._entities = existing._entities
        self._ids = existing._ids
        self._node_index = existing._node_index

    fn __del__(owned self):
        for i in range(self._component_count):
            self._data[int(self._ids[i])].free()

    fn __len__(self) -> Int:
        """Returns the number of entities in the archetype."""
        return self._size

    @always_inline
    fn get_node_index(self) -> UInt:
        """Returns the index of the archetype's node in the archetype graph."""
        return self._node_index

    @always_inline
    fn reserve(inout self):
        """Extends the capacity of the archetype by factor 2."""
        self.reserve(self._capacity * 2)

    fn reserve(inout self, new_capacity: UInt):
        """Extends the capacity of the archetype to a given number.

        Does nothing if the new capacity is not larger than the current capacity.

        Args:
            new_capacity: The new capacity of the archetype.
        """
        if new_capacity <= self._capacity:
            return

        self._capacity = new_capacity
        for i in range(self._component_count):
            id = int(self._ids[i])
            new_size = int(self._item_sizes[id]) * new_capacity
            new_memory = UnsafePointer[UInt8].alloc(new_size)
            memcpy(
                new_memory,
                self._data[id],
                new_size,
            )
            self._data[id].free()
            self._data[id] = new_memory

    @always_inline
    fn get_entity(self, index: UInt) -> ref [self._entities] Entity:
        """Returns the entity at the given index."""
        return self._entities[index]

    @always_inline
    fn _get_component_ptr(
        self, index: UInt, id: Self.Id
    ) -> UnsafePointer[UInt8]:
        """Returns the component with the given id at the given index."""
        return self._data[int(id)] + index * int(self._item_sizes[int(id)])

    @always_inline
    fn has_component(self, id: Self.Id) -> Bool:
        """Returns whether the archetype contains the given component id."""
        return bool(self._data[int(id)])

    @always_inline
    fn has_relation(self) -> Bool:
        """Returns whether the archetype has self relation component."""
        # TODO
        # return self.has_relation_component
        return False

    fn remove(inout self, index: UInt) raises -> Bool:
        """Removes an entity and its components from the archetype.

        Performs a swap-remove and reports whether a swap was necessary
        (i.e. not the last entity that was removed).
        """

        self._size -= 1

        var swapped = index != self._size

        if swapped:
            self._entities[index] = self._entities.pop()

            for i in range(self._component_count):
                id = int(self._ids[i])
                size = int(self._item_sizes[id])
                if size == 0:
                    continue

                memcpy(
                    self._get_component_ptr(index, id),
                    self._get_component_ptr(self._size, id),
                    size,
                )
        else:
            _ = self._entities.pop()

        return swapped

    fn add(inout self, entity: Entity) -> Int:
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
        inout self, count: Int, inout entity_pool: EntityPool
    ) -> Int as start_index:
        """Adds an entity to the archetype.

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
