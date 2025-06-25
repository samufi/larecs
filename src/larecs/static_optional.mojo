from memory import UnsafePointer
from .bitmask import BitMask
from sys.intrinsics import _type_is_eq


@fieldwise_init
struct StaticOptional[
    ElementType: Copyable & Movable,
    has_value: Bool = True,
](Boolable, Copyable, ExplicitlyCopyable, Movable):
    """An optional type that can potentially hold a value of ElementType.

    In contrast to the built-in optional, it is decided at
    compile time whether a value is present. This allows
    this type to have a size of 0 in these cases.

    Parameters:
        ElementType: The type of the elements in the array.
        has_value: Whether the element exists.
    """

    # Fields
    alias type = __mlir_type[
        `!pop.array<`, Int(has_value).value, `, `, Self.ElementType, `>`
    ]
    var _value: Self.type
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
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))

    @always_inline
    @implicit
    fn __init__(out self, owned value: Self.ElementType):
        """Constructs an optional type holding the provided value.

        Args:
            value: The value to fill the optional with.
        """
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))

        @parameter
        if _type_is_eq[Self.ElementType, BitMask]():
            print(
                "Initializing StaticOptional with BitMask:",
                UnsafePointer(to=value).bitcast[BitMask]()[]._bytes,
            )

        UnsafePointer(to=value).move_pointee_into(self.unsafe_ptr())

        @parameter
        if _type_is_eq[Self.ElementType, BitMask]():
            print(
                "The stored value is:",
                UnsafePointer(to=self[]).bitcast[BitMask]()[]._bytes,
            )

        __disable_del value

    fn __moveinit__(out self, owned other: Self):
        """Move construct the optional.

        Args:
            other: The optional to move.
        """
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))

        @parameter
        if has_value:

            @parameter
            if _type_is_eq[Self.ElementType, BitMask]():
                print(
                    "Moving StaticOptional with BitMask:",
                    UnsafePointer(to=other[]).bitcast[BitMask]()[]._bytes,
                )
            other.unsafe_ptr().move_pointee_into(self.unsafe_ptr())

            @parameter
            if _type_is_eq[Self.ElementType, BitMask]():
                print(
                    "The moved value is:",
                    UnsafePointer(to=self[]).bitcast[BitMask]()[]._bytes,
                )

    @always_inline
    fn copy(self) -> Self:
        """Explicitly copy the provided value.

        Returns:
            A copy of the value.
        """
        return self

    @always_inline
    fn __copyinit__(out self, other: Self):
        """Copy construct the optional.

        Args:
            other: The optional to copy.
        """
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))

        @parameter
        if has_value:
            self.unsafe_ptr().init_pointee_copy(other[])

    fn __del__(owned self):
        """Deallocate the optional."""

        @parameter
        if has_value:
            self.unsafe_ptr().destroy_pointee()

    # ===------------------------------------------------------------------===#
    # Methods
    # ===------------------------------------------------------------------===#

    @always_inline
    fn __getitem__(ref self) -> ref [self] Self.ElementType:
        """Get a reference to the value.

        Returns:
            A reference to the value.
        """
        return self.unsafe_ptr()[]

    @always_inline
    fn or_else(self, value: ElementType) -> ElementType:
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
    fn unsafe_ptr(
        ref self,
    ) -> UnsafePointer[
        Self.ElementType,
        mut = Origin(__origin_of(self)).mut,
        origin = __origin_of(self),
    ]:
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

        return (
            UnsafePointer(to=self._value)
            .bitcast[Self.ElementType]()
            .origin_cast[
                mut = Origin(__origin_of(self)).mut, origin = __origin_of(self)
            ]()
        )

    @always_inline
    fn __bool__(self) -> Bool:
        """Check if the optional has a value.

        Returns:
            True if the optional has a value, False otherwise.
        """
        return has_value
