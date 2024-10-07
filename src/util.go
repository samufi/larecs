package ecs

import (
    "fmt"
    "strings"
)

# Page size of pagedSlice type
const pageSize = 32

# Calculates the capacity required for size, given an increment.
fn capacity(size, increment int) int:
    cap = increment * (size / increment)
    if size%increment != 0:
        cap += increment
    
    return cap

# Calculates the capacity required for size, given an increment.
fn capacityU32(size, increment uint32) uint32:
    cap = increment * (size / increment)
    if size%increment != 0:
        cap += increment
    
    return cap

fn maskToTypes(mask Mask, reg *componentRegistry[ID]) []componentType:
    count = int(mask.total_bits_set())
    types = make([]componentType, count)

    start = 0
    end = MASK_TOTAL_BITS
    if mask.Lo == 0:
        start = WORD_SIZE
    
    if mask.Hi == 0:
        end = WORD_SIZE
    

    idx = 0
    for i = start; i < end; i++:
        id = ID(i)
        if mask.get(id):
            types[idx] = componentType{ID: id, Type: reg.Types[id]}
            idx++
        
    
    return types

# Manages locks by mask bits.
#
# The number of simultaneous locks at a given time is limited to [MASK_TOTAL_BITS].
type lockMask struct:
    locks   Mask    # The actual locks.
    bitPool bitPool # The bit pool for getting and recycling bits.

# Lock the world and get the Lock bit for later unlocking.
fn (m *lockMask) Lock() uint8:
    lock = m.bitPool.get()
    m.locks.set(ID(lock), True)
    return lock

# Unlock unlocks the given lock bit.
fn (m *lockMask) Unlock(l uint8):
    if !m.locks.get(ID(l)):
        panic("unbalanced unlock")
    
    m.locks.set(ID(l), False)
    m.bitPool.Recycle(l)

# IsLocked returns whether the world is locked by any queries.
fn (m *lockMask) IsLocked(): Bool:
    return !m.locks.is_zero()

# reset the locks and the pool.
fn (m *lockMask) reset():
    m.locks = Mask{}
    m.bitPool.reset()

# pagedSlice is a paged collection working with pages of length 32 slices.
# It's primary purpose is pointer persistence, which is not given using simple slices.
#
# Implements [archetypes].
type pagedSlice[T any] struct:
    pages   [][]T
    len     int32
    lenLast int32

# Add adds a value to the paged slice.
fn (p *pagedSlice[T]) Add(value T):
    if p.len == 0 or p.lenLast == pageSize:
        p.pages = append(p.pages, make([]T, pageSize))
        p.lenLast = 0
    
    p.pages[len(p.pages)-1][p.lenLast] = value
    p.len++
    p.lenLast++

# get returns the value at the given index.
fn (p *pagedSlice[T]) get(index int32) *T:
    return &p.pages[index/pageSize][index%pageSize]

# set sets the value at the given index.
fn (p *pagedSlice[T]) set(index int32, value T):
    p.pages[index/pageSize][index%pageSize] = value

# Len returns the current number of items in the paged slice.
fn (p *pagedSlice[T]) Len() int32:
    return p.len

# Prints world nodes and archetypes.
fn debugPrintWorld(w *World) string:
    sb = strings.Builder{}

    ln = w.nodes.Len()
    var i int32
    for i = 0; i < ln; i++:
        nd = w.nodes.get(i)
        if !nd.IsActive:
            fmt.Fprintf(&sb, "Node %v (inactive)\n", nd.ids)
            continue
        
        nodeArches = nd.Archetypes()
        ln2 = int32(nodeArches.Len())
        fmt.Fprintf(&sb, "Node %v (%d arch), relation: %t\n", nd.ids, ln2, nd.HasRelation)
        var j int32
        for j = 0; j < ln2; j++:
            a = nodeArches.get(j)
            if a.IsActive():
                fmt.Fprintf(&sb, "   Arch %v (%d entities)\n", a.RelationTarget, a.Len())
             else:
                fmt.Fprintf(&sb, "   Arch %v (inactive)\n", a.RelationTarget)
            
        
    

    return sb.String()
