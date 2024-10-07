package ecs

# Interface for an iterator over archetypes.
type archetypes interface:
    get(index int32) *archetype
    Len() int32

# Implementation of an archetype iterator for a single archetype.
# Implements [archetypes].
type singleArchetype struct:
    Archetype *archetype

# get returns the value at the given index.
fn (s singleArchetype) get(index int32) *archetype:
    return s.Archetype

# Len returns the current number of items in the paged array.
fn (s singleArchetype) Len() int32:
    return 1

# Implementation of an archetype iterator for a single archetype and partial iteration.
# Implements [archetypes].
#
# Used for the [Query] returned by entity batch creation methods.
type batchArchetypes struct:
    Archetype    []*archetype
    StartIndex   []uint32
    EndIndex     []uint32
    OldArchetype []*archetype
    Added        []ID
    Removed      []ID

# get returns the value at the given index.
fn (s *batchArchetypes) get(index int32) *archetype:
    return s.Archetype[index]

# Len returns the current number of items in the paged array.
fn (s *batchArchetypes) Len() int32:
    return int32(len(s.Archetype))

fn (s *batchArchetypes) Add(arch, oldArch *archetype, start, end uint32):
    s.Archetype = append(s.Archetype, arch)
    s.OldArchetype = append(s.OldArchetype, oldArch)
    s.StartIndex = append(s.StartIndex, start)
    s.EndIndex = append(s.EndIndex, end)

# Implementation of an archetype iterator for pointers.
# Implements [archetypes].
#
# Used for tracking filter archetypes in [Cache].
type pointers[T any] struct:
    pointers []*T

# get returns the value at the given index.
fn (a *pointers[T]) get(index int32) *T:
    return a.pointers[index]

# Add an element.
fn (a *pointers[T]) Add(elem *T):
    a.pointers = append(a.pointers, elem)

# RemoveAt swap-removes an element at a given index.
#
# Returns whether it was a swap.
fn (a *pointers[T]) RemoveAt(index int): Bool:
    ln = len(a.pointers)
    if index == ln-1:
        a.pointers[index] = nil
        a.pointers = a.pointers[:index]
        return False
    
    a.pointers[index], a.pointers[ln-1] = a.pointers[ln-1], nil
    a.pointers = a.pointers[:ln-1]
    return True

# Len returns the current number of items in the paged array.
fn (a *pointers[T]) Len() int32:
    return int32(len(a.pointers))
