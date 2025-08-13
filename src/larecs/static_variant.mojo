from sys.info import sizeof
from sys.intrinsics import _type_is_eq
from .static_optional import StaticOptional


alias StaticVariantType = Movable
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

    fn __copyinit__[
        T: Copyable & StaticVariantType, //
    ](out self: Self[variant_idx, T], owned other: Self[variant_idx, T]):
        """
        Initializes the variant by copying the value from another variant.

        Args:
            other: The variant to copy from.
        """
        self._data = other._data

    fn copy[
        T: ExplicitlyCopyable & StaticVariantType, //
    ](self: Self[variant_idx, T], out copy: Self[variant_idx, T]):
        """
        Initializes the variant by copying the value from another variant.

        Args:
            other: The variant to copy from.
        """
        copy = Self(self._data.copy())

    @staticmethod
    @always_inline
    fn isa[type: AnyType]() -> Bool:
        """
        Checks if the variant holds a value of the specified type.

        Parameters:
            type: The type to check against.

        Returns:
            True if the variant holds a value of the specified type, False otherwise.
        """
        return _type_is_eq[type, Self.EltType]()

    # NOTE: This is a workaround to allow using the common members of the static variant. Accessing common members of a
    #       static variant is awkward, because the compiler does not check the variants for similarities. To do this
    #       properly, we would need to implement a generic Iterator[Archetype[*Ts]] trait. But this is not possible yet,
    #       because parameters on traits are not implemented. This should be fixed in the future.
    fn __bool__[
        T: Boolable & StaticVariantType, //
    ](self: Self[variant_idx, T]) -> Bool:
        return self._data.__bool__()

    fn __next__[
        T: Iterator & StaticVariantType, //
    ](self: Self[variant_idx, T]) -> Bool:
        return self._data.__next__()

    fn __has_next__[
        T: Iterator & StaticVariantType, //
    ](self: Self[variant_idx, T]) -> Bool:
        return self._data.__has_next__()

    fn __iter__[
        T: Iteratable & StaticVariantType, //
    ](self: Self[variant_idx, T]) -> Bool:
        return self._data.__iter__()


trait Iteratable:
    """
    A trait that defines the requirements for types that can be iterated over.
    """

    fn __iter__[T: Iterator](self) -> T:
        ...
