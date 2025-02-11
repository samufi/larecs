from memory import UnsafePointer
from collections import Optional, InlineArray
from algorithm import vectorize

from .pool import EntityPool
from .entity import Entity, EntityIndex
from .archetype import Archetype as _Archetype, MutableEntityAccessor
from .graph import BitMaskGraph
from .bitmask import BitMask
from .debug_utils import debug_warn
from .component import (
    ComponentManager,
    ComponentType,
    constrain_components_unique,
)
from .bitmask import BitMask
from .query import Query, _EntityIterator
from .lock import LockMask, LockedContext
from .resource import ResourceContaining, Resources


@value
struct Replacer[
    mut: MutableOrigin,
    size: Int,
    *component_types: ComponentType,
    resources_type: ResourceContaining,
]:
    """
    Replacer is a helper struct for removing and adding components to an [..entity.Entity].

    It stores the components to remove and allows adding new components
    in one go.

    Parameters:
        mut: The mutability of the world.
        size: The number of components to remove.
        component_types: The types of the components.
        resources_type: The type of the resource container.
    """

    var _world: Pointer[
        World[*component_types, resources_type=resources_type], mut
    ]
    var _remove_ids: InlineArray[
        World[*component_types, resources_type=resources_type].Id, size
    ]

    fn by[
        *AddTs: ComponentType
    ](self, entity: Entity, *components: *AddTs) raises:
        """
        Removes and adds the components to an [..entity.Entity].

        Parameters:
            AddTs: The types of the components to add.

        Args:
            entity:         The entity to modify.
            components: The components to add.

        Raises:
            Error: when called for a removed (and potentially recycled) entity.
            Error: when called with components that can't be added because they are already present.
            Error: when called with components that can't be removed because they are not present.
            Error: when called on a locked world. Do not use during [.World.query] iteration.
        """
        self._world[]._remove_and_add[*AddTs](
            entity,
            components,
            self._remove_ids,
        )

    fn by[
        *AddTs: ComponentType
    ](self, *components: *AddTs, entity: Entity) raises:
        """
        Removes and adds the components to an [..entity.Entity].

        Parameters:
            AddTs: The types of the components to add.

        Args:
            components: The components to add.
            entity:     The entity to modify.

        Raises:
            Error: when called for a removed (and potentially recycled) entity.
            Error: when called with components that can't be added because they are already present.
            Error: when called with components that can't be removed because they are not present.
            Error: when called on a locked world. Do not use during [.World.query] iteration.
        """
        self._world[]._remove_and_add[*AddTs](
            entity,
            components,
            self._remove_ids,
        )


struct World[
    *component_types: ComponentType, resources_type: ResourceContaining
](Movable):
    """
    World is the central type holding entity and component data, as well as resources.

    The World provides all the basic ECS functionality of Larecs,
    like [.World.query], [.World.add_entity], [.World.add], [.World.remove], [.World.get] or [.World.remove_entity].
    """

    alias Id = BitMask.IndexType
    alias component_manager = ComponentManager[*component_types]()
    alias Archetype = _Archetype[
        *component_types, component_manager = Self.component_manager
    ]
    # _listener       Listener                  # EntityEvent _listener.
    # _node_pointers   []*archNode               # Helper list of all node pointers for queries.
    # _tarquery bitSet                    # Whether entities are potential relation targets. Used for archetype cleanup.
    # _relation_nodes  []*archNode               # Archetype nodes that have an entity relation.
    # _filter_cache    Cache                     # Cache for registered filters.
    # _nodes          pagedSlice[archNode]      # The archetype graph.
    # _archetype_data  pagedSlice[_archetype_data] # Storage for the actual archetype data (components).
    # _node_data       pagedSlice[_node_data]      # The archetype graph's data.
    # _stats          _stats.World               # Cached world statistics.
    var _entity_pool: EntityPool  # Pool for entities.
    var _entities: List[
        EntityIndex, hint_trivial_type=True
    ]  # Mapping from entities to archetype and index.
    var _archetype_map: BitMaskGraph[
        -1, hint_trivial_type=True
    ]  # Mapping from component masks to archetypes.
    var _locks: LockMask  # World _locks.

    var _archetypes: List[
        Self.Archetype
    ]  # Archetypes that have no relations components.

    var resources: resources_type  # The resources of the world.

    fn __init__(
        mut self,
        owned resources: resources_type = resources_type(),
    ) raises:
        """
        Creates a new [.World].
        """
        self._archetype_map = BitMaskGraph[-1, hint_trivial_type=True](0)
        self._archetypes = List[Self.Archetype](Self.Archetype())
        self._entities = List[EntityIndex, hint_trivial_type=True](
            EntityIndex(0, 0)
        )
        self._entity_pool = EntityPool()
        self._locks = LockMask()
        self.resources = resources^

        # TODO
        # var _tarquery = bitSet
        # _tarquery.ExtendTo(1)
        # self._tarquery = _tarquery

        # self._listener:       nil,
        # self._resources:      newResources(),
        # self._filter_cache:    newCache(),

        # var node = self.createArchetypeNode(Mask, ID, false)

    fn __moveinit__(mut self, owned other: Self):
        """
        Moves the contents of another [.World] into a new one.
        """
        self._archetype_map = other._archetype_map^
        self._archetypes = other._archetypes^
        self._entities = other._entities^
        self._entity_pool = other._entity_pool^
        self._locks = other._locks^
        self.resources = other.resources^

    fn copy(self, out other: Self):
        """
        Copies the contents of another [.World] into a new one.
        """
        other._archetype_map = self._archetype_map
        other._archetypes = self._archetypes
        other._entities = self._entities
        other._entity_pool = self._entity_pool
        other._locks = self._locks
        other.resources = self.resources

    @always_inline
    fn _get_archetype_index[
        size: Int
    ](mut self, components: InlineArray[Self.Id, size]) -> Int:
        """Returns the archetype list index of the archetype differing from
        the archetype at the start node by the given indices.

        If necessary, creates a new archetype.

        Args:
            components:       The components that distinguish the archetypes.

        Returns:
            The archetype list index of the archetype differing from the start
            archetype by the components at the given indices.
        """
        node_index = self._archetype_map.get_node_index(components, 0)
        if self._archetype_map.has_value(node_index):
            return self._archetype_map[node_index]

        archetype_index = len(self._archetypes)
        self._archetypes.append(
            Self.Archetype(
                node_index,
                self._archetype_map.get_node_mask(node_index),
                components,
            )
        )

        self._archetype_map[node_index] = archetype_index

        return archetype_index

    @always_inline
    fn _get_archetype_index[
        size: Int
    ](
        mut self,
        components: InlineArray[Self.Id, size],
        start_node_index: Int,
    ) -> Int:
        """Returns the archetype list index of the archetype
        with the given component indices.

        If necessary, creates a new archetype.

        Args:
            components:       The components that distinguish the archetypes.
            start_node_index: The index of the start archetype's node.

        Returns:
            The archetype list index of the archetype differing from the start
            archetype by the components at the given indices.
        """
        node_index = self._archetype_map.get_node_index(
            components, start_node_index
        )
        if self._archetype_map.has_value(node_index):
            return self._archetype_map[node_index]

        archetype_index = len(self._archetypes)
        self._archetypes.append(
            Self.Archetype(
                node_index,
                self._archetype_map.get_node_mask(node_index),
            )
        )

        self._archetype_map[node_index] = archetype_index

        return archetype_index

    @always_inline
    fn add_entity(mut self, out entity: Entity) raises:
        """Returns a new or recycled [..entity.Entity].

        Do not use during [.World.query] iteration!

        ⚠️ Important:
        Entities are intended to be stored and passed around via copy, not via pointers! See [..entity.Entity].

        Example:

        ```mojo {doctest="add_entity" global=true hide=true}
        from larecs import World, Resources
        ```

        ```mojo {doctest="add_entity"}
        world = World(Resources())
        e = world.add_entity()
        ```

        Returns:
            The new or recycled entity.

        Raises:
            Error: If the world is locked.
        """
        self._assert_unlocked()
        entity = self._create_entity(0)

    fn add_entity[
        *Ts: ComponentType
    ](mut self, *components: *Ts, out entity: Entity) raises:
        """Returns a new or recycled [..entity.Entity].

        The given component types are added to the entity.
        Do not use during [.World.query] iteration!

        ⚠️ Important:
        Entities are intended to be stored and passed around via copy, not via pointers! See [..entity.Entity].

        Example:

        ```mojo {doctest="add_entity_comps" global=true hide=true}
        from larecs import World, Resources

        @value
        struct Position:
            var x: Float64
            var y: Float64

        @value
        struct Velocity:
            var x: Float64
            var y: Float64
        ```

        ```mojo {doctest="add_entity_comps"}
        world = World[Position, Velocity](Resources())
        e = world.add_entity(
            Position(0, 0),
            Velocity(0.5, -0.5),
        )
        ```

        Parameters:
            Ts: The components to add to the entity.

        Args:
            components: The components to add to the entity.

        Raises:
            Error: If the world is [.World.is_locked locked].

        Returns:
            The new or recycled [..entity.Entity].

        """
        self._assert_unlocked()

        alias size = components.__len__()

        archetype_index = self._get_archetype_index(
            Self.component_manager.get_id_arr[*Ts]()
        )
        entity = self._create_entity(archetype_index)
        index_in_archetype = self._entities[entity.get_id()].index

        archetype = Pointer.address_of(self._archetypes[archetype_index])

        @parameter
        for i in range(size):
            archetype[].get_component[
                T = Ts[i.value], assert_has_component=False
            ](index_in_archetype) = components[i]

        # TODO
        # if self._listener != nil:
        #     var newRel *Id
        #     if arch.HasRelationComponent:
        #         newRel = &arch.RelationComponent

        #     var bits = subscription(true, false, len(comps) > 0, false, newRel != nil, newRel != nil)
        #     var trigger = self._listener.Subscriptions() & bits
        #     if trigger != 0 && subscribes(trigger, &arch.Mask, nil, self._listener.Components(), nil, newRel):
        #         self._listener.Notify(self, EntityEventEntity: entity, Added: arch.Mask, AddedIDs: comps, NewRelation: newRel, EventTypes: bits)

        return

    @always_inline
    fn _create_entity(mut self, archetype_index: Int, out entity: Entity):
        """
        Creates an Entity and adds it to the given archetype.
        """
        entity = self._entity_pool.get()
        idx = self._archetypes[archetype_index].add(entity)
        if entity.get_id() == len(self._entities):
            self._entities.append(EntityIndex(idx, archetype_index))
        else:
            self._entities[entity.get_id()] = EntityIndex(idx, archetype_index)

    @always_inline
    fn _create_entities[
        element_origin: MutableOrigin
    ](mut self, archetype_index: Int, count: Int):
        """
        Creates multiple Entities and adds them to the given archetype.
        """
        archetype = self._archetypes[archetype_index]
        arch_start_idx = archetype.extend(count, self._entity_pool)
        last_entity_id = archetype.get_entity(arch_start_idx + count).get_id()
        if last_entity_id > len(self._entities):
            self._entities.resize(
                index(last_entity_id), EntityIndex(0, archetype_index)
            )
        for i in range(arch_start_idx, arch_start_idx + count):
            entity_id = archetype.get_entity(i).get_id()
            self._entities[entity_id].archetype_index = archetype_index
            self._entities[entity_id].index = arch_start_idx + i

    fn remove_entity(mut self, entity: Entity) raises:
        """
        Removes an [..entity.Entity], making it eligible for recycling.

        Do not use during [.World.query] iteration!

        Args:
            entity: The entity to remove.

        Raises:
            Error: If the world is locked or the entity does not exist.
        """
        self._assert_unlocked()
        self._assert_alive(entity)

        idx = self._entities[entity.get_id()]
        old_archetype_index = idx.archetype_index
        old_archetype = Pointer.address_of(
            self._archetypes[old_archetype_index]
        )

        # if self._listener != nil:
        #     var oldRel *Id
        #     if old_archetype.HasRelationComponent:
        #         oldRel = &old_archetype.RelationComponent

        #     var oldIds []Id
        #     if len(old_archetype.node.Ids) > 0:
        #         oldIds = old_archetype.node.Ids

        #     var bits = subscription(false, true, false, len(oldIds) > 0, oldRel != nil, oldRel != nil)
        #     var trigger = self._listener.Subscriptions() & bits
        #     if trigger != 0 && subscribes(trigger, nil, &old_archetype.Mask, self._listener.Components(), oldRel, nil):
        #         var lock = self.lock()
        #         self._listener.Notify(self, EntityEventEntity: entity, Removed: old_archetype.Mask, RemovedIDs: oldIds, OldRelation: oldRel, OldTarget: old_archetype.RelationTarget, EventTypes: bits)
        #         self.unlock(lock)

        swapped = old_archetype[].remove(idx.index)

        self._entity_pool.recycle(entity)

        if swapped:
            swap_entity = old_archetype[].get_entity(idx.index)
            self._entities[swap_entity.get_id()].index = idx.index

    @always_inline
    fn is_alive(self, entity: Entity) -> Bool:
        """
        Reports whether an [..entity.Entity] is still alive.

        Args:
            entity: The entity to check.
        """
        return self._entity_pool.is_alive(entity)

    @always_inline
    fn has[T: ComponentType](self, entity: Entity) raises -> Bool:
        """
        Returns whether an [..entity.Entity] has a given component.

        Parameters:
            T: The type of the component.

        Args:
            entity: The entity to check.

        Raises:
            Error: If the entity does not exist.
        """
        self._assert_alive(entity)
        return self._archetypes[
            self._entities[entity.get_id()].archetype_index
        ].has_component(Self.component_manager.get_id[T]())

    fn get[
        T: ComponentType
    ](mut self, entity: Entity) raises -> ref [self._archetypes[0]._data] T:
        """Returns a reference to the given component of an [..entity.Entity].

        Parameters:
            T: The type of the component.

        Raises:
            Error: If the entity is not alive or does not have the component.
        """
        entity_index = self._entities[entity.get_id()]
        self._assert_alive(entity)

        return self._archetypes[entity_index.archetype_index].get_component[
            T=T
        ](entity_index.index)

    @always_inline
    fn get_ptr[
        T: ComponentType
    ](mut self, entity: Entity) raises -> Pointer[
        T, __origin_of(self._archetypes[0]._data)
    ]:
        """Returns a pointer to the given component of the [..entity.Entity].

        Parameters:
            T: The type of the component.

        Args:
            entity: The entity to get the component from.

        Raises:
            Error: If the entity is not alive or does not have the component.
        """
        entity_index = self._entities[entity.get_id()]
        self._assert_alive(entity)
        return self._archetypes[entity_index.archetype_index].get_component_ptr[
            T=T
        ](entity_index.index)

    fn set[
        T: ComponentType
    ](mut self, entity: Entity, owned component: T) raises:
        """
        Overwrites a component for an [..entity.Entity], using the given content.

        Parameters:
            T:         The type of the component.

        Args:
            entity:    The entity to modify.
            component: The new component.

        Raises:
            Error: If the [..entity.Entity] does not exist.
        """
        self._assert_alive(entity)
        entity_index = self._entities[entity.get_id()]
        self._archetypes[entity_index.archetype_index].get_component[T=T](
            entity_index.index
        ) = (component^)

    fn set[
        *Ts: ComponentType
    ](mut self, entity: Entity, owned *components: *Ts) raises:
        """
        Overwrites a component for an [..entity.Entity], using the given content.

        Parameters:
            Ts:        The types of the components.

        Args:
            entity:    The entity to modify.
            components: The new components.

        Raises:
            Error: If the entity does not exist or does not have the component.
        """
        constrain_components_unique[*Ts]()

        self._assert_alive(entity)
        entity_index = self._entities[entity.get_id()]
        archetype = Pointer.address_of(
            self._archetypes[entity_index.archetype_index]
        )

        @parameter
        for i in range(components.__len__()):
            archetype[].get_component[T = Ts[i.value]](
                entity_index.index
            ) = components[i]

    fn add[
        *Ts: ComponentType
    ](mut self, entity: Entity, *add_components: *Ts) raises:
        """
        Adds components to an [..entity.Entity].

        Parameters:
            Ts: The types of the components to add.

        Args:
            entity:         The entity to modify.
            add_components: The components to add.

        Raises:
            Error: when called for a removed (and potentially recycled) entity.
            Error: when called with components that can't be added because they are already present.
            Error: when called on a locked world. Do not use during [.World.query] iteration.
        """
        self._remove_and_add(entity, add_components)

    fn add[
        *Ts: ComponentType
    ](mut self, *add_components: *Ts, entity: Entity) raises:
        """
        Adds components to an [..entity.Entity].

        Parameters:
            Ts: The types of the components to add.

        Args:
            add_components: The components to add.
            entity:         The entity to modify.

        Raises:
            Error: when called for a removed (and potentially recycled) entity.
            Error: when called with components that can't be added because they are already present.
            Error: when called on a locked world. Do not use during [.World.query] iteration.
        """
        self._remove_and_add(entity, add_components)

    fn remove[*Ts: ComponentType](mut self, entity: Entity) raises:
        """
        Removes components from an [..entity.Entity].

        Parameters:
            Ts: The types of the components to remove.

        Args:
            entity: The entity to modify.

        Raises:
            Error: when called for a removed (and potentially recycled) entity.
            Error: when called with components that can't be removed because they are not present.
            Error: when called on a locked world. Do not use during [.World.query] iteration.
        """
        self._remove_and_add(
            entity, remove_ids=Self.component_manager.get_id_arr[*Ts]()
        )

    @always_inline
    fn replace[
        *Ts: ComponentType
    ](mut self) -> Replacer[
        __origin_of(self),
        VariadicPack[MutableAnyOrigin, ComponentType, *Ts].__len__(),
        *component_types,
        resources_type=resources_type,
    ]:
        """
        Returns a [.Replacer] for removing and adding components to an Entity in one go.

        Use as `world.replace[Comp1, Comp2]().by(comp3, comp4, comp5, entity=entity)`.

        The number of removed components does not need to match the number of added components.

        Parameters:
            Ts: The types of the components to remove.
        """
        return Replacer[
            __origin_of(self),
            VariadicPack[MutableAnyOrigin, ComponentType, *Ts].__len__(),
            *component_types,
        ](
            Pointer.address_of(self),
            Self.component_manager.get_id_arr[*Ts](),
        )

    @always_inline
    fn _remove_and_add[
        *Ts: ComponentType, rem_size: Int = 0
    ](
        mut self,
        entity: Entity,
        *add_components: *Ts,
        remove_ids: Optional[InlineArray[Self.Id, rem_size]] = None,
    ) raises:
        """
        Adds and removes components to an [..entity.Entity].

        Parameters:
            Ts:       The types of the components to add.
            rem_size: The number of components to remove.

        Args:
            entity:         The entity to modify.
            add_components: The components to add.
            remove_ids:     The IDs of the components to remove.

        Raises:
            Error: when called for a removed (and potentially recycled) entity.
            Error: when called with components that can't be added because they are already present.
            Error: when called with components that can't be removed because they are not present.
            Error: when called on a locked world. Do not use during [.World.query] iteration.
        """
        self._remove_and_add(entity, add_components, remove_ids)

    @always_inline
    fn _remove_and_add[
        *Ts: ComponentType, rem_size: Int = 0
    ](
        mut self,
        entity: Entity,
        add_components: VariadicPack[_, ComponentType, *Ts],
        remove_ids: Optional[InlineArray[Self.Id, rem_size]] = None,
    ) raises:
        """
        Adds and removes components to an [..entity.Entity].

        See documentation of overloaded function for details.
        """
        alias add_size = add_components.__len__()

        self._assert_unlocked()
        self._assert_alive(entity)

        @parameter
        if not add_size and not rem_size:
            return

        idx = self._entities[entity.get_id()]

        old_archetype_index = idx.archetype_index
        old_archetype = Pointer.address_of(
            self._archetypes[old_archetype_index]
        )

        index_in_old_archetype = idx.index

        var component_ids: Optional[InlineArray[Self.Id, add_size]] = None

        @parameter
        if add_size:
            component_ids = Optional[InlineArray[Self.Id, add_size]](
                Self.component_manager.get_id_arr[*Ts]()
            )

        start_node_index = old_archetype[].get_node_index()

        var archetype_index: Int = -1
        compare_mask = old_archetype[].get_mask()

        alias add_error_msg = "Entity already has one of the components to add."
        alias remove_error_msg = "Entity does not have one of the components to remove."

        @parameter
        if rem_size:

            @parameter
            if add_size:
                start_node_index = self._archetype_map.get_node_index(
                    remove_ids.value(), start_node_index
                )
                if not compare_mask.contains(
                    self._archetype_map.get_node_mask(start_node_index)
                ):
                    raise Error(remove_error_msg)

                compare_mask = self._archetype_map.get_node_mask(
                    start_node_index
                )
            else:
                archetype_index = self._get_archetype_index(
                    remove_ids.value(), start_node_index
                )

        @parameter
        if add_size:
            archetype_index = self._get_archetype_index(
                component_ids.value(), start_node_index
            )

        archetype = Pointer.address_of(self._archetypes[archetype_index])
        index_in_archetype = archetype[].add(entity)

        @parameter
        if add_size:
            if not archetype[].get_mask().contains(compare_mask):
                raise Error(add_error_msg)
        else:
            if not compare_mask.contains(archetype[].get_mask()):
                raise Error(remove_error_msg)

        for i in range(old_archetype[]._component_count):
            id = old_archetype[]._ids[i]

            @parameter
            if rem_size:
                if not archetype[].has_component(id):
                    continue

            archetype[].unsafe_set(
                index_in_archetype,
                id,
                old_archetype[]._get_component_ptr(
                    index(index_in_old_archetype), id
                ),
            )

        @parameter
        for i in range(add_size):
            archetype[].unsafe_set(
                index_in_archetype,
                component_ids.value()[i],
                UnsafePointer.address_of(add_components[i]).bitcast[UInt8](),
            )

        swapped = old_archetype[].remove(index_in_old_archetype)
        if swapped:
            var swapEntity = old_archetype[].get_entity(idx.index)
            self._entities[swapEntity.get_id()].index = idx.index

        self._entities[entity.get_id()] = EntityIndex(
            index_in_archetype, archetype_index
        )

    @always_inline
    fn _assert_unlocked(self) raises:
        """
        Checks if the world is locked, and raises if so.

        Raises:
            Error: If the world is locked.
        """
        if self.is_locked():
            raise Error("Attempt to modify a locked world.")

    @always_inline
    fn _assert_alive(self, entity: Entity) raises:
        """
        Checks if the entity is alive, and raises if not.

        Args:
            entity: The entity to check.

        Raises:
            Error: If the entity does not exist.
        """
        if not self._entity_pool.is_alive(entity):
            raise Error("The considered entity does not exist anymore.")

    @always_inline
    fn apply[
        operation: fn (accessor: MutableEntityAccessor) capturing -> None,
        *Ts: ComponentType,
        unroll_factor: Int = 1,
    ](mut self) raises:
        """
        Applies an operation to all entities with the given components.

        Parameters:
            operation: The operation to apply.
            Ts:        The types of the components.
            unroll_factor: The unroll factor for the operation
                (see [vectorize doc](https://docs.modular.com/mojo/stdlib/algorithm/functional/vectorize)).

        Raises:
            Error: If the world is locked.
        """

        @always_inline
        @parameter
        fn operation_wrapper[simd_width: Int](accessor: MutableEntityAccessor):
            operation(accessor)

        self.apply[operation_wrapper, *Ts, unroll_factor=unroll_factor]()

    fn apply[
        operation: fn[simd_width: Int] (
            accessor: MutableEntityAccessor
        ) capturing -> None,
        *Ts: ComponentType,
        simd_width: Int = 1,
        unroll_factor: Int = 1,
    ](mut self) raises:
        """
        Applies an operation to all entities with the given components.

        The operation is applied to chunks of `simd_width` entities,
        unless not enough are available anymore. Then the chunk size
        `simd_width` is reduced.

        Uses [`vectorize`](https://docs.modular.com/mojo/stdlib/algorithm/functional/vectorize/) internally.
        Have a look there to see a more detailed explanation of the parameters
        `simd_width` and `unroll_factor`.

        Caution! If `simd_width` is greater than 1, the operation **must**
        apply to the `simd_width` elements after the element passed to
        `operation`, assuming that each component is stored in contiguous
        memory. This may require knowledge of the memory layout
        of the components!


        Example:
        ```mojo {doctest="apply" global=true hide=true}
        from larecs import World, Resources, MutableEntityAccessor
        ```

        ```mojo {doctest="apply"}
        from sys.info import simdwidthof
        from memory import UnsafePointer

        world = World[Float64](Resources())
        e = world.add_entity()

        fn operation[simd_width: Int](accessor: MutableEntityAccessor) capturing:
            # Define the operation to apply here.
            # Note that due to the immature
            # capturing system of Mojo, the world may be
            # accessible by copy capturing here, even
            # though it is not copyable.
            # Do NOT change `world` from inside the operation,
            # as it will not be reflected in the world
            # or may cause a segmentation fault.

            # Get the component
            try:
                component = accessor.get_ptr[Float64]()
            except:
                return

            # Get an unsafe pointer to the memory
            # location of the component
            ptr = UnsafePointer.address_of(component[])

            # Load a SIMD of size `simd_width`
            # Note that a strided load is needed if the component as more than one field.
            val = ptr.load[width=simd_width]()

            # Do an operation on the SIMD
            val += 1

            # Store the SIMD at the same address
            ptr.store(val)

        world.apply[operation, Float64, simd_width=simdwidthof[Float64]()]()
        ```

        Parameters:
            operation: The operation to apply.
            Ts:        The types of the components.
            simd_width: The SIMD width for the operation
                (see [vectorize doc](https://docs.modular.com/mojo/stdlib/algorithm/functional/vectorize)).
            unroll_factor: The unroll factor for the operation
                (see [vectorize doc](https://docs.modular.com/mojo/stdlib/algorithm/functional/vectorize)).

        Constraints:
            The simd_width must be a power of 2.

        Raises:
            Error: If the world is locked.
        """
        self._assert_unlocked()

        with self._locked():
            mask = BitMask(Self.component_manager.get_id_arr[*Ts]())

            for archetype in self._archetypes:
                if archetype[].get_mask().contains(mask):

                    @always_inline
                    @parameter
                    fn closure[simd_width: Int](i: Int) capturing:
                        accessor = archetype[].get_entity_accessor(i)
                        operation[simd_width](accessor)

                    vectorize[closure, simd_width, unroll_factor=unroll_factor](
                        len(archetype[])
                    )

    # fn Reset(self):
    #     """
    #     Reset removes all _entities and _resources from the world.

    #     Does NOT free reserved memory, remove _archetypes, clear the _registry, clear cached filters, etc.
    #     However, it removes _archetypes with a relation component that is not zero.

    #     Can be used to run systematic simulations without the need to re-allocate memory for each run.
    #     Accelerates re-populating the world by a factor of 2-3.
    #     """
    #     self._assert_unlocked()

    #     self._entities = self._entities[:1]
    #     self._tarquery.Reset()
    #     self._entity_pool.Reset()
    #     self._locks.Reset()
    #     self._resources.reset()

    #     var len = self._nodes.Len()
    #     var i: int32
    #     for i = 0 in range(i < len, i++):
    #         self._nodes.get(i).Reset(self.Cache())

    # fn Query(self, filter: Filter) -> Query:
    #     """
    #     Query creates a [Query] iterator.

    #     Locks the world to prevent changes to component compositions.
    #     The lock is released automatically when the query finishes iteration, or when [Query.Close] is called.
    #     The number of simultaneous _locks (and thus open queries) at a given time is limited to [MaskTotalBits] (256).

    #     A query can iterate through its _entities only once, and can't be used anymore afterwards.

    #     To create a [Filter] for querying, see [All], [Mask.Without], [Mask.Exclusive] and [RelationFilter].

    #     For type-safe generics queries, see package [github.com/mlange-42/arche/generic].
    #     For advanced filtering, see package [github.com/mlange-42/arche/filter].
    #     """
    #     var l = self.lock()
    #     if cached, var ok = filter.(*CachedFilter); ok:
    #         return newCachedQuery(self, cached.filter, l, self._filter_cache.get(cached).Archetypes.pointers)

    #     return newQuery(self, filter, l, self._node_pointers)

    # fn Resources(self):
    #     """
    #     Resources of the world.

    #     Resources are component-like data that is not associated to an entity, but unique to the world.
    #     """
    #     return &self._resources

    # fn Cache(self):
    #     """
    #     Cache returns the [Cache] of the world, for registering filters.

    #     See [Cache] for details on filter caching.
    #     """
    #     if self._filter_cache.getArchetypes == nil:
    #         self._filter_cache.getArchetypes = self.getArchetypes

    #     return &self._filter_cache

    # fn Batch(self):
    #     """
    #     Batch creates a [Batch] processing helper.
    #     It provides the functionality to manipulate large numbers of _entities in batches,
    #     which is more efficient than handling them one by one.
    #     """
    #     return &Batchw

    @always_inline
    fn query(
        mut self,
        out iterator: Query[
            __origin_of(self),
            *component_types,
            resources_type=resources_type,
            component_manager = Self.component_manager,
        ],
    ) raises:
        """
        Returns an iterator with accessors to all [..entity.Entity Entities] without components.

        Returns:
            An iterator with accessors to all entities without components.

        Raises:
            Error: If the world is [.World.is_locked locked].
        """
        iterator = Query[
            __origin_of(self),
            *component_types,
            resources_type=resources_type,
            component_manager = Self.component_manager,
        ](
            Pointer.address_of(self),
            BitMask(),
        )

    @always_inline
    fn query[
        *Ts: ComponentType
    ](
        mut self,
        out iterator: Query[
            __origin_of(self),
            *component_types,
            resources_type=resources_type,
            component_manager = Self.component_manager,
        ],
    ) raises:
        """
        Returns an iterator with accessors to all [..entity.Entity Entities] with the given components.

        Parameters:
            Ts: The types of the components.

        Returns:
            An iterator with accessors to all entities with the given components.

        Raises:
            Error: If the world is [.World.is_locked locked].
        """
        iterator = Query[
            __origin_of(self),
            *component_types,
            resources_type=resources_type,
            component_manager = Self.component_manager,
        ](
            Pointer.address_of(self),
            BitMask(Self.component_manager.get_id_arr[*Ts]()),
        )

    fn _get_iterator[
        has_without_mask: Bool
    ](
        mut self,
        mask: BitMask,
        without_mask: Optional[BitMask],
        out iterator: _EntityIterator[
            __origin_of(self._archetypes),
            __origin_of(self._locks),
            *component_types,
            component_manager = Self.component_manager,
            has_without_mask=has_without_mask,
        ],
    ) raises:
        iterator = _EntityIterator[
            __origin_of(self._archetypes),
            __origin_of(self._locks),
            *component_types,
            component_manager = Self.component_manager,
            has_without_mask=has_without_mask,
        ](
            Pointer.address_of(self._archetypes),
            Pointer.address_of(self._locks),
            mask,
            without_mask,
        )

    @always_inline
    fn is_locked(self) -> Bool:
        """
        Returns whether the world is locked by any [.World.query queries].
        """
        return self._locks.is_locked()

    @always_inline
    fn _lock(mut self) raises -> UInt8:
        """
        Locks the world and gets the lock bit for later unlocking.
        """
        return self._locks.lock()

    @always_inline
    fn _unlock(mut self, lock: UInt8) raises:
        """
        Unlocks the given lock bit.
        """
        self._locks.unlock(lock)

    @always_inline
    fn _locked(mut self) -> LockedContext[__origin_of(self._locks)]:
        """
        Returns a context manager that unlocks the world when it goes out of scope.

        Returns:
            A context manager that unlocks the world when it goes out of scope.
        """
        return self._locks.locked()

    # fn Mask(self, entity: Entity) -> Mask:
    #     """
    #     Mask returns the archetype [Mask] for the given [Entity].
    #     """
    #     if !self._entity_pool.Alive(entity):
    #         panic("can't get mask for a dead entity")

    #     return self._entities[entity.id].arch.Mask

    # fn Ids(self, entity: Entity):
    #     """
    #     Ids returns the component IDs for the archetype of the given [Entity].

    #     Returns a copy of the archetype's component IDs slice, for safety.
    #     This means that the result can be manipulated safely,
    #     but also that calling the method may incur some significant cost.
    #     """
    #     if !self._entity_pool.Alive(entity):
    #         panic("can't get component IDs for a dead entity")

    #     return append([]Id, self._entities[entity.id].arch.node.Ids...)

    # fn SetListener(self, _listener: Listener):
    #     """
    #     SetListener sets a [Listener] for the world.
    #     The _listener is immediately called on every [ecs.Entity] change.
    #     Replaces the current _listener. Call with nil to remove a _listener.

    #     For details, see [EntityEvent], [Listener] and sub-package [event].
    #     """
    #     self._listener = _listener

    # fn Stats(self):
    #     """
    #     Stats reports statistics for inspecting the World.

    #     The underlying [_stats.World] object is re-used and updated between calls.
    #     The returned pointer should thus not be stored for later analysis.
    #     Rather, the required data should be extracted immediately.
    #     """
    #     self._stats.Entities = _stats.Entities
    #         Used:     self._entity_pool.Len(),
    #         Total:    self._entity_pool.Cap(),
    #         Recycled: self._entity_pool.Available(),
    #         Capacity: self._entity_pool.TotalCap(),

    #     var compCount = len(self._registry.Components)
    #     var types = append([]reflect.Type, self._registry.Types[:compCount]...)

    #     var memory = cap(self._entities)*int(entityIndexSize) + self._entity_pool.TotalCap()*int(entitySize)

    #     var cntOld = int32(len(self._stats.Nodes))
    #     var cntNew = int32(self._nodes.Len())
    #     var cntActive = 0
    #     var i: int32
    #     for i = 0 in range(i < cntOld, i++):
    #         var node = self._nodes.get(i)
    #         var nodeStats = &self._stats.Nodes[i]
    #         node.UpdateStats(nodeStats, &self._registry)
    #         if node.IsActive:
    #             memory += nodeStats.Memory
    #             cntActive++

    #     for i = cntOld in range(i < cntNew, i++):
    #         var node = self._nodes.get(i)
    #         self._stats.Nodes = append(self._stats.Nodes, node.Stats(&self._registry))
    #         if node.IsActive:
    #             memory += self._stats.Nodes[i].Memory
    #             cntActive++

    #     self._stats.ComponentCount = compCount
    #     self._stats.ComponentTypes = types
    #     self._stats.Locked = self.is_locked()
    #     self._stats.Memory = memory
    #     self._stats.CachedFilters = len(self._filter_cache.filters)
    #     self._stats.ActiveNodeCount = cntActive

    #     return &self._stats

    # fn DumpEntities(self) -> EntityDump:
    #     """
    #     DumpEntities dumps entity information into an [EntityDump] object.
    #     This dump can be used with [World.LoadEntities] to set the World's entity state.

    #     For world serialization with components and _resources, see module [github.com/mlange-42/arche-serde].
    #     """
    #     var alive = []uint32

    #     var query = self.Query(All())
    #     for query.Next()
    #         alive = append(alive, uint32(query.Entity().id))

    #     var data = EntityDump
    #         Entities:  append([]Entity, self._entity_pool._entities...),
    #         Alive:     alive,
    #         Next:      uint32(self._entity_pool.next),
    #         Available: self._entity_pool.available,

    #     return data

    # fn LoadEntities(self, data: *EntityDump):
    #     """
    #     LoadEntities resets all _entities to the state saved with [World.DumpEntities].

    #     Use this only on an empty world! Can be used after [World.Reset].

    #     The resulting world will have the same _entities (in terms of Id, generation and alive state)
    #     as the original world. This is necessary for proper serialization of entity relations.
    #     However, the _entities will not have any components.

    #     Panics if the world has any dead or alive _entities.

    #     For world serialization with components and _resources, see module [github.com/mlange-42/arche-serde].
    #     """
    #     self._assert_unlocked()

    #     if len(self._entity_pool._entities) > 1 || self._entity_pool.available > 0:
    #         panic("can set entity data only on a fresh or reset world")

    #     var capacity = capacity(len(data.Entities), self.config.CapacityIncrement)

    #     var _entities = make([]Entity, 0, capacity)
    #     _entities = append(_entities, data.Entities...)

    #     self._entity_pool._entities = _entities
    #     self._entity_pool.next = eid(data.Next)
    #     self._entity_pool.available = data.Available

    #     self._entities = make([]entityIndex, len(data.Entities), capacity)
    #     self._tarquery = bitSet
    #     self._tarquery.ExtendTo(capacity)

    #     var arch = self._archetypes.get(0)
    #     for _, idx in enumerate(data.Alive):
    #         var entity = self._entity_pool._entities[idx]
    #         var archIdx = arch.Alloc(entity)
    #         self._entities[entity.id] = entityIndexarch: arch, index: archIdx

    # ----------------- from world_internal.go -----------------

    # fn newEntities(self, count: int, targetID: ID, hasTarget: Bool, target: Entity, comps: ...ID):
    #     """
    #     Creates new _entities without returning a query over them.
    #     Used via [World.Batch].
    #     """
    #     arch, var startIdx = self.newEntitiesNoNotify(count, targetID, hasTarget, target, comps...)

    #     if self._listener != nil:
    #         var newRel *ID
    #         if arch.HasRelationComponent:
    #             newRel = &arch.RelationComponent

    #         var bits = subscription(true, false, len(comps) > 0, false, newRel != nil, newRel != nil)
    #         var trigger = self._listener.Subscriptions() & bits
    #         if trigger != 0 && subscribes(trigger, &arch.Mask, nil, self._listener.Components(), nil, newRel):
    #             var cnt = uint32(count)
    #             var i: uint32
    #             for i = 0 in range(i < cnt, i++):
    #                 var idx = startIdx + i
    #                 var entity = arch.GetEntity(idx)
    #                 self._listener.Notify(self, EntityEventEntity: entity, Added: arch.Mask, AddedIDs: comps, NewRelation: newRel, EventTypes: bits)

    #     return arch, startIdx

    # fn newEntitiesQuery(self, count: int, targetID: ID, hasTarget: Bool, target: Entity, comps: ...ID) -> Query:
    #     """
    #     Creates new _entities and returns a query over them.
    #     Used via [World.Batch].
    #     """
    #     arch, var startIdx = self.newEntitiesNoNotify(count, targetID, hasTarget, target, comps...)
    #     var lock = self.lock()

    #     var batches = batchArchetypes
    #         Added:   arch.Components(),
    #         Removed: nil,

    #     batches.Add(arch, nil, startIdx, arch.Len())
    #     return newBatchQuery(self, lock, &batches)

    # fn newEntitiesWith(self, count: int, targetID: ID, hasTarget: Bool, target: Entity, comps: ...Component):
    #     """
    #     Creates new _entities with component values without returning a query over them.
    #     Used via [World.Batch].
    #     """
    #     var ids = make([]ID, len(comps))
    #     for i, c in enumerate(comps):
    #         ids[i] = c.ID

    #     arch, var startIdx = self.newEntitiesWithNoNotify(count, targetID, hasTarget, target, ids, comps...)

    #     if self._listener != nil:
    #         var newRel *ID
    #         if arch.HasRelationComponent:
    #             newRel = &arch.RelationComponent

    #         var bits = subscription(true, false, len(comps) > 0, false, newRel != nil, newRel != nil)
    #         var trigger = self._listener.Subscriptions() & bits
    #         if trigger != 0 && subscribes(trigger, &arch.Mask, nil, self._listener.Components(), nil, newRel):
    #             var i: uint32
    #             var cnt = uint32(count)
    #             for i = 0 in range(i < cnt, i++):
    #                 var idx = startIdx + i
    #                 var entity = arch.GetEntity(idx)
    #                 self._listener.Notify(self, EntityEventEntity: entity, Added: arch.Mask, AddedIDs: ids, NewRelation: newRel, EventTypes: bits)

    #     return arch, startIdx

    # fn newEntitiesWithQuery(self, count: int, targetID: ID, hasTarget: Bool, target: Entity, comps: ...Component) -> Query:
    #     """
    #     Creates new _entities with component values and returns a query over them.
    #     Used via [World.Batch].
    #     """
    #     var ids = make([]ID, len(comps))
    #     for i, c in enumerate(comps):
    #         ids[i] = c.ID

    #     arch, var startIdx = self.newEntitiesWithNoNotify(count, targetID, hasTarget, target, ids, comps...)
    #     var lock = self.lock()
    #     var batches = batchArchetypes
    #         Added:   arch.Components(),
    #         Removed: nil,

    #     batches.Add(arch, nil, startIdx, arch.Len())
    #     return newBatchQuery(self, lock, &batches)

    # fn newEntitiesNoNotify(self, count: int, targetID: ID, hasTarget: Bool, target: Entity, comps: ...ID):
    #     """
    #     Internal method to create new _entities.
    #     """
    #     self.checkLocked()

    #     if count < 1:
    #         panic("can only create a positive number of _entities")

    #     if !target.IsZero() && !self.entityPool.Alive(target):
    #         panic("can't make a dead entity a relation target")

    #     var arch = self._archetypes.Get(0)
    #     if len(comps) > 0:
    #         arch = self._find_or_create_archetype(arch, comps, nil, target)

    #     if hasTarget:
    #         self.checkRelation(arch, targetID)
    #         if !target.IsZero():
    #             self._tarquery.Set(target.id, true)

    #     var startIdx = arch.Len()
    #     self.createEntities(arch, uint32(count))

    #     return arch, startIdx

    # fn newEntitiesWithNoNotify(self, count: int, targetID: ID, hasTarget: Bool, target: Entity, ids: []ID, comps: ...Component):
    #     """
    #     Internal method to create new _entities with component values.
    #     """
    #     self.checkLocked()

    #     if count < 1:
    #         panic("can only create a positive number of _entities")

    #     if !target.IsZero() && !self.entityPool.Alive(target):
    #         panic("can't make a dead entity a relation target")

    #     if len(comps) == 0:
    #         return self.newEntitiesNoNotify(count, targetID, hasTarget, target)

    #     var cnt = uint32(count)

    #     var arch = self._archetypes.Get(0)
    #     if len(comps) > 0:
    #         arch = self._find_or_create_archetype(arch, ids, nil, target)

    #     if hasTarget:
    #         self.checkRelation(arch, targetID)
    #         if !target.IsZero():
    #             self._tarquery.Set(target.id, true)

    #     var startIdx = arch.Len()
    #     self.createEntities(arch, uint32(count))

    #     var i: uint32
    #     for i = 0 in range(i < cnt, i++):
    #         var idx = startIdx + i
    #         var entity = arch.GetEntity(idx)
    #         for _, c in enumerate(comps):
    #             self.copyTo(entity, c.ID, c.Comp)

    #     return arch, startIdx

    # fn removeEntities(self, filter: Filter) -> int:
    #     """
    #     RemoveEntities removes and recycles all _entities matching a filter.

    #     Returns the number of removed _entities.

    #     Panics when called on a locked world.
    #     Do not use during [Query] iteration!
    #     """
    #     self.checkLocked()

    #     var lock = self.lock()

    #     var bits: event.Subscription
    #     var listen: Bool

    #     var count: uint32

    #     var arches = self.getArchetypes(filter)
    #     var numArches = int32(len(arches))
    #     var i: int32
    #     for i = 0 in range(i < numArches, i++):
    #         var arch = arches[i]
    #         var ln = arch.Len()
    #         if ln == 0:
    #             continue

    #         count += ln

    #         var oldRel *ID
    #         var oldIds []ID
    #         if self._listener != nil:
    #             if arch.HasRelationComponent:
    #                 oldRel = &arch.RelationComponent

    #             if len(arch.node.Ids) > 0:
    #                 oldIds = arch.node.Ids

    #             bits = subscription(false, true, false, len(oldIds) > 0, oldRel != nil, oldRel != nil)
    #             var trigger = self._listener.Subscriptions() & bits
    #             listen = trigger != 0 && subscribes(trigger, nil, &arch.Mask, self._listener.Components(), oldRel, nil)

    #         var j: uint32
    #         for j = 0 in range(j < ln, j++):
    #             var entity = arch.GetEntity(j)
    #             if listen:
    #                 self._listener.Notify(self, EntityEventEntity: entity, Removed: arch.Mask, RemovedIDs: oldIds, OldRelation: oldRel, OldTarget: arch.RelationTarget, EventTypes: bits)

    #             var index = &self._entities[entity.id]
    #             index.arch = nil

    #             if self._tarquery.Get(entity.id):
    #                 self._cleanup_archetypes(entity)
    #                 self._tarquery.Set(entity.id, false)

    #             self.entityPool.Recycle(entity)

    #         arch.Reset()
    #         self._cleanup_archetype(arch)

    #     self.unlock(lock)

    #     return int(count)

    # fn notifyExchange(self, arch: *archetype, old_mask: *Mask, entity: Entity, add: []ID, rem: []ID, oldTarget: Entity, oldRel: *ID):
    #     """
    #     notify listeners for an exchange.
    #     """
    #     var newRel *ID
    #     if arch.HasRelationComponent:
    #         newRel = &arch.RelationComponent

    #     var relChanged = false
    #     if oldRel != nil || newRel != nil:
    #         relChanged = (oldRel == nil) != (newRel == nil) || *oldRel != *newRel

    #     var targChanged = oldTarget != arch.RelationTarget

    #     var bits = subscription(false, false, len(add) > 0, len(rem) > 0, relChanged, relChanged || targChanged)
    #     var trigger = self._listener.Subscriptions() & bits
    #     if trigger != 0:
    #         var changed = old_mask.Xor(&arch.Mask)
    #         var added = arch.Mask.And(&changed)
    #         var removed = old_mask.And(&changed)
    #         if subscribes(trigger, &added, &removed, self._listener.Components(), oldRel, newRel):
    #             self._listener.Notify(self,
    #                 EntityEventEntity: entity, Added: added, Removed: removed,
    #                     AddedIDs: add, RemovedIDs: rem, OldRelation: oldRel, NewRelation: newRel,
    #                     OldTarget: oldTarget, EventTypes: bits,
    #             )

    # fn exchangeBatch(self, filter: Filter, add: []ID, rem: []ID, relation: ID, hasRelation: Bool, target: Entity) -> int:
    #     """
    #     ExchangeBatch exchanges components for many _entities, matching a filter.

    #     If the callback argument is given, it is called with a [Query] over the affected _entities,
    #     one Query for each affected archetype.

    #     Panics:
    #     - when called with components that can't be added or removed because they are already present/not present, respectively.
    #     - when called on a locked world. Do not use during [Query] iteration!

    #     See also [World.Exchange].
    #     """
    #     var batches = batchArchetypes
    #         Added:   add,
    #         Removed: rem,

    #     var count = self.exchangeBatchNoNotify(filter, add, rem, relation, hasRelation, target, &batches)

    #     if self._listener != nil:
    #         self.notifyQuery(&batches)

    #     return count

    # fn exchangeBatchQuery(self, filter: Filter, add: []ID, rem: []ID, relation: ID, hasRelation: Bool, target: Entity) -> Query:
    #     var batches = batchArchetypes
    #         Added:   add,
    #         Removed: rem,

    #     self.exchangeBatchNoNotify(filter, add, rem, relation, hasRelation, target, &batches)

    #     var lock = self.lock()
    #     return newBatchQuery(self, lock, &batches)

    # fn exchangeBatchNoNotify(self, filter: Filter, add: []ID, rem: []ID, relation: ID, hasRelation: Bool, target: Entity, batches: *batchArchetypes) -> int:
    #     self.checkLocked()

    #     if len(add) == 0 && len(rem) == 0:
    #         if hasRelation:
    #             panic("exchange operation has no effect, but a relation is specified. Use Batch.SetRelation instead")

    #         return 0

    #     var arches = self.getArchetypes(filter)
    #     var lengths = make([]uint32, len(arches))
    #     var totalEntities: uint32 = 0
    #     for i, arch in enumerate(arches):
    #         lengths[i] = arch.Len()
    #         totalEntities += arch.Len()

    #     for i, arch in enumerate(arches):
    #         var archLen = lengths[i]

    #         if archLen == 0:
    #             continue

    #         newArch, var start = self.exchangeArch(arch, archLen, add, rem, relation, hasRelation, target)
    #         batches.Add(newArch, arch, start, newArch.Len())

    #     return int(totalEntities)

    # fn exchangeArch(self, old_archetype: *archetype, oldArchLen: uint32, add: []ID, rem: []ID, relation: ID, hasRelation: Bool, target: Entity):
    #     var mask = self._get_exchange_mask(old_archetype.Mask, add, rem)
    #     var oldIDs = old_archetype.Components()

    #     if hasRelation:
    #         if !mask.Get(relation):
    #             tp, var _ = self._registry.ComponentType(relation.id)
    #             panic(fmt.Sprintf("can't add relation: resulting entity has no component %s", tp.Name()))

    #         if !self._registry.IsRelation.Get(relation):
    #             tp, var _ = self._registry.ComponentType(relation.id)
    #             panic(fmt.Sprintf("can't add relation: %s is not a relation component", tp.Name()))

    #     else
    #         target = old_archetype.RelationTarget
    #         if !target.IsZero() && old_archetype.Mask.ContainsAny(&self._registry.IsRelation):
    #             for _, id in enumerate(rem):
    #                 # Removing a relation
    #                 if self._registry.IsRelation.Get(id):
    #                     target = Entity
    #                     break

    #     var arch = self._find_or_create_archetype(old_archetype, add, rem, target)

    #     var startIdx = arch.Len()
    #     var count = oldArchLen
    #     arch.AllocN(uint32(count))

    #     var i: uint32
    #     for i = 0 in range(i < count, i++):
    #         var idx = startIdx + i
    #         var entity = old_archetype.GetEntity(i)
    #         var index = &self._entities[entity.id]
    #         arch.SetEntity(idx, entity)
    #         index.arch = arch
    #         index.index = idx

    #         for _, id in enumerate(oldIDs):
    #             if mask.Get(id):
    #                 var comp = old_archetype.Get(i, id)
    #                 arch.SetPointer(idx, id, comp)

    #     if !target.IsZero():
    #         self._tarquery.Set(target.id, true)

    #     # Theoretically, it could be oldArchLen < old_archetype.Len(),
    #     # which means we can't reset the archetype.
    #     # However, this should not be possible as processing an entity twice
    #     # would mean an illegal component addition/removal.
    #     old_archetype.Reset()
    #     self._cleanup_archetype(old_archetype)

    #     return arch, startIdx

    # fn copyTo(self, entity: Entity, id: ID, comp: interface) -> unsafe:
    #     """
    #     Copies a component to an entity
    #     """
    #     if !self.Has(entity, id):
    #         panic("can't copy component into entity that has no such component type")

    #     var index = &self._entities[entity.id]
    #     var arch = index.arch

    #     return arch.Set(index.index, id, comp)

    # fn getArchetypes(self, filter: Filter):
    #     """
    #     Returns all _archetypes that match the given filter.
    #     """
    #     if cached, var ok = filter.(*CachedFilter); ok:
    #         return self._filter_cache.get(cached).Archetypes.pointers

    #     var arches = []*archetype
    #     var _nodes = self._node_pointers

    #     for _, nd in enumerate(_nodes):
    #         if !nd.IsActive || !nd.Matches(filter):
    #             continue

    #         if rf, var ok = filter.(*RelationFilter); ok:
    #             var target = rf.Target
    #             if arch, var ok = nd.archetypeMap[target]; ok:
    #                 arches = append(arches, arch)

    #             continue

    #         var nodeArches = nd.Archetypes()
    #         var ln2 = int32(nodeArches.Len())
    #         var j: int32
    #         for j = 0 in range(j < ln2, j++):
    #             var a = nodeArches.Get(j)
    #             if a.IsActive():
    #                 arches = append(arches, a)

    #     return arches

    # fn extendArchetypeLayouts(self, count: uint8):
    #     """
    #     Extend the number of access layouts in _archetypes.
    #     """
    #     var len = self._nodes.Len()
    #     var i: int32
    #     for i = 0 in range(i < len, i++):
    #         self._nodes.Get(i).ExtendArchetypeLayouts(count)

    # fn componentID(self, tp: reflect.Type) -> ID:
    #     """
    #     componentID returns the ID for a component type, and registers it if not already registered.
    #     """
    #     id, var newID = self._registry.ComponentID(tp)
    #     if newID:
    #         if self.is_locked():
    #             self._registry.unregisterLastComponent()
    #             panic("attempt to register a new component in a locked world")

    #         if id > 0 && id%layoutChunkSize == 0:
    #             self.extendArchetypeLayouts(id + layoutChunkSize)

    #     return IDid: id

    # fn resourceID(self, tp: reflect.Type) -> ResID:
    #     """
    #     resourceID returns the ID for a resource type, and registers it if not already registered.
    #     """
    #     id, var _ = self._resources._registry.ComponentID(tp)
    #     return ResIDid: id

    # fn closeQuery(self, query: *Query):
    #     """
    #     closeQuery closes a query and unlocks the world.
    #     """
    #     query.nodeIndex = -2
    #     query.archIndex = -2
    #     self.unlock(query.lockBit)

    #     if self._listener != nil:
    #         if arch, var ok = query.nodeArchetypes.(*batchArchetypes); ok:
    #             self.notifyQuery(arch)

    # fn notifyQuery(self, batchArch: *batchArchetypes):
    #     """
    #     notifies the _listener for all _entities on a batch query.
    #     """
    #     var count = batchArch.Len()
    #     var i: int32
    #     for i = 0 in range(i < count, i++):
    #         var arch = batchArch.Get(i)

    #         var newRel *ID
    #         if arch.HasRelationComponent:
    #             newRel = &arch.RelationComponent

    #         var event = EntityEvent
    #             Entity: Entity, Added: arch.Mask, Removed: Mask, AddedIDs: batchArch.Added, RemovedIDs: batchArch.Removed,
    #             OldRelation: nil, NewRelation: newRel,
    #             OldTarget: Entity, EventTypes: 0,

    #         var old_archetype = batchArch.OldArchetype[i]
    #         var relChanged = newRel != nil
    #         var targChanged = !arch.RelationTarget.IsZero()

    #         if old_archetype != nil:
    #             var oldRel *ID
    #             if old_archetype.HasRelationComponent:
    #                 oldRel = &old_archetype.RelationComponent

    #             relChanged = false
    #             if oldRel != nil || newRel != nil:
    #                 relChanged = (oldRel == nil) != (newRel == nil) || *oldRel != *newRel

    #             targChanged = old_archetype.RelationTarget != arch.RelationTarget
    #             var changed = event.Added.Xor(&old_archetype.node.Mask)
    #             event.Added = changed.And(&event.Added)
    #             event.Removed = changed.And(&old_archetype.node.Mask)
    #             event.OldTarget = old_archetype.RelationTarget
    #             event.OldRelation = oldRel

    #         var bits = subscription(old_archetype == nil, false, len(batchArch.Added) > 0, len(batchArch.Removed) > 0, relChanged, relChanged || targChanged)
    #         event.EventTypes = bits

    #         var trigger = self._listener.Subscriptions() & bits
    #         if trigger != 0 && subscribes(trigger, &event.Added, &event.Removed, self._listener.Components(), event.OldRelation, event.NewRelation):
    #             start, var end = batchArch.StartIndex[i], batchArch.EndIndex[i]
    #             var e: uint32
    #             for e = start in range(e < end, e++):
    #                 var entity = arch.GetEntity(e)
    #                 event.Entity = entity
    #                 self._listener.Notify(self, event)
