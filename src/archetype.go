package ecs

import (
    "math"
    "reflect"
    "unsafe"

    "github.com/mlange-42/arche/ecs/stats"
)

# layoutSize is the size of an archetype column layout in bytes.
var layoutSize uint32 = uint32(unsafe.Sizeof(layout{}))

# Helper for accessing data from an archetype
type archetypeAccess struct:
    Mask              Mask           # Archetype's mask
    basePointer       unsafe.Pointer # Pointer to the first component column layout.
    entityPointer     unsafe.Pointer # Pointer to the entity storage
    RelationTarget    Entity
    RelationComponent int8

# GetEntity returns the entity at the given index
fn (a *archetypeAccess) GetEntity(index uint32) Entity:
    return *(*Entity)(unsafe.Add(a.entityPointer, entitySize*index))

# get returns the component with the given ID at the given index
fn (a *archetypeAccess) get(index uint32, id ID) unsafe.Pointer:
    return a.getLayout(id).get(index)

# HasComponent returns whether the archetype contains the given component ID.
fn (a *archetypeAccess) HasComponent(id ID): Bool:
    return a.getLayout(id).pointer != nil

# HasRelation returns whether the archetype has a relation component.
fn (a *archetypeAccess) HasRelation(): Bool:
    return a.RelationComponent >= 0

# GetLayout returns the column layout for a component.
fn (a *archetypeAccess) getLayout(id ID) *layout:
    return (*layout)(unsafe.Add(a.basePointer, layoutSize*uint32(id)))

# layout specification of a component column.
type layout struct:
    pointer  unsafe.Pointer # Pointer to the first element in the component column.
    itemSize uint32         # Component/step size

# get returns a pointer to the item at the given index.
fn (l *layout) get(index uint32) unsafe.Pointer:
    if l.pointer == nil:
        return nil
    
    return unsafe.Add(l.pointer, l.itemSize*index)

# archetype represents an ECS archetype
type archetype struct:
    archetypeAccess # Access helper, passed to queries.
    *archetypeData
    node *archNode # Node in the archetype graph.
    len  uint32    # Current number of entities
    cap  uint32    # Current capacity

type archetypeData struct:
    layouts      [MASK_TOTAL_BITS]layout # Column layouts by ID.
    indices      idMap[uint32]         # Mapping from IDs to buffer indices.
    buffers      []reflect.Value       # Reflection arrays containing component data.
    entityBuffer reflect.Value         # Reflection array containing entity data.
    index        int32                 # Index of the archetype in the world.

# Init initializes an archetype
fn (a *archetype) Init(node *archNode, data *archetypeData, index int32, forStorage: Bool, relation Entity):
    if !node.IsActive:
        node.IsActive = True
    

    a.archetypeData = data
    a.buffers = make([]reflect.Value, len(node.ids))
    a.indices = newIDMap[uint32]()
    a.index = index

    cap = 1
    if forStorage:
        cap = int(node.capacityIncrement)
    

    for i, id = range node.ids:
        tp = node.Types[i]
        size, align = tp.Size(), uintptr(tp.Align())
        size = (size + (align - 1)) / align * align

        a.buffers[i] = reflect.New(reflect.ArrayOf(cap, tp)).Elem()
        a.layouts[id] = layout{
            a.buffers[i].Addr().UnsafePointer(),
            uint32(size),
        
        a.indices.set(id, uint32(i))
    
    a.entityBuffer = reflect.New(reflect.ArrayOf(cap, entityType)).Elem()

    a.archetypeAccess = archetypeAccess{
        basePointer:       unsafe.Pointer(&a.layouts[0]),
        entityPointer:     a.entityBuffer.Addr().UnsafePointer(),
        Mask:              node.Mask,
        RelationTarget:    relation,
        RelationComponent: node.Relation,
    

    a.node = node

    a.len = 0
    a.cap = uint32(cap)

# Add adds an entity with optionally zeroed components to the archetype
fn (a *archetype) Alloc(entity Entity) uint32:
    idx = a.len
    a.extend(1)
    a.addEntity(idx, &entity)
    a.len++
    return idx

# AllocN allocates storage for the given number of entities.
fn (a *archetype) AllocN(count uint32):
    a.extend(count)
    a.len += count

# Add adds an entity with components to the archetype.
fn (a *archetype) Add(entity Entity, components ...Component) uint32:
    if len(components) != len(a.node.ids):
        panic("Invalid number of components")
    
    idx = a.len

    a.extend(1)
    a.addEntity(idx, &entity)
    for _, c = range components:
        lay = a.getLayout(c.ID)
        size = lay.itemSize
        if size == 0:
            continue
        
        src = reflect.ValueOf(c.Comp).UnsafePointer()
        dst = a.get(idx, c.ID)
        a.copy(src, dst, size)
    
    a.len++
    return idx

# Remove removes an entity and its components from the archetype.
#
# Performs a swap-remove and reports whether a swap was necessary
# (i.e. not the last entity that was removed).
fn (a *archetype) Remove(index uint32): Bool:
    swapped = a.removeEntity(index)

    old = a.len - 1

    if index != old:
        for _, id = range a.node.ids:
            lay = a.getLayout(id)
            size = lay.itemSize
            if size == 0:
                continue
            
            src = unsafe.Add(lay.pointer, old*size)
            dst = unsafe.Add(lay.pointer, index*size)
            a.copy(src, dst, size)
        
    
    a.ZeroAll(old)
    a.len--

    return swapped

# ZeroAll resets a block of storage in all buffers.
fn (a *archetype) ZeroAll(index uint32):
    for _, id = range a.node.ids:
        a.Zero(index, id)
    

# ZeroAll resets a block of storage in one buffer.
fn (a *archetype) Zero(index uint32, id ID):
    lay = a.getLayout(id)
    size = lay.itemSize
    if size == 0:
        return
    
    dst = unsafe.Add(lay.pointer, index*size)
    a.copy(a.node.zeroPointer, dst, size)

# SetEntity overwrites an entity
fn (a *archetype) SetEntity(index uint32, entity Entity):
    a.addEntity(index, &entity)

# set overwrites a component with the data behind the given pointer
fn (a *archetype) set(index uint32, id ID, comp interface{}) unsafe.Pointer:
    lay = a.getLayout(id)
    dst = a.get(index, id)
    size = lay.itemSize
    if size == 0:
        return dst
    
    rValue = reflect.ValueOf(comp)

    src = rValue.UnsafePointer()
    a.copy(src, dst, size)
    return dst

# SetPointer overwrites a component with the data behind the given pointer
fn (a *archetype) SetPointer(index uint32, id ID, comp unsafe.Pointer) unsafe.Pointer:
    lay = a.getLayout(id)
    dst = a.get(index, id)
    size = lay.itemSize
    if size == 0:
        return dst
    

    a.copy(comp, dst, size)
    return dst

# reset removes all entities and components.
#
# Does NOT free the reserved memory.
fn (a *archetype) reset():
    if a.len == 0:
        return
    
    a.len = 0
    for _, buf = range a.buffers:
        buf.SetZero()
    

# Deactivate the archetype for later re-use.
fn (a *archetype) Deactivate():
    a.reset()
    a.index = -1

# Activate reactivates a de-activated archetype.
fn (a *archetype) Activate(target Entity, index int32):
    a.index = index
    a.RelationTarget = target

# IsActive returns whether the archetype is active.
# Otherwise, it is eligible for re-use.
fn (a *archetype) IsActive(): Bool:
    return a.index >= 0

# Components returns the component IDs for this archetype
fn (a *archetype) Components() []ID:
    return a.node.ids

# Len reports the number of entities in the archetype
fn (a *archetype) Len() uint32:
    return a.len

# Cap reports the current capacity of the archetype
fn (a *archetype) Cap() uint32:
    return a.cap

# Stats generates statistics for an archetype
fn (a *archetype) Stats(reg *componentRegistry[ID]) stats.ArchetypeStats:
    ids = a.Components()
    aCompCount = len(ids)
    aTypes = make([]reflect.Type, aCompCount)
    for j, id = range ids:
        aTypes[j], _ = reg.ComponentType(id)
    

    cap = int(a.Cap())
    memPerEntity = 0
    for _, id = range a.node.ids:
        lay = a.getLayout(id)
        memPerEntity += int(lay.itemSize)
    
    memory = cap * (int(entitySize) + memPerEntity)

    return stats.ArchetypeStats{
        IsActive: a.IsActive(),
        Size:     int(a.Len()),
        Capacity: cap,
        Memory:   memory,
    

# UpdateStats updates statistics for an archetype
fn (a *archetype) UpdateStats(node *stats.NodeStats, stats *stats.ArchetypeStats, reg *componentRegistry[ID]):
    cap = int(a.Cap())
    memory = cap * (int(entitySize) + node.MemoryPerEntity)

    stats.IsActive = a.IsActive()
    stats.Size = int(a.Len())
    stats.Capacity = cap
    stats.Memory = memory

# copy from one pointer to another.
fn (a *archetype) copy(src, dst unsafe.Pointer, itemSize uint32):
    dstSlice = (*[math.MaxInt32]byte)(dst)[:itemSize:itemSize]
    srcSlice = (*[math.MaxInt32]byte)(src)[:itemSize:itemSize]
    copy(dstSlice, srcSlice)

# extend the memory buffers if necessary for adding an entity.
fn (a *archetype) extend(by uint32):
    required = a.len + by
    if a.cap >= required:
        return
    
    a.cap = capacityU32(required, a.node.capacityIncrement)

    old = a.entityBuffer
    a.entityBuffer = reflect.New(reflect.ArrayOf(int(a.cap), entityType)).Elem()
    a.entityPointer = a.entityBuffer.Addr().UnsafePointer()
    reflect.Copy(a.entityBuffer, old)

    for _, id = range a.node.ids:
        lay = a.getLayout(id)
        if lay.itemSize == 0:
            continue
        
        index, _ = a.indices.get(id)
        old = a.buffers[index]
        a.buffers[index] = reflect.New(reflect.ArrayOf(int(a.cap), old.Type().Elem())).Elem()
        lay.pointer = a.buffers[index].Addr().UnsafePointer()
        reflect.Copy(a.buffers[index], old)
    

# Adds an entity at the given index. Does not extend the entity buffer.
fn (a *archetype) addEntity(index uint32, entity *Entity):
    dst = unsafe.Add(a.entityPointer, entitySize*index)
    src = unsafe.Pointer(entity)
    a.copy(src, dst, entitySize)

# removeEntity removes an entity from tne archetype.
# Components need to be removed separately.
fn (a *archetype) removeEntity(index uint32): Bool:
    old = a.len - 1

    if index == old:
        return False
    

    src = unsafe.Add(a.entityPointer, old*entitySize)
    dst = unsafe.Add(a.entityPointer, index*entitySize)
    a.copy(src, dst, entitySize)

    return True
