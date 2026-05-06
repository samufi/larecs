from std.sys.intrinsics import _type_is_eq
from std.sys.defines import is_defined
from std.reflection import reflect
from std.collections.check_bounds import check_bounds
from std.memory import memcpy, UnsafePointer
from std.bit import next_power_of_two
from .entity import Entity
from .component import (
    ComponentType,
    constrain_components_unique,
    ComponentManager,
)
from .bitmask import BitMask
from .pool import EntityPool

comptime DEFAULT_CAPACITY = 32
"""Default capacity of an archetype."""

comptime MutableEntityAccessor = EntityAccessor[archetype_mutability=True, ...]
"""An entity accessor with mutable references to the components."""


struct EntityAccessor[
    archetype_mutability: Bool,
    //,
    archetype_origin: Origin[mut=archetype_mutability],
    *ComponentTypes: ComponentType,
](Movable):
    """Accessor for an Entity.

    Caution: use this only in the context it was created in.
    In particular, do not store it anywhere.

    Parameters:
        archetype_mutability: Whether the reference to the list is mutable.
        archetype_origin: The lifetime of the List.
        ComponentTypes: The types of the components.
    """

    comptime Archetype = Archetype[
        *Self.ComponentTypes,
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
        #comptime assert Self.component_manager._ContainsComponent[
            #T
        #], "Component type not in component manager"
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
        # comptime assert Self.component_manager._ContainsComponents[
        #     *Ts
        # ], "All component types must be contained in the component manager."

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
        # comptime assert Self.component_manager._ContainsComponent[
        #     T
        # ], "Component type not in component manager"
        return self._archetype[].has_component[T]()

@fieldwise_init
struct MissingComponentsError[*Ts: ComponentType](Writable):
    def write_to(self, mut writer: Some[Writer]):
        comptime if len(Self.Ts) <= 1:
            writer.write("The component [")
            comptime for i in range(len(Self.Ts)):
                comptime T = Self.Ts[i]
                writer.write(reflect[T]().name())
            writer.write("] is missing.")
        else:
            writer.write("At least one of the components [")
            comptime for i in range(len(Self.Ts)):
                comptime T = Self.Ts[i]
                writer.write(reflect[T]().name(), ", ")
            writer.write("] is missing.")

comptime ComponentId = Int

struct _ComponentStorage[*ComponentTypes: ComponentType](Copyable, Movable, Sized, ImplicitlyDestructible):
    """
    Internal struct to store component data for an archetype.

    UnsafePointers to the component buffers are stored in a sparse tuple indexed by component ID (position in the ComponentTypes TypeList).
    Only pointers for active components (those contained in the archetype) are allocated and valid; the rest are dangling pointers that must not be dereferenced!

    Layout example for 3 component types where only components 0 and 2 are active:
    ```
    +========================+==================================+========================+
    |      Component 0       |      Component 1 (inactive)      |      Component 2       |
    +========================+==================================+========================+
    | alloc[Type0](capacity) | dangling pointer (not allocated) | alloc[Type2](capacity) |
    +------------------------+----------------------------------+------------------------+
    ```

    Parameters:
        ComponentTypes: The component types of the world.
    """

    comptime component_manager = ComponentManager[*Self.ComponentTypes]

    comptime ComponentPointer[T: ComponentType] = Optional[UnsafePointer[T, MutExternalOrigin]]

    comptime _PointerMapper[T: ComponentType]: ImplicitlyCopyable & RegisterPassable & Defaultable = Self.ComponentPointer[T]

    comptime _PointerTuple = Tuple[*Self.ComponentTypes.map[Self._PointerMapper]()]

    var capacity: Int
    """The capacity of the component storage, i.e. how many entities can be stored without reallocating."""
    var size: Int
    """The current size of the component storage, i.e. how many entities are currently stored."""
    var data: Self._PointerTuple
    """The component data, stored as typed pointers to component buffers."""

    var active_component_mask: BitMask
    """Ids of the active components in the archetype."""

    def __init__(out self, active_component_mask: BitMask, *, size: Int = 0, capacity: Int = DEFAULT_CAPACITY):
        self.data = Self._PointerTuple()
        self.capacity = capacity
        self.size = size
        self.active_component_mask = active_component_mask

        self.unsafe_init_components(active_component_mask)

    def __init__(out self, *, copy: Self):
        self.capacity = copy.capacity
        self.size = copy.size
        self.active_component_mask = copy.active_component_mask
        self.data = Self._PointerTuple()

        def copy_component_ptr[T: ComponentType, id: ComponentId](ptr: UnsafePointer[T, MutExternalOrigin]) capturing -> Self.ComponentPointer[T]:
            return rebind[Self.ComponentPointer[T]](copy.data[id])

        self._for_active_components[is_mutating=True, func=copy_component_ptr]()

    def __len__(self) -> Int:
        """
        Gets the current size (number of stored entities) of the component storage.

        Returns:
            The current size of the component storage.
        """
        return self.size

    def __del__(deinit self):
        def free_component_storage[T: ComponentType, id: ComponentId](ptr: UnsafePointer[T, MutExternalOrigin]) capturing:
                ptr.free()

        self._for_active_components[is_mutating=False, func=free_component_storage]()

    def copy_deep(self, out new_storage: Self):
        new_storage = Self(copy=self)

        def memcpy_component[T: ComponentType, id: ComponentId](ptr: UnsafePointer[T, MutExternalOrigin]) capturing -> Self.ComponentPointer[T]:
            new_ptr = alloc[T](self.capacity)
            memcpy(dest=new_ptr, src=ptr, count=self.capacity)
            return rebind[Self.ComponentPointer[T]](Optional(new_ptr))

        new_storage._for_active_components[is_mutating=True, func=memcpy_component]()

    def unsafe_init_components(
        mut self, read init_component_mask: BitMask
    ):
        """(Re)Initializes owned component storage while keeping the component layout intact.

        Important:
        This is intended for internal ownership-transfer flows where another archetype has
        taken over the old storage pointers and this archetype must regain valid, uniquely
        owned allocations before continuing.

        The component IDs themselves are not changed here; they are read from `self._ids`
        to determine which component buffers must be reallocated.

        Args:
            init_component_mask: A bit mask indicating which components should be initialized.
        """
        self.capacity = DEFAULT_CAPACITY

        def init_component_ptr[T: ComponentType, id: ComponentId](ptr: UnsafePointer[T, MutExternalOrigin]) capturing -> Self.ComponentPointer[T]:
            if init_component_mask.get(id):
                return rebind[Self.ComponentPointer[T]](Optional(alloc[T](self.capacity)))
            else:
                return rebind[Self.ComponentPointer[T]](Optional(ptr))

        self._for_active_components[is_mutating=True, func=init_component_ptr]()


    @always_inline
    def get_component_count(self) -> Int:
        """Returns the number of active components in the storage.

        Returns:
            The number of active component types.
        """
        return self.active_component_mask.total_bits_set()

    @always_inline
    def add_entity(mut self) -> Int:
        """Adds an entity to the storage (increments size, checks capacity).

        Returns:
            The index of the newly added entity.
        """
        if self.size == self.capacity:
            self.reserve(max(self.capacity * 2, 8))
        var idx = self.size
        self.size += 1
        return idx

    @always_inline
    def clear(mut self):
        """Removes all entities from the storage (resets size to 0).

        Note: does not free any memory.
        """
        self.size = 0

    def reserve(mut self, new_capacity: Int):
        """Extends the capacity of the storage to at least the specified number of entities.

        Uses a power-of-2 allocation strategy. The actual allocated capacity will be the next
        power of 2 greater than or equal to the requested capacity.

        Does nothing if the requested capacity is not larger than the current capacity.

        Args:
            new_capacity: The minimum required capacity. The actual allocated capacity
                         will be `next_power_of_two(new_capacity)` to maintain power-of-2 growth.
        """
        debug_assert(
            0 < new_capacity, "New capacity must be greater than zero."
        )

        if new_capacity <= self.capacity:
            return

        var new_pow2_capacity = next_power_of_two(new_capacity)

        def resize_component_storage[T: ComponentType, id: ComponentId](old_ptr: UnsafePointer[T, MutExternalOrigin]) capturing -> Self.ComponentPointer[T]:
            var new_ptr = alloc[T](new_pow2_capacity)
            memcpy(
                dest=new_ptr,
                src=old_ptr,
                count=self.capacity,
            )
            old_ptr.free()
            return rebind[Self.ComponentPointer[T]](Optional(new_ptr))

        self.capacity = new_pow2_capacity

    def reserve(mut self, *, add: Int):
        """
        Reserves additional capacity for at least `add` amount of entities.

        Args:
            add: The minimum number of additional entities to reserve capacity for.
        """

        debug_assert(0 <= add, "Amount of additional entities must be non-negative")

        self.reserve(self.size + add)

    def swap_remove_entity(mut self, remove_idx: Int) -> Bool:
        """Performs a swap-remove operation for entity at idx, moving last entity to idx.

        Swaps component data for all active components between idx and new_size (last entity).

        Args:
            remove_idx: The index of the entity to remove.

        Returns:
            Whether a swap was performed (i.e. idx was not the last entity).
        """
        check_bounds(remove_idx, self.size)

        self.size -= 1

        if remove_idx == self.size:
            return False


        def swap_component_data[T: ComponentType, id: ComponentId](ptr: UnsafePointer[T, MutExternalOrigin]) capturing:
            memcpy(
                dest=ptr + remove_idx,
                src=ptr + self.size,
                count=1,
            )

        self._for_active_components[is_mutating=False, func=swap_component_data]()

        return True

    def get_component_ptr[
        T: ComponentType,
    ](ref self) -> UnsafePointer[T, MutExternalOrigin]:
        """Returns the base pointer for the given component type.

        Parameters:
            T: The type of the component.

        Returns:
            The pointer to the component.
        """
        comptime assert Self.component_manager._ContainsComponent[
            T
        ], "Component type not in component manager"
        comptime id = Self.component_manager.get_id[T]()

        self.assert_has_component[T]()

        return rebind[Self.ComponentPointer[T]](self.data[id]).value()

    def has_component[
        T: ComponentType
    ](self) -> Bool:
        """Returns whether the storage contains the given component type.

        Parameters:
            T: The type of the component.

        Returns:
            Whether the storage contains the component type.
        """
        Self.component_manager.assert_valid_components[T]()
        comptime id = Self.component_manager.get_id[T]()
        return self.active_component_mask.get(id)

    def has_components[*Ts: ComponentType](self) -> Bool:
        """Returns whether the storage contains all the given component types."""
        Self.component_manager.assert_valid_components[*Ts]()
        comptime comp_mask = BitMask(Self.component_manager.get_id_arr[*Ts]())
        return self.active_component_mask.contains(comp_mask)

    def assert_has_component[
        T: ComponentType
    ](self):
        """Asserts if the storage does not contain the given component type.
            Is enabled by defining the ASSERT_COMPONENTS_EXIST flag at compile time.

        Parameters:
            T: The type of the component.

        """
        comptime if is_defined["ASSERT_COMPONENTS_EXIST"]():
            Self.component_manager.assert_valid_components[T]()

            assert self.has_component[T](), MissingComponentsError[T]()

    def set_component[
        T: ComponentType
    ](mut self, entity_idx: Int, var component: T):
        """Sets a typed component value.

        Parameters:
            T: The component type.

        Args:
            entity_idx: The entity row index.
            component: The component value to store.
        """
        self.get_component_ptr[T]()[entity_idx] = component^

    def assert_has_components[*Ts: ComponentType](self):
        """Raises if the storage does not contain all the given component types.
            Is enabled by defining the ASSERT_COMPONENTS_EXIST flag at compile time.

        Parameters:
            Ts: The types of the components to check.
        """
        comptime if is_defined["ASSERT_COMPONENTS_EXIST"]():
            Self.component_manager.assert_valid_components[*Ts]()

            assert self.has_components[*Ts](), MissingComponentsError[*Ts]()


    def set_components[*Ts: ComponentType](mut self, entity_idx: Int, var *components: *Ts):
        """Sets the component with the given Type T at the given index.

        Parameters:
            Ts: The types of the components to set. Constraints: Must be contained in the component manager and must be unique.

        Args:
            entity_idx: The index of the entity.
            components: The new values of the components.
        """
        comptime assert constrain_components_unique[
            *Ts
        ](), "Component types must be unique."
        check_bounds(entity_idx, self.size)

        Self.component_manager.assert_valid_components[*Ts]()
        self.assert_has_components[*Ts]()

        def set_component[comp_id: Int](var component: Ts[comp_id]) capturing:
            comptime T = Ts[comp_id]
            self.get_component_ptr[T]()[entity_idx] = component^

        (components^).consume_elements[set_component]()

    def set_component_from[T: ComponentType](mut self, to_idx: Int, storage: _ComponentStorage, count: Int, from_idx: Int = 0):
        """Sets the component with the given Type T for multiple consecutive entities starting with the given index.

        Parameters:
            T: The type of the component. Constraints: Must be contained in the component manager.

        Args:
            to_idx: The index of the first entity to set.
            storage: The storage to copy components from.
            count: The number of elements to set.
            from_idx: The index of the first entity in the storage to copy from.
        """
        check_bounds(to_idx, self.size)
        check_bounds(from_idx, storage.size)
        debug_assert(0 <= count, "Count must be non-negative.")
        check_bounds(to_idx + count - 1, self.size)
        check_bounds(from_idx + count - 1, storage.size)

        memcpy(
            dest=self.get_component_ptr[T]() + to_idx,
            src=storage.get_component_ptr[T]() + from_idx,
            count=count,
        )

    def _for_active_components[
        is_mutating: Bool,
        func: def [T: ComponentType, id: ComponentId](ptr: UnsafePointer[T, MutExternalOrigin]) capturing -> Self.ComponentPointer[T]
    ](mut self) where is_mutating:
        """Helper to iterate over active components and their pointers.

        Parameters:
            is_mutating: Whether the function mutates the component pointers. This determines whether the pointers passed to the function are mutable or not.
            func: A function that takes a component ID and the corresponding typed pointer, and performs some operation.
        """
        comptime for id in range(len(Self.ComponentTypes)):
            comptime T = Self.ComponentTypes[id]
            comp_ptr = rebind[Self.ComponentPointer[T]](self.data[id])
            if self.has_component[T]() and comp_ptr is not None:
                self.data[id] = rebind[Self._PointerTuple.element_types[id]](func[T,id](comp_ptr.value()))

    def _for_active_components[
        is_mutating: Bool,
        func: def [T: ComponentType, id: ComponentId](ptr: UnsafePointer[T, MutExternalOrigin]) capturing
    ](self) where not is_mutating:
        """Helper to iterate over active components and their pointers.

        Parameters:
            is_mutating: Whether the function mutates the component pointers. This determines whether the pointers passed to the function are mutable or not.
            func: A function that takes a component ID and the corresponding typed pointer, and performs some operation.
        """
        comptime for id in range(len(Self.ComponentTypes)):
            comptime T = Self.ComponentTypes[id]
            comp_ptr = rebind[Self.ComponentPointer[T]](self.data[id])
            if self.has_component[T]() and comp_ptr is not None:
                func[T,id](comp_ptr.value())



struct Archetype[
    *ComponentTypes: ComponentType,
](Boolable, Copyable, Movable, Sized):
    """
    Archetype represents an ECS archetype.

    Parameters:
        ComponentTypes: The component types of the archetype.
    """

    comptime Index = UInt32
    """The type of the index of entities."""

    comptime max_size = BitMask.total_bits
    """The maximal number of components in the archetype."""

    comptime EntityAccessor = EntityAccessor[
        _, *Self.ComponentTypes,
        #component_manager=Self.component_manager
    ]
    """The type of the entity accessors generated by the archetype."""

    var _storage: _ComponentStorage[*Self.ComponentTypes]
    """The component storage of the archetype."""

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
        self = Self.__init__(0, BitMask(), 0)

    @always_inline
    def __init__(
        out self, node_index: Int, mask: BitMask,
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
        debug_assert(
            0 <= capacity, "Capacity must be greater or equal to zero."
        )
        check_bounds(node_index, Self.max_size)

        self._mask = mask

        self._storage = _ComponentStorage[*Self.ComponentTypes](mask, capacity=capacity)

        self._entities = List[Entity]()
        self._node_index = node_index

    @always_inline
    def __init__[
        component_count: Int
    ](
        out self,
        node_index: Int,
        component_ids: InlineArray[ComponentId, component_count] = InlineArray[
            ComponentId, component_count
        ](fill=ComponentId(0)),
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

        self = Self(node_index, BitMask(component_ids), capacity)

    def __init__(out self, *, copy: Self):
        """Copies the data from an existing archetype to a new one.

        Args:
            copy: The archetype to copy from.
        """
        # Copy the attributes that can be trivially
        # copied via a simple assignment
        self._entities = copy._entities.copy()
        self._node_index = copy._node_index
        self._mask = copy._mask

        # Copy the data
        self._storage = copy._storage.copy_deep()

    @always_inline
    def __len__(self) -> Int:
        """Returns the number of entities in the archetype.

        Returns:
            The number of entities in the archetype.
        """
        return len(self._storage)

    @always_inline
    def __bool__(self) -> Bool:
        """Returns whether the archetype contains entities.

        Returns:
            Whether the archetype contains entities.
        """
        return Bool(self._entities)


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
        self.reserve(max(self._storage.capacity * 2, 8))

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
        self._storage.reserve(new_capacity)

    @always_inline
    def get_entity(self, idx: Int) -> ref[self._entities] Entity:
        """Returns the entity at the given index.

        Args:
            idx: The index of the entity.

        Returns:
            A reference to the entity at the given index.
        """
        check_bounds(idx, self._storage.size)
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
        check_bounds(idx, self._storage.size)

        accessor = Self.EntityAccessor(
            Pointer(to=self),
            idx,
        )

    # @always_inline
    # def unsafe_take_data_from_parts[](
    #     mut self,
    #     ids: InlineArray[Self.Id, Self.max_size],
    #     data: InlineArray[
    #         UnsafePointer[UInt8, MutExternalOrigin], Self.max_size
    #     ],
    #     item_sizes: InlineArray[Int, Self.max_size],
    #     component_count: Int,
    #     capacity: Int,
    # ):
    #     """Unsafely takes ownership of component storage described by raw archetype parts.

    #     This helper transfers pointer ownership into `self` without cloning the underlying
    #     component buffers. It is therefore only valid for internal handoff paths where the
    #     caller guarantees that the source storage will not remain managed by another
    #     archetype after this call. In practice, the source archetype must either be
    #     reinitialized immediately (by calling [.Archetype.unsafe_reinit_components]) or
    #     otherwise prevented from freeing or mutating the same pointers.

    #     Args:
    #         ids: The component IDs whose metadata and storage ownership are being taken.
    #         data: The component storage pointers to transfer into this archetype.
    #         item_sizes: The byte width for each component ID in `ids`.
    #         component_count: The number of valid component entries contained in `ids`,
    #             `data`, and `item_sizes`.
    #         capacity: The storage capacity that the transferred buffers were allocated for.
    #     """
    #     for i in range(self._storage.get_component_count()):
    #         var id = self._storage.active_component_ids[i]
    #         check_bounds(id, Self.max_size)
    #         var found = False
    #         for j in range(component_count):
    #             if ids[j] == id:
    #                 var old_ptr_untyped = self.data[id].bitcast[UInt8]()
    #                 if old_ptr_untyped != data[j]:
    #                     # Free old pointer if different
    #                     comptime for comp_id, T in enumerate(Self.ComponentTypes):
    #                         if comp_id == id:
    #                             old_ptr_untyped.bitcast[T]().free()
    #                 # Store new typed pointer
    #                 comptime for comp_id, T in enumerate(Self.ComponentTypes):
    #                     if comp_id == id:
    #                         self.data[comp_id] = data[j].bitcast[T]()
    #                 self.item_sizes[id] = item_sizes[j]
    #                 found = True
    #                 break

    #         if not found and self.capacity < capacity:
    #             # Reallocate if sizes don't match
    #             comptime for comp_id, T in enumerate(Self.ComponentTypes):
    #                 if comp_id == id:
    #                     var old_ptr = self.data[comp_id]
    #                     old_ptr.free()
    #                     var new_ptr = alloc[T](capacity)
    #                     self.data[comp_id] = new_ptr

    #     self.capacity = capacity

    @always_inline
    def get_component[
        T: ComponentType
    ](ref self, entity_idx: Int) -> ref[self] T:
        """Returns the component with the given Type T at the given index.

        Parameters:
            T: The type of the component. Constraints: Must be contained in the component manager.

        Args:
            entity_idx: The index of the entity.

        Returns:
            A reference to the component.
        """
        check_bounds(entity_idx, self._storage.size)

        return self._storage.get_component_ptr[T]()[entity_idx]

    @always_inline
    def set_component[
        T: ComponentType
    ](mut self, entity_idx: Int, var component: T):
        """Sets the component with the given Type T at the given index.

        Parameters:
            T: The type of the component. Constraints: Must be contained in the component manager.

        Args:
            entity_idx: The index of the entity.
            component: The new value of the component.
        """
        self._storage.set_component[T](entity_idx, component^)

    @always_inline
    def set_components[
        *Ts: ComponentType
    ](mut self, entity_idx: Int, var *components: *Ts):
        """Sets the component with the given Type T at the given index.

        Parameters:
            Ts: The types of the components to set. Constraints: Must be contained in the component manager and must be unique.

        Args:
            entity_idx: The index of the entity.
            components: The new values of the components.
        """
        self._storage.set_components[*Ts](entity_idx, *components^)
    
    def set_component_range[
        T: ComponentType
    ](mut self, start_entity_idx: Int, count: Int, value: T):
        """Fills the component with the given Type T for multiple consecutive entities starting with the given index.

        Parameters:
            T: The type of the component. Constraints: Must be contained in the component manager.

        Args:
            start_entity_idx: The index of the first entity to set.
            count: The number of elements to set.
            value: The value to fill the component with.
        """
        check_bounds(start_entity_idx, self._storage.size)
        debug_assert(0<=count, "Count must be non-negative.")
        check_bounds(start_entity_idx + count - 1, self._storage.size)

        var comp_ptr = self._storage.get_component_ptr[T]()
        Span(ptr=comp_ptr+start_entity_idx, length=count).fill(value)
    
    def set_component_from[
        T: ComponentType
    ](mut self, to_idx: Int, archetype: Archetype, count: Int, from_idx: Int = 0):
        """Sets the component with the given Type T for multiple consecutive entities starting with the given index.

        Parameters:
            T: The type of the component. Constraints: Must be contained in the component manager.

        Args:
            to_idx: The index of the first entity to set.
            archetype: The archetype to copy components from.
            count: The number of elements to set.
            from_idx: The index of the first entity in the archetype to copy from.
        """
        self._storage.set_component_from[T](to_idx, archetype._storage, count, from_idx)

    @always_inline
    def get_entities(self) -> ref[self._entities] List[Entity]:
        """Returns the entities in the archetype.

        Returns:
            A reference to the entities in the archetype.
        """
        return self._entities

    @always_inline
    def has_component[T: ComponentType](self) -> Bool:
        """Returns whether the archetype contains the given component id.

        Parameters:
            T: The type of the component. Constraints: Must be contained in the component manager of the storage.

        Returns:
            Whether the archetype contains the component.
        """
        return self._storage.has_component[T]()

    @always_inline
    def assert_has_component[T: ComponentType](self):
        """Raises if the archetype does not contain the given component id.

        Parameters:
            T: The type of the component. Constraints: Must be contained in the component manager of the storage.
        """
        self._storage.assert_has_component[T]()

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
        var swapped = self._storage.swap_remove_entity(idx)

        if swapped:
            self._entities[idx] = self._entities.pop()
        else:
            _ = self._entities.pop()

        return swapped

    @always_inline
    def clear(mut self):
        """Removes all entities from the archetype.

        Note: does not free any memory.
        """
        self._entities.clear()
        self._storage.clear()

    @always_inline
    def add(mut self, entity: Entity) -> Int:
        """Adds an entity to the archetype.

        Args:
            entity: The entity to add.

        Returns:
            The index of the entity in the archetype.
        """
        var idx = self._storage.add_entity()
        self._entities.append(entity)
        return idx

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
            return self._storage.size - 1

        start_index = self._storage.size

        self._storage.reserve(
            add=count
        )  # `reserve` handles calculating a good capacity to use
        self._entities.reserve(
            self._storage.capacity
        )  # use the capacity calculated by `reserve` for the entities list as well

        for _ in range(count):
            self._entities.append(entity_pool.get())

        return start_index
