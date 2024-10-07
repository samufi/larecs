package ecs

import (
    "fmt"
    "reflect"
    "unsafe"

    "github.com/mlange-42/arche/ecs/stats"
)

# ComponentID returns the [ID] for a component type via generics.
# Registers the type if it is not already registered.
#
# The number of unique component types per [World] is limited to [MASK_TOTAL_BITS].
fn ComponentID[T any](w *World) ID:
    tp = reflect.TypeOf((*T)(nil)).Elem()
    return w.componentID(tp)

# TypeID returns the [ID] for a component type.
# Registers the type if it is not already registered.
#
# The number of unique component types per [World] is limited to [MASK_TOTAL_BITS].
fn TypeID(w *World, tp reflect.Type) ID:
    return w.componentID(tp)

# ResourceID returns the [ResID] for a resource type via generics.
# Registers the type if it is not already registered.
#
# The number of resources per [World] is limited to [MASK_TOTAL_BITS].
fn ResourceID[T any](w *World) ResID:
    tp = reflect.TypeOf((*T)(nil)).Elem()
    return w.resourceID(tp)

# GetResource returns a pointer to the given resource type in the world.
#
# Returns nil if there is no such resource.
#
# Uses reflection. For more efficient access, see [World.Resources],
# and [github.com/mlange-42/arche/generic.Resource.get] for a generic variant.
# These methods are more than 20 times faster than the GetResource function.
#
# See also [AddResource].
fn GetResource[T any](w *World) *T:
    return w.resources.get(ResourceID[T](w)).(*T)

# AddResource adds a resource to the world.
# Returns the ID for the added resource.
#
# Panics if there is already such a resource.
#
# Uses reflection. For more efficient access, see [World.Resources],
# and [github.com/mlange-42/arche/generic.Resource.Add] for a generic variant.
#
# The number of resources per [World] is limited to [MASK_TOTAL_BITS].
fn AddResource[T any](w *World, res *T) ResID:
    id = ResourceID[T](w)
    w.resources.Add(id, res)
    return id

# World is the central type holding entity and component data, as well as resources.
#
# The World provides all the basic ECS functionality of Arche,
# like [World.Query], [World.NewEntity], [World.Add], [World.Remove] or [World.RemoveEntity].
#
# For more advanced functionality, see [World.Relations], [World.Resources],
# [World.Batch], [World.Cache] and [Builder].
type World struct:
    config         Config                # World configuration.
    listener       fn(e *EntityEvent)  # Component change listener.
    resources      Resources             # World resources.
    entities       []entityIndex         # Mapping from entities to archetype and index.
    targetEntities bitSet                # Whether entities are potential relation targets.
    entityPool     entityPool            # Pool for entities.
    archetypes     pagedSlice[archetype] # Archetypes that have no relations components.
    archetypeData  pagedSlice[archetypeData]
    nodes          pagedSlice[archNode]  # The archetype graph.
    NodeData       pagedSlice[NodeData]  # The archetype graph's data.
    nodePointers   []*archNode           # Helper list of all node pointers for queries.
    relationNodes  []*archNode           # Archetype nodes that have an entity relation.
    locks          lockMask              # World locks.
    registry       componentRegistry[ID] # Component registry.
    filterCache    Cache                 # Cache for registered filters.
    stats          stats.WorldStats      # Cached world statistics

# NewWorld creates a new [World] from an optional [Config].
#
# Uses the default [Config] if called without an argument.
# Accepts zero or one arguments.
fn NewWorld(config ...Config) World:
    if len(config) > 1:
        panic("can't use more than one Config")
    
    if len(config) == 1:
        return fromConfig(config[0])
    
    return fromConfig(NewConfig())

# fromConfig creates a new [World] from a [Config].
fn fromConfig(conf Config) World:
    if conf.CapacityIncrement < 1:
        panic("invalid CapacityIncrement in config, must be > 0")
    
    if conf.RelationCapacityIncrement < 1:
        conf.RelationCapacityIncrement = conf.CapacityIncrement
    
    entities = make([]entityIndex, 1, conf.CapacityIncrement)
    entities[0] = entityIndex{arch: nil, index: 0}
    targetEntities = bitSet{}
    targetEntities.ExtendTo(1)

    w = World{
        config:         conf,
        entities:       entities,
        targetEntities: targetEntities,
        entityPool:     newEntityPool(uint32(conf.CapacityIncrement)),
        registry:       newComponentRegistry(),
        archetypes:     pagedSlice[archetype]{},
        archetypeData:  pagedSlice[archetypeData]{},
        nodes:          pagedSlice[archNode]{},
        relationNodes:  []*archNode{},
        locks:          lockMask{},
        listener:       nil,
        resources:      newResources(),
        filterCache:    newCache(),
    
    node = w.createArchetypeNode(Mask{}, -1)
    w.createArchetype(node, Entity{}, False)
    return w

# NewEntity returns a new or recycled [Entity].
# The given component types are added to the entity.
#
# Panics when called on a locked world.
# Do not use during [Query] iteration!
#
# ⚠️ Important:
# Entities are intended to be stored and passed around via copy, not via pointers! See [Entity].
#
# Note that calling a method with varargs in Go causes a slice allocation.
# For maximum performance, pre-allocate a slice of component IDs and pass it using ellipsis:
#
#    # fast
#    world.NewEntity(idA, idB, idC)
#    # even faster
#    world.NewEntity(ids...)
#
# For more advanced and batched entity creation, see [Builder].
# See also the generic variants under [github.com/mlange-42/arche/generic.Map1], etc.
fn (w *World) NewEntity(comps ...ID) Entity:
    w.checkLocked()

    arch = w.archetypes.get(0)
    if len(comps) > 0:
        arch = w.findOrCreateArchetype(arch, comps, nil, Entity{})
    

    entity = w.createEntity(arch)

    if w.listener != nil:
        w.listener(&EntityEvent{entity, Mask{}, arch.Mask, comps, nil, arch.node.ids, 1, Entity{}, arch.RelationTarget, False})
    
    return entity

# NewEntityWith returns a new or recycled [Entity].
# The given component values are assigned to the entity.
#
# The components in the Comp field of [Component] must be pointers.
# The passed pointers are no valid references to the assigned memory!
#
# Panics when called on a locked world.
# Do not use during [Query] iteration!
#
# ⚠️ Important:
# Entities are intended to be stored and passed around via copy, not via pointers! See [Entity].
#
# For more advanced and batched entity creation, see [Builder].
# See also the generic variants under [github.com/mlange-42/arche/generic.Map1], etc.
fn (w *World) NewEntityWith(comps ...Component) Entity:
    w.checkLocked()

    if len(comps) == 0:
        return w.NewEntity()
    

    ids = make([]ID, len(comps))
    for i, c = range comps:
        ids[i] = c.ID
    

    arch = w.archetypes.get(0)
    arch = w.findOrCreateArchetype(arch, ids, nil, Entity{})

    entity = w.createEntity(arch)

    for _, c = range comps:
        w.copyTo(entity, c.ID, c.Comp)
    

    if w.listener != nil:
        w.listener(&EntityEvent{entity, Mask{}, arch.Mask, ids, nil, arch.node.ids, 1, Entity{}, arch.RelationTarget, False})
    
    return entity

# Creates a new entity with a relation and a target entity.
fn (w *World) newEntityTarget(targetID ID, target Entity, comps ...ID) Entity:
    w.checkLocked()

    if !target.is_zero() and !w.entityPool.Alive(target):
        panic("can't make a dead entity a relation target")
    

    arch = w.archetypes.get(0)

    if len(comps) > 0:
        arch = w.findOrCreateArchetype(arch, comps, nil, target)
    
    w.checkRelation(arch, targetID)

    entity = w.createEntity(arch)

    if !target.is_zero():
        w.targetEntities.set(target.id, True)
    

    if w.listener != nil:
        w.listener(&EntityEvent{entity, Mask{}, arch.Mask, comps, nil, arch.node.ids, 1, Entity{}, arch.RelationTarget, False})
    
    return entity

# Creates a new entity with a relation and a target entity.
fn (w *World) newEntityTargetWith(targetID ID, target Entity, comps ...Component) Entity:
    w.checkLocked()

    if !target.is_zero() and !w.entityPool.Alive(target):
        panic("can't make a dead entity a relation target")
    

    ids = make([]ID, len(comps))
    for i, c = range comps:
        ids[i] = c.ID
    

    arch = w.archetypes.get(0)
    arch = w.findOrCreateArchetype(arch, ids, nil, target)
    w.checkRelation(arch, targetID)

    entity = w.createEntity(arch)

    if !target.is_zero():
        w.targetEntities.set(target.id, True)
    

    for _, c = range comps:
        w.copyTo(entity, c.ID, c.Comp)
    

    if w.listener != nil:
        w.listener(&EntityEvent{entity, Mask{}, arch.Mask, ids, nil, arch.node.ids, 1, Entity{}, arch.RelationTarget, False})
    
    return entity

# Creates new entities without returning a query over them.
# Used via [World.Batch].
fn (w *World) newEntities(count int, targetID int8, target Entity, comps ...ID) (*archetype, uint32):
    arch, startIdx = w.newEntitiesNoNotify(count, targetID, target, comps...)

    if w.listener != nil:
        cnt = uint32(count)
        var i uint32
        for i = 0; i < cnt; i++:
            idx = startIdx + i
            entity = arch.GetEntity(idx)
            w.listener(&EntityEvent{entity, Mask{}, arch.Mask, comps, nil, arch.node.ids, 1, Entity{}, arch.RelationTarget, False})
        
    

    return arch, startIdx

# Creates new entities and returns a query over them.
# Used via [World.Batch].
fn (w *World) newEntitiesQuery(count int, targetID int8, target Entity, comps ...ID) Query:
    arch, startIdx = w.newEntitiesNoNotify(count, targetID, target, comps...)
    lock = w.lock()

    batches = batchArchetypes{
        Added:   arch.Components(),
        Removed: nil,
    
    batches.Add(arch, nil, startIdx, arch.Len())
    return newBatchQuery(w, lock, &batches)

# Creates new entities with component values without returning a query over them.
# Used via [World.Batch].
fn (w *World) newEntitiesWith(count int, targetID int8, target Entity, comps ...Component) (*archetype, uint32):
    ids = make([]ID, len(comps))
    for i, c = range comps:
        ids[i] = c.ID
    

    arch, startIdx = w.newEntitiesWithNoNotify(count, targetID, target, ids, comps...)

    if w.listener != nil:
        var i uint32
        cnt = uint32(count)
        for i = 0; i < cnt; i++:
            idx = startIdx + i
            entity = arch.GetEntity(idx)
            w.listener(&EntityEvent{entity, Mask{}, arch.Mask, ids, nil, arch.node.ids, 1, Entity{}, arch.RelationTarget, False})
        
    

    return arch, startIdx

# Creates new entities with component values and returns a query over them.
# Used via [World.Batch].
fn (w *World) newEntitiesWithQuery(count int, targetID int8, target Entity, comps ...Component) Query:
    ids = make([]ID, len(comps))
    for i, c = range comps:
        ids[i] = c.ID
    

    arch, startIdx = w.newEntitiesWithNoNotify(count, targetID, target, ids, comps...)
    lock = w.lock()
    batches = batchArchetypes{
        Added:   arch.Components(),
        Removed: nil,
    
    batches.Add(arch, nil, startIdx, arch.Len())
    return newBatchQuery(w, lock, &batches)

# RemoveEntity removes an [Entity], making it eligible for recycling.
#
# Panics when called on a locked world or for an already removed entity.
# Do not use during [Query] iteration!
fn (w *World) RemoveEntity(entity Entity):
    w.checkLocked()

    if !w.entityPool.Alive(entity):
        panic("can't remove a dead entity")
    

    index = &w.entities[entity.id]
    oldArch = index.arch

    if w.listener != nil:
        lock = w.lock()
        w.listener(&EntityEvent{entity, oldArch.Mask, Mask{}, nil, oldArch.node.ids, nil, -1, oldArch.RelationTarget, Entity{}, False})
        w.unlock(lock)
    

    swapped = oldArch.Remove(index.index)

    w.entityPool.Recycle(entity)

    if swapped:
        swapEntity = oldArch.GetEntity(index.index)
        w.entities[swapEntity.id].index = index.index
    
    index.arch = nil

    if w.targetEntities.get(entity.id):
        w.cleanupArchetypes(entity)
        w.targetEntities.set(entity.id, False)
    

    w.cleanupArchetype(oldArch)

# RemoveEntities removes and recycles all entities matching a filter.
#
# Returns the number of removed entities.
#
# Panics when called on a locked world.
# Do not use during [Query] iteration!
fn (w *World) removeEntities(filter Filter) int:
    w.checkLocked()

    lock = w.lock()

    var count uint32

    arches = w.getArchetypes(filter)
    numArches = int32(len(arches))
    var i int32
    for i = 0; i < numArches; i++:
        arch = arches[i]
        len = arch.Len()
        if len == 0:
            continue
        

        count += len

        var j uint32
        for j = 0; j < len; j++:
            entity = arch.GetEntity(j)
            if w.listener != nil:
                w.listener(&EntityEvent{entity, arch.Mask, Mask{}, nil, arch.node.ids, nil, -1, arch.RelationTarget, Entity{}, False})
            
            index = &w.entities[entity.id]
            index.arch = nil

            if w.targetEntities.get(entity.id):
                w.cleanupArchetypes(entity)
                w.targetEntities.set(entity.id, False)
            

            w.entityPool.Recycle(entity)
        
        arch.reset()
        w.cleanupArchetype(arch)
    
    w.unlock(lock)

    return int(count)

# Alive reports whether an entity is still alive.
fn (w *World) Alive(entity Entity): Bool:
    return w.entityPool.Alive(entity)

# get returns a pointer to the given component of an [Entity].
# Returns nil if the entity has no such component.
#
# Panics when called for a removed (and potentially recycled) entity.
#
# See [World.GetUnchecked] for an optimized version for static entities.
# See also [github.com/mlange-42/arche/generic.Map.get] for a generic variant.
fn (w *World) get(entity Entity, comp ID) unsafe.Pointer:
    if !w.entityPool.Alive(entity):
        panic("can't get component of a dead entity")
    
    index = &w.entities[entity.id]
    return index.arch.get(index.index, comp)

# GetUnchecked returns a pointer to the given component of an [Entity].
# Returns nil if the entity has no such component.
#
# GetUnchecked is an optimized version of [World.get],
# for cases where entities are static or checked with [World.Alive] in user code.
# It can also be used after getting another component of the same entity with [World.get].
#
# Panics when called for a removed entity, but not for a recycled entity.
#
# See also [github.com/mlange-42/arche/generic.Map.get] for a generic variant.
fn (w *World) GetUnchecked(entity Entity, comp ID) unsafe.Pointer:
    index = &w.entities[entity.id]
    return index.arch.get(index.index, comp)

# Has returns whether an [Entity] has a given component.
#
# Panics when called for a removed (and potentially recycled) entity.
#
# See [World.HasUnchecked] for an optimized version for static entities.
# See also [github.com/mlange-42/arche/generic.Map.Has] for a generic variant.
fn (w *World) Has(entity Entity, comp ID): Bool:
    if !w.entityPool.Alive(entity):
        panic("can't check for component of a dead entity")
    
    return w.entities[entity.id].arch.HasComponent(comp)

# HasUnchecked returns whether an [Entity] has a given component.
#
# HasUnchecked is an optimized version of [World.Has],
# for cases where entities are static or checked with [World.Alive] in user code.
#
# Panics when called for a removed entity, but not for a recycled entity.
#
# See also [github.com/mlange-42/arche/generic.Map.Has] for a generic variant.
fn (w *World) HasUnchecked(entity Entity, comp ID): Bool:
    return w.entities[entity.id].arch.HasComponent(comp)

# Add adds components to an [Entity].
#
# Panics:
#   - when called for a removed (and potentially recycled) entity.
#   - when called with components that can't be added because they are already present.
#   - when called on a locked world. Do not use during [Query] iteration!
#
# Note that calling a method with varargs in Go causes a slice allocation.
# For maximum performance, pre-allocate a slice of component IDs and pass it using ellipsis:
#
#    # fast
#    world.Add(entity, idA, idB, idC)
#    # even faster
#    world.Add(entity, ids...)
#
# See also [World.Exchange].
# See also the generic variants under [github.com/mlange-42/arche/generic.Map1], etc.
fn (w *World) Add(entity Entity, comps ...ID):
    w.Exchange(entity, comps, nil)

# Assign assigns multiple components to an [Entity], using pointers for the content.
#
# The components in the Comp field of [Component] must be pointers.
# The passed pointers are no valid references to the assigned memory!
#
# Panics:
#   - when called for a removed (and potentially recycled) entity.
#   - when called with components that can't be added because they are already present.
#   - when called on a locked world. Do not use during [Query] iteration!
#
# See also the generic variants under [github.com/mlange-42/arche/generic.Map1], etc.
fn (w *World) Assign(entity Entity, comps ...Component):
    w.assign(entity, -1, Entity{}, comps...)

# assign with relation target.
fn (w *World) assign(entity Entity, relation int8, target Entity, comps ...Component):
    len = len(comps)
    if len == 0:
        panic("no components given to assign")
    
    if len == 1:
        c = comps[0]
        w.exchange(entity, []ID{c.ID}, nil, relation, target)
        w.copyTo(entity, c.ID, c.Comp)
        return
    
    ids = make([]ID, len)
    for i, c = range comps:
        ids[i] = c.ID
    
    w.exchange(entity, ids, nil, relation, target)
    for _, c = range comps:
        w.copyTo(entity, c.ID, c.Comp)
    

# set overwrites a component for an [Entity], using the given pointer for the content.
#
# The passed component must be a pointer.
# Returns a pointer to the assigned memory.
# The passed in pointer is not a valid reference to that memory!
#
# Panics:
#   - when called for a removed (and potentially recycled) entity.
#   - if the entity does not have a component of that type.
#   - when called on a locked world. Do not use during [Query] iteration!
#
# See also [github.com/mlange-42/arche/generic.Map.set] for a generic variant.
fn (w *World) set(entity Entity, id ID, comp interface{}) unsafe.Pointer:
    return w.copyTo(entity, id, comp)

# Remove removes components from an entity.
#
# Panics:
#   - when called for a removed (and potentially recycled) entity.
#   - when called with components that can't be removed because they are not present.
#   - when called on a locked world. Do not use during [Query] iteration!
#
# See also [World.Exchange].
# See also the generic variants under [github.com/mlange-42/arche/generic.Map1], etc.
fn (w *World) Remove(entity Entity, comps ...ID):
    w.Exchange(entity, nil, comps)

# Exchange adds and removes components in one pass.
# This is more efficient than subsequent use of [World.Add] and [World.Remove].
#
# Panics:
#   - when called for a removed (and potentially recycled) entity.
#   - when called with components that can't be added or removed because they are already present/not present, respectively.
#   - when called on a locked world. Do not use during [Query] iteration!
#
# See also the generic variants under [github.com/mlange-42/arche/generic.Exchange].
fn (w *World) Exchange(entity Entity, add []ID, rem []ID):
    w.exchange(entity, add, rem, -1, Entity{})

# exchange with relation target.
fn (w *World) exchange(entity Entity, add []ID, rem []ID, relation int8, target Entity):
    w.checkLocked()

    if !w.entityPool.Alive(entity):
        panic("can't exchange components on a dead entity")
    

    if len(add) == 0 and len(rem) == 0:
        return
    
    index = &w.entities[entity.id]
    oldArch = index.arch

    oldMask = oldArch.Mask
    mask = w.getExchangeMask(oldMask, add, rem)

    if relation >= 0:
        if !mask.get(ID(relation)):
            panic("can't add relation: resulting entity has no relation")
        
        if !w.registry.IsRelation.get(ID(relation)):
            panic("can't add relation: this is not a relation component")
        
     else:
        target = oldArch.RelationTarget
    

    oldIDs = oldArch.Components()

    arch = w.findOrCreateArchetype(oldArch, add, rem, target)
    newIndex = arch.Alloc(entity)

    for _, id = range oldIDs:
        if mask.get(id):
            comp = oldArch.get(index.index, id)
            arch.SetPointer(newIndex, id, comp)
        
    

    swapped = oldArch.Remove(index.index)

    if swapped:
        swapEntity = oldArch.GetEntity(index.index)
        w.entities[swapEntity.id].index = index.index
    
    w.entities[entity.id] = entityIndex{arch: arch, index: newIndex}

    w.cleanupArchetype(oldArch)

    if w.listener != nil:
        w.listener(&EntityEvent{entity, oldMask, arch.Mask, add, rem, arch.node.ids, 0, oldArch.RelationTarget, arch.RelationTarget, False})
    

# Modify a mask by adding and removing IDs.
fn (w *World) getExchangeMask(mask Mask, add []ID, rem []ID) Mask:
    for _, comp = range add:
        if mask.get(comp):
            panic(fmt.Sprintf("entity already has component of type %v, can't add", w.registry.Types[comp]))
        
        mask.set(comp, True)
    
    for _, comp = range rem:
        if !mask.get(comp):
            panic(fmt.Sprintf("entity does not have a component of type %v, can't remove", w.registry.Types[comp]))
        
        mask.set(comp, False)
    
    return mask

# ExchangeBatch exchanges components for many entities, matching a filter.
#
# If the callback argument is given, it is called with a [Query] over the affected entities,
# one Query for each affected archetype.
#
# Panics:
#   - when called with components that can't be added or removed because they are already present/not present, respectively.
#   - when called on a locked world. Do not use during [Query] iteration!
#
# See also [World.Exchange].
fn (w *World) exchangeBatch(filter Filter, add []ID, rem []ID):
    batches = batchArchetypes{
        Added:   add,
        Removed: rem,
    

    w.exchangeBatchNoNotify(filter, add, rem, &batches)

    if w.listener != nil:
        w.notifyQuery(&batches)
    

fn (w *World) exchangeBatchQuery(filter Filter, add []ID, rem []ID) Query:
    batches = batchArchetypes{
        Added:   add,
        Removed: rem,
    

    w.exchangeBatchNoNotify(filter, add, rem, &batches)

    lock = w.lock()
    return newBatchQuery(w, lock, &batches)

fn (w *World) exchangeBatchNoNotify(filter Filter, add []ID, rem []ID, batches *batchArchetypes):
    w.checkLocked()

    if len(add) == 0 and len(rem) == 0:
        return
    

    arches = w.getArchetypes(filter)
    lengths = make([]uint32, len(arches))
    for i, arch = range arches:
        lengths[i] = arch.Len()
    

    for i, arch = range arches:
        archLen = lengths[i]

        if archLen == 0:
            continue
        

        newArch, start = w.exchangeArch(arch, archLen, add, rem)
        batches.Add(newArch, arch, start, newArch.Len())
    

fn (w *World) exchangeArch(oldArch *archetype, oldArchLen uint32, add []ID, rem []ID) (*archetype, uint32):
    mask = w.getExchangeMask(oldArch.Mask, add, rem)
    oldIDs = oldArch.Components()
    arch = w.findOrCreateArchetype(oldArch, add, rem, oldArch.RelationTarget)

    startIdx = arch.Len()
    count = oldArchLen
    arch.AllocN(uint32(count))

    var i uint32
    for i = 0; i < count; i++:
        idx = startIdx + i
        entity = oldArch.GetEntity(i)
        index = &w.entities[entity.id]
        arch.SetEntity(idx, entity)
        index.arch = arch
        index.index = idx

        for _, id = range oldIDs:
            if mask.get(id):
                comp = oldArch.get(i, id)
                arch.SetPointer(idx, id, comp)
            
        
    

    # Theoretically, it could be oldArchLen < oldArch.Len(),
    # which means we can't reset the archetype.
    # However, this should not be possible as processing an entity twice
    # would mean an illegal component addition/removal.
    oldArch.reset()
    w.cleanupArchetype(oldArch)

    return arch, startIdx

# getRelation returns the target entity for an entity relation.
#
# Panics:
#   - when called for a removed (and potentially recycled) entity.
#   - when called for a missing component.
#   - when called for a component that is not a relation.
#
# See [Relation] for details and examples.
fn (w *World) getRelation(entity Entity, comp ID) Entity:
    if !w.entityPool.Alive(entity):
        panic("can't get relation of a dead entity")
    

    index = &w.entities[entity.id]
    w.checkRelation(index.arch, comp)

    return index.arch.RelationTarget

# getRelationUnchecked returns the target entity for an entity relation.
#
# getRelationUnchecked is an optimized version of [World.getRelation].
# Does not check if the entity is alive or that the component ID is applicable.
fn (w *World) getRelationUnchecked(entity Entity, comp ID) Entity:
    index = &w.entities[entity.id]
    return index.arch.RelationTarget

# setRelation sets the target entity for an entity relation.
#
# Panics:
#   - when called for a removed (and potentially recycled) entity.
#   - when called for a removed (and potentially recycled) target.
#   - when called for a missing component.
#   - when called for a component that is not a relation.
#   - when called on a locked world. Do not use during [Query] iteration!
#
# See [Relation] for details and examples.
fn (w *World) setRelation(entity Entity, comp ID, target Entity):
    w.checkLocked()

    if !w.entityPool.Alive(entity):
        panic("can't set relation for a dead entity")
    
    if !target.is_zero() and !w.entityPool.Alive(target):
        panic("can't make a dead entity a relation target")
    

    index = &w.entities[entity.id]
    w.checkRelation(index.arch, comp)

    oldArch = index.arch

    if index.arch.RelationTarget == target:
        return
    

    arch = oldArch.node.GetArchetype(target)
    if arch == nil:
        arch = w.createArchetype(oldArch.node, target, True)
    

    newIndex = arch.Alloc(entity)
    for _, id = range oldArch.node.ids:
        comp = oldArch.get(index.index, id)
        arch.SetPointer(newIndex, id, comp)
    

    swapped = oldArch.Remove(index.index)

    if swapped:
        swapEntity = oldArch.GetEntity(index.index)
        w.entities[swapEntity.id].index = index.index
    
    w.entities[entity.id] = entityIndex{arch: arch, index: newIndex}
    w.targetEntities.set(target.id, True)

    w.cleanupArchetype(oldArch)

    if w.listener != nil:
        w.listener(&EntityEvent{entity, arch.Mask, arch.Mask, nil, nil, arch.node.ids, 0, oldArch.RelationTarget, arch.RelationTarget, True})
    

# set relation target in batches.
fn (w *World) setRelationBatch(filter Filter, comp ID, target Entity):
    batches = batchArchetypes{}
    w.setRelationBatchNoNotify(filter, comp, target, &batches)
    if w.listener != nil:
        w.notifyQuery(&batches)
    

fn (w *World) setRelationBatchQuery(filter Filter, comp ID, target Entity) Query:
    batches = batchArchetypes{}
    w.setRelationBatchNoNotify(filter, comp, target, &batches)
    lock = w.lock()
    return newBatchQuery(w, lock, &batches)

fn (w *World) setRelationBatchNoNotify(filter Filter, comp ID, target Entity, batches *batchArchetypes):
    w.checkLocked()

    if !target.is_zero() and !w.entityPool.Alive(target):
        panic("can't make a dead entity a relation target")
    

    arches = w.getArchetypes(filter)
    lengths = make([]uint32, len(arches))
    for i, arch = range arches:
        lengths[i] = arch.Len()
    

    for i, arch = range arches:
        archLen = lengths[i]

        if archLen == 0:
            continue
        

        newArch, start, end = w.setRelationArch(arch, archLen, comp, target)
        batches.Add(newArch, arch, start, end)
    

fn (w *World) setRelationArch(oldArch *archetype, oldArchLen uint32, comp ID, target Entity) (*archetype, uint32, uint32):
    w.checkRelation(oldArch, comp)

    if oldArch.RelationTarget == target:
        return oldArch, 0, oldArchLen
    
    oldIDs = oldArch.Components()

    arch = oldArch.node.GetArchetype(target)
    if arch == nil:
        arch = w.createArchetype(oldArch.node, target, True)
    

    startIdx = arch.Len()
    count = oldArchLen
    arch.AllocN(count)

    var i uint32
    for i = 0; i < count; i++:
        idx = startIdx + i
        entity = oldArch.GetEntity(i)
        index = &w.entities[entity.id]
        arch.SetEntity(idx, entity)
        index.arch = arch
        index.index = idx

        for _, id = range oldIDs:
            comp = oldArch.get(i, id)
            arch.SetPointer(idx, id, comp)
        
    

    # Theoretically, it could be oldArchLen < oldArch.Len(),
    # which means we can't reset the archetype.
    # However, this should not be possible as processing an entity twice
    # would mean an illegal component addition/removal.
    oldArch.reset()
    w.cleanupArchetype(oldArch)

    return arch, uint32(startIdx), arch.Len()

fn (w *World) checkRelation(arch *archetype, comp ID):
    if arch.node.Relation != int8(comp):
        w.relationError(arch, comp)
    

fn (w *World) relationError(arch *archetype, comp ID):
    if !arch.HasComponent(comp):
        panic(fmt.Sprintf("entity does not have relation component %v", w.registry.Types[comp]))
    
    panic(fmt.Sprintf("not a relation component: %v", w.registry.Types[comp]))

# reset removes all entities and resources from the world.
#
# Does NOT free reserved memory, remove archetypes, clear the registry, clear cached filters, etc.
# However, it removes archetypes with a relation component that is not zero.
#
# Can be used to run systematic simulations without the need to re-allocate memory for each run.
# Accelerates re-populating the world by a factor of 2-3.
fn (w *World) reset():
    w.checkLocked()

    w.entities = w.entities[:1]
    w.targetEntities.reset()
    w.entityPool.reset()
    w.locks.reset()
    w.resources.reset()

    len = w.nodes.Len()
    var i int32
    for i = 0; i < len; i++:
        w.nodes.get(i).reset(w.Cache())
    

# Query creates a [Query] iterator.
#
# Locks the world to prevent changes to component compositions.
# The lock is released automatically when the query finishes iteration, or when [Query.Close] is called.
# The number of simultaneous locks (and thus open queries) at a given time is limited to [MASK_TOTAL_BITS].
#
# To create a [Filter] for querying, see [all], [Mask.without], [Mask.exclusive] and [RelationFilter].
#
# For type-safe generics queries, see package [github.com/mlange-42/arche/generic].
# For advanced filtering, see package [github.com/mlange-42/arche/filter].
fn (w *World) Query(filter Filter) Query:
    l = w.lock()
    if cached, ok = filter.(*CachedFilter); ok:
        return newCachedQuery(w, cached.filter, l, w.filterCache.get(cached).Archetypes.pointers)
    

    return newQuery(w, filter, l, w.nodePointers)

# Resources of the world.
#
# Resources are component-like data that is not associated to an entity, but unique to the world.
fn (w *World) Resources() *Resources:
    return &w.resources

# Cache returns the [Cache] of the world, for registering filters.
#
# See [Cache] for details on filter caching.
fn (w *World) Cache() *Cache:
    if w.filterCache.getArchetypes == nil:
        w.filterCache.getArchetypes = w.getArchetypes
    
    return &w.filterCache

# Batch creates a [Batch] processing helper.
# It provides the functionality to manipulate large numbers of entities in batches,
# which is more efficient than handling them one by one.
fn (w *World) Batch() *Batch:
    return &Batch{w}

# Relations returns the [Relations] of the world, for accessing entity [Relation] targets.
#
# See [Relations] for details.
fn (w *World) Relations() *Relations:
    return &Relations{world: w}

# IsLocked returns whether the world is locked by any queries.
fn (w *World) IsLocked(): Bool:
    return w.locks.IsLocked()

# Mask returns the archetype [Mask] for the given [Entity].
#
# Can be used for fast checks of the entity composition, e.g. using a [Filter].
fn (w *World) Mask(entity Entity) Mask:
    if !w.entityPool.Alive(entity):
        panic("can't get mask for a dead entity")
    
    return w.entities[entity.id].arch.Mask

# ComponentType returns the reflect.Type for a given component ID, as well as whether the ID is in use.
fn (w *World) ComponentType(id ID) (reflect.Type,: Bool):
    return w.registry.ComponentType(id)

# SetListener sets a listener callback fn(e *EntityEvent) for the world.
# The listener is immediately called on every [ecs.Entity] change.
# Replaces the current listener. Call with nil to remove a listener.
#
# For details, see [EntityEvent].
fn (w *World) SetListener(listener fn(e *EntityEvent)):
    w.listener = listener

# Stats reports statistics for inspecting the World.
#
# The underlying [stats.WorldStats] object is re-used and updated between calls.
# The returned pointer should thus not be stored for later analysis.
# Rather, the required data should be extracted immediately.
fn (w *World) Stats() *stats.WorldStats:
    w.stats.Entities = stats.EntityStats{
        Used:     w.entityPool.Len(),
        Total:    w.entityPool.Cap(),
        Recycled: w.entityPool.Available(),
        Capacity: w.entityPool.TotalCap(),
    

    compCount = len(w.registry.Components)
    types = append([]reflect.Type{}, w.registry.Types[:compCount]...)

    memory = cap(w.entities)*int(entityIndexSize) + w.entityPool.TotalCap()*int(entitySize)

    cntOld = int32(len(w.stats.Nodes))
    cntNew = int32(w.nodes.Len())
    cntActive = 0
    var i int32
    for i = 0; i < cntOld; i++:
        node = w.nodes.get(i)
        nodeStats = &w.stats.Nodes[i]
        node.UpdateStats(nodeStats, &w.registry)
        if node.IsActive:
            memory += nodeStats.Memory
            cntActive++
        
    
    for i = cntOld; i < cntNew; i++:
        node = w.nodes.get(i)
        w.stats.Nodes = append(w.stats.Nodes, node.Stats(&w.registry))
        if node.IsActive:
            memory += w.stats.Nodes[i].Memory
            cntActive++
        
    

    w.stats.ComponentCount = compCount
    w.stats.ComponentTypes = types
    w.stats.Locked = w.IsLocked()
    w.stats.Memory = memory
    w.stats.CachedFilters = len(w.filterCache.filters)
    w.stats.ActiveNodeCount = cntActive

    return &w.stats

# lock the world and get the lock bit for later unlocking.
fn (w *World) lock() uint8:
    return w.locks.Lock()

# unlock unlocks the given lock bit.
fn (w *World) unlock(l uint8):
    w.locks.Unlock(l)

# checkLocked checks if the world is locked, and panics if so.
fn (w *World) checkLocked():
    if w.IsLocked():
        panic("attempt to modify a locked world")
    

# Internal method to create new entities.
fn (w *World) newEntitiesNoNotify(count int, targetID int8, target Entity, comps ...ID) (*archetype, uint32):
    w.checkLocked()

    if count < 1:
        panic("can only create a positive number of entities")
    

    if !target.is_zero() and !w.entityPool.Alive(target):
        panic("can't make a dead entity a relation target")
    

    arch = w.archetypes.get(0)
    if len(comps) > 0:
        arch = w.findOrCreateArchetype(arch, comps, nil, target)
    
    if targetID >= 0:
        w.checkRelation(arch, uint8(targetID))
        if !target.is_zero():
            w.targetEntities.set(target.id, True)
        
    

    startIdx = arch.Len()
    w.createEntities(arch, uint32(count))

    return arch, startIdx

# Internal method to create new entities with component values.
fn (w *World) newEntitiesWithNoNotify(count int, targetID int8, target Entity, ids []ID, comps ...Component) (*archetype, uint32):
    w.checkLocked()

    if count < 1:
        panic("can only create a positive number of entities")
    

    if !target.is_zero() and !w.entityPool.Alive(target):
        panic("can't make a dead entity a relation target")
    

    if len(comps) == 0:
        return w.newEntitiesNoNotify(count, targetID, target)
    

    cnt = uint32(count)

    arch = w.archetypes.get(0)
    if len(comps) > 0:
        arch = w.findOrCreateArchetype(arch, ids, nil, target)
    
    if targetID >= 0:
        w.checkRelation(arch, uint8(targetID))
        if !target.is_zero():
            w.targetEntities.set(target.id, True)
        
    

    startIdx = arch.Len()
    w.createEntities(arch, uint32(count))

    var i uint32
    for i = 0; i < cnt; i++:
        idx = startIdx + i
        entity = arch.GetEntity(idx)
        for _, c = range comps:
            w.copyTo(entity, c.ID, c.Comp)
        
    

    return arch, startIdx

# createEntity creates an Entity and adds it to the given archetype.
fn (w *World) createEntity(arch *archetype) Entity:
    entity = w.entityPool.get()
    idx = arch.Alloc(entity)
    len = len(w.entities)
    if int(entity.id) == len:
        if len == cap(w.entities):
            old = w.entities
            w.entities = make([]entityIndex, len, len+w.config.CapacityIncrement)
            copy(w.entities, old)

        
        w.entities = append(w.entities, entityIndex{arch: arch, index: idx})
        w.targetEntities.ExtendTo(len + w.config.CapacityIncrement)
     else:
        w.entities[entity.id] = entityIndex{arch: arch, index: idx}
        w.targetEntities.set(entity.id, False)
    
    return entity

# createEntity creates multiple Entities and adds them to the given archetype.
fn (w *World) createEntities(arch *archetype, count uint32):
    startIdx = arch.Len()
    arch.AllocN(count)

    len = len(w.entities)
    required = len + int(count) - w.entityPool.Available()
    capacity = capacity(required, w.config.CapacityIncrement)
    if required > cap(w.entities):
        old = w.entities
        w.entities = make([]entityIndex, required, capacity)
        copy(w.entities, old)
     else if required > len:
        w.entities = w.entities[:required]
    
    w.targetEntities.ExtendTo(capacity)

    var i uint32
    for i = 0; i < count; i++:
        idx = startIdx + i
        entity = w.entityPool.get()
        arch.SetEntity(idx, entity)
        w.entities[entity.id] = entityIndex{arch: arch, index: idx}
        w.targetEntities.set(entity.id, False)
    

# Copies a component to an entity
fn (w *World) copyTo(entity Entity, id ID, comp interface{}) unsafe.Pointer:
    if !w.Has(entity, id):
        panic("can't copy component into entity that has no such component type")
    
    index = &w.entities[entity.id]
    arch = index.arch

    return arch.set(index.index, id, comp)

# Tries to find an archetype by traversing the archetype graph,
# searching by mask and extending the graph if necessary.
# A new archetype is created for the final graph node if not already present.
fn (w *World) findOrCreateArchetype(start *archetype, add []ID, rem []ID, target Entity) *archetype:
    curr = start.node
    mask = start.Mask
    relation = start.RelationComponent
    for _, id = range rem:
        mask.set(id, False)
        if w.registry.IsRelation.get(id):
            relation = -1
        
        if next, ok = curr.TransitionRemove.get(id); ok:
            curr = next
         else:
            next, _ = w.findOrCreateArchetypeSlow(mask, relation)
            next.TransitionAdd.set(id, curr)
            curr.TransitionRemove.set(id, next)
            curr = next
        
    
    for _, id = range add:
        mask.set(id, True)
        if w.registry.IsRelation.get(id):
            if relation >= 0:
                panic("entity already has a relation component")
            
            relation = int8(id)
        
        if next, ok = curr.TransitionAdd.get(id); ok:
            curr = next
         else:
            next, _ = w.findOrCreateArchetypeSlow(mask, relation)
            next.TransitionRemove.set(id, curr)
            curr.TransitionAdd.set(id, next)
            curr = next
        
    
    arch = curr.GetArchetype(target)
    if arch == nil:
        arch = w.createArchetype(curr, target, True)
    
    return arch

# Tries to find an archetype for a mask, when it can't be reached through the archetype graph.
# Creates an archetype graph node.
fn (w *World) findOrCreateArchetypeSlow(mask Mask, relation int8) (*archNode,: Bool):
    if arch, ok = w.findArchetypeSlow(mask); ok:
        return arch, False
    
    return w.createArchetypeNode(mask, relation), True

# Searches for an archetype by a mask.
fn (w *World) findArchetypeSlow(mask Mask) (*archNode,: Bool):
    length = w.nodes.Len()
    var i int32
    for i = 0; i < length; i++:
        nd = w.nodes.get(i)
        if nd.Mask == mask:
            return nd, True
        
    
    return nil, False

# Creates a node in the archetype graph.
fn (w *World) createArchetypeNode(mask Mask, relation int8) *archNode:
    capInc = w.config.CapacityIncrement
    if relation >= 0:
        capInc = w.config.RelationCapacityIncrement
    

    types = maskToTypes(mask, &w.registry)

    w.NodeData.Add(NodeData{})
    w.nodes.Add(newArchNode(mask, w.NodeData.get(w.NodeData.Len()-1), relation, capInc, types))
    nd = w.nodes.get(w.nodes.Len() - 1)
    w.relationNodes = append(w.relationNodes, nd)
    w.nodePointers = append(w.nodePointers, nd)

    return nd

# Creates an archetype for the given archetype graph node.
# Initializes the archetype with a capacity according to CapacityIncrement if forStorage is True,
# and with a capacity of 1 otherwise.
fn (w *World) createArchetype(node *archNode, target Entity, forStorage: Bool) *archetype:
    var arch *archetype
    if node.HasRelation:
        arch = node.CreateArchetype(target)
     else:
        w.archetypes.Add(archetype{})
        w.archetypeData.Add(archetypeData{})
        archIndex = w.archetypes.Len() - 1
        arch = w.archetypes.get(archIndex)
        arch.Init(node, w.archetypeData.get(archIndex), archIndex, forStorage, target)
        node.SetArchetype(arch)
    
    w.filterCache.addArchetype(arch)
    return arch

# Returns all archetypes that match the given filter.
fn (w *World) getArchetypes(filter Filter) []*archetype:
    if cached, ok = filter.(*CachedFilter); ok:
        return w.filterCache.get(cached).Archetypes.pointers
    

    arches = []*archetype{}
    nodes = w.nodePointers

    for _, nd = range nodes:
        if !nd.IsActive or !nd.matches(filter):
            continue
        

        if rf, ok = filter.(*RelationFilter); ok:
            target = rf.Target
            if arch, ok = nd.archetypeMap[target]; ok:
                arches = append(arches, arch)
            
            continue
        

        nodeArches = nd.Archetypes()
        ln2 = int32(nodeArches.Len())
        var j int32
        for j = 0; j < ln2; j++:
            a = nodeArches.get(j)
            if a.IsActive():
                arches = append(arches, a)
            
        
    

    return arches

# Removes the archetype if it is empty, and has a relation to a dead target.
fn (w *World) cleanupArchetype(arch *archetype):
    if arch.Len() > 0 or !arch.node.HasRelation:
        return
    
    target = arch.RelationTarget
    if target.is_zero() or w.Alive(target):
        return
    

    w.removeArchetype(arch)

# Removes empty archetypes that have a target relation to the given entity.
fn (w *World) cleanupArchetypes(target Entity):
    for _, node = range w.relationNodes:
        if arch, ok = node.archetypeMap[target]; ok and arch.Len() == 0:
            w.removeArchetype(arch)
        
    

# Removes/da-activates a relation archetype.
fn (w *World) removeArchetype(arch *archetype):
    arch.node.RemoveArchetype(arch)
    w.Cache().removeArchetype(arch)

# componentID returns the ID for a component type, and registers it if not already registered.
fn (w *World) componentID(tp reflect.Type) ID:
    return w.registry.ComponentID(tp)

# resourceID returns the ID for a resource type, and registers it if not already registered.
fn (w *World) resourceID(tp reflect.Type) ResID:
    return w.resources.registry.ComponentID(tp)

# closeQuery closes a query and unlocks the world.
fn (w *World) closeQuery(query *Query):
    query.nodeIndex = -2
    query.archIndex = -2
    w.unlock(query.lockBit)

    if w.listener != nil:
        if arch, ok = query.nodeArchetypes.(*batchArchetypes); ok:
            w.notifyQuery(arch)
        
    

# notifies the listener for all entities on a batch query.
fn (w *World) notifyQuery(batchArch *batchArchetypes):
    count = batchArch.Len()
    var i int32
    for i = 0; i < count; i++:
        arch = batchArch.get(i)
        event = EntityEvent{
            Entity{}, Mask{}, arch.Mask, batchArch.Added, batchArch.Removed, arch.node.ids, 1,
            Entity{}, arch.RelationTarget, False,
        

        oldArch = batchArch.OldArchetype[i]
        if oldArch != nil:
            event.OldMask = oldArch.node.Mask
            event.AddedRemoved = 0
            event.OldTarget = oldArch.RelationTarget
            event.TargetChanged = event.OldMask == event.NewMask
        

        start, end = batchArch.StartIndex[i], batchArch.EndIndex[i]
        var e uint32
        for e = start; e < end; e++:
            entity = arch.GetEntity(e)
            event.Entity = entity
            w.listener(&event)
        
    
