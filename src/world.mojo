struct World
    """ 
    World is the central type holding entity and component data, as well as resources.

    The World provides all the basic ECS functionality of Arche,
    like [World.Query], [World.new_entity], [World.Add], [World.Remove] or [World.RemoveEntity].

    For more advanced functionality, see [World.Relations], [World.Resources],
    [World.Batch], [World.Cache] and [Builder].
    """ 
    # listener       Listener                  # EntityEvent listener.
    # nodePointers   []*archNode               # Helper list of all node pointers for queries.
    # entities       []entityIndex             # Mapping from entities to archetype and index.
    # targetEntities bitSet                    # Whether entities are potential relation targets. Used for archetype cleanup.
    # relationNodes  []*archNode               # Archetype nodes that have an entity relation.
    # filterCache    Cache                     # Cache for registered filters.
    # nodes          pagedSlice[archNode]      # The archetype graph.
    # archetypeData  pagedSlice[archetypeData] # Storage for the actual archetype data (components).
    # nodeData       pagedSlice[nodeData]      # The archetype graph's data.
    # archetypes     pagedSlice[archetype]     # Archetypes that have no relations components.
    # entityPool     entityPool                # Pool for entities.
    # stats          stats.World               # Cached world statistics.
    # resources      Resources                 # World resources.
    # registry       componentRegistry         # Component registry.
    # locks          lockMask                  # World locks.
    # config         Config                    # World configuration.


    fn __init__(inout self, *config: Config) -> self:
        """
        Creates a new [World] from an optional [Config].
        
        Uses the default [Config] if called without an argument.
        Accepts zero or one arguments.
        """
        if len(config) > 1:
            raise Error("Can't use more than one Config")
        
		# TODO
        # if len(config) == 1:
        #     return fromConfig(config[0])
        
        # return fromConfig(NewConfig())


    fn new_entity(self, *comps: Id) -> Entity:
        """
        Returns a new or recycled [Entity].
        The given component types are added to the entity.
        
        Panics when called on a locked world.
        Do not use during [Query] iteration!
        
        ⚠️ Important:
        Entities are intended to be stored and passed around via copy, not via pointers! See [Entity].
        
        Note that calling a method with varargs in Go causes a slice allocation.
        For maximum performance, pre-allocate a slice of component IDs and pass it using ellipsis:
        
        # fast
        world.new_entity(idA, idB, idC)
        # even faster
        world.new_entity(ids...)
        
        For more advanced and batched entity creation, see [Builder].
        See also the generic variants under [github.com/mlange-42/arche/generic.Map1], etc.
        """
        self._check_locked()

        var arch = self.archetypes.get(0)
        if len(comps) > 0:
            arch = self._find_or_create_archetype(arch, comps, nil, Entity)
        

        var entity = self._create_entity(arch)

        if self.listener != nil:
            var newRel *Id
            if arch.HasRelationComponent:
                newRel = &arch.RelationComponent
            
            var bits = subscription(true, false, len(comps) > 0, false, newRel != nil, newRel != nil)
            var trigger = self.listener.Subscriptions() & bits
            if trigger != 0 && subscribes(trigger, &arch.Mask, nil, self.listener.Components(), nil, newRel):
                self.listener.Notify(self, EntityEventEntity: entity, Added: arch.Mask, AddedIDs: comps, NewRelation: newRel, EventTypes: bits)
            
        
        return entity


    fn NewEntityWith(self, comps: ...Component) -> Entity:
        """
        NewEntityWith returns a new or recycled [Entity].
        The given component values are assigned to the entity.
        
        The components in the Comp field of [Component] must be pointers.
        The passed pointers are no valid references to the assigned memory!
        
        Panics when called on a locked world.
        Do not use during [Query] iteration!
        
        ⚠️ Important:
        Entities are intended to be stored and passed around via copy, not via pointers! See [Entity].
        
        For more advanced and batched entity creation, see [Builder].
        See also the generic variants under [github.com/mlange-42/arche/generic.Map1], etc.
        """
        self._check_locked()

        if len(comps) == 0:
            return self.new_entity()
        

        var ids = make([]Id, len(comps))
        for i, c in enumerate(comps):
            ids[i] = c.Id
        

        var arch = self.archetypes.get(0)
        arch = self._find_or_create_archetype(arch, ids, nil, Entity)

        var entity = self._create_entity(arch)

        for _, c in enumerate(comps):
            self.copyTo(entity, c.Id, c.Comp)
        

        if self.listener != nil:
            var newRel *Id
            if arch.HasRelationComponent:
                newRel = &arch.RelationComponent
            
            var bits = subscription(true, false, len(comps) > 0, false, newRel != nil, newRel != nil)
            var trigger = self.listener.Subscriptions() & bits
            if trigger != 0 && subscribes(trigger, &arch.Mask, nil, self.listener.Components(), nil, newRel):
                self.listener.Notify(self, EntityEventEntity: entity, Added: arch.Mask, AddedIDs: ids, NewRelation: newRel, EventTypes: bits)
            
        
        return entity


    fn RemoveEntity(self, entity: Entity):
        """
        RemoveEntity removes an [Entity], making it eligible for recycling.
        
        Panics when called on a locked world or for an already removed entity.
        Do not use during [Query] iteration!
        """
        self._check_locked()

        if !self.entityPool.Alive(entity):
            panic("can't remove a dead entity")
        

        var index = &self.entities[entity.id]
        var oldArch = index.arch

        if self.listener != nil:
            var oldRel *Id
            if oldArch.HasRelationComponent:
                oldRel = &oldArch.RelationComponent
            
            var oldIds []Id
            if len(oldArch.node.Ids) > 0:
                oldIds = oldArch.node.Ids
            

            var bits = subscription(false, true, false, len(oldIds) > 0, oldRel != nil, oldRel != nil)
            var trigger = self.listener.Subscriptions() & bits
            if trigger != 0 && subscribes(trigger, nil, &oldArch.Mask, self.listener.Components(), oldRel, nil):
                var lock = self.lock()
                self.listener.Notify(self, EntityEventEntity: entity, Removed: oldArch.Mask, RemovedIDs: oldIds, OldRelation: oldRel, OldTarget: oldArch.RelationTarget, EventTypes: bits)
                self.unlock(lock)
            
        

        var swapped = oldArch.Remove(index.index)

        self.entityPool.Recycle(entity)

        if swapped:
            var swapEntity = oldArch.GetEntity(index.index)
            self.entities[swapEntity.id].index = index.index
        
        index.arch = nil

        if self.targetEntities.get(entity.id):
            self.cleanupArchetypes(entity)
            self.targetEntities.Set(entity.id, false)
        

        self.cleanupArchetype(oldArch)


    fn Alive(self, entity: Entity) -> bool:
        """
        Alive reports whether an entity is still alive.
        """
        return self.entityPool.Alive(entity)


    fn get(self, entity: Entity, comp: Id) -> unsafe:
        """
        get returns a pointer to the given component of an [Entity].
        Returns nil if the entity has no such component.
        
        Panics when called for a removed (and potentially recycled) entity.
        
        See [World.GetUnchecked] for an optimized version for static entities.
        See also [github.com/mlange-42/arche/generic.Map.get] for a generic variant.
        """
        if !self.entityPool.Alive(entity):
            panic("can't get component of a dead entity")
        
        var index = &self.entities[entity.id]
        return index.arch.get(index.index, comp)


    fn GetUnchecked(self, entity: Entity, comp: Id) -> unsafe:
        """
        GetUnchecked returns a pointer to the given component of an [Entity].
        Returns nil if the entity has no such component.
        
        GetUnchecked is an optimized version of [World.get],
        for cases where entities are static or checked with [World.Alive] in user code.
        It can also be used after getting another component of the same entity with [World.get].
        
        Panics when called for a removed entity, but not for a recycled entity.
        
        See also [github.com/mlange-42/arche/generic.Map.get] for a generic variant.
        """
        var index = &self.entities[entity.id]
        return index.arch.get(index.index, comp)


    fn Has(self, entity: Entity, comp: Id) -> bool:
        """
        Has returns whether an [Entity] has a given component.
        
        Panics when called for a removed (and potentially recycled) entity.
        
        See [World.HasUnchecked] for an optimized version for static entities.
        See also [github.com/mlange-42/arche/generic.Map.Has] for a generic variant.
        """
        if !self.entityPool.Alive(entity):
            panic("can't check for component of a dead entity")
        
        return self.entities[entity.id].arch.HasComponent(comp)


    fn HasUnchecked(self, entity: Entity, comp: Id) -> bool:
        """
        HasUnchecked returns whether an [Entity] has a given component.
        
        HasUnchecked is an optimized version of [World.Has],
        for cases where entities are static or checked with [World.Alive] in user code.
        
        Panics when called for a removed entity, but not for a recycled entity.
        
        See also [github.com/mlange-42/arche/generic.Map.Has] for a generic variant.
        """
        return self.entities[entity.id].arch.HasComponent(comp)


    fn Add(self, entity: Entity, comps: ...Id):
        """
        Add adds components to an [Entity].
        
        Panics:
        - when called for a removed (and potentially recycled) entity.
        - when called with components that can't be added because they are already present.
        - when called on a locked world. Do not use during [Query] iteration!
        
        Note that calling a method with varargs in Go causes a slice allocation.
        For maximum performance, pre-allocate a slice of component IDs and pass it using ellipsis:
        
        # fast
        world.Add(entity, idA, idB, idC)
        # even faster
        world.Add(entity, ids...)
        
        See also [World.Exchange].
        See also the generic variants under [github.com/mlange-42/arche/generic.Map1], etc.
        """
        self.Exchange(entity, comps, nil)


    fn Assign(self, entity: Entity, comps: ...Component):
        """
        Assign assigns multiple components to an [Entity], using pointers for the content.
        
        The components in the Comp field of [Component] must be pointers.
        The passed pointers are no valid references to the assigned memory!
        
        Panics:
        - when called for a removed (and potentially recycled) entity.
        - when called with components that can't be added because they are already present.
        - when called on a locked world. Do not use during [Query] iteration!
        
        See also the generic variants under [github.com/mlange-42/arche/generic.Map1], etc.
        """
        self.assign(entity, Id, false, Entity, comps...)


    fn Set(self, entity: Entity, id: Id, comp: interface) -> unsafe:
        """
        Set overwrites a component for an [Entity], using the given pointer for the content.
        
        The passed component must be a pointer.
        Returns a pointer to the assigned memory.
        The passed in pointer is not a valid reference to that memory!
        
        Panics:
        - when called for a removed (and potentially recycled) entity.
        - if the entity does not have a component of that type.
        - when called on a locked world. Do not use during [Query] iteration!
        
        See also [github.com/mlange-42/arche/generic.Map.Set] for a generic variant.
        """
        return self.copyTo(entity, id, comp)


    fn Remove(self, entity: Entity, comps: ...Id):
        """
        Remove removes components from an entity.
        
        Panics:
        - when called for a removed (and potentially recycled) entity.
        - when called with components that can't be removed because they are not present.
        - when called on a locked world. Do not use during [Query] iteration!
        
        See also [World.Exchange].
        See also the generic variants under [github.com/mlange-42/arche/generic.Map1], etc.
        """
        self.Exchange(entity, nil, comps)


    fn Exchange(self, entity: Entity, add: []Id, rem: []Id):
        """
        Exchange adds and removes components in one pass.
        This is more efficient than subsequent use of [World.Add] and [World.Remove].
        
        When a [Relation] component is removed and another one is added,
        the target entity of the relation is reset to zero.
        
        Panics:
        - when called for a removed (and potentially recycled) entity.
        - when called with components that can't be added or removed because they are already present/not present, respectively.
        - when called on a locked world. Do not use during [Query] iteration!
        
        See also [Relations.Exchange] and the generic variants under [github.com/mlange-42/arche/generic.Exchange].
        """
        self.exchange(entity, add, rem, Id, false, Entity)


    fn Reset(self):
        """
        Reset removes all entities and resources from the world.
        
        Does NOT free reserved memory, remove archetypes, clear the registry, clear cached filters, etc.
        However, it removes archetypes with a relation component that is not zero.
        
        Can be used to run systematic simulations without the need to re-allocate memory for each run.
        Accelerates re-populating the world by a factor of 2-3.
        """
        self._check_locked()

        self.entities = self.entities[:1]
        self.targetEntities.Reset()
        self.entityPool.Reset()
        self.locks.Reset()
        self.resources.reset()

        var len = self.nodes.Len()
        var i: int32
        for i = 0 in range(i < len, i++):
            self.nodes.get(i).Reset(self.Cache())
        


    fn Query(self, filter: Filter) -> Query:
        """
        Query creates a [Query] iterator.
        
        Locks the world to prevent changes to component compositions.
        The lock is released automatically when the query finishes iteration, or when [Query.Close] is called.
        The number of simultaneous locks (and thus open queries) at a given time is limited to [MaskTotalBits] (256).
        
        A query can iterate through its entities only once, and can't be used anymore afterwards.
        
        To create a [Filter] for querying, see [All], [Mask.Without], [Mask.Exclusive] and [RelationFilter].
        
        For type-safe generics queries, see package [github.com/mlange-42/arche/generic].
        For advanced filtering, see package [github.com/mlange-42/arche/filter].
        """
        var l = self.lock()
        if cached, var ok = filter.(*CachedFilter); ok:
            return newCachedQuery(self, cached.filter, l, self.filterCache.get(cached).Archetypes.pointers)
        

        return newQuery(self, filter, l, self.nodePointers)


    fn Resources(self):
        """
        Resources of the world.
        
        Resources are component-like data that is not associated to an entity, but unique to the world.
        """
        return &self.resources


    fn Cache(self):
        """
        Cache returns the [Cache] of the world, for registering filters.
        
        See [Cache] for details on filter caching.
        """
        if self.filterCache.getArchetypes == nil:
            self.filterCache.getArchetypes = self.getArchetypes
        
        return &self.filterCache


    fn Batch(self):
        """
        Batch creates a [Batch] processing helper.
        It provides the functionality to manipulate large numbers of entities in batches,
        which is more efficient than handling them one by one.
        """
        return &Batchw


    fn Relations(self):
        """
        Relations returns the [Relations] of the world, for accessing entity [Relation] targets.
        
        See [Relations] for details.
        """
        return &Relationsworld: self


    fn IsLocked(self) -> bool:
        """
        IsLocked returns whether the world is locked by any queries.
        """
        return self.locks.IsLocked()


    fn Mask(self, entity: Entity) -> Mask:
        """
        Mask returns the archetype [Mask] for the given [Entity].
        """
        if !self.entityPool.Alive(entity):
            panic("can't get mask for a dead entity")
        
        return self.entities[entity.id].arch.Mask


    fn Ids(self, entity: Entity):
        """
        Ids returns the component IDs for the archetype of the given [Entity].
        
        Returns a copy of the archetype's component IDs slice, for safety.
        This means that the result can be manipulated safely,
        but also that calling the method may incur some significant cost.
        """
        if !self.entityPool.Alive(entity):
            panic("can't get component IDs for a dead entity")
        
        return append([]Id, self.entities[entity.id].arch.node.Ids...)


    fn SetListener(self, listener: Listener):
        """
        SetListener sets a [Listener] for the world.
        The listener is immediately called on every [ecs.Entity] change.
        Replaces the current listener. Call with nil to remove a listener.
        
        For details, see [EntityEvent], [Listener] and sub-package [event].
        """
        self.listener = listener


    fn Stats(self):
        """
        Stats reports statistics for inspecting the World.
        
        The underlying [stats.World] object is re-used and updated between calls.
        The returned pointer should thus not be stored for later analysis.
        Rather, the required data should be extracted immediately.
        """
        self.stats.Entities = stats.Entities
            Used:     self.entityPool.Len(),
            Total:    self.entityPool.Cap(),
            Recycled: self.entityPool.Available(),
            Capacity: self.entityPool.TotalCap(),
        

        var compCount = len(self.registry.Components)
        var types = append([]reflect.Type, self.registry.Types[:compCount]...)

        var memory = cap(self.entities)*int(entityIndexSize) + self.entityPool.TotalCap()*int(entitySize)

        var cntOld = int32(len(self.stats.Nodes))
        var cntNew = int32(self.nodes.Len())
        var cntActive = 0
        var i: int32
        for i = 0 in range(i < cntOld, i++):
            var node = self.nodes.get(i)
            var nodeStats = &self.stats.Nodes[i]
            node.UpdateStats(nodeStats, &self.registry)
            if node.IsActive:
                memory += nodeStats.Memory
                cntActive++
            
        
        for i = cntOld in range(i < cntNew, i++):
            var node = self.nodes.get(i)
            self.stats.Nodes = append(self.stats.Nodes, node.Stats(&self.registry))
            if node.IsActive:
                memory += self.stats.Nodes[i].Memory
                cntActive++
            
        

        self.stats.ComponentCount = compCount
        self.stats.ComponentTypes = types
        self.stats.Locked = self.IsLocked()
        self.stats.Memory = memory
        self.stats.CachedFilters = len(self.filterCache.filters)
        self.stats.ActiveNodeCount = cntActive

        return &self.stats


    fn DumpEntities(self) -> EntityDump:
        """
        DumpEntities dumps entity information into an [EntityDump] object.
        This dump can be used with [World.LoadEntities] to set the World's entity state.
        
        For world serialization with components and resources, see module [github.com/mlange-42/arche-serde].
        """
        var alive = []uint32

        var query = self.Query(All())
        for query.Next() 
            alive = append(alive, uint32(query.Entity().id))
        

        var data = EntityDump
            Entities:  append([]Entity, self.entityPool.entities...),
            Alive:     alive,
            Next:      uint32(self.entityPool.next),
            Available: self.entityPool.available,
        

        return data


    fn LoadEntities(self, data: *EntityDump):
        """
        LoadEntities resets all entities to the state saved with [World.DumpEntities].
        
        Use this only on an empty world! Can be used after [World.Reset].
        
        The resulting world will have the same entities (in terms of Id, generation and alive state)
        as the original world. This is necessary for proper serialization of entity relations.
        However, the entities will not have any components.
        
        Panics if the world has any dead or alive entities.
        
        For world serialization with components and resources, see module [github.com/mlange-42/arche-serde].
        """
        self._check_locked()

        if len(self.entityPool.entities) > 1 || self.entityPool.available > 0:
            panic("can set entity data only on a fresh or reset world")
        

        var capacity = capacity(len(data.Entities), self.config.CapacityIncrement)

        var entities = make([]Entity, 0, capacity)
        entities = append(entities, data.Entities...)

        self.entityPool.entities = entities
        self.entityPool.next = eid(data.Next)
        self.entityPool.available = data.Available

        self.entities = make([]entityIndex, len(data.Entities), capacity)
        self.targetEntities = bitSet
        self.targetEntities.ExtendTo(capacity)

        var arch = self.archetypes.get(0)
        for _, idx in enumerate(data.Alive):
            var entity = self.entityPool.entities[idx]
            var archIdx = arch.Alloc(entity)
            self.entities[entity.id] = entityIndexarch: arch, index: archIdx
        
