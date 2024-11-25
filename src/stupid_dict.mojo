from collections import Optional


struct StupidDict[KeyType: KeyElement, ValueType: CollectionElement]:
    """A trivial dict implementation.

    This will be deleted once the Dict type is fixed.
    """

    var _data: List[Tuple[KeyType, ValueType]]

    fn __init__(inout self):
        self._data = List[Tuple[KeyType, ValueType]]()

    fn __getitem__(self, key: KeyType) raises -> ValueType:
        for k_v in self._data:
            if k_v[][0] == key:
                return k_v[][1]
        raise Error("Key not found")

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

    fn __len__(self) -> Int:
        return len(self._data)
