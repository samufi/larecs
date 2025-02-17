from collections import Dict, Optional, InlineArray
from memory import memcpy, OwnedPointer, UnsafePointer
from sys.info import sizeof

from .bitmask import BitMask
from .types import get_max_size

alias ResId = UInt


trait Resource(CollectionElement):
    alias ID: ResourceId


@value
@register_passable("trivial")
struct _DummyResource(Resource):
    alias ID = ResourceId("larecs/resources/_DummyResource")


@register_passable("trivial")
struct ResourceId(KeyElement):
    var _id: UInt

    fn id(self) -> UInt:
        return self._id

    fn __init__(out self, name: String):
        self._id = name.__hash__()

    fn __eq__(self, other: Self) -> Bool:
        return self._id == other._id

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn __hash__(self) -> UInt:
        return self._id


struct _ResourceWrapper[T: Resource](Movable):
    var _pointer: OwnedPointer[T]

    fn __init__(out self, owned resource: T):
        self._pointer = OwnedPointer(resource^)

    fn __moveinit__(out self, owned existing: Self):
        self._pointer = existing._pointer^

    fn get(ref self) -> Pointer[T, __origin_of(self)]:
        return Pointer[T, __origin_of(self)].address_of(
            self._pointer.unsafe_ptr()[]
        )


struct Resources:
    alias wrapper_size = sizeof[_ResourceWrapper[_DummyResource]]()
    alias destructor = fn () escaping

    alias dType = BitMask.IndexDType
    """The DType of the component ids."""
    alias size = get_max_size[Self.dType]()
    """The maximum number of resouces. An interim solution for simplicity."""

    var _lookup: Dict[ResourceId, ResId]
    var _data: UnsafePointer[UInt8]
    var _destructors: List[Self.destructor]
    var _initialized_flags: InlineArray[Bool, max(Self.size, 1)]

    fn __init__(out self):
        self._lookup = Dict[ResourceId, ResId]()
        self._data = UnsafePointer[UInt8].alloc(Self.size * Self.wrapper_size)
        self._destructors = List[Self.destructor]()
        self._initialized_flags = InlineArray[Bool, max(Self.size, 1)](False)

    fn __len__(self) -> Int:
        return len(self._lookup)

    fn __del__(owned self):
        for i in range(len(self)):
            if self._initialized_flags[i]:
                self._destructors[i]()

        self._data.free()
        # TODO: anything else?

    fn add[T: Resource](mut self, owned resource: T) raises:
        id_new = self._get_or_register_id[T]()
        id = id_new[0]
        is_new = id_new[1]

        if not is_new:
            raise Error(
                "resource is already present. replacing resources is not yet"
                " supported"
            )

        wrapper = _ResourceWrapper(resource^)
        unsafe_ptr = UnsafePointer[_ResourceWrapper[T]]().alloc(1)
        unsafe_ptr.init_pointee_move(wrapper^)

        memcpy(
            self._get_unsafe_ptr(id),
            unsafe_ptr.bitcast[UInt8](),
            index(Self.wrapper_size),
        )
        ptr = self._get_ptr[T](id)

        fn destructor() escaping:
            ptr[]._pointer[].__del__()

        self._destructors.append(destructor)
        self._initialized_flags[id] = True

    fn get_ptr[T: Resource](ref self) raises -> Pointer[T, __origin_of(self)]:
        id = self._get_id[T]()
        if not self._initialized_flags[id]:
            raise Error("can't get resource {}: not initialized".format(id))

        wrapper = (self._data + id * Self.wrapper_size).bitcast[
            _ResourceWrapper[T]
        ]()
        return Pointer[T, __origin_of(self)].address_of(
            wrapper[]._pointer.unsafe_ptr()[]
        )

    fn has[T: Resource](self) raises -> Bool:
        id = self._get_id[T]()
        return self._initialized_flags[id]

    fn remove[T: Resource](mut self) raises:
        id = self._get_id[T]()
        if not self._initialized_flags[id]:
            raise Error("can't remove resource {}: not initialized".format(id))

        self._destructors[id]()
        self._initialized_flags[id] = False
        self._get_ptr[T](id).__del__()

    fn _get_id[T: Resource](self) raises -> ResId:
        if T.ID in self._lookup:
            return self._lookup.get(T.ID).value()
        raise Error("resource not found")

    fn _get_or_register_id[T: Resource](mut self) raises -> (ResId, Bool):
        if T.ID in self._lookup:
            return self._lookup.get(T.ID).value(), False
        return self._register[T](), True

    fn _register[T: Resource](mut self) raises -> ResId:
        if len(self._lookup) >= Self.size:
            raise Error(
                String("Ran out of the capacity of {} resources").format(
                    Self.size
                )
            )
        var id = ResId(len(self._lookup))
        self._lookup[T.ID] = id
        return id

    @always_inline
    fn _get_ptr[
        T: Resource
    ](ref self, id: ResId) raises -> Pointer[
        _ResourceWrapper[T], __origin_of(self)
    ]:
        return Pointer[_ResourceWrapper[T], __origin_of(self)].address_of(
            (self._data + id * Self.wrapper_size).bitcast[
                _ResourceWrapper[T]
            ]()[]
        )

    @always_inline
    fn _get_unsafe_ptr(self, id: ResId) -> UnsafePointer[UInt8]:
        return self._data + id * Self.wrapper_size
