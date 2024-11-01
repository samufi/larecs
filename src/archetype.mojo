from collections import InlineArray, InlineList
from component import ComponentInfo, ComponentReference
from memory import memcpy, UnsafePointer
from entity import Entity

from types import get_max_uint_size, TrivialIntable


struct Archetype[Id: TrivialIntable](CollectionElementNew):
    """Archetype represents an ECS archetype.

    Parameters:
        Id: The type of the component identifier.
            Note: The size of the type needs to be
            suffiently small. If it is bigger than
            UInt16, a compile-time error will be raised
            ("failed to run the pass manager").

    """

    # The maximal number of components in the archetype.
    alias max_size = get_max_uint_size[Id]()

    # Pointers to the component data.
    var _data: InlineArray[
        UnsafePointer[UInt8], Self.max_size, run_destructors=True
    ]

    # Current number of entities.
    var _size: UInt

    # Current capacity.
    var _capacity: UInt

    # Sizes of the component types by column
    var _item_sizes: InlineArray[UInt32, Self.max_size, run_destructors=True]

    # The indices of the present components
    var _ids: InlineList[Id, Self.max_size]

    # The entities in the archetype
    var _entities: List[Entity]

    fn __init__(
        inout self, capacity: UInt, *components: ComponentInfo[Self.Id]
    ):
        self._size = 0
        self._capacity = capacity
        self._data = InlineArray[
            UnsafePointer[UInt8], Self.max_size, run_destructors=True
        ](UnsafePointer[UInt8]())
        self._item_sizes = InlineArray[
            UInt32, Self.max_size, run_destructors=True
        ](0)
        self._ids = InlineList[Id, Self.max_size]()
        self._entities = List[Entity]()

        for component in components:
            self._item_sizes[int(component[].id)] = component[].size
            self._ids.append(component[].id)
            self._data[int(component[].id)] = UnsafePointer[UInt8].alloc(
                self._capacity * int(component[].size)
            )

    fn __init__(inout self, /, *, other: Self):
        # Copy the attributes that can be trivially
        # copied via a simple assignment
        self._size = other._size
        self._capacity = other._capacity
        self._item_sizes = other._item_sizes
        self._entities = other._entities

        # Hopefully this can become a simple copy in the future
        self._ids = InlineList[Id, Self.max_size]()
        self._ids._size = other._ids._size
        self._ids._array = other._ids._array

        # Copy the data
        self._data = InlineArray[
            UnsafePointer[UInt8], Self.max_size, run_destructors=True
        ](UnsafePointer[UInt8]())

        for id in other._ids:
            size = self._capacity * int(other._item_sizes[int(id[])])
            self._data[int(id[])] = UnsafePointer[UInt8].alloc(size)
            memcpy(
                self._data[int(id[])],
                other._data[int(id[])],
                size,
            )

    fn __moveinit__(inout self, owned existing: Self):
        self._data = existing._data
        self._size = existing._size
        self._capacity = existing._capacity
        self._item_sizes = existing._item_sizes
        self._entities = existing._entities

        # Hopefully this can become a simple copy in the future
        # Note that the pattern from the copyinit above does not
        # work here, because existing is owned and 
        # copying internal variables causes destruction issues.
        # I am not sure why.
        self._ids = InlineList[Id, Self.max_size]()
        for id in existing._ids:
            self._ids.append(id[])

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
        for i in self._ids:
            new_memory = UnsafePointer[UInt8].alloc(int(self._capacity))
            memcpy(
                new_memory,
                self._data[int(i[])],
                int(self._size * self._item_sizes[int(i[])]),
            )
            self._data[int(i[])].free()
            self._data[int(i[])] = new_memory

    @always_inline
    fn get_entity(self, index: UInt) -> ref [__lifetime_of(self)] Entity:
        """Returns the entity at the given index."""
        return self._entities[index]

    @always_inline
    fn _get_component_ptr(self, index: UInt, id: Id) -> UnsafePointer[UInt8]:
        """Returns the component with the given id at the given index."""
        return self._data[int(id)] + index * int(self._item_sizes[int(id)])

    @always_inline
    fn has_component(self, id: Id) -> Bool:
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

            for id in self._ids:
                size = int(self._item_sizes[int(id[])])
                if size == 0:
                    continue

                memcpy(
                    self._get_component_ptr(index, int(id[])),
                    self._get_component_ptr(self._size, int(id[])),
                    size,
                )
        else:
            _ = self._entities.pop()

        return swapped
