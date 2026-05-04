from std.sys.intrinsics import _type_is_eq
from std.collections.check_bounds import check_bounds
from std.memory import memcpy, UnsafePointer
from std.sys import size_of
from std.bit import next_power_of_two
from .entity import Entity
from .component import (
    constrain_components_unique,
    get_max_size,
    ComponentManager,
)
from .bitmask import BitMask
from .pool import EntityPool
from .types import get_max_size

comptime DEFAULT_CAPACITY = 32
"""Default capacity of an archetype."""

comptime MutableEntityAccessor = EntityAccessor[archetype_mutability=True, ...]
"""An entity accessor with mutable references to the components."""


struct EntityAccessor[
    archetype_mutability: Bool,
    //,
    archetype_origin: Origin[mut=archetype_mutability],
    *ComponentTypes: ComponentType,
    component_manager: ComponentManager[*ComponentTypes],
](Movable):
    """Accessor for an Entity.

    Caution: use this only in the context it was created in.
    In particular, do not store it anywhere.

    Parameters:
        archetype_mutability: Whether the reference to the list is mutable.
        archetype_origin: The lifetime of the List.
        ComponentTypes: The types of the components.
        component_manager: The component manager that provides size information about the component types.
    """

    comptime Archetype = Archetype[
        *Self.ComponentTypes, component_manager=Self.component_manager
    ]
    """The archetype of the entity."""

    var _archetype: Pointer[Self.Archetype, Self.archetype_origin]
    var _index_in_archetype: Int

    @doc_hidden
    @always_inline
    def __init__(
        out self,
        archetype: Pointer[Self.Archetype, Self.archetype_origin],
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
    def get_entity(self) -> Entity:
        """Returns the entity of the accessor.

        Returns:
            The entity of the accessor.
        """
        return self._archetype[].get_entity(self._index_in_archetype)

    @always_inline
    def get[T: ComponentType](ref self) raises -> ref[self.archetype_origin] T:
        """Returns a reference to the given component of the Entity.

        Parameters:
            T: The type of the component.

        Raises:
            Error: If the entity's archetype does not contain the component.

        Returns:
            A reference to the component of the entity.
        """
        comptime assert Self.component_manager._ContainsComponent[
            T
        ], "Component type not in component manager"
        return self._archetype[].get_component[T](
            self._index_in_archetype,
        )

    @always_inline
    def set[
        origin: MutOrigin, *Ts: ComponentType
    ](
        mut self: EntityAccessor[
            origin,
            *Self.ComponentTypes,
            component_manager=Self.component_manager,
        ],
        var *components: *Ts,
    ) raises:
        """
        Overwrites components for an [..entity.Entity], using the given content.

        Parameters:
            origin: The origin of the accessor.
            Ts:        The types of the components.

        Args:
            components: The new components.

        Raises:
            Error: If the entity's archetype does not contain one of the components.
        """
        comptime assert constrain_components_unique[
            *Ts
        ](), "Component types must be unique."
        comptime assert Self.component_manager._ContainsComponents[
            *Ts
        ], "All component types must be contained in the component manager."

        self._archetype[].set_components[*Ts](
            self._index_in_archetype, *components^
        )

    @always_inline
    def has[T: ComponentType](self) -> Bool:
        """
        Returns whether an [..entity.Entity] has a given component.

        Parameters:
            T: The type of the component.

        Returns:
            Whether the entity has the component.
        """
        comptime assert Self.component_manager._ContainsComponent[
            T
        ], "Component type not in component manager"
        return self._archetype[].has_component[T]()


struct Archetype[
    *ComponentTypes: ComponentType,
    component_manager: ComponentManager[*ComponentTypes],
](Boolable, Copyable, Movable, Sized):
    """
    Archetype represents an ECS archetype.

    Parameters:
        ComponentTypes: The component types of the archetype.
        component_manager: The component manager that provides size information about the component types.
    """

    comptime Id = Self.component_manager.Id
    """The type of the component ids."""

    comptime Index = UInt32
    """The type of the index of entities."""

    comptime max_size = BitMask.total_bits
    """The maximal number of components in the archetype."""

    comptime EntityAccessor = EntityAccessor[
        _, *Self.ComponentTypes, component_manager=Self.component_manager
    ]
    """The type of the entity accessors generated by the archetype."""

    # TODO: When <insert modular issue> is resolved use TypeList.map here to get a Tuple of typed pointers
    comptime PointerTypes = InlineArray[
        UnsafePointer[UInt8, MutExternalOrigin], Self.max_size
    ]

    # Pointers to the component data.
    var _data: Self.PointerTypes

    # Current number of entities.
    var _size: Int

    # Current capacity.
    var _capacity: Int

    # number of components.
    var _component_count: Int

    # Sizes of the component types by column
    var _item_sizes: InlineArray[Int, Self.max_size]

    # The indices of the present components
    var _ids: InlineArray[Self.Id, Self.max_size]

    # The entities in the archetype
    var _entities: List[Entity]

    # Index of the the archetype's node in the archetype graph
    var _node_index: Int

    # Mask of the the archetype's node in the archetype graph
    var _mask: BitMask

    def __init__(
        out self,
    ):
        """Initializes the zero archetype without any component.

        Returns:
            The zero archetype.
        """
        self = Self.__init__[used_internally=True](0, BitMask(), 0)

    @doc_hidden
    @always_inline
    def __init__[
        *, used_internally: Bool
    ](
        out self, node_index: Int, mask: BitMask, capacity: Int
    ) where used_internally:
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

        debug_assert(
            0 <= capacity, "Capacity must be greater or equal to zero."
        )
        check_bounds(node_index, Self.max_size)

        self._size = 0
        self._mask = mask
        self._component_count = 0
        self._capacity = capacity
        self._ids = InlineArray[Self.Id, Self.max_size](fill=-1)
        self._data = InlineArray[
            UnsafePointer[UInt8, MutExternalOrigin], Self.max_size
        ](fill=UnsafePointer[UInt8, MutExternalOrigin].unsafe_dangling())
        self._item_sizes = InlineArray[Int, Self.max_size](fill=0)
        self._entities = List[Entity]()
        self._node_index = node_index

    @always_inline
    def __init__[
        component_count: Int
    ](
        out self,
        node_index: Int,
        component_ids: InlineArray[Self.Id, component_count] = InlineArray[
            Self.Id, component_count
        ](fill=Self.Id(0)),
        capacity: Int = DEFAULT_CAPACITY,
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

        Constraints:
            `component_count` must be non-negative.
        """
        comptime assert (
            0 <= component_count
        ), "Component count must be non-negative."

        mask_ = BitMask()

        comptime for i in range(component_count):
            mask_.set[True](component_ids[i])

        self = Self(node_index, mask_, component_ids, capacity)

    def __init__[
        component_count: Int
    ](
        out self,
        node_index: Int,
        mask: BitMask,
        component_ids: InlineArray[Self.Id, component_count],
        capacity: Int = DEFAULT_CAPACITY,
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

        Constraints:
             `component_count` must be non-negative.
        """
        comptime assert (
            0 <= component_count
        ), "Component count must be non-negative."

        self = Self.__init__[used_internally=True](node_index, mask, capacity)
        self._component_count = component_count

        comptime for i in range(component_count):
            id = component_ids[i]
            self._item_sizes[id] = Self.component_manager.component_sizes[id]
            self._ids[i] = id
            self._data[id] = alloc[UInt8](
                self._capacity * Self.component_manager.component_sizes[id]
            )

    def __init__(
        out self,
        node_index: Int,
        mask: BitMask,
        capacity: Int = DEFAULT_CAPACITY,
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

        comptime for i in range(len(Self.ComponentTypes)):
            if mask.get(i):
                self._item_sizes[i] = Self.component_manager.component_sizes[i]
                self._ids[self._component_count] = i
                self._data[i] = alloc[UInt8](
                    self._capacity * self._item_sizes[i]
                )
                self._component_count += 1

    def __init__(out self, *, copy: Self):
        """Copies the data from an existing archetype to a new one.

        Args:
            copy: The archetype to copy from.
        """
        # Copy the attributes that can be trivially
        # copied via a simple assignment
        self._size = copy._size
        self._capacity = copy._capacity
        self._component_count = copy._component_count
        self._item_sizes = copy._item_sizes
        self._entities = copy._entities.copy()
        self._ids = copy._ids
        self._node_index = copy._node_index
        self._mask = copy._mask

        # Copy the data
        self._data = InlineArray[
            UnsafePointer[UInt8, MutExternalOrigin], Self.max_size
        ](fill=UnsafePointer[UInt8, MutExternalOrigin].unsafe_dangling())

        for i in range(copy._component_count):
            id = copy._ids[i]
            size = copy._capacity * copy._item_sizes[id]
            self._data[id] = alloc[UInt8](size)
            memcpy(
                dest=self._data[id],
                src=copy._data[id],
                count=size,
            )

    def __del__(deinit self):
        """Frees the memory of the archetype."""
        for i in range(self._component_count):
            self._data[self._ids[i]].free()

    @always_inline
    def __len__(self) -> Int:
        """Returns the number of entities in the archetype.

        Returns:
            The number of entities in the archetype.
        """
        return Int(self._size)

    @always_inline
    def __bool__(self) -> Bool:
        """Returns whether the archetype contains entities.

        Returns:
            Whether the archetype contains entities.
        """
        return Bool(self._size)

    def unsafe_reinit_components(
        mut self, ids: InlineArray[Self.Id, Self.max_size]
    ):
        """Reinitializes owned component storage while keeping the component layout intact.

        Important:
        This is intended for internal ownership-transfer flows where another archetype has
        taken over the old storage pointers and this archetype must regain valid, uniquely
        owned allocations before continuing.

        The component IDs themselves are not changed here; they are read from `self._ids`
        to determine which component buffers must be reallocated.

        Args:
            ids: The IDs of the components that should get reinitialized.
        """
        self._capacity = DEFAULT_CAPACITY

        for i in range(self._component_count):
            id = self._ids[i]
            if id in ids:
                self._data[id] = alloc[UInt8](
                    self._capacity * self._item_sizes[id]
                )

    @always_inline
    def get_node_index(self) -> Int:
        """Returns the index of the archetype's node in the archetype graph.

        Returns:
            The index of the archetype's node in the archetype graph.
        """
        return self._node_index

    @always_inline
    def get_mask(self) -> ref[self._mask] BitMask:
        """Returns the mask of the archetype's node in the archetype graph.

        Returns:
            The mask of the archetype's node in the archetype graph.
        """
        return self._mask

    @always_inline
    def reserve(mut self):
        """Extends the capacity of the archetype by factor 2 using power-of-2 allocation strategy.

        Doubles the current capacity (minimum 8) to provide exponential growth that minimizes
        the frequency of memory reallocations while maintaining reasonable memory usage.
        This follows standard container growth patterns optimized for amortized performance.
        """
        self.reserve(max(self._capacity * 2, 8))

    def reserve(mut self, new_capacity: Int):
        """Extends the capacity of the archetype to at least the specified number of entities.

        Uses a power-of-2 allocation strategy to ensure optimal memory alignment and reduce
        fragmentation. The actual allocated capacity will be the next power of 2 greater than
        or equal to the requested capacity.

        Does nothing if the requested capacity is not larger than the current capacity,
        avoiding unnecessary work and maintaining existing memory layout.

        Args:
            new_capacity: The minimum required capacity. The actual allocated capacity
                         will be `next_power_of_two(new_capacity)` to maintain power-of-2 growth.

        Example:

        ```mojo
        # Requesting 100 entities will allocate capacity for 128 (next power of 2)
        archetype.reserve(100)  # Actually reserves 128

        # Requesting 64 entities allocates exactly 64 (already power of 2)
        archetype.reserve(64)   # Actually reserves 64
        ```
        """
        debug_assert(
            0 < new_capacity, "New capacity must be greater than zero."
        )

        if new_capacity <= self._capacity:
            return

        new_pow2_capacity = next_power_of_two(new_capacity)

        for i in range(self._component_count):
            id = self._ids[i]
            old_size = self._item_sizes[id] * self._capacity
            new_size = self._item_sizes[id] * new_pow2_capacity
            new_memory = alloc[UInt8](new_size)
            memcpy(
                dest=new_memory,
                src=self._data[id],
                count=old_size,
            )
            self._data[id].free()
            self._data[id] = new_memory

        self._capacity = new_pow2_capacity

    @always_inline
    def get_entity(self, idx: Int) -> ref[self._entities] Entity:
        """Returns the entity at the given index.

        Args:
            idx: The index of the entity.

        Returns:
            A reference to the entity at the given index.
        """
        check_bounds(idx, self._size)
        return self._entities[idx]

    @always_inline
    def get_entity_accessor[
        mut: Bool, //, origin: Origin[mut=mut]
    ](
        ref[origin] self,
        idx: Int,
        out accessor: Self.EntityAccessor[archetype_origin=origin],
    ):
        """Returns an accessor for the entity at the given index.

        Args:
            idx: The index of the entity.

        Returns:
            An accessor for the entity at the given index.
        """
        check_bounds(idx, self._size)

        accessor = Self.EntityAccessor(
            Pointer(to=self),
            idx,
        )

    @always_inline
    def unsafe_set[
        mut: Bool, //, origin: Origin[mut=mut]
    ](mut self, idx: Int, id: Self.Id, value: UnsafePointer[UInt8, origin]):
        """Sets the component with the given id at the given index.

        Args:
            idx: The index of the entity.
            id: The id of the component.
            value: A pointer to the value being set.
        """
        check_bounds(idx, self._size)

        memcpy(
            dest=self._get_component_ptr(idx, id),
            src=value,
            count=self._item_sizes[id],
        )

    @always_inline
    def unsafe_set[
        mut: Bool, //, origin: Origin[mut=mut], T: ComponentType
    ](
        mut self,
        start_idx: Int,
        data: UnsafePointer[UInt8, origin],
        count: Int,
    ):
        """Sets the data of the component with the given id for multiple consecutive entities starting with the given index.

        Parameters:
            mut: Whether the data pointer is mutable.
            origin: The lifetime of the data pointer.
            T: The type of the index. Constraints: Must be contained in the component manager.

        Args:
            start_idx: The index of the first entity to set.
            data: Pointer to the values to set the component with.
            count: The number of elements to set.
        """
        comptime assert Self.component_manager._ContainsComponent[
            T
        ], "Component type not in component manager"
        debug_assert(
            0 <= start_idx and start_idx + count <= self._size,
            "Index out of bounds.",
        )

        comptime id = Self.component_manager.get_id[T]()

        memcpy(
            dest=self._get_component_ptr(start_idx, id),
            src=data,
            count=self._item_sizes[id] * count,
        )

    @always_inline
    def unsafe_take_data_from_parts[](
        mut self,
        ids: InlineArray[Self.Id, Self.max_size],
        data: InlineArray[
            UnsafePointer[UInt8, MutExternalOrigin], Self.max_size
        ],
        item_sizes: InlineArray[Int, Self.max_size],
        component_count: Int,
        capacity: Int,
    ):
        """Unsafely takes ownership of component storage described by raw archetype parts.

        This helper transfers pointer ownership into `self` without cloning the underlying
        component buffers. It is therefore only valid for internal handoff paths where the
        caller guarantees that the source storage will not remain managed by another
        archetype after this call. In practice, the source archetype must either be
        reinitialized immediately (by calling [.Archetype.unsafe_reinit_components]) or
        otherwise prevented from freeing or mutating the same pointers.

        Args:
            ids: The component IDs whose metadata and storage ownership are being taken.
            data: The component storage pointers to transfer into this archetype.
            item_sizes: The byte width for each component ID in `ids`.
            component_count: The number of valid component entries contained in `ids`,
                `data`, and `item_sizes`.
            capacity: The storage capacity that the transferred buffers were allocated for.
        """
        for i in range(self._component_count):
            id = self._ids[i]
            check_bounds(id, Self.max_size)
            if id in ids:
                if self._data[id] != data[id]:
                    self._data[id].free()
                self._data[id] = data[id]
                self._item_sizes[id] = item_sizes[id]
            elif self._capacity < capacity:
                self._data[id].free()
                self._data[id] = alloc[UInt8](capacity * self._item_sizes[id])

        self._capacity = capacity

    @always_inline
    def _get_component_ptr(
        self, entity_idx: Int, id: Self.Id
    ) -> UnsafePointer[UInt8, MutExternalOrigin]:
        """Returns the component with the given id at the given index.

        Does not check if the archetype contains the component.

        Args:
            entity_idx: The index of the entity.
            id: The id of the component.

        Returns:
            A pointer to the component.
        """
        check_bounds(entity_idx, self._size)

        return self._data[id] + entity_idx * self._item_sizes[id]

    @always_inline
    def get_component[
        T: ComponentType
    ](ref self, entity_idx: Int) raises -> ref[self] T:
        """Returns the component with the given Type T at the given index.

        Parameters:
            T: The type of the component. Constraints: Must be contained in the component manager.

        Args:
            entity_idx: The index of the entity.

        Raises:
            Error: If the archetype does not contain the component.

        Returns:
            A reference to the component.
        """
        comptime assert Self.component_manager._ContainsComponent[
            T
        ], "Component type not in component manager"
        comptime id = Self.component_manager.get_id[T]()

        check_bounds(entity_idx, self._size)

        self.assert_has_component(id)
        return self._get_component_ptr(entity_idx, id).bitcast[T]()[]

    @always_inline
    def set_component[
        T: ComponentType
    ](mut self, entity_idx: Int, var component: T) raises:
        """Sets the component with the given Type T at the given index.

        Parameters:
            T: The type of the component. Constraints: Must be contained in the component manager.

        Args:
            entity_idx: The index of the entity.
            component: The new value of the component.

        Raises:
            Error: If the archetype does not contain the component.
        """
        comptime assert Self.component_manager._ContainsComponent[
            T
        ], "Component type not in component manager"
        check_bounds(entity_idx, self._size)
        self.get_component[T](entity_idx) = component^

    @always_inline
    def set_components[
        *Ts: ComponentType
    ](mut self, entity_idx: Int, var *components: *Ts) raises:
        """Sets the component with the given Type T at the given index.

        Parameters:
            Ts: The types of the components to set. Constraints: Must be contained in the component manager and must be unique.

        Args:
            entity_idx: The index of the entity.
            components: The new values of the components.

        Raises:
            Error: If the archetype does not contain one of the components.
        """
        comptime assert constrain_components_unique[
            *Ts
        ](), "Component types must be unique."
        check_bounds(entity_idx, self._size)

        comptime for i in range(len(Ts)):
            comptime T = Ts[i]
            comptime assert Self.component_manager._ContainsComponent[
                T
            ], "Component type not in component manager"
            self.assert_has_component(Self.component_manager.get_id[T]())

        def set_component[comp_id: Int](var component: Ts[comp_id]) capturing:
            comptime T = Ts[comp_id]
            comptime id = Self.component_manager.get_id[T]()
            memcpy(
                dest=self._get_component_ptr(entity_idx, id),
                src=UnsafePointer(to=component).bitcast[UInt8](),
                count=self._item_sizes[id],
            )

        (components^).consume_elements[set_component]()

    @always_inline
    def get_entities(self) -> ref[self._entities] List[Entity]:
        """Returns the entities in the archetype.

        Returns:
            A reference to the entities in the archetype.
        """
        return self._entities

    @always_inline
    def has_component(self, id: Self.Id) -> Bool:
        """Returns whether the archetype contains the given component id.

        Args:
            id: The id of the component.

        Returns:
            Whether the archetype contains the component.
        """
        return self._mask.get(id)

    @always_inline
    def has_component[T: ComponentType](self) -> Bool:
        """Returns whether the archetype contains the given component id.

        Parameters:
            T: The type of the component. Constraints: Must be contained in the component manager.

        Returns:
            Whether the archetype contains the component.
        """
        comptime assert Self.component_manager._ContainsComponent[
            T
        ], "Component type not in component manager"
        return self._mask.get(Self.component_manager.get_id[T]())

    @always_inline
    def assert_has_component(self, id: Self.Id) raises:
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
    def remove(mut self, idx: Int) -> Bool:
        """Removes an entity and its components from the archetype.

        Performs a swap-remove and reports whether a swap was necessary
        (i.e. not the last entity that was removed).

        Args:
            idx: The index of the entity to remove.

        Returns:
            Whether a swap was necessary.
        """

        check_bounds(idx, self._size)

        # Store new size temporarily to not interfere with further bounds checking
        new_size = self._size - 1

        var swapped = idx != new_size

        if swapped:
            self._entities[idx] = self._entities.pop()

            for i in range(self._component_count):
                id = self._ids[i]
                size = self._item_sizes[id]
                if size == 0:
                    continue

                memcpy(
                    dest=self._get_component_ptr(idx, id),
                    src=self._get_component_ptr(new_size, id),
                    count=size,
                )
        else:
            _ = self._entities.pop()

        self._size = new_size

        return swapped

    @always_inline
    def clear(mut self):
        """Removes all entities from the archetype.

        Note: does not free any memory.
        """
        self._entities.clear()
        self._size = 0

    @always_inline
    def add(mut self, entity: Entity) -> Int:
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

    @always_inline
    def extend(
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
        if count <= 0:
            return self._size - 1

        if self._size + count >= self._capacity:
            self.reserve(
                self._size + count
            )  # `reserve` handles calculating a good capacity to use
            self._entities.reserve(
                self._capacity
            )  # use the capacity calculated by `reserve` for the entities list as well

        start_index = self._size
        for _ in range(count):
            self._entities.append(entity_pool.get())
        self._size += count
        return start_index
