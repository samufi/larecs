from bit import pop_count, bit_width
from bitmask import BitMask
from collections import Optional
from hashlib._ahash import AHasher

struct BitMaskLookup[ValueType: CollectionElement]:
    var _keys: List[BitMask]
    var _key_hashes: List[UInt16]
    var _values: List[ValueType]
    var _slot_to_index: List[UInt16]
    var _count: Int
    var _capacity: Int

    fn __init__(inout self, capacity: Int = 16):
        self._count = 0
        if capacity <= 8:
            self._capacity = 8
        else:
            var icapacity = Int64(capacity)
            self._capacity = capacity if pop_count(icapacity) == 1 else
                            1 << int(bit_width(icapacity))
        self._keys = List[BitMask]()
        self._key_hashes = List[UInt16](0) * self._capacity
        self._values = List[ValueType]()
        self._slot_to_index = List[UInt16](0) * self._capacity
        
    fn __copyinit__(inout self, existing: Self):
        self._count = existing._count
        self._capacity = existing._capacity
        self._keys = existing._keys
        self._key_hashes = existing._key_hashes
        self._values = existing._values
        self._slot_to_index = existing._slot_to_index

    fn __moveinit__(inout self, owned existing: Self):
        self._count = existing._count
        self._capacity = existing._capacity
        self._keys = existing._keys^
        self._key_hashes = existing._key_hashes^
        self._values = existing._values^
        self._slot_to_index = existing._slot_to_index^

    fn __len__(self) -> Int:
        return self._count

    @always_inline
    fn __getitem__(self, key: BitMask) raises -> ValueType:
        var key_index = self._find_key_index(key)
        if key_index == 0:
            raise Error("Key not found")

        return self._values[key_index - 1]

    @always_inline
    fn __contains__(self, key: BitMask) -> Bool:
        return self._find_key_index(key) != 0

    fn __setitem__(inout self, key: BitMask, value: ValueType):
        if self._count / self._capacity >= 0.87:
            self._rehash()
        
        var key_hash = _hash(key)
        var modulo_mask = self._capacity - 1
        var slot = int(key_hash & modulo_mask)
        while True:
            var key_index = int(self._slot_to_index[slot])
            if key_index == 0:
                self._keys.append(key)
                self._key_hashes[slot] = key_hash
                self._values.append(value)
                self._count += 1
                self._slot_to_index[slot] = UInt16(len(self._keys))
                return
            
            var other_key_hash = self._key_hashes[slot]
            if other_key_hash == key_hash:
                var other_key = self._keys[key_index - 1]
                if other_key == key:
                    self._values[key_index - 1] = value # replace value
                    return
            
            slot = (slot + 1) & modulo_mask

    @always_inline
    fn _find_key_index(self, key: BitMask) -> Int:
        var key_hash = _hash(key)
        var modulo_mask = self._capacity - 1

        var slot = int(key_hash & modulo_mask)
        while True:
            var key_index = int(self._slot_to_index[slot])
            if key_index == 0:
                return key_index
            
            var other_key_hash = self._key_hashes[slot]
            if key_hash == other_key_hash:
                var other_key = self._keys[key_index - 1]
                if other_key == key:
                    return key_index
            
            slot = (slot + 1) & modulo_mask

    @always_inline
    fn _rehash(inout self):
        var old_slot_to_index = self._slot_to_index
        var old_capacity = self._capacity
        self._capacity <<= 1
        self._slot_to_index = List[UInt16](0) * self._capacity
        
        var key_hashes = self._key_hashes
        key_hashes = List[UInt16]() * self._capacity
            
        var modulo_mask = self._capacity - 1
        for i in range(old_capacity):
            if old_slot_to_index[i] == 0:
                continue
            var key_hash = self._key_hashes[i]

            var slot = int(key_hash & modulo_mask)

            while True:
                var key_index = self._slot_to_index[slot]

                if key_index == 0:
                    self._slot_to_index[slot] = old_slot_to_index[i]
                    break
                else:
                    slot = (slot + 1) & modulo_mask

            key_hashes[slot] = key_hash  
        
        self._key_hashes = key_hashes

@always_inline
fn _hash(key: BitMask) -> UInt16:
    var hasher = AHasher[0]()
    hasher._update_with_simd(key._bytes)
    return hasher^.finish().cast[DType.uint16]()