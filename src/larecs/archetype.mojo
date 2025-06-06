from sys.intrinsics import _type_is_eq
from memory import memcpy, UnsafePointer
from .component import ComponentManager, constrain_components_unique
from .entity import Entity
from .bitmask import BitMask
from .pool import EntityPool
from .types import get_max_size

alias DEFAULT_CAPACITY = 32
"""Default capacity of an archetype."""

alias MutableEntityAccessor = EntityAccessor[True]
"""An entity accessor with mutable references to the components."""


struct EntityAccessor[
    archetype_mutability: Bool,
    archetype_origin: Origin[archetype_mutability],
    *ComponentTypes: ComponentType,
    component_manager: ComponentManager[*ComponentTypes],
]:
    """Accessor for an Entity.

    Caution: use this only in the context it was created in.
    In particular, do not store it anywhere.

    Parameters:
        archetype_mutability: Whether the reference to the list is mutable.
        archetype_origin: The lifetime of the List.
        ComponentTypes: The types of the components.
        component_manager: The component manager.
    """

    alias Archetype = Archetype[
        *ComponentTypes, component_manager=component_manager
    ]
    """The archetype of the entity."""

    var _archetype: Pointer[Self.Archetype, archetype_origin]
    var _index_in_archetype: Int

    @doc_private
    @always_inline
    fn __init__(
        out self,
        archetype: Pointer[Self.Archetype, archetype_origin],
        index_in_archetype: Int,
    ):
        """
        Args:
            archetype: The archetype of the entity.
            index_in_archetype: The index of the entity in the archetype.
        """
        self._archetype = archetype
        self._index_in_archetype = index_in_archetype

    @always_inline
    fn get_entity(self) -> Entity:
        """Returns the entity of the accessor.

        Returns:
            The entity of the accessor.
        """
        return self._archetype[].get_entity(self._index_in_archetype)

    @always_inline
    fn get[
        T: ComponentType
    ](ref self) raises -> ref [self._archetype[]._data] T:
        """Returns a reference to the given component of the Entity.

        Parameters:
            T: The type of the component.

        Returns:
            A reference to the component of the entity.

        Raises:
            Error: If the entity does not have the component.
        """
        return self._archetype[].get_component[T=T](
            self._index_in_archetype,
        )

    @always_inline
    fn set[
        *Ts: ComponentType
    ](
        mut self: EntityAccessor[archetype_mutability=True],
        owned *components: *Ts,
    ) raises:
        """
        Overwrites components for an [..entity.Entity], using the given content.

        Parameters:
            Ts:        The types of the components.

        Args:
            components: The new components.

        Raises:
            Error: If the entity does not exist or does not have the component.
        """
        constrain_components_unique[*Ts]()

        @parameter
        for i in range(components.__len__()):
            self._archetype[].get_component[T = Ts[i.value]](
                self._index_in_archetype
            ) = components[i]

    @always_inline
    fn has[T: ComponentType](self) -> Bool:
        """
        Returns whether an [..entity.Entity] has a given component.

        Parameters:
            T: The type of the component.

        Returns:
            Whether the entity has the component.
        """
        return self._archetype[].has_component[T]()


struct Archetype[
    *Ts: ComponentType,
    component_manager: ComponentManager[*Ts],
](Boolable, Copyable, ExplicitlyCopyable, Movable, Sized):
    """
    Archetype represents an ECS archetype.

    Parameters:
        Ts: The component types of the archetype.
        component_manager: The component manager.
    """

    alias dType = BitMask.IndexDType
    """The DType of the component ids."""

    alias Id = SIMD[Self.dType, 1]
    """The type of the component ids."""

    alias Index = UInt32
    """The type of the index of entities."""

    alias max_size = get_max_size[Self.dType]()
    """The maximal number of components in the archetype."""

    alias EntityAccessor = EntityAccessor[
        _, _, *Ts, component_manager=component_manager
    ]
    """The type of the entity accessors generated by the archetype."""

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

    # Mask of the the archetype's node in the archetype graph
    var _mask: BitMask

    fn __init__(
        out self,
    ):
        """Initializes the zero archetype without any component.

        Returns:
            The zero archetype.
        """
        self = Self.__init__[used_internally=True](0, BitMask(), 0)

    @doc_private
    fn __init__[
        *, used_internally: Bool
    ](out self, node_index: UInt, mask: BitMask, capacity: UInt):
        """Initializes the archetype without allocating memory for components.

        Note:
            Do not use this constructor directly!

        Parameters:
            used_internally: A flag indicating whether this constructor
                is used internally.

        Args:
            node_index: The index of the archetype's node in the archetype graph.
            mask: The mask of the archetype's node in the archetype graph.
            capacity:   The initial capacity of the archetype.

        Constraints:
            `used_internally` must be `True` to use this constructor.

        Returns:
            An archetype without allocated memory.
        """
        constrained[
            used_internally,
            "This constructor is meant for internal use only.",
        ]()

        self._size = 0
        self._mask = mask
        self._component_count = 0
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

        Parameters:
            component_count: The number of components in the archetype.

        Returns:
            The archetype with the given components.
        """
        mask_ = BitMask()

        @parameter
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

        The components in the archetype are determined by the component_ids.
        The mask is not checked for consistency with the component IDs.

        Args:
            node_index: The index of the archetype's node in the archetype graph.
            mask: The mask of the archetype's node in the archetype graph
                  (not used in initializer; not checked for consistency with component_ids).
            component_ids: The IDs of the components of the archetype.
            capacity: The initial capacity of the archetype.

        Parameters:
            component_count: The number of components in the archetype.

        Returns:
            The archetype with the given components and BitMask.
        """
        constrained[
            Self.dType.is_integral(),
            "The component identifier type needs to be an integral type.",
        ]()

        constrained[
            Self.max_size >= component_count,
            "An archetype cannot have more components than "
            + String(Self.max_size)
            + ".",
        ]()

        self = Self.__init__[used_internally=True](node_index, mask, capacity)
        self._component_count = component_count

        @parameter
        for i in range(component_count):
            id = component_ids[i]
            self._item_sizes[id] = component_manager.component_sizes[id]
            self._ids[i] = id
            self._data[id] = UnsafePointer[UInt8].alloc(
                self._capacity * index(component_manager.component_sizes[id])
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

        Returns:
            The archetype based on the given mask.
        """
        self = Self.__init__[used_internally=True](node_index, mask, capacity)
        self._component_count = 0

        @parameter
        for i in range(component_manager.component_count):
            if mask.get(i):
                self._item_sizes[i] = component_manager.component_sizes[i]
                self._ids[self._component_count] = i
                self._data[i] = UnsafePointer[UInt8].alloc(
                    self._capacity * index(self._item_sizes[i])
                )
                self._component_count += 1

    fn copy(self, out other: Self):
        """Returns a copy of the archetype.

        Returns:
            A copy of the current archetype.
        """
        other = self

    fn __moveinit__(out self, owned existing: Self):
        """Moves the data from an existing archetype to a new one.

        Args:
            existing: The archetype to move from.
        """
        self._data = existing._data^
        self._size = existing._size
        self._capacity = existing._capacity
        self._component_count = existing._component_count
        self._item_sizes = existing._item_sizes^
        self._entities = existing._entities^
        self._ids = existing._ids
        self._node_index = existing._node_index
        self._mask = existing._mask

    fn __copyinit__(out self, existing: Self):
        """Copies the data from an existing archetype to a new one.

        Args:
            existing: The archetype to copy from.
        """
        # Copy the attributes that can be trivially
        # copied via a simple assignment
        self._size = existing._size
        self._capacity = existing._capacity
        self._component_count = existing._component_count
        self._item_sizes = existing._item_sizes
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
            size = existing._capacity * index(existing._item_sizes[id])
            self._data[id] = UnsafePointer[UInt8].alloc(size)
            memcpy(
                self._data[id],
                existing._data[id],
                size,
            )

    fn __del__(owned self):
        """Frees the memory of the archetype."""
        for i in range(self._component_count):
            self._data[self._ids[i]].free()

    @always_inline
    fn __len__(self) -> Int:
        """Returns the number of entities in the archetype.

        Returns:
            The number of entities in the archetype.
        """
        return self._size

    @always_inline
    fn __bool__(self) -> Bool:
        """Returns whether the archetype contains entities.

        Returns:
            Whether the archetype contains entities.
        """
        return Bool(self._size)

    @always_inline
    fn get_node_index(self) -> UInt:
        """Returns the index of the archetype's node in the archetype graph.

        Returns:
            The index of the archetype's node in the archetype graph.
        """
        return self._node_index

    @always_inline
    fn get_mask(self) -> ref [self._mask] BitMask:
        """Returns the mask of the archetype's node in the archetype graph.

        Returns:
            The mask of the archetype's node in the archetype graph.
        """
        return self._mask

    @always_inline
    fn reserve(mut self):
        """Extends the capacity of the archetype by factor 2."""
        self.reserve(max(self._capacity * 2, 8))

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
            old_size = index(self._item_sizes[id]) * self._capacity
            new_size = index(self._item_sizes[id]) * new_capacity
            new_memory = UnsafePointer[UInt8].alloc(new_size)
            memcpy(
                new_memory,
                self._data[id],
                old_size,
            )
            self._data[id].free()
            self._data[id] = new_memory

        self._capacity = new_capacity

    @always_inline
    fn get_entity[T: Indexer](self, idx: T) -> ref [self._entities] Entity:
        """Returns the entity at the given index.

        Parameters:
            T: The type of the index.

        Args:
            idx: The index of the entity.

        Returns:
            A reference to the entity at the given index.
        """
        return self._entities[idx]

    @always_inline
    fn get_entity_accessor[
        mutability: Bool, //,
        T: Indexer,
        origin: Origin[mutability],
    ](
        ref [origin]self,
        idx: T,
        out accessor: Self.EntityAccessor[mutability, origin],
    ):
        """Returns an accessor for the entity at the given index.

        Parameters:
            mutability: Whether the reference to the list is mutable.
            T: The type of the index.
            origin: The lifetime of the list.

        Args:
            idx: The index of the entity.

        Returns:
            An accessor for the entity at the given index.
        """
        accessor = Self.EntityAccessor(
            Pointer(to=self),
            index(idx),
        )

    @always_inline
    fn unsafe_set[
        T: Indexer
    ](mut self, idx: T, id: Self.Id, value: UnsafePointer[UInt8]):
        """Sets the component with the given id at the given index.

        Parameters:
            T: The type of the index.

        Args:
            idx: The index of the entity.
            id: The id of the component.
            value: A pointer to the value being set.
        """
        memcpy(
            self._get_component_ptr(index(idx), id),
            value,
            index(self._item_sizes[id]),
        )

    @always_inline
    fn _get_component_ptr(self, idx: UInt, id: Self.Id) -> UnsafePointer[UInt8]:
        """Returns the component with the given id at the given index.

        Does not check if the archetype contains the component.

        Args:
            idx: The index of the entity.
            id: The id of the component.

        Returns:
            A pointer to the component.
        """
        return self._data[id] + idx * self._item_sizes[id]

    @always_inline
    fn get_component[
        IndexType: Indexer, //,
        *,
        T: ComponentType,
        assert_has_component: Bool = True,
    ](ref self, idx: IndexType) raises -> ref [self._data] T:
        """Returns the component with the given id at the given index.

        Args:
            idx:    The index of the entity.

        Parameters:
            IndexType: The type of the index.
            T: The type of the component.
            assert_has_component: Whether to assert that the archetype
                    contains the component.

        Raises:
            Error:  If assert_has_component and the archetype does not contain the component.

        Returns:
            A reference to the component.
        """
        alias id = component_manager.get_id[T]()
        alias component_size = component_manager.component_sizes[id]

        @parameter
        if assert_has_component:
            self.assert_has_component(id)

        return (self._data[id] + index(idx) * component_size).bitcast[T]()[]

    @always_inline
    fn get_entities(self) -> ref [self._entities] List[Entity]:
        """Returns the entities in the archetype.

        Returns:
            A reference to the entities in the archetype.
        """
        return self._entities

    @always_inline
    fn has_component(self, id: Self.Id) -> Bool:
        """Returns whether the archetype contains the given component id.

        Args:
            id: The id of the component.

        Returns:
            Whether the archetype contains the component.
        """
        return Bool(self._data[id])

    @always_inline
    fn has_component[T: ComponentType](self) -> Bool:
        """Returns whether the archetype contains the given component id.

        Parameters:
            T: The type of the component.

        Returns:
            Whether the archetype contains the component.
        """
        return Bool(self._data[component_manager.get_id[T]()])

    @always_inline
    fn assert_has_component(self, id: Self.Id) raises:
        """Raises if the archetype does not contain the given component id.

        Args:
            id: The id of the component.

        Raises:
            Error: If the archetype does not contain the component.
        """
        if not self.has_component(id):
            raise Error(
                "Archetype does not contain component with id "
                + String(id)
                + "."
            )

    @always_inline
    fn remove[T: Indexer](mut self, idx: T) -> Bool:
        """Removes an entity and its components from the archetype.

        Performs a swap-remove and reports whether a swap was necessary
        (i.e. not the last entity that was removed).

        Parameters:
            T: The type of the index.

        Args:
            idx: The index of the entity to remove.

        Returns:
            Whether a swap was necessary.
        """

        self._size -= 1

        var swapped = Int(idx) != self._size

        if swapped:
            self._entities[idx] = self._entities.pop()

            for i in range(self._component_count):
                id = self._ids[i]
                size = self._item_sizes[id]
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

    fn clear(mut self):
        """Removes all entities from the archetype.

        Note: does not free any memory.
        """
        self._entities.clear()
        self._size = 0

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
        count: UInt,
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
            new_capacity = max(self._size + count, UInt(2) * self._capacity)
            self.reserve(new_capacity)
            self._entities.reserve(new_capacity)

        start_index = self._size
        for _ in range(count):
            self._entities.append(entity_pool.get())
        self._size += count
        return start_index
