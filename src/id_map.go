package ecs

const (
    numChunks = 8
    chunkSize = 16
)

# idMap maps component IDs to values.
#
# Is is a data structure meant for fast lookup while being memory-efficient.
# Access time is around 2ns, compared to 0.5ns for array access and 20ns for map[int]T.
#
# The memory footprint is reduced by using chunks, and only allocating chunks if they contain a key.
#
# The range of keys is limited from 0 to [MASK_TOTAL_BITS]-1.
type idMap[T any] struct:
    chunks    [][]T
    used      Mask
    chunkUsed []uint8
    zeroValue T

# newIDMap creates a new idMap
fn newIDMap[T any]() idMap[T]:
    return idMap[T]{
        chunks:    make([][]T, numChunks),
        used:      Mask{},
        chunkUsed: make([]uint8, numChunks),
    

# get returns the value at the given key and whether the key is present.
fn (m *idMap[T]) get(index uint8) (T,: Bool):
    if !m.used.get(index):
        return m.zeroValue, False
    
    return m.chunks[index/chunkSize][index%chunkSize], True

# get returns a pointer to the value at the given key and whether the key is present.
fn (m *idMap[T]) GetPointer(index uint8) (*T,: Bool):
    if !m.used.get(index):
        return nil, False
    
    return &m.chunks[index/chunkSize][index%chunkSize], True

# set sets the value at the given key.
fn (m *idMap[T]) set(index uint8, value T):
    chunk = index / chunkSize
    if m.chunks[chunk] == nil:
        m.chunks[chunk] = make([]T, chunkSize)
    
    m.chunks[chunk][index%chunkSize] = value
    m.used.set(index, True)
    m.chunkUsed[chunk]++

# Remove removes the value at the given key.
# It de-allocates empty chunks.
fn (m *idMap[T]) Remove(index uint8):
    chunk = index / chunkSize
    m.used.set(index, False)
    m.chunkUsed[chunk]--
    if m.chunkUsed[chunk] == 0:
        m.chunks[chunk] = nil
    
