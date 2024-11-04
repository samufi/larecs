from collections import InlineArray, InlineList
from component import ComponentInfo, ComponentReference
from memory import memcpy, UnsafePointer
from entity import Entity

from types import get_max_uint_size, TrivialIntable


struct Archetype[dType: DType](CollectionElementNew):
    """Archetype represents an ECS archetype.

    Parameters:
        Id: The type of the component identifier.
            Note: The size of the type needs to be
            suffiently small. If it is bigger than
            UInt16, a compile-time error will be raised
            ("failed to run the pass manager").

    """

    alias Id = SIMD[dType, 1]

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
    var _ids: SIMD[dType, Self.max_size]

    # The entities in the archetype
    var _entities: List[Entity]

    fn __init__(
        inout self, capacity: UInt, *components: ComponentInfo[dType]
    ) raises:
        
        @parameter
        if not dType.is_integral():
            raise Error(
                "The component identifier type needs to be an integral type."
            )

        if len(components) > self.max_size:
            raise Error(
                "An archetype cannot have more than "
                + str(self.max_size)
                + " components."
            )
        
        self._size = 0
        self._component_count = len(components)
        self._capacity = capacity
        self._ids = SIMD[dType, Self.max_size]()
        self._data = InlineArray[
            UnsafePointer[UInt8], Self.max_size, run_destructors=True
        ](UnsafePointer[UInt8]())
        self._item_sizes = InlineArray[
            UInt32, Self.max_size, run_destructors=True
        ](0)
        self._entities = List[Entity]()

        for i in range(self._component_count):
            component = components[i]
            self._item_sizes[int(component.id)] = component.size
            self._ids[i] = component.id
            self._data[int(component.id)] = UnsafePointer[UInt8].alloc(
                self._capacity * int(component.size)
            )

    fn __init__(inout self, /, *, other: Self):
        # Copy the attributes that can be trivially
        # copied via a simple assignment
        self._size = other._size
        self._capacity = other._capacity
        self._component_count = other._component_count
        self._item_sizes = other._item_sizes
        self._entities = other._entities
        self._ids = other._ids

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
        self._data = existing._data
        self._size = existing._size
        self._capacity = existing._capacity
        self._component_count = existing._component_count
        self._item_sizes = existing._item_sizes
        self._entities = existing._entities
        self._ids = existing._ids

    fn __del__(owned self):
        for i in range(self._component_count):
            self._data[int(self._ids[i])].free()

    fn __len__(self) -> Int:
        """Returns the number of entities in the archetype."""
        return self._size

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
