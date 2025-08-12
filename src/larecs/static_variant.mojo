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
