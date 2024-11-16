from bit import pop_count, bit_not
from filter import MaskFilter


@value
@register_passable
struct BitMask(Stringable):
    """BitMask is a 256 bit bitmask."""

    alias IndexType = UInt8
    alias total_bits = 256
    alias total_bytes = Self.total_bits // 8

    var _bytes: SIMD[DType.uint8, Self.total_bytes]

    @always_inline
    fn __init__(inout self, bytes: SIMD[DType.uint8, Self.total_bytes]):
        """Initializes the mask with the given bytes."""
        self._bytes = bytes

    @always_inline
    fn __init__(inout self, bits: VariadicList[BitMask.IndexType]):
        """Initializes the mask with the bits at the given indices set to True.
        """
        self._bytes = SIMD[DType.uint8, Self.total_bytes]()
        for bit in bits:
            self.set[True](bit)

    @always_inline
    fn __init__(inout self, *bits: Self.IndexType):
        """Initializes the mask with the bits at the given indices set to True.
        """
        self.__init__(bits)

    @always_inline
    fn matches(self, bits: Self) -> Bool:
        """Matches the mask as filter against another mask."""
        return bits.contains(self)

    @always_inline
    fn without(self, *comps: Self.IndexType) -> MaskFilter:
        """Creates a [MaskFilter] which filters for including the mask's components
        and excludes the components given as arguments.
        """
        return MaskFilter(
            include=self,
            exclude=BitMask(comps),
        )

    @always_inline
    fn exclusive(self) -> MaskFilter:
        """Creates a [MaskFilter] which filters for exactly the mask's components.
        matches only entities that have exactly the given components, and no other.
        """
        return MaskFilter(
            include=self,
            exclude=self.invert(),
        )

    @always_inline
    fn get(self, bit: Self.IndexType) -> Bool:
        """Reports whether the bit at the given index is set.

        Returns False for bit >= Self.total_bits.
        """
        var index: Self.IndexType = bit // 8
        var offset: Self.IndexType = bit - (8 * index)
        mask = 1 << offset
        return (self._bytes[int(index)] & mask) == mask

    @always_inline
    fn set(inout self, bit: Self.IndexType, value: Bool):
        """Sets the state of bit at the given index."""
        if value:
            self.set[True](bit)
        else:
            self.set[False](bit)

    @always_inline
    fn set[value: Bool](inout self, bit: Self.IndexType):
        """Sets the state of bit at the given index."""
        var index: Self.IndexType = bit // 8
        var offset: Self.IndexType = bit - (8 * index)

        @parameter
        if value:
            self._bytes[int(index)] |= 1 << offset
        else:
            self._bytes[int(index)] &= ~(1 << offset)

    @always_inline
    fn invert(self) -> BitMask:
        """Returns the inversion of this mask."""
        return BitMask(bit_not(self._bytes))

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns whether no bits are set in the mask."""
        return not self._bytes.reduce_or()

    @always_inline
    fn reset(inout self):
        """Resets the mask setting all bits to False."""
        self._bytes = 0

    @always_inline
    fn contains(self, other: Self) -> Bool:
        """Reports if the other mask is a subset of this mask."""
        return ((self._bytes & other._bytes) == other._bytes).reduce_and()

    @always_inline
    fn contains_any(self, other: Self) -> Bool:
        """Reports if any bit of the other mask is in this mask."""
        return ((self._bytes & other._bytes) != 0).reduce_or()

    @always_inline
    fn total_bits_set(self) -> Int:
        """Returns how many bits are set in this mask."""
        # The cast to uint16 is necessary to avoid overflow 
        # in the reduce operation.
        return int(pop_count(self._bytes).cast[DType.uint16]().reduce_add())

    fn __str__(self) -> String:
        """Implements str(...)."""
        var result: String = "["
        for i in range(len(self._bytes) * 8):
            if self.get(i):
                result += "1"
            else:
                result += "0"
        result += "]"
        return result

    @always_inline
    fn __repr__(self) -> String:
        """Representation string of the Mask."""
        return "BitMask(" + str(self._bytes) + ")"
