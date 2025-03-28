from memory import UnsafePointer
from sys.info import sizeof


fn _destructor[T: CollectionElement](box: UnsafeBox.data_type):
    box.bitcast[T]().destroy_pointee()
    box.free()


fn _dummy_destructor(box: UnsafeBox.data_type):
    # No-op destructor
    pass


fn _copy_initializer[
    T: CollectionElement
](existing_box: UnsafeBox.data_type) -> UnsafePointer[Byte]:
    ptr = UnsafePointer[T].alloc(1)
    ptr.init_pointee_copy(existing_box.bitcast[T]()[])
    return ptr.bitcast[Byte]()


fn _dummy_copy_initializer(
    existing_box: UnsafeBox.data_type,
) -> UnsafePointer[Byte]:
    # No-op copy initializer
    return UnsafePointer[Byte]()


struct UnsafeBox(CollectionElement):
    alias data_type = UnsafePointer[Byte]
    var _data: Self.data_type
    var _destructor: fn (self: Self.data_type)
    var _copy_initializer: fn (
        existing_box: UnsafeBox.data_type
    ) -> UnsafePointer[Byte]

    fn __init__[used_internally: Bool = False](out self):
        constrained[
            used_internally,
            "This constructor is meant for internal use only.",
        ]()
        self._data = UnsafePointer[Byte]()

        self._destructor = _dummy_destructor

        self._copy_initializer = _dummy_copy_initializer

    fn __init__[T: CollectionElement](out self, owned data: T):
        ptr = UnsafePointer[T].alloc(1)
        self._data = ptr.bitcast[Byte]()
        ptr.init_pointee_move(data^)
        self._destructor = _destructor[T]
        self._copy_initializer = _copy_initializer[T]

    fn __moveinit__(out self, owned other: Self):
        self._data = other._data
        self._destructor = other._destructor
        self._copy_initializer = other._copy_initializer

    fn __copyinit__(out self, other: Self):
        self = Self.__init__[used_internally=True]()
        self._data = other._copy_initializer(other._data)
        self._destructor = other._destructor
        self._copy_initializer = other._copy_initializer

    @always_inline
    fn unsafe_get_ptr[
        T: CollectionElement
    ](ref self) -> Pointer[T, __origin_of(self._data)]:
        return Pointer[T, __origin_of(self._data)].address_of(
            self._data.bitcast[T]()[]
        )

    fn __del__(owned self):
        self._destructor(self._data)

    @always_inline
    fn unsafe_get[mut: Bool, //, T: CollectionElement, origin: Origin[mut]](ref [origin] self) -> ref [self._data] T:
        return self.unsafe_get_ptr[T]()[]
