from bit import pop_count, bit_not
from .filter import MaskFilter
from hashlib import Hasher


@fieldwise_init
struct _BitMaskIndexIter(ImplicitlyCopyable, Movable, Sized):
    """Iterator for BitMask indices."""

    alias DataContainerType = SIMD[DType.uint8, BitMask.total_bytes]

    var _byte_index: Int
    var _offset_index: Int
    var _bytes: Self.DataContainerType
    var _mask: Self.DataContainerType
    var _compare: Self.DataContainerType
    var _index: UInt8
    var _size: Int

    fn __init__(out self, var bytes: Self.DataContainerType):
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


@register_passable
struct BitMask(
    EqualityComparable, ImplicitlyCopyable, KeyElement, Movable, Stringable
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
    fn __init__(out self, *bits: Self.IndexType):
        """Initializes the mask with the bits at the given indices set to True.
        """
        self = Self(bits)

    @implicit
    @always_inline
    fn __init__(out self, bits: VariadicList[BitMask.IndexType]):
        """Initializes the mask with the bits at the given indices set to True.
        """
        self._bytes = SIMD[DType.uint8, Self.total_bytes]()
        for bit in bits:
            self.set[True](bit)

    @implicit
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
    fn __hash__[H: Hasher](self, mut hasher: H):
        """Hashes the mask."""
        return hasher.update(self._bytes)

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        """Compares two masks for equality."""
        return self._bytes == other._bytes

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        """Compares two masks for inequality."""
        return not self.__eq__(other)

    @always_inline
    fn get(self, bit: Self.IndexType) -> Bool:
        """Reports whether the bit at the given index is set.

        Returns False for bit >= Self.total_bits.
        """
        var idx: Self.IndexType = bit >> 3  # equivalent to bit // 8
        var offset: Self.IndexType = bit & 7  # equivalent to bit - (8 * idx)
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
        var idx: Self.IndexType = bit >> 3  # equivalent to bit // 8
        var offset: Self.IndexType = bit & 7  # equivalent to bit - (8 * idx)

        @parameter
        if value:
            self._bytes[index(idx)] |= 1 << offset
        else:
            self._bytes[index(idx)] &= ~(1 << offset)

    @always_inline
    fn set(self, *comps: Self.IndexType, value: Bool) -> Self:
        """Returns a BitMask where the bits given as indices are set/unset according to the given value.

        Arguments:
            comps: The InlineArray containing the bits to be set or unset.
            value: If True, the bits in `comps` will be set in the resulting BitMask; if False, they will be unset.

        Returns:
            A new BitMask with the specified bits set or unset.
        """
        return self.set(comps, value)

    @always_inline
    fn set[value: Bool](self, *comps: Self.IndexType) -> Self:
        """Returns a BitMask where the bits given as indices are set/unset according to the given value.

        Parameters:
            value: If True, the bits in `comps` will be set in the resulting BitMask; if False, they will be unset.

        Arguments:
            comps: The InlineArray containing the bits to be set or unset.

        Returns:
            A new BitMask with the specified bits set or unset.
        """
        return self.set[value](comps)

    @always_inline
    fn set(self, comps: InlineArray[Self.IndexType], value: Bool) -> Self:
        """Returns a BitMask where the bits set in the given InlineArray are set/unset according to the given value.

        Arguments:
            comps: The InlineArray containing the bits to be set or unset.
            value: If True, the bits in `comps` will be set in the resulting BitMask; if False, they will be unset.

        Returns:
            A new BitMask with the specified bits set or unset.
        """
        return self.set(comps, value)

    @always_inline
    fn set[value: Bool](self, comps: InlineArray[Self.IndexType]) -> Self:
        """Returns a BitMask where the bits set in the given InlineArray are set/unset according to the given value.

        Parameters:
            value: If True, the bits in `comps` will be set in the resulting BitMask; if False, they will be unset.

        Arguments:
            comps: The InlineArray containing the bits to be set or unset.

        Returns:
            A new BitMask with the specified bits set or unset.
        """
        return self.set[value](comps)

    @always_inline
    fn set(self, other: BitMask, value: Bool) -> Self:
        """Returns a BitMask where the bits set in the other BitMask are set/unset according to the given value.

        Arguments:
            other: The BitMask containing the bits to be set or unset.
            value: If True, the bits in 'other' will be set in the resulting BitMask; if False, they will be unset.

        Returns:
            A new BitMask with the specified bits set or unset.
        """
        if value:
            return self.set[True](other)
        else:
            return self.set[False](other)

    @always_inline
    fn set[value: Bool](self, other: BitMask) -> Self:
        """Returns a BitMask where the bits set in the other BitMask are set/unset according to the given value.

        Parameters:
            value: If True, the bits in 'other' will be set in the resulting BitMask; if False, they will be unset.

        Arguments:
            other: The BitMask containing the bits to be set or unset.

        Returns:
            A new BitMask with the specified bits set or unset.
        """

        @parameter
        if value:
            return self | other
        else:
            return self & ~other

    @always_inline
    fn flip(self, bit: Self.IndexType) -> Self:
        """Flips the state of bit at the given index."""
        copy = self.copy()
        copy.flip_mut(bit)
        return copy

    @always_inline
    fn flip_mut(mut self, bit: Self.IndexType):
        """Flips the state of bit at the given index."""
        var idx: Self.IndexType = bit >> 3  # equivalent to bit // 8
        var offset: Self.IndexType = bit & 7  # equivalent to bit - (8 * idx)
        self._bytes[index(bit)] ^= 1 << offset

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
        return (self._bytes & other._bytes) == other._bytes

    @always_inline
    fn contains_any(self, other: Self) -> Bool:
        """Reports if any bit of the other mask is in this mask."""
        return (self._bytes & other._bytes) != 0

    @always_inline
    fn total_bits_set(self) -> Int:
        """Returns how many bits are set in this mask."""
        return self._bytes.reduce_bit_count()

    @always_inline
    fn get_indices(self, out result: _BitMaskIndexIter):
        """Returns the indices of the bits that are set."""
        result = _BitMaskIndexIter(self._bytes)

    @always_inline
    fn __invert__(self) -> BitMask:
        """Returns the inversion of this mask."""
        return BitMask(bytes=~self._bytes)

    @always_inline
    fn __or__(self, other: Self) -> BitMask:
        """Returns the bitwise OR of this mask and another mask.

        Performs element-wise bitwise OR operation between this mask and another mask,
        creating a new mask where a bit is set if it's set in either operand.

        Args:
            other: The other BitMask to OR with this mask.

        Returns:
            A new BitMask containing the bitwise OR of both masks.

        **Performance Note:**
        This operation is highly optimized using SIMD instructions for fast parallel
        bitwise operations across all 256 bits simultaneously.
        """
        copy = self.copy()
        copy |= other
        return copy

    @always_inline
    fn __ior__(mut self, other: Self):
        """Performs in-place bitwise OR with another BitMask.

        This method modifies the current BitMask by performing a bitwise OR operation
        with another BitMask. Each bit in the resulting BitMask is set if it is set
        in either the current BitMask or the provided BitMask.

        Args:
            other: The BitMask to perform the bitwise OR operation with.

        **Performance Note:**
        This operation is optimized using SIMD instructions for efficient parallel
        processing of all 256 bits.
        """
        self._bytes |= other._bytes

    @always_inline
    fn __and__(self, other: Self) -> BitMask:
        """Returns the bitwise AND of this mask and another mask.

        Performs element-wise bitwise AND operation between this mask and another mask,
        creating a new mask where a bit is set if it's set in both operands.

        Args:
            other: The other BitMask to AND with this mask.

        Returns:
            A new BitMask containing the bitwise AND of both masks.

        **Performance Note:**
        This operation is highly optimized using SIMD instructions for fast parallel
        bitwise operations across all 256 bits simultaneously.
        """
        copy = self.copy()
        copy &= other
        return copy

    @always_inline
    fn __iand__(mut self, other: Self):
        """Performs in-place bitwise AND with another BitMask.

        This method modifies the current BitMask by performing a bitwise AND operation
        with another BitMask. Each bit in the resulting BitMask is set if it is set
        in both the current BitMask and the provided BitMask.

        Args:
            other: The BitMask to perform the bitwise AND operation with.

        **Performance Note:**
        This operation is optimized using SIMD instructions for efficient parallel
        processing of all 256 bits.
        """
        self._bytes &= other._bytes

    @always_inline
    fn __xor__(self, other: Self) -> BitMask:
        """Returns the bitwise XOR of this mask and another mask.

        Performs element-wise bitwise XOR operation between this mask and another mask,
        creating a new mask where a bit is set if it's set in one operand but not both.

        Args:
            other: The other BitMask to XOR with this mask.

        Returns:
            A new BitMask containing the bitwise XOR of both masks.

        **Performance Note:**
        This operation is highly optimized using SIMD instructions for fast parallel
        bitwise operations across all 256 bits simultaneously.
        """
        copy = self.copy()
        copy ^= other
        return copy

    @always_inline
    fn __ixor__(mut self, other: Self):
        """Performs in-place bitwise XOR with another BitMask.

        This method modifies the current BitMask by performing a bitwise XOR operation
        with another BitMask. Each bit in the resulting BitMask is set if it is set
        in one operand but not both.

        Args:
            other: The BitMask to perform the bitwise XOR operation with.

        **Performance Note:**
        This operation is optimized using SIMD instructions for efficient parallel
        processing of all 256 bits.
        """
        self._bytes ^= other._bytes

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
