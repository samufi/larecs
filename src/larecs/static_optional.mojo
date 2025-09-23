@fieldwise_init
struct StaticOptional[
    ElementType: ImplicitlyCopyable & Movable,
    has_value: Bool = True,
](Boolable, Copyable, ImplicitlyCopyable, Movable):
    """An optional type that can potentially hold a value of ElementType.

    In contrast to the built-in optional, it is decided at
    compile time whether a value is present. This allows
    this type to have a size of 0 in these cases.

    Parameters:
        ElementType: The type of the elements in the array.
        has_value: Whether the element exists.
    """

    # Fields
    var _value: InlineArray[ElementType, Int(has_value)]
    """The underlying storage for the optional."""

    # ===------------------------------------------------------------------===#
    # Life cycle methods
    # ===------------------------------------------------------------------===#

    @always_inline
    @implicit
    fn __init__(out self, none: None = None):
        """This constructor will always cause a compile time error if used.
        It is used to steer users away from uninitialized memory.
        """
        constrained[
            not has_value,
            "Initialize with a value if `has_value` is `True`",
        ]()
        self._value = {uninitialized = True}

    @always_inline
    @implicit
    fn __init__(out self, var value: Self.ElementType):
        """Constructs an optional type holding the provided value.

        Args:
            value: The value to fill the optional with.
        """
        self._value = {value^}

    @always_inline
    fn __getitem__(ref self) -> ref [self._value] Self.ElementType:
        """Get a reference to the value.

        Returns:
            A reference to the value.
        """
        constrained[
            has_value,
            (
                "The value is not present. Use `has_value` to check if the"
                " value is present."
            ),
        ]()
        return self._value.unsafe_get(0)

    @always_inline
    fn or_else(
        ref self, ref value: ElementType
    ) -> ref [self._value, value] ElementType:
        """Returns a copy of the value contained in the Optional or a default value if no value is present.

        Args:
            value: The default value to return if the optional is empty.

        Returns:
            A copy of the value contained in the Optional or the default value if no value is present.
        """

        @parameter
        if has_value:
            return self[]
        else:
            return value

    @always_inline
    fn unsafe_ptr(self) -> UnsafePointer[Self.ElementType]:
        """Get an `UnsafePointer` to the underlying array.

        That pointer is unsafe but can be used to read or write to the array.
        Be careful when using this. As opposed to a pointer to a `List`,
        this pointer becomes invalid when the `InlineArray` is moved.

        Make sure to refresh your pointer every time the `InlineArray` is moved.

        Returns:
            An `UnsafePointer` to the underlying value.
        """
        constrained[
            has_value,
            (
                "The value is not present. Use `has_value` to check if the"
                " value is present."
            ),
        ]()

        return self._value.unsafe_ptr()

    @always_inline
    fn __bool__(self) -> Bool:
        """Check if the optional has a value.

        Returns:
            True if the optional has a value, False otherwise.
        """
        return has_value
