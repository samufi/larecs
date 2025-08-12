<<<<<<< HEAD
from sys.info import sizeof
from sys.intrinsics import _type_is_eq
from .static_optional import StaticOptional


alias StaticVariantType = Movable
"""
A trait that defines the requirements for types that can be used in StaticVariant.

All types stored in a StaticVariant must be Movable to ensure proper memory management
and ownership transfer semantics.
"""


struct StaticVariant[variant_idx: Int, *Ts: StaticVariantType](Movable):
    """
    A compile-time variant type that can hold exactly one of the provided types.

    StaticVariant provides type-safe storage for one of several possible types, with the
    specific type determined at compile time via the `variant_idx` parameter. This is useful
    for scenarios where you need to store different types in a collection while maintaining
    type safety and avoiding runtime overhead.

    **Key features:**
    - Zero runtime type checking overhead - all type information is compile-time
    - Type-safe access via the `is_a` method and direct indexing
    - Memory efficient - only stores the size of the contained type
    - Movable semantics for efficient ownership transfer

    **Important Notes:**
    - The `variant_idx` must be known at compile time and correspond to a valid type index
    - Once created, the variant always holds the type specified by `variant_idx`
    - No runtime type conversion is supported - the type is fixed at compile time
    - All stored types must implement the StaticVariantType trait (Movable)

    **Example:**

    ```mojo
    # Define some component types
    @fieldwise_init
    struct Position(Movable):
        var x: Float64
        var y: Float64

        fn update(inout self, dt: Float64):
            # Position doesn't change on its own
            pass

    @fieldwise_init
    struct Velocity(Movable):
        var dx: Float64
        var dy: Float64

        fn update(inout self, dt: Float64):
            # Apply some damping to velocity
            self.dx *= 0.99
            self.dy *= 0.99

    # Define a generic function that works with any component type
    fn process_component[variant_idx: Int](
        inout component: StaticVariant[variant_idx, Position, Velocity],
        dt: Float64
    ):
        # Compile-time polymorphism - the correct update method is called
        # based on the variant_idx parameter with zero runtime overhead
        component[].update(dt)

    # Create variants and process them polymorphically
    var pos_var = StaticVariant[0, Position, Velocity](Position(1.0, 2.0))
    var vel_var = StaticVariant[1, Position, Velocity](Velocity(0.5, -0.5))

    # Same function handles different types at compile time
    process_component(pos_var, 0.016)  # Calls Position.update()
    process_component(vel_var, 0.016)  # Calls Velocity.update()

    # Type-safe access when needed
    if pos_var.is_a[Position]():
        print("Position:", pos_var[][].x, pos_var[][].y)
    ```

    **Performance Considerations:**
    - Compile-time type resolution eliminates runtime overhead
    - Direct memory access without indirection or boxing
    - Efficient for scenarios with known, limited type sets

    Parameters:
        variant_idx: The compile-time index specifying which type this variant holds.
                    Must be in range [0, len(Ts)).
        Ts: The variadic list of types that this variant can hold. All types must
            implement StaticVariantType (Movable).
    """

    alias ElementType = Ts[variant_idx]
    var _data: Self.ElementType

    fn __init__(out self, owned value: Self.ElementType) raises:
        """
        Initializes the variant with a value of the specified type.

        The value is moved into the variant, transferring ownership. The variant
        will hold exactly this type as determined by the `variant_idx` parameter.

        Args:
            value: The value to store in the variant. Must be of type ElementType
                  (the type at index `variant_idx` in the Ts parameter list).

        Raises:
            Error: If `variant_idx` is out of bounds for the provided type list.

        **Example:**
        ```mojo
        alias MyVariant = StaticVariant[0, Int, String]
        var variant = MyVariant(42)  # Holds an Int at index 0
        ```
        """

        constrained[
            variant_idx >= 0 and variant_idx < len(VariadicList(Ts)),
            "variant_idx must be within the range of provided types.",
        ]()

        self._data = value^

    fn __getitem__(ref self) -> ref [self._data] Self.ElementType:
        """
        Returns a reference to the value stored in the variant.

        Provides direct access to the contained value without type checking overhead.
        The reference lifetime is tied to the variant's lifetime.

        Returns:
            A reference to the stored value of type ElementType.

        **Example:**
        ```mojo
        alias IntVariant = StaticVariant[0, Int, String]
        var variant = IntVariant(42)
        var value_ref = variant[]  # Direct access to the Int
        print(value_ref)  # Prints: 42
        ```

        **Safety Note:**
        This method assumes the variant contains the expected type. Use `is_a[T]()`
        to verify the type at compile time if needed for additional safety.
        """
        return self._data

    @staticmethod
    @always_inline
    fn is_a[type: AnyType]() -> Bool:
        """
        Checks if the variant holds a value of the specified type.

        This is a compile-time type comparison that determines whether the variant's
        ElementType (determined by `variant_idx`) matches the queried type. No runtime
        overhead is incurred as this is resolved at compile time.

        Parameters:
            type: The type to check against the variant's contained type.

        Returns:
            True if the variant's ElementType matches the specified type, False otherwise.

        **Example:**
        ```mojo
        alias MyVariant = StaticVariant[0, Int, String]  # Holds Int at index 0

        # Compile-time type checking
        if MyVariant.is_a[Int]():
            print("Variant holds an Int")  # This will execute

        if MyVariant.is_a[String]():
            print("Variant holds a String")  # This will not execute
        ```

        **Performance Note:**
        This method is completely resolved at compile time with no runtime cost.
        It's effectively equivalent to a compile-time boolean constant.
        """
        return _type_is_eq[type, Self.ElementType]()


# BUG: Mojo crashes with these methods (see https://github.com/modular/modular/issues/5172). When fixed, we can use
#      these for better ergonomics when working with StaticVariant.
#      This may also be fixable when conditional conformance with `requires` is released.
#
#     fn __copyinit__[
#         T: Copyable & StaticVariantType, //
#     ](out self: Self[variant_idx, T], read other: Self[variant_idx, T]):
#         """
#         Initializes the variant by copying the value from another variant.

#         Args:
#             other: The variant to copy from.
#         """
#         self._data = other._data

#     fn copy[
#         T: ExplicitlyCopyable & StaticVariantType, //
#     ](read self: Self[variant_idx, T], out copy: Self[variant_idx, T]):
#         """
#         Initializes the variant by copying the value from another variant.

#         Args:
#             other: The variant to copy from.
#         """
#         copy = Self(self._data.copy())

#     fn __bool__[
#         T: Boolable & StaticVariantType, //
#     ](self: Self[variant_idx, T]) -> Bool:
#         return self._data.__bool__()

#     fn __next__[
#         T: Iterator & StaticVariantType, //
#     ](self: Self[variant_idx, T]) -> Bool:
#         return self._data.__next__()

#     fn __has_next__[
#         T: Iterator & StaticVariantType, //
#     ](self: Self[variant_idx, T]) -> Bool:
#         return self._data.__has_next__()

#     fn __iter__[
#         T: Iteratable & StaticVariantType, //
#     ](self: Self[variant_idx, T]) -> Bool:
#         return self._data.__iter__()


# trait Iteratable:
#     """
#     A trait that defines the requirements for types that can be iterated over.
#     """

#     fn __iter__[T: Iterator](self) -> T:
#         ...
||||||| parent of 5b6d854 (Add StaticVariant)
=======
from sys.info import sizeof
from sys.intrinsics import _type_is_eq
from .static_optional import StaticOptional


alias StaticVariantType = Copyable & Movable
"""
A trait that defines the requirements for types that can be used in StaticVariant.
"""


struct StaticVariant[variant_idx: Int, *Ts: StaticVariantType](Movable):
    """
    A variant type that can hold one of the provided types.

    Parameters:
        variant_idx: The index of the type that this variant holds.
        Ts: The types that the variant can hold.
    """

    alias EltType = Ts[variant_idx]
    var _data: Self.EltType

    fn __init__(out self, owned value: Self.EltType) raises:
        """
        Initializes the variant with a value of the specified type.
        """

        constrained[
            variant_idx >= 0 and variant_idx < len(VariadicList(Ts)),
            "variant_idx must be within the range of provided types.",
        ]()

        self._data = value^

    fn __getitem__(ref self) -> ref [self._data] Self.EltType:
        """
        Returns a reference to the value stored in the variant.

        """
        return self._data
>>>>>>> 5b6d854 (Add StaticVariant)
