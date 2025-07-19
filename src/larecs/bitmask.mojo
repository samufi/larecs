from bit import pop_count, bit_not
from hashlib import Hasher
from .filter import MaskFilter


@fieldwise_init
struct _BitMaskIndexIter(Copyable, ExplicitlyCopyable, Movable, Sized):
    """Iterator for BitMask indices."""

    alias DataContainerType = SIMD[DType.uint8, BitMask.total_bytes]

    var _byte_index: Int
    var _offset_index: Int
    var _bytes: Self.DataContainerType
    var _mask: Self.DataContainerType
    var _compare: Self.DataContainerType
    var _index: UInt8
    var _size: Int

    fn __init__(out self, owned bytes: Self.DataContainerType):
        self._bytes = bytes
        self._mask = Self.DataContainerType(1)
        self._compare = self._bytes & self._mask
        self._byte_index = 0
        self._offset_index = 0
        self._index = 0
        self._size = self._bytes.reduce_bit_count()

    fn __iter__(self) -> Self:
        return self

    fn __next__(
        mut self,
    ) -> BitMask.IndexType:
        for i in range(self._offset_index, 8):
            for j in range(self._byte_index, 32):
                if self._compare[j]:
                    self._offset_index = i
                    self._byte_index = j + 1
                    self._index += 1
                    return j * 8 + i
            self._mask <<= 1
            self._compare = self._bytes & self._mask
            self._byte_index = 0
        return 255

    @always_inline
    fn __has_next__(self) -> Bool:
        return self._index < self._size

    @always_inline
    fn __len__(self) -> Int:
        return self._size


struct BitMask(
    Copyable, EqualityComparable, KeyElement, Movable, Representable, Stringable
):
    """BitMask is a 256 bit bitmask."""

    alias IndexDType = DType.uint8
    alias IndexType = SIMD[Self.IndexDType, 1]
    alias total_bits = 256
    alias total_bytes = Self.total_bits // 8

    var _bytes: SIMD[DType.uint8, Self.total_bytes]

    @always_inline
    fn __init__(out self, *, bytes: SIMD[DType.uint8, Self.total_bytes]):
        """Initializes the mask with the given bytes."""
        self._bytes = bytes

    @always_inline
    fn __init__(out self, bits: VariadicList[BitMask.IndexType]):
        """Initializes the mask with the bits at the given indices set to True.
        """
        self._bytes = SIMD[DType.uint8, Self.total_bytes]()
        for bit in bits:
            self.set[True](bit)

    @always_inline
    fn __init__[
        size: Int
    ](out self, bits: InlineArray[BitMask.IndexType, size]):
        """Initializes the mask with the bits at the given indices set to True.
        """
        self._bytes = SIMD[DType.uint8, Self.total_bytes]()

        @parameter
        for i in range(size):
            self.set[True](bits[i])

    @always_inline
    fn __init__(out self, *bits: Self.IndexType):
        """Initializes the mask with the bits at the given indices set to True.
        """
        self = Self(bits)

    @always_inline
    fn __hash__[H: Hasher](self, mut hasher: H):
        """Hashes the mask."""
        return hasher.update(self._bytes)

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        """Compares two masks for equality."""
        return (self._bytes == other._bytes).reduce_and()

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        """Compares two masks for inequality."""
        return not self.__eq__(other)

    @always_inline
    fn matches(self, bits: Self) -> Bool:
        """Matches the mask as filter against another mask."""
        return bits.contains(self)

    @always_inline
    fn without(self, *comps: Self.IndexType) -> MaskFilter:
        """Creates a [..filter.MaskFilter] which filters for including the mask's components
        and excludes the components given as arguments.
        """
        return MaskFilter(
            include=self,
            exclude=BitMask(comps),
        )

    @always_inline
    fn exclusive(self) -> MaskFilter:
        """Creates a [..filter.MaskFilter] which filters for exactly the mask's components.
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
        var idx: Self.IndexType = bit // 8
        var offset: Self.IndexType = bit - (8 * idx)
        mask = 1 << offset
        return (self._bytes[index(idx)] & mask) == mask

    @always_inline
    fn set(mut self, bit: Self.IndexType, value: Bool):
        """Sets the state of bit at the given index."""
        if value:
            self.set[True](bit)
        else:
            self.set[False](bit)

    @always_inline
    fn set[value: Bool](mut self, bit: Self.IndexType):
        """Sets the state of bit at the given index."""
        var idx: Self.IndexType = bit // 8
        var offset: Self.IndexType = bit - (8 * idx)

        @parameter
        if value:
            self._bytes[index(idx)] |= 1 << offset
        else:
            self._bytes[index(idx)] &= ~(1 << offset)

    @always_inline
    fn flip(mut self, bit: Self.IndexType):
        """Flips the state of bit at the given index."""
        var idx: Self.IndexType = bit // 8
        var offset: Self.IndexType = bit - (8 * idx)
        self._bytes[index(idx)] ^= 1 << offset

    @always_inline
    fn invert(self) -> BitMask:
        """Returns the inversion of this mask."""
        print("Create inversion:", bit_not(self._bytes))
        return BitMask(bytes=bit_not(self._bytes))

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns whether no bits are set in the mask."""
        return not self._bytes.reduce_or()

    @always_inline
    fn reset(mut self):
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
        return self._bytes.reduce_bit_count()

    @always_inline
    fn get_indices(self, out result: _BitMaskIndexIter):
        """Returns the indices of the bits that are set."""
        result = _BitMaskIndexIter(self._bytes)

    fn __str__(self) -> String:
        """Implements String(...)."""
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
        return "BitMask(" + String(self._bytes) + ")"
