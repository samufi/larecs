from collections import Optional, InlineArray


struct StupidDict[KeyType: KeyElement, ValueType: CollectionElement]:
    """A trivial dict implementation.

    This will be deleted once the Dict type is fixed.
    """

    var _data: List[Tuple[KeyType, ValueType]]

    fn __init__(inout self):
        self._data = List[Tuple[KeyType, ValueType]]()

    @always_inline
    fn __getitem__(self, key: KeyType) raises -> ValueType:
        for k_v in self._data:
            if k_v[][0] == key:
                return k_v[][1]
        raise Error("Key not found")

    @always_inline
    fn __contains__(self, key: KeyType) -> Bool:
        for k_v in self._data:
            if k_v[][0] == key:
                return True
        return False

    @always_inline
    fn get(self, key: KeyType) -> Optional[ValueType]:
        for k_v in self._data:
            if k_v[][0] == key:
                return Optional(k_v[][1])
        return Optional[ValueType](None)

    fn __setitem__(inout self, key: KeyType, value: ValueType):
        for k_v in self._data:
            if k_v[][0] == key:
                k_v[][1] = value
                return
        self._data.append(Tuple(key, value))

    @always_inline
    fn __len__(self) -> Int:
        return len(self._data)


struct SimdDict[keyDType: DType, ValueType: CollectionElement, size: Int]:
    """A trivial dict implementation.

    This will be deleted once the Dict type is fixed.
    """

    alias KeyType = SIMD[keyDType, 1]

    var _values: InlineArray[ValueType, size]
    var _keys: SIMD[keyDType, size]
    var _size: Int

    fn __init__(inout self):
        self._values = InlineArray[ValueType, size](unsafe_uninitialized=True)
        self._keys = SIMD[keyDType, size]()
        self._size = 0

    @always_inline
    fn __getitem__(self, key: Self.KeyType) raises -> ValueType:
        for i in range(self._size):
            if self._keys[i] == key:
                return self._values[i]
        raise Error("Key not found")

    @always_inline
    fn __contains__(self, key: Self.KeyType) -> Bool:
        return key in self._keys

    @always_inline
    fn get(self, key: Self.KeyType) -> Optional[ValueType]:
        for i in range(self._size):
            if self._keys[i] == key:
                return Optional(self._values[i])
        return Optional[ValueType](None)

    fn __setitem__(inout self, key: Self.KeyType, value: ValueType) raises:
        for i in range(self._size):
            if self._keys[i] == key:
                self._values[i] = value
                return
        if self._size >= size:
            raise Error("Dict is full.")
        self._keys[self._size] = key
        self._values[self._size] = value
        self._size += 1

    @always_inline
    fn __len__(self) -> Int:
        return self._size
