from pool import EntityPool
from entity import EntityIndex

struct World
    """ 
    World is the central type holding entity and component data, as well as _resources.

    The World provides all the basic ECS functionality of Arche,
    like [World.Query], [World.new_entity], [World.Add], [World.Remove] or [World.RemoveEntity].

    For more advanced functionality, see [World.Relations], [World.Resources],
    [World.Batch], [World.Cache] and [Builder].
    """ 
    # _listener       Listener                  # EntityEvent _listener.
    # _node_pointers   []*archNode               # Helper list of all node pointers for queries.
    _entities       List[EntityIndex]          # Mapping from entities to archetype and index.
    # _target_entities bitSet                    # Whether entities are potential relation targets. Used for archetype cleanup.
    # _relation_nodes  []*archNode               # Archetype nodes that have an entity relation.
    # _filter_cache    Cache                     # Cache for registered filters.
    # _nodes          pagedSlice[archNode]      # The archetype graph.
    # _archetype_data  pagedSlice[_archetype_data] # Storage for the actual archetype data (components).
    # _node_data       pagedSlice[_node_data]      # The archetype graph's data.
    # _archetypes     pagedSlice[archetype]     # Archetypes that have no relations components.
    _entity_pool     EntityPool                # Pool for entities.
    # _stats          _stats.World               # Cached world statistics.
    # _resources      Resources                 # World _resources.
    # _registry       componentRegistry         # Component _registry.
    # _locks          lockMask                  # World _locks.


    fn __init__(inout self) -> self:
        """
        Creates a new [World].
        """
        
        self._entities = List[EntityIndex](EnitiyIndex(index=0)) #TODO: arch = None
        self._entity_pool = EntityPool()

        # TODO
        # var _target_entities = bitSet
        # _target_entities.ExtendTo(1)
        # self._target_entities = _target_entities

        # self._registry:       newComponentRegistry(),
        # self._archetypes:     pagedSlice[archetype],
        # self._archetype_data:  pagedSlice[_archetype_data],
        # self._nodes:          pagedSlice[archNode],
        # self._relation_nodes:  []*archNode,
        # self._locks:          lockMask,
        # self._listener:       nil,
        # self._resources:      newResources(),
        # self._filter_cache:    newCache(),
        
        # var node = self.createArchetypeNode(Mask, ID, false)
        # self.createArchetype(node, Entity, false)


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

        var arch = self._archetypes.get(0)
        if len(comps) > 0:
            arch = self._find_or_create_archetype(arch, comps, nil, Entity)
        
        var entity = self._create_entity(arch)

        # TODO
        # if self._listener != nil:
        #     var newRel *Id
        #     if arch.HasRelationComponent:
        #         newRel = &arch.RelationComponent
            
        #     var bits = subscription(true, false, len(comps) > 0, false, newRel != nil, newRel != nil)
        #     var trigger = self._listener.Subscriptions() & bits
        #     if trigger != 0 && subscribes(trigger, &arch.Mask, nil, self._listener.Components(), nil, newRel):
        #         self._listener.Notify(self, EntityEventEntity: entity, Added: arch.Mask, AddedIDs: comps, NewRelation: newRel, EventTypes: bits)
        
        return entity


    # fn NewEntityWith(self, comps: ...Component) -> Entity:
    #     """
    #     NewEntityWith returns a new or recycled [Entity].
    #     The given component values are assigned to the entity.
        
    #     The components in the Comp field of [Component] must be pointers.
    #     The passed pointers are no valid references to the assigned memory!
        
    #     Panics when called on a locked world.
    #     Do not use during [Query] iteration!
        
    #     ⚠️ Important:
    #     Entities are intended to be stored and passed around via copy, not via pointers! See [Entity].
        
    #     For more advanced and batched entity creation, see [Builder].
    #     See also the generic variants under [github.com/mlange-42/arche/generic.Map1], etc.
    #     """
    #     self._check_locked()

    #     if len(comps) == 0:
    #         return self.new_entity()
        

    #     var ids = make([]Id, len(comps))
    #     for i, c in enumerate(comps):
    #         ids[i] = c.Id
        

    #     var arch = self._archetypes.get(0)
    #     arch = self._find_or_create_archetype(arch, ids, nil, Entity)

    #     var entity = self._create_entity(arch)

    #     for _, c in enumerate(comps):
    #         self.copyTo(entity, c.Id, c.Comp)
        

    #     if self._listener != nil:
    #         var newRel *Id
    #         if arch.HasRelationComponent:
    #             newRel = &arch.RelationComponent
            
    #         var bits = subscription(true, false, len(comps) > 0, false, newRel != nil, newRel != nil)
    #         var trigger = self._listener.Subscriptions() & bits
    #         if trigger != 0 && subscribes(trigger, &arch.Mask, nil, self._listener.Components(), nil, newRel):
    #             self._listener.Notify(self, EntityEventEntity: entity, Added: arch.Mask, AddedIDs: ids, NewRelation: newRel, EventTypes: bits)
            
        
    #     return entity


    # fn RemoveEntity(self, entity: Entity):
    #     """
    #     RemoveEntity removes an [Entity], making it eligible for recycling.
        
    #     Panics when called on a locked world or for an already removed entity.
    #     Do not use during [Query] iteration!
    #     """
    #     self._check_locked()

    #     if !self._entity_pool.Alive(entity):
    #         panic("can't remove a dead entity")
        

    #     var index = &self._entities[entity.id]
    #     var oldArch = index.arch

    #     if self._listener != nil:
    #         var oldRel *Id
    #         if oldArch.HasRelationComponent:
    #             oldRel = &oldArch.RelationComponent
            
    #         var oldIds []Id
    #         if len(oldArch.node.Ids) > 0:
    #             oldIds = oldArch.node.Ids
            

    #         var bits = subscription(false, true, false, len(oldIds) > 0, oldRel != nil, oldRel != nil)
    #         var trigger = self._listener.Subscriptions() & bits
    #         if trigger != 0 && subscribes(trigger, nil, &oldArch.Mask, self._listener.Components(), oldRel, nil):
    #             var lock = self.lock()
    #             self._listener.Notify(self, EntityEventEntity: entity, Removed: oldArch.Mask, RemovedIDs: oldIds, OldRelation: oldRel, OldTarget: oldArch.RelationTarget, EventTypes: bits)
    #             self.unlock(lock)
            
        

    #     var swapped = oldArch.Remove(index.index)

    #     self._entity_pool.Recycle(entity)

    #     if swapped:
    #         var swapEntity = oldArch.GetEntity(index.index)
    #         self._entities[swapEntity.id].index = index.index
        
    #     index.arch = nil

    #     if self._target_entities.get(entity.id):
    #         self.cleanupArchetypes(entity)
    #         self._target_entities.Set(entity.id, false)
        

    #     self.cleanupArchetype(oldArch)


    # fn Alive(self, entity: Entity) -> bool:
    #     """
    #     Alive reports whether an entity is still alive.
    #     """
    #     return self._entity_pool.Alive(entity)


    # fn get(self, entity: Entity, comp: Id) -> unsafe:
    #     """
    #     get returns a pointer to the given component of an [Entity].
    #     Returns nil if the entity has no such component.
        
    #     Panics when called for a removed (and potentially recycled) entity.
        
    #     See [World.GetUnchecked] for an optimized version for static _entities.
    #     See also [github.com/mlange-42/arche/generic.Map.get] for a generic variant.
    #     """
    #     if !self._entity_pool.Alive(entity):
    #         panic("can't get component of a dead entity")
        
    #     var index = &self._entities[entity.id]
    #     return index.arch.get(index.index, comp)


    # fn GetUnchecked(self, entity: Entity, comp: Id) -> unsafe:
    #     """
    #     GetUnchecked returns a pointer to the given component of an [Entity].
    #     Returns nil if the entity has no such component.
        
    #     GetUnchecked is an optimized version of [World.get],
    #     for cases where _entities are static or checked with [World.Alive] in user code.
    #     It can also be used after getting another component of the same entity with [World.get].
        
    #     Panics when called for a removed entity, but not for a recycled entity.
        
    #     See also [github.com/mlange-42/arche/generic.Map.get] for a generic variant.
    #     """
    #     var index = &self._entities[entity.id]
    #     return index.arch.get(index.index, comp)


    # fn Has(self, entity: Entity, comp: Id) -> bool:
    #     """
    #     Has returns whether an [Entity] has a given component.
        
    #     Panics when called for a removed (and potentially recycled) entity.
        
    #     See [World.HasUnchecked] for an optimized version for static _entities.
    #     See also [github.com/mlange-42/arche/generic.Map.Has] for a generic variant.
    #     """
    #     if !self._entity_pool.Alive(entity):
    #         panic("can't check for component of a dead entity")
        
    #     return self._entities[entity.id].arch.HasComponent(comp)


    # fn HasUnchecked(self, entity: Entity, comp: Id) -> bool:
    #     """
    #     HasUnchecked returns whether an [Entity] has a given component.
        
    #     HasUnchecked is an optimized version of [World.Has],
    #     for cases where _entities are static or checked with [World.Alive] in user code.
        
    #     Panics when called for a removed entity, but not for a recycled entity.
        
    #     See also [github.com/mlange-42/arche/generic.Map.Has] for a generic variant.
    #     """
    #     return self._entities[entity.id].arch.HasComponent(comp)


    # fn Add(self, entity: Entity, comps: ...Id):
    #     """
    #     Add adds components to an [Entity].
        
    #     Panics:
    #     - when called for a removed (and potentially recycled) entity.
    #     - when called with components that can't be added because they are already present.
    #     - when called on a locked world. Do not use during [Query] iteration!
        
    #     Note that calling a method with varargs in Go causes a slice allocation.
    #     For maximum performance, pre-allocate a slice of component IDs and pass it using ellipsis:
        
    #     # fast
    #     world.Add(entity, idA, idB, idC)
    #     # even faster
    #     world.Add(entity, ids...)
        
    #     See also [World.Exchange].
    #     See also the generic variants under [github.com/mlange-42/arche/generic.Map1], etc.
    #     """
    #     self.Exchange(entity, comps, nil)


    # fn Assign(self, entity: Entity, comps: ...Component):
    #     """
    #     Assign assigns multiple components to an [Entity], using pointers for the content.
        
    #     The components in the Comp field of [Component] must be pointers.
    #     The passed pointers are no valid references to the assigned memory!
        
    #     Panics:
    #     - when called for a removed (and potentially recycled) entity.
    #     - when called with components that can't be added because they are already present.
    #     - when called on a locked world. Do not use during [Query] iteration!
        
    #     See also the generic variants under [github.com/mlange-42/arche/generic.Map1], etc.
    #     """
    #     self.assign(entity, Id, false, Entity, comps...)


    # fn Set(self, entity: Entity, id: Id, comp: interface) -> unsafe:
    #     """
    #     Set overwrites a component for an [Entity], using the given pointer for the content.
        
    #     The passed component must be a pointer.
    #     Returns a pointer to the assigned memory.
    #     The passed in pointer is not a valid reference to that memory!
        
    #     Panics:
    #     - when called for a removed (and potentially recycled) entity.
    #     - if the entity does not have a component of that type.
    #     - when called on a locked world. Do not use during [Query] iteration!
        
    #     See also [github.com/mlange-42/arche/generic.Map.Set] for a generic variant.
    #     """
    #     return self.copyTo(entity, id, comp)


    # fn Remove(self, entity: Entity, comps: ...Id):
    #     """
    #     Remove removes components from an entity.
        
    #     Panics:
    #     - when called for a removed (and potentially recycled) entity.
    #     - when called with components that can't be removed because they are not present.
    #     - when called on a locked world. Do not use during [Query] iteration!
        
    #     See also [World.Exchange].
    #     See also the generic variants under [github.com/mlange-42/arche/generic.Map1], etc.
    #     """
    #     self.Exchange(entity, nil, comps)


    # fn Exchange(self, entity: Entity, add: []Id, rem: []Id):
    #     """
    #     Exchange adds and removes components in one pass.
    #     This is more efficient than subsequent use of [World.Add] and [World.Remove].
        
    #     When a [Relation] component is removed and another one is added,
    #     the target entity of the relation is reset to zero.
        
    #     Panics:
    #     - when called for a removed (and potentially recycled) entity.
    #     - when called with components that can't be added or removed because they are already present/not present, respectively.
    #     - when called on a locked world. Do not use during [Query] iteration!
        
    #     See also [Relations.Exchange] and the generic variants under [github.com/mlange-42/arche/generic.Exchange].
    #     """
    #     self.exchange(entity, add, rem, Id, false, Entity)


    # fn Reset(self):
    #     """
    #     Reset removes all _entities and _resources from the world.
        
    #     Does NOT free reserved memory, remove _archetypes, clear the _registry, clear cached filters, etc.
    #     However, it removes _archetypes with a relation component that is not zero.
        
    #     Can be used to run systematic simulations without the need to re-allocate memory for each run.
    #     Accelerates re-populating the world by a factor of 2-3.
    #     """
    #     self._check_locked()

    #     self._entities = self._entities[:1]
    #     self._target_entities.Reset()
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


    # fn Relations(self):
    #     """
    #     Relations returns the [Relations] of the world, for accessing entity [Relation] targets.
        
    #     See [Relations] for details.
    #     """
    #     return &Relationsworld: self


    # fn IsLocked(self) -> bool:
    #     """
    #     IsLocked returns whether the world is locked by any queries.
    #     """
    #     return self._locks.IsLocked()


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
    #     self._stats.Locked = self.IsLocked()
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
    #     self._check_locked()

    #     if len(self._entity_pool._entities) > 1 || self._entity_pool.available > 0:
    #         panic("can set entity data only on a fresh or reset world")
        

    #     var capacity = capacity(len(data.Entities), self.config.CapacityIncrement)

    #     var _entities = make([]Entity, 0, capacity)
    #     _entities = append(_entities, data.Entities...)

    #     self._entity_pool._entities = _entities
    #     self._entity_pool.next = eid(data.Next)
    #     self._entity_pool.available = data.Available

    #     self._entities = make([]entityIndex, len(data.Entities), capacity)
    #     self._target_entities = bitSet
    #     self._target_entities.ExtendTo(capacity)

    #     var arch = self._archetypes.get(0)
    #     for _, idx in enumerate(data.Alive):
    #         var entity = self._entity_pool._entities[idx]
    #         var archIdx = arch.Alloc(entity)
    #         self._entities[entity.id] = entityIndexarch: arch, index: archIdx


    # ----------------- from world_internal.go -----------------

    # fn newEntityTarget(self, targetID: ID, target: Entity, comps: ...ID) -> Entity:
    #     """
    #     Creates a new entity with a relation and a target entity.
    #     """
    #     self.checkLocked()

    #     if !target.IsZero() && !self.entityPool.Alive(target):
    #         panic("can't make a dead entity a relation target")
        

    #     var arch = self._archetypes.Get(0)

    #     if len(comps) > 0:
    #         arch = self.findOrCreateArchetype(arch, comps, nil, target)
        
    #     self.checkRelation(arch, targetID)

    #     var entity = self._create_entity(arch)

    #     if !target.IsZero():
    #         self._target_entities.Set(target.id, true)
        

    #     if self._listener != nil:
    #         var bits = subscription(true, false, len(comps) > 0, false, true, true)
    #         var trigger = self._listener.Subscriptions() & bits
    #         if trigger != 0 && subscribes(trigger, &arch.Mask, nil, self._listener.Components(), nil, &targetID):
    #             self._listener.Notify(self, EntityEventEntity: entity, Added: arch.Mask, AddedIDs: comps, NewRelation: &targetID, EventTypes: bits)
            
        
    #     return entity


    # fn newEntityTargetWith(self, targetID: ID, target: Entity, comps: ...Component) -> Entity:
    #     """
    #     Creates a new entity with a relation and a target entity.
    #     """
    #     self.checkLocked()

    #     if !target.IsZero() && !self.entityPool.Alive(target):
    #         panic("can't make a dead entity a relation target")
        

    #     var ids = make([]ID, len(comps))
    #     for i, c in enumerate(comps):
    #         ids[i] = c.ID
        

    #     var arch = self._archetypes.Get(0)
    #     arch = self.findOrCreateArchetype(arch, ids, nil, target)
    #     self.checkRelation(arch, targetID)

    #     var entity = self._create_entity(arch)

    #     if !target.IsZero():
    #         self._target_entities.Set(target.id, true)
        

    #     for _, c in enumerate(comps):
    #         self.copyTo(entity, c.ID, c.Comp)
        

    #     if self._listener != nil:
    #         var bits = subscription(true, false, len(comps) > 0, false, true, true)
    #         var trigger = self._listener.Subscriptions() & bits
    #         if trigger != 0 && subscribes(trigger, &arch.Mask, nil, self._listener.Components(), nil, &targetID):
    #             self._listener.Notify(self, EntityEventEntity: entity, Added: arch.Mask, AddedIDs: ids, NewRelation: &targetID, EventTypes: bits)
            
        
    #     return entity


    # fn newEntities(self, count: int, targetID: ID, hasTarget: bool, target: Entity, comps: ...ID):
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


    # fn newEntitiesQuery(self, count: int, targetID: ID, hasTarget: bool, target: Entity, comps: ...ID) -> Query:
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


    # fn newEntitiesWith(self, count: int, targetID: ID, hasTarget: bool, target: Entity, comps: ...Component):
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


    # fn newEntitiesWithQuery(self, count: int, targetID: ID, hasTarget: bool, target: Entity, comps: ...Component) -> Query:
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


    # fn newEntitiesNoNotify(self, count: int, targetID: ID, hasTarget: bool, target: Entity, comps: ...ID):
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
    #         arch = self.findOrCreateArchetype(arch, comps, nil, target)
        
    #     if hasTarget:
    #         self.checkRelation(arch, targetID)
    #         if !target.IsZero():
    #             self._target_entities.Set(target.id, true)
            
        

    #     var startIdx = arch.Len()
    #     self.createEntities(arch, uint32(count))

    #     return arch, startIdx


    # fn newEntitiesWithNoNotify(self, count: int, targetID: ID, hasTarget: bool, target: Entity, ids: []ID, comps: ...Component):
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
    #         arch = self.findOrCreateArchetype(arch, ids, nil, target)
        
    #     if hasTarget:
    #         self.checkRelation(arch, targetID)
    #         if !target.IsZero():
    #             self._target_entities.Set(target.id, true)
            
        

    #     var startIdx = arch.Len()
    #     self.createEntities(arch, uint32(count))

    #     var i: uint32
    #     for i = 0 in range(i < cnt, i++):
    #         var idx = startIdx + i
    #         var entity = arch.GetEntity(idx)
    #         for _, c in enumerate(comps):
    #             self.copyTo(entity, c.ID, c.Comp)
            
        

    #     return arch, startIdx


    # fn _create_entity(self, arch: *archetype) -> Entity:
    #     """
    #     Creates an Entity and adds it to the given archetype.
    #     """
    #     var entity = self.entityPool.Get()
    #     var idx = arch.Alloc(entity)
    #     var len = len(self._entities)
    #     if int(entity.id) == len:
    #         if len == cap(self._entities):
    #             var old = self._entities
    #             self._entities = make([]entityIndex, len, len+self.config.CapacityIncrement)
    #             copy(self._entities, old)

            
    #         self._entities = append(self._entities, entityIndexarch: arch, index: idx)
    #         self._target_entities.ExtendTo(len + self.config.CapacityIncrement)
    #     else 
    #         self._entities[entity.id] = entityIndexarch: arch, index: idx
    #         self._target_entities.Set(entity.id, false)
        
    #     return entity


    # fn createEntities(self, arch: *archetype, count: uint32):
    #     """
    #     _create_entity creates multiple Entities and adds them to the given archetype.
    #     """
    #     var startIdx = arch.Len()
    #     arch.AllocN(count)

    #     var len = len(self._entities)
    #     var required = len + int(count) - self.entityPool.Available()
    #     var capacity = capacity(required, self.config.CapacityIncrement)
    #     if required > cap(self._entities):
    #         var old = self._entities
    #         self._entities = make([]entityIndex, required, capacity)
    #         copy(self._entities, old)
    #     else if required > len:
    #         self._entities = self._entities[:required]
        
    #     self._target_entities.ExtendTo(capacity)

    #     var i: uint32
    #     for i = 0 in range(i < count, i++):
    #         var idx = startIdx + i
    #         var entity = self.entityPool.Get()
    #         arch.SetEntity(idx, entity)
    #         self._entities[entity.id] = entityIndexarch: arch, index: idx
    #         self._target_entities.Set(entity.id, false)
        


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
    #     var listen: bool

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

    #             if self._target_entities.Get(entity.id):
    #                 self.cleanupArchetypes(entity)
    #                 self._target_entities.Set(entity.id, false)
                

    #             self.entityPool.Recycle(entity)
            
    #         arch.Reset()
    #         self.cleanupArchetype(arch)
        
    #     self.unlock(lock)

    #     return int(count)


    # fn assign(self, entity: Entity, relation: ID, hasRelation: bool, target: Entity, comps: ...Component):
    #     """
    #     assign with relation target.
    #     """
    #     var len = len(comps)
    #     if len == 0:
    #         panic("no components given to assign")
        
    #     var ids = make([]ID, len)
    #     for i, c in enumerate(comps):
    #         ids[i] = c.ID
        
    #     arch, oldMask, oldTarget, var oldRel = self.exchangeNoNotify(entity, ids, nil, relation, hasRelation, target)
    #     for _, c in enumerate(comps):
    #         self.copyTo(entity, c.ID, c.Comp)
        
    #     if self._listener != nil:
    #         self.notifyExchange(arch, oldMask, entity, ids, nil, oldTarget, oldRel)
        


    # fn exchange(self, entity: Entity, add: []ID, rem: []ID, relation: ID, hasRelation: bool, target: Entity):
    #     """
    #     exchange with relation target.
    #     """
    #     if self._listener != nil:
    #         arch, oldMask, oldTarget, var oldRel = self.exchangeNoNotify(entity, add, rem, relation, hasRelation, target)
    #         self.notifyExchange(arch, oldMask, entity, add, rem, oldTarget, oldRel)
    #         return
        
    #     self.exchangeNoNotify(entity, add, rem, relation, hasRelation, target)


    # fn exchangeNoNotify(self, entity: Entity, add: []ID, rem: []ID, relation: ID, hasRelation: bool, target: Entity):
    #     """
    #     perform exchange operation without notifying listeners.
    #     """
    #     self.checkLocked()

    #     if !self.entityPool.Alive(entity):
    #         panic("can't exchange components on a dead entity")
        

    #     if len(add) == 0 && len(rem) == 0:
    #         if hasRelation:
    #             panic("exchange operation has no effect, but a relation is specified. Use World.Relation instead")
            
    #         return nil, nil, Entity, nil
        
    #     var index = &self._entities[entity.id]
    #     var oldArch = index.arch

    #     var oldMask = oldArch.Mask
    #     var mask = self.getExchangeMask(oldMask, add, rem)

    #     if hasRelation:
    #         if !mask.Get(relation):
    #             tp, var _ = self._registry.ComponentType(relation.id)
    #             panic(fmt.Sprintf("can't add relation: resulting entity has no component %s", tp.Name()))
            
    #         if !self._registry.IsRelation.Get(relation):
    #             tp, var _ = self._registry.ComponentType(relation.id)
    #             panic(fmt.Sprintf("can't add relation: %s is not a relation component", tp.Name()))
            
    #     else 
    #         target = oldArch.RelationTarget
    #         if !oldArch.RelationTarget.IsZero() && oldArch.Mask.ContainsAny(&self._registry.IsRelation):
    #             for _, id in enumerate(rem):
    #                 # Removing a relation
    #                 if self._registry.IsRelation.Get(id):
    #                     target = Entity
    #                     break
                    
                
            
        

    #     var oldIDs = oldArch.Components()

    #     var arch = self.findOrCreateArchetype(oldArch, add, rem, target)
    #     var newIndex = arch.Alloc(entity)

    #     for _, id in enumerate(oldIDs):
    #         if mask.Get(id):
    #             var comp = oldArch.Get(index.index, id)
    #             arch.SetPointer(newIndex, id, comp)
            
        

    #     var swapped = oldArch.Remove(index.index)

    #     if swapped:
    #         var swapEntity = oldArch.GetEntity(index.index)
    #         self._entities[swapEntity.id].index = index.index
        
    #     self._entities[entity.id] = entityIndexarch: arch, index: newIndex

    #     var oldRel *ID
    #     if oldArch.HasRelationComponent:
    #         oldRel = &oldArch.RelationComponent
        
    #     var oldTarget = oldArch.RelationTarget

    #     if !target.IsZero():
    #         self._target_entities.Set(target.id, true)
        

    #     self.cleanupArchetype(oldArch)

    #     return arch, &oldMask, oldTarget, oldRel


    # fn notifyExchange(self, arch: *archetype, oldMask: *Mask, entity: Entity, add: []ID, rem: []ID, oldTarget: Entity, oldRel: *ID):
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
    #         var changed = oldMask.Xor(&arch.Mask)
    #         var added = arch.Mask.And(&changed)
    #         var removed = oldMask.And(&changed)
    #         if subscribes(trigger, &added, &removed, self._listener.Components(), oldRel, newRel):
    #             self._listener.Notify(self,
    #                 EntityEventEntity: entity, Added: added, Removed: removed,
    #                     AddedIDs: add, RemovedIDs: rem, OldRelation: oldRel, NewRelation: newRel,
    #                     OldTarget: oldTarget, EventTypes: bits,
    #             )
            
        


    # fn getExchangeMask(self, mask: Mask, add: []ID, rem: []ID) -> Mask:
    #     """
    #     Modify a mask by adding and removing IDs.
    #     """
    #     for _, comp in enumerate(rem):
    #         if !mask.Get(comp):
    #             panic(fmt.Sprintf("entity does not have a component of type %v, can't remove", self._registry.Types[comp.id]))
            
    #         mask.Set(comp, false)
        
    #     for _, comp in enumerate(add):
    #         if mask.Get(comp):
    #             panic(fmt.Sprintf("entity already has component of type %v, can't add", self._registry.Types[comp.id]))
            
    #         mask.Set(comp, true)
        
    #     return mask


    # fn exchangeBatch(self, filter: Filter, add: []ID, rem: []ID, relation: ID, hasRelation: bool, target: Entity) -> int:
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


    # fn exchangeBatchQuery(self, filter: Filter, add: []ID, rem: []ID, relation: ID, hasRelation: bool, target: Entity) -> Query:
    #     var batches = batchArchetypes
    #         Added:   add,
    #         Removed: rem,
        

    #     self.exchangeBatchNoNotify(filter, add, rem, relation, hasRelation, target, &batches)

    #     var lock = self.lock()
    #     return newBatchQuery(self, lock, &batches)


    # fn exchangeBatchNoNotify(self, filter: Filter, add: []ID, rem: []ID, relation: ID, hasRelation: bool, target: Entity, batches: *batchArchetypes) -> int:
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


    # fn exchangeArch(self, oldArch: *archetype, oldArchLen: uint32, add: []ID, rem: []ID, relation: ID, hasRelation: bool, target: Entity):
    #     var mask = self.getExchangeMask(oldArch.Mask, add, rem)
    #     var oldIDs = oldArch.Components()

    #     if hasRelation:
    #         if !mask.Get(relation):
    #             tp, var _ = self._registry.ComponentType(relation.id)
    #             panic(fmt.Sprintf("can't add relation: resulting entity has no component %s", tp.Name()))
            
    #         if !self._registry.IsRelation.Get(relation):
    #             tp, var _ = self._registry.ComponentType(relation.id)
    #             panic(fmt.Sprintf("can't add relation: %s is not a relation component", tp.Name()))
            
    #     else 
    #         target = oldArch.RelationTarget
    #         if !target.IsZero() && oldArch.Mask.ContainsAny(&self._registry.IsRelation):
    #             for _, id in enumerate(rem):
    #                 # Removing a relation
    #                 if self._registry.IsRelation.Get(id):
    #                     target = Entity
    #                     break
                    
                
            
        

    #     var arch = self.findOrCreateArchetype(oldArch, add, rem, target)

    #     var startIdx = arch.Len()
    #     var count = oldArchLen
    #     arch.AllocN(uint32(count))

    #     var i: uint32
    #     for i = 0 in range(i < count, i++):
    #         var idx = startIdx + i
    #         var entity = oldArch.GetEntity(i)
    #         var index = &self._entities[entity.id]
    #         arch.SetEntity(idx, entity)
    #         index.arch = arch
    #         index.index = idx

    #         for _, id in enumerate(oldIDs):
    #             if mask.Get(id):
    #                 var comp = oldArch.Get(i, id)
    #                 arch.SetPointer(idx, id, comp)
                
            
        

    #     if !target.IsZero():
    #         self._target_entities.Set(target.id, true)
        

    #     # Theoretically, it could be oldArchLen < oldArch.Len(),
    #     # which means we can't reset the archetype.
    #     # However, this should not be possible as processing an entity twice
    #     # would mean an illegal component addition/removal.
    #     oldArch.Reset()
    #     self.cleanupArchetype(oldArch)

    #     return arch, startIdx


    # fn getRelation(self, entity: Entity, comp: ID) -> Entity:
    #     """
    #     getRelation returns the target entity for an entity relation.
        
    #     Panics:
    #     - when called for a removed (and potentially recycled) entity.
    #     - when called for a missing component.
    #     - when called for a component that is not a relation.
        
    #     See [Relation] for details and examples.
    #     """
    #     if !self.entityPool.Alive(entity):
    #         panic("can't get relation of a dead entity")
        

    #     var index = &self._entities[entity.id]
    #     self.checkRelation(index.arch, comp)

    #     return index.arch.RelationTarget


    # fn getRelationUnchecked(self, entity: Entity, comp: ID) -> Entity:
    #     """
    #     getRelationUnchecked returns the target entity for an entity relation.
        
    #     getRelationUnchecked is an optimized version of [World.getRelation].
    #     Does not check if the entity is alive or that the component ID is applicable.
    #     """
    #     _ = comp
    #     var index = &self._entities[entity.id]
    #     return index.arch.RelationTarget


    # fn setRelation(self, entity: Entity, comp: ID, target: Entity):
    #     """
    #     setRelation sets the target entity for an entity relation.
        
    #     Panics:
    #     - when called for a removed (and potentially recycled) entity.
    #     - when called for a removed (and potentially recycled) target.
    #     - when called for a missing component.
    #     - when called for a component that is not a relation.
    #     - when called on a locked world. Do not use during [Query] iteration!
        
    #     See [Relation] for details and examples.
    #     """
    #     self.checkLocked()

    #     if !self.entityPool.Alive(entity):
    #         panic("can't set relation for a dead entity")
        
    #     if !target.IsZero() && !self.entityPool.Alive(target):
    #         panic("can't make a dead entity a relation target")
        

    #     var index = &self._entities[entity.id]
    #     self.checkRelation(index.arch, comp)

    #     var oldArch = index.arch

    #     if oldArch.RelationTarget == target:
    #         return
        

    #     var arch = oldArch.node.GetArchetype(target)
    #     if arch == nil:
    #         arch = self.createArchetype(oldArch.node, target, true)
        

    #     var newIndex = arch.Alloc(entity)
    #     for _, id in enumerate(oldArch.node.Ids):
    #         var comp = oldArch.Get(index.index, id)
    #         arch.SetPointer(newIndex, id, comp)
        

    #     var swapped = oldArch.Remove(index.index)

    #     if swapped:
    #         var swapEntity = oldArch.GetEntity(index.index)
    #         self._entities[swapEntity.id].index = index.index
        
    #     self._entities[entity.id] = entityIndexarch: arch, index: newIndex

    #     if !target.IsZero():
    #         self._target_entities.Set(target.id, true)
        

    #     var oldTarget = oldArch.RelationTarget
    #     self.cleanupArchetype(oldArch)

    #     if self._listener != nil:
    #         var trigger = self._listener.Subscriptions() & event.TargetChanged
    #         if trigger != 0 && subscribes(trigger, nil, nil, self._listener.Components(), &comp, &comp):
    #             self._listener.Notify(self, EntityEventEntity: entity, OldRelation: &comp, NewRelation: &comp, OldTarget: oldTarget, EventTypes: event.TargetChanged)
            
        


    # fn setRelationBatch(self, filter: Filter, comp: ID, target: Entity) -> int:
    #     """
    #     set relation target in batches.
    #     """
    #     var batches = batchArchetypes
    #     var count = self.setRelationBatchNoNotify(filter, comp, target, &batches)
    #     if self._listener != nil && self._listener.Subscriptions().Contains(event.TargetChanged):
    #         self.notifyQuery(&batches)
        
    #     return count


    # fn setRelationBatchQuery(self, filter: Filter, comp: ID, target: Entity) -> Query:
    #     var batches = batchArchetypes
    #     self.setRelationBatchNoNotify(filter, comp, target, &batches)
    #     var lock = self.lock()
    #     return newBatchQuery(self, lock, &batches)


    # fn setRelationBatchNoNotify(self, filter: Filter, comp: ID, target: Entity, batches: *batchArchetypes) -> int:
    #     self.checkLocked()

    #     if !target.IsZero() && !self.entityPool.Alive(target):
    #         panic("can't make a dead entity a relation target")
        

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
            

    #         if arch.RelationTarget == target:
    #             continue
            

    #         newArch, start, var end = self.setRelationArch(arch, archLen, comp, target)
    #         batches.Add(newArch, arch, start, end)
        
    #     return int(totalEntities)


    # fn setRelationArch(self, oldArch: *archetype, oldArchLen: uint32, comp: ID, target: Entity):
    #     self.checkRelation(oldArch, comp)

    #     # Before, _entities with unchanged target were included in the query,
    #     # and events were emitted for them. Seems better to skip them completely,
    #     # which is done in World.setRelationBatchNoNotify.
    #     #if oldArch.RelationTarget == target:
    #     #    return oldArch, 0, oldArchLen
    #     #

    #     var oldIDs = oldArch.Components()

    #     var arch = oldArch.node.GetArchetype(target)
    #     if arch == nil:
    #         arch = self.createArchetype(oldArch.node, target, true)
        

    #     var startIdx = arch.Len()
    #     var count = oldArchLen
    #     arch.AllocN(count)

    #     var i: uint32
    #     for i = 0 in range(i < count, i++):
    #         var idx = startIdx + i
    #         var entity = oldArch.GetEntity(i)
    #         var index = &self._entities[entity.id]
    #         arch.SetEntity(idx, entity)
    #         index.arch = arch
    #         index.index = idx

    #         for _, id in enumerate(oldIDs):
    #             var comp = oldArch.Get(i, id)
    #             arch.SetPointer(idx, id, comp)
            
        

    #     if !target.IsZero():
    #         self._target_entities.Set(target.id, true)
        

    #     # Theoretically, it could be oldArchLen < oldArch.Len(),
    #     # which means we can't reset the archetype.
    #     # However, this should not be possible as processing an entity twice
    #     # would mean an illegal component addition/removal.
    #     oldArch.Reset()
    #     self.cleanupArchetype(oldArch)

    #     return arch, uint32(startIdx), arch.Len()


    # fn checkRelation(self, arch: *archetype, comp: ID):
    #     if arch.node.Relation.id != comp.id:
    #         self.relationError(arch, comp)
        


    # fn relationError(self, arch: *archetype, comp: ID):
    #     if !arch.HasComponent(comp):
    #         panic(fmt.Sprintf("entity does not have relation component %v", self._registry.Types[comp.id]))
        
    #     panic(fmt.Sprintf("not a relation component: %v", self._registry.Types[comp.id]))


    # fn lock(self) -> uint8:
    #     """
    #     lock the world and get the lock bit for later unlocking.
    #     """
    #     return self._locks.Lock()


    # fn unlock(self, l: uint8):
    #     """
    #     unlock unlocks the given lock bit.
    #     """
    #     self._locks.Unlock(l)


    # fn checkLocked(self):
    #     """
    #     checkLocked checks if the world is locked, and panics if so.
    #     """
    #     if self.IsLocked():
    #         panic("attempt to modify a locked world")
        


    # fn copyTo(self, entity: Entity, id: ID, comp: interface) -> unsafe:
    #     """
    #     Copies a component to an entity
    #     """
    #     if !self.Has(entity, id):
    #         panic("can't copy component into entity that has no such component type")
        
    #     var index = &self._entities[entity.id]
    #     var arch = index.arch

    #     return arch.Set(index.index, id, comp)


    # fn findOrCreateArchetype(self, start: *archetype, add: []ID, rem: []ID, target: Entity):
    #     """
    #     Tries to find an archetype by traversing the archetype graph,
    #     searching by mask and extending the graph if necessary.
    #     A new archetype is created for the final graph node if not already present.
    #     """
    #     var curr = start.node
    #     var mask = start.Mask
    #     var relation = start.RelationComponent
    #     var hasRelation = start.HasRelationComponent
    #     for _, id in enumerate(rem):
    #         # Not required, as removing happens only via exchange,
    #         # which calls getExchangeMask, which does the same check.
    #         #if !mask.Get(id):
    #         #    panic(fmt.Sprintf("entity does not have a component of type %v, or it was removed twice", self._registry.Types[id.id]))
    #         #
    #         mask.Set(id, false)
    #         if self._registry.IsRelation.Get(id):
    #             relation = ID
    #             hasRelation = false
            
    #         if next, var ok = curr.TransitionRemove.Get(id.id); ok:
    #             curr = next
    #         else 
    #             next, var _ = self.findOrCreateArchetypeSlow(mask, relation, hasRelation)
    #             next.TransitionAdd.Set(id.id, curr)
    #             curr.TransitionRemove.Set(id.id, next)
    #             curr = next
            
        
    #     for _, id in enumerate(add):
    #         if mask.Get(id):
    #             panic(fmt.Sprintf("entity already has component of type %v, or it was added twice", self._registry.Types[id.id]))
            
    #         if start.Mask.Get(id):
    #             panic(fmt.Sprintf("component of type %v added and removed in the same exchange operation", self._registry.Types[id.id]))
            
    #         mask.Set(id, true)
    #         if self._registry.IsRelation.Get(id):
    #             if hasRelation:
    #                 panic("entity already has a relation component")
                
    #             relation = id
    #             hasRelation = true
            
    #         if next, var ok = curr.TransitionAdd.Get(id.id); ok:
    #             curr = next
    #         else 
    #             next, var _ = self.findOrCreateArchetypeSlow(mask, relation, hasRelation)
    #             next.TransitionRemove.Set(id.id, curr)
    #             curr.TransitionAdd.Set(id.id, next)
    #             curr = next
            
        
    #     var arch = curr.GetArchetype(target)
    #     if arch == nil:
    #         arch = self.createArchetype(curr, target, true)
        
    #     return arch


    # fn findOrCreateArchetypeSlow(self, mask: Mask, relation: ID, hasRelation: bool):
    #     """
    #     Tries to find an archetype for a mask, when it can't be reached through the archetype graph.
    #     Creates an archetype graph node.
    #     """
    #     if arch, var ok = self.findArchetypeSlow(mask); ok:
    #         return arch, false
        
    #     return self.createArchetypeNode(mask, relation, hasRelation), true


    # fn findArchetypeSlow(self, mask: Mask):
    #     """
    #     Searches for an archetype by a mask.
    #     """
    #     var length = self._nodes.Len()
    #     var i: int32
    #     for i = 0 in range(i < length, i++):
    #         var nd = self._nodes.Get(i)
    #         if nd.Mask == mask:
    #             return nd, true
            
        
    #     return nil, false


    # fn createArchetypeNode(self, mask: Mask, relation: ID, hasRelation: bool):
    #     """
    #     Creates a node in the archetype graph.
    #     """
    #     var capInc = self.config.CapacityIncrement
    #     if hasRelation:
    #         capInc = self.config.RelationCapacityIncrement
        

    #     var types = mask.toTypes(&self._registry)

    #     self._node_data.Add(_node_data)
    #     self._nodes.Add(newArchNode(mask, self._node_data.Get(self._node_data.Len()-1), relation, hasRelation, capInc, types))
    #     var nd = self._nodes.Get(self._nodes.Len() - 1)
    #     self._relation_nodes = append(self._relation_nodes, nd)
    #     self._node_pointers = append(self._node_pointers, nd)

    #     return nd


    # fn createArchetype(self, node: *archNode, target: Entity, forStorage: bool):
    #     """
    #     Creates an archetype for the given archetype graph node.
    #     Initializes the archetype with a capacity according to CapacityIncrement if forStorage is true,
    #     and with a capacity of 1 otherwise.
    #     """
    #     var arch *archetype
    #     var layouts = capacityNonZero(self._registry.Count(), int(layoutChunkSize))

    #     if node.HasRelation:
    #         arch = node.CreateArchetype(uint8(layouts), target)
    #     else 
    #         self._archetypes.Add(archetype)
    #         self._archetype_data.Add(_archetype_data)
    #         var archIndex = self._archetypes.Len() - 1
    #         arch = self._archetypes.Get(archIndex)
    #         arch.Init(node, self._archetype_data.Get(archIndex), archIndex, forStorage, uint8(layouts), Entity)
    #         node.SetArchetype(arch)
        
    #     self._filter_cache.addArchetype(arch)
    #     return arch


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


    # fn cleanupArchetype(self, arch: *archetype):
    #     """
    #     Removes the archetype if it is empty, and has a relation to a dead target.
    #     """
    #     if arch.Len() > 0 || !arch.node.HasRelation:
    #         return
        
    #     var target = arch.RelationTarget
    #     if target.IsZero() || self.Alive(target):
    #         return
        

    #     self.removeArchetype(arch)


    # fn cleanupArchetypes(self, target: Entity):
    #     """
    #     Removes empty _archetypes that have a target relation to the given entity.
    #     """
    #     for _, node in enumerate(self._relation_nodes):
    #         if arch, var ok = node.archetypeMap[target]; ok && arch.Len() == 0:
    #             self.removeArchetype(arch)
            
        


    # fn removeArchetype(self, arch: *archetype):
    #     """
    #     Removes/de-activates a relation archetype.
    #     """
    #     arch.node.RemoveArchetype(arch)
    #     self.Cache().removeArchetype(arch)


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
    #         if self.IsLocked():
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
            

    #         var oldArch = batchArch.OldArchetype[i]
    #         var relChanged = newRel != nil
    #         var targChanged = !arch.RelationTarget.IsZero()

    #         if oldArch != nil:
    #             var oldRel *ID
    #             if oldArch.HasRelationComponent:
    #                 oldRel = &oldArch.RelationComponent
                
    #             relChanged = false
    #             if oldRel != nil || newRel != nil:
    #                 relChanged = (oldRel == nil) != (newRel == nil) || *oldRel != *newRel
                
    #             targChanged = oldArch.RelationTarget != arch.RelationTarget
    #             var changed = event.Added.Xor(&oldArch.node.Mask)
    #             event.Added = changed.And(&event.Added)
    #             event.Removed = changed.And(&oldArch.node.Mask)
    #             event.OldTarget = oldArch.RelationTarget
    #             event.OldRelation = oldRel
            

    #         var bits = subscription(oldArch == nil, false, len(batchArch.Added) > 0, len(batchArch.Removed) > 0, relChanged, relChanged || targChanged)
    #         event.EventTypes = bits

    #         var trigger = self._listener.Subscriptions() & bits
    #         if trigger != 0 && subscribes(trigger, &event.Added, &event.Removed, self._listener.Components(), event.OldRelation, event.NewRelation):
    #             start, var end = batchArch.StartIndex[i], batchArch.EndIndex[i]
    #             var e: uint32
    #             for e = start in range(e < end, e++):
    #                 var entity = arch.GetEntity(e)
    #                 event.Entity = entity
    #                 self._listener.Notify(self, event)
                
            
        
