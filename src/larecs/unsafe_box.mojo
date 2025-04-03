from memory import UnsafePointer
from sys.info import sizeof


fn _destructor[T: CollectionElement](box_storage: UnsafeBox.data_type):
    """
    Destructor for the UnsafeBox.

    It destroys the pointee and frees the memory associated with the box.

    Parameters:
        T: The type of the element stored in the UnsafeBox.

    Args:
        box_storage: The UnsafeBox.data_type instance to be destroyed.
    """
    box_storage.bitcast[T]().destroy_pointee()
    box_storage.free()


fn _dummy_destructor(box: UnsafeBox.data_type):
    """
    No-op destructor for the UnsafeBox.

    Args:
        box: The UnsafeBox.data_type instance to be destroyed.
             Note, this will not be touched here.
    """
    pass


fn _copy_initializer[
    T: CollectionElement
](existing_box: UnsafeBox.data_type) -> UnsafePointer[Byte]:
    """
    Copy initializer for the data in the UnsafeBox.

    It creates a new pointer to the data and initializes it with the
    existing data.

    Parameters:
        T: The type of the element stored in the UnsafeBox.

    Args:
        existing_box: The UnsafeBox.data_type instance to be copied.

    Returns:
        A pointer to the newly allocated data.
    """

    @parameter
    if sizeof[T]() == 0:
        ptr = UnsafePointer[T]()
    else:
        ptr = UnsafePointer[T].alloc(1)
        ptr.init_pointee_copy(existing_box.bitcast[T]()[])

    return ptr.bitcast[Byte]()


fn _dummy_copy_initializer(
    existing_box: UnsafeBox.data_type,
) -> UnsafePointer[Byte]:
    """
    No-op copy initializer for the data in the UnsafeBox.

    Returns a dummy pointer.

    Args:
        existing_box: The UnsafeBox.data_type instance to be copied.

    Returns:
        A null pointer.
    """
    return UnsafePointer[Byte]()


struct UnsafeBox(CollectionElement):
    """
    A box that can hold a single value without knowing its type at compile time.

    This is useful for generic programming, where the type of the value
    is not known until runtime.

    Note: This is an unsafe feature. Retrieving the value from the box
    requires knowing the type of the value stored in the box. If the
    wrong type is used, it can lead to undefined behavior.
    """

    alias data_type = UnsafePointer[Byte]
    """The type of the data stored in the box."""

    var _data: Self.data_type
    var _destructor: fn (self: Self.data_type)
    var _copy_initializer: fn (
        existing_box: UnsafeBox.data_type
    ) -> UnsafePointer[Byte]

    fn __init__[used_internally: Bool = False](out self):
        """
        Trivial constructor for the UnsafeBox used only internally.

        Parameters:
            used_internally: A flag indicating whether this constructor
                is used internally.

        Constraints:
            `used_internally` must be `True` to use this constructor.
        """
        constrained[
            used_internally,
            "This constructor is meant for internal use only.",
        ]()
        self._data = UnsafePointer[Byte]()
        self._destructor = _dummy_destructor
        self._copy_initializer = _dummy_copy_initializer

    fn __init__[T: CollectionElement](out self, owned data: T):
        """
        Constructor for the UnsafeBox.

        Parameters:
            T: The type of the element stored in the UnsafeBox.

        Args:
            data: The value to be stored in the box.
        """

        @parameter
        if sizeof[T]() == 0:
            ptr = UnsafePointer[T]()
        else:
            ptr = UnsafePointer[T].alloc(1)
            ptr.init_pointee_move(data^)

        self._data = ptr.bitcast[Byte]()
        self._destructor = _destructor[T]
        self._copy_initializer = _copy_initializer[T]

    fn __moveinit__(out self, owned other: Self):
        """
        Move constructor for the UnsafeBox.

        Args:
            other: The UnsafeBox instance to be moved from.
        """
        self._data = other._data
        self._destructor = other._destructor
        self._copy_initializer = other._copy_initializer

    fn __copyinit__(out self, other: Self):
        """
        Copy constructor for the UnsafeBox.

        Args:
            other: The UnsafeBox instance to be copied from.
        """
        self = Self.__init__[used_internally=True]()
        self._data = other._copy_initializer(other._data)
        self._destructor = other._destructor
        self._copy_initializer = other._copy_initializer

    @always_inline
    fn __del__(owned self):
        """
        Destructor for the UnsafeBox.

        It destroys the data stored in the box and frees the memory
        associated with the box.
        """
        self._destructor(self._data)

    @always_inline
    fn unsafe_get_ptr[
        T: CollectionElement
    ](ref self) -> Pointer[T, __origin_of(self._data)]:
        """
        Returns a pointer to the data stored in the box.

        Parameters:
            T: The type of the element stored in the UnsafeBox.

        Returns:
            A pointer to the data stored in the box.
        """
        return Pointer[T, __origin_of(self._data)].address_of(
            self._data.bitcast[T]()[]
        )

    @always_inline
    fn unsafe_get[T: CollectionElement](ref self) -> ref [self._data] T:
        """
        Returns a reference to the data stored in the box.

        Parameters:
            T: The type of the element stored in the UnsafeBox.

        Returns:
            A reference to the data stored in the box.
        """
        return self.unsafe_get_ptr[T]()[]
