from bit import pop_count, bit_not
from .filter import MaskFilter
from hashlib import Hasher


@fieldwise_init
struct _BitMaskIndexIter(ImplicitlyCopyable, Movable, Sized):
    """Iterator for BitMask indices.

    Iterates over the indices of all bits that are set to True in a BitMask,
    providing efficient access to set bit positions.
    """

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
    """A 256-bit bitmask for efficient set operations."""

    alias IndexDType = DType.uint8
    alias IndexType = SIMD[Self.IndexDType, 1]
    alias total_bits = 256
    alias total_bytes = Self.total_bits // 8

    var _bytes: SIMD[DType.uint8, Self.total_bytes]

    @always_inline
    fn __init__(out self, *, bytes: SIMD[DType.uint8, Self.total_bytes]):
        """Initializes the mask with the given bytes.

        Creates a new BitMask from a raw byte representation.

        Args:
            bytes: The raw byte data representing the bitmask state.
        """
        self._bytes = bytes

    @always_inline
    fn __init__(out self, bits: VariadicList[BitMask.IndexType]):
        """Initializes the mask with the bits at the given indices set to True.

        Creates a new BitMask with only the specified bit indices set.

        Args:
            bits: A variadic list of bit indices to set to True.
        """
        self._bytes = SIMD[DType.uint8, Self.total_bytes]()
        for bit in bits:
            self.set[True](bit)

    @always_inline
    fn __init__[
        size: Int
    ](out self, bits: InlineArray[BitMask.IndexType, size]):
        """Initializes the mask with the bits at the given indices set to True.

        Creates a new BitMask with only the specified bit indices set.

        Parameters:
            size: The compile-time size of the inline array.

        Args:
            bits: An inline array of bit indices to set to True.
        """
        self._bytes = SIMD[DType.uint8, Self.total_bytes]()

        @parameter
        for i in range(size):
            self.set[True](bits[i])

    @always_inline
    fn __init__(out self, *bits: Self.IndexType):
        """Initializes the mask with the bits at the given indices set to True.

        Creates a new BitMask with only the specified bit indices set.

        Args:
            bits: Variadic bit indices to set to True.
        """
        self = Self(bits)

    @always_inline
    fn __hash__[H: Hasher](self, mut hasher: H):
        """Hashes the mask.

        Computes a hash value for the mask by hashing its underlying byte representation.

        Parameters:
            H: The hasher type to use.

        Args:
            hasher: The hasher to update with the mask's bytes.
        """
        hasher.update(self._bytes)

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        """Compares two masks for equality.

        Checks if all bits in both masks have the same state.

        Args:
            other: The other BitMask to compare with.

        Returns:
            True if both masks are identical, False otherwise.
        """
        return self._bytes == other._bytes

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        """Compares two masks for inequality.

        Checks if the masks differ in at least one bit.

        Args:
            other: The other BitMask to compare with.

        Returns:
            True if the masks are different, False otherwise.
        """
        return not self.__eq__(other)

    @always_inline
    fn __invert__(self) -> Self:
        """Returns the inversion of this mask.

        Creates a new mask where all bits are flipped (0 becomes 1, 1 becomes 0).

        Returns:
            A new BitMask with all bits inverted.
        """
        return Self(bytes=~self._bytes)

    @always_inline
    fn __or__(self, other: Self, out result: Self):
        """Returns the bitwise OR of this mask and another mask.

        Performs element-wise bitwise OR operation between this mask and another mask,
        creating a new mask where a bit is set if it's set in either operand.

        Args:
            other: The other BitMask to OR with this mask.

        Returns:
            A new BitMask containing the bitwise OR of both masks.
        """
        result = self.copy()
        result |= other

    @always_inline
    fn __ior__(mut self, other: Self):
        """Performs in-place bitwise OR with another BitMask.

        This method modifies the current BitMask by performing a bitwise OR operation
        with another BitMask. Each bit in the resulting BitMask is set if it is set
        in either the current BitMask or the provided BitMask.

        Args:
            other: The BitMask to perform the bitwise OR operation with.
        """
        self._bytes |= other._bytes

    @always_inline
    fn __and__(self, other: Self, out result: Self):
        """Returns the bitwise AND of this mask and another mask.

        Performs element-wise bitwise AND operation between this mask and another mask,
        creating a new mask where a bit is set if it's set in both operands.

        Args:
            other: The other BitMask to AND with this mask.

        Returns:
            A new BitMask containing the bitwise AND of both masks.
        """
        result = self.copy()
        result &= other

    @always_inline
    fn __iand__(mut self, other: Self):
        """Performs in-place bitwise AND with another BitMask.

        This method modifies the current BitMask by performing a bitwise AND operation
        with another BitMask. Each bit in the resulting BitMask is set if it is set
        in both the current BitMask and the provided BitMask.

        Args:
            other: The BitMask to perform the bitwise AND operation with.
        """
        self._bytes &= other._bytes

    fn __str__(self) -> String:
        """Implements String(...).

        Converts the mask to a string representation showing all 256 bits.

        Returns:
            A string in the format "[01101...]" showing the state of all bits.
        """
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
        """Representation string of the mask.

        Creates a debug representation showing the internal byte structure.

        Returns:
            A string in the format "BitMask(<bytes>)" for debugging.
        """
        return "BitMask(" + String(self._bytes) + ")"

    @always_inline
    fn matches(self, bits: Self) -> Bool:
        """Matches the mask as filter against another mask.

        Checks if the provided mask contains all bits set in this mask.

        Args:
            bits: The BitMask to check against.

        Returns:
            True if bits contains all bits set in this mask, False otherwise.
        """
        return bits.contains(self)

    @always_inline
    fn exclusive(self) -> MaskFilter:
        """Creates a [..filter.MaskFilter] which filters for exactly the mask's components.

        Matches only entities that have exactly the given components, and no other.
        This creates a filter that excludes all components not in this mask.

        Returns:
            A [..filter.MaskFilter] configured for exact component matching.
        """
        return MaskFilter(
            include=self,
            exclude=~self,
        )

    @always_inline
    fn get(self, bit: Self.IndexType) -> Bool:
        """Reports whether the bit at the given index is set.

        Args:
            bit: The index of the bit to check.

        Returns:
            True if the bit is set, False otherwise.
        """
        var idx: Self.IndexType = bit >> 3  # equivalent to bit // 8
        var offset: Self.IndexType = bit & 7  # equivalent to bit - (8 * idx)
        mask = 1 << offset
        return (self._bytes[index(idx)] & mask) == mask

    @always_inline
    fn set(mut self, bit: Self.IndexType, value: Bool):
        """Sets the state of bit at the given index.

        Args:
            bit: The index of the bit to modify.
            value: The value to set the bit to (True or False).
        """
        if value:
            self.set[True](bit)
        else:
            self.set[False](bit)

    @always_inline
    fn set[value: Bool](mut self, bit: Self.IndexType):
        """Sets the state of bit at the given index.

        Parameters:
            value: The compile-time value to set the bit to (True or False).

        Args:
            bit: The index of the bit to modify.
        """
        var idx: Self.IndexType = bit >> 3  # equivalent to bit // 8
        var offset: Self.IndexType = bit & 7  # equivalent to bit - (8 * idx)

        @parameter
        if value:
            self._bytes[index(idx)] |= 1 << offset
        else:
            self._bytes[index(idx)] &= ~(1 << offset)

    @always_inline
    fn set(mut self, *comps: Self.IndexType, value: Bool):
        """Modifies the [BitMask] to set the components given as arguments to the provided value.

        Args:
            comps: Variadic bit indices to modify.
            value: The value to set the bits to (True or False).
        """
        self.set(BitMask(comps), value)

    @always_inline
    fn set[value: Bool](mut self, *comps: Self.IndexType):
        """Modifies the [BitMask] to set the components given as arguments to the provided value.

        Parameters:
            value: The compile-time value to set the bits to (True or False).

        Args:
            comps: Variadic bit indices to modify.
        """
        self.set[value](BitMask(comps))

    @always_inline
    fn set(mut self, comps: InlineArray[Self.IndexType], value: Bool):
        """Modifies the [BitMask] to set the components given in the array to the provided value.

        Args:
            comps: An inline array of bit indices to modify.
            value: The value to set the bits to (True or False).
        """
        self.set(BitMask(comps), value)

    @always_inline
    fn set[value: Bool](mut self, comps: InlineArray[Self.IndexType]):
        """Modifies the [BitMask] to set the components given in the array to the provided value.

        Parameters:
            value: The compile-time value to set the bits to (True or False).

        Args:
            comps: An inline array of bit indices to modify.
        """
        self.set[value](BitMask(comps))

    @always_inline
    fn set(mut self, other: BitMask, value: Bool):
        """Modifies the [BitMask] to set the components set in the given [BitMask] to the provided value.

        Args:
            other: A [BitMask] whose set bits identify which bits to modify.
            value: The value to set the bits to (True or False).
        """
        if value:
            self.set[True](other)
        else:
            self.set[False](other)

    @always_inline
    fn set[value: Bool](mut self, other: BitMask):
        """Modifies the [BitMask] to set the components set in the given [BitMask] to the provided value.

        Creates a new [BitMask] with all bits set in the other mask modified to the
        compile-time known value.

        Parameters:
            value: The compile-time value to set the bits to (True or False).

        Args:
            other: A [BitMask] whose set bits identify which bits to modify.
        """

        @parameter
        if value:
            self |= other
        else:
            self &= ~other

    @always_inline
    fn flip(mut self, bit: Self.IndexType):
        """Flips the state of bit at the given index.

        Toggles the bit at the specified index (0 becomes 1, 1 becomes 0).

        Args:
            bit: The index of the bit to flip.
        """
        var idx: Self.IndexType = bit >> 3  # equivalent to bit // 8
        var offset: Self.IndexType = bit & 7  # equivalent to bit - (8 * idx)
        self._bytes[index(idx)] ^= 1 << offset

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns whether no bits are set in the mask.

        Checks if the mask is completely empty (all bits are False).

        Returns:
            True if no bits are set, False otherwise.
        """
        return not self._bytes.reduce_or()

    @always_inline
    fn reset(mut self):
        """Resets the mask setting all bits to False.

        Clears all bits in the mask, setting the entire mask to zero.
        """
        self._bytes = 0

    @always_inline
    fn contains(self, other: Self) -> Bool:
        """Reports if the other mask is a subset of this mask.

        Checks whether all bits set in the other mask are also set in this mask.

        Args:
            other: The [BitMask] to check for containment.

        Returns:
            True if all bits set in other are also set in this mask, False otherwise.
        """
        return (self._bytes & other._bytes) == other._bytes

    @always_inline
    fn contains_any(self, other: Self) -> Bool:
        """Reports if any bit of the other mask is in this mask.

        Checks whether at least one bit set in the other mask is also set in this mask.

        Args:
            other: The [BitMask] to check for overlap.

        Returns:
            True if any bit set in other is also set in this mask, False otherwise.
        """
        return (self._bytes & other._bytes) != 0

    @always_inline
    fn total_bits_set(self) -> Int:
        """Returns how many bits are set in this mask.

        Counts the total number of bits that are set to True.

        Returns:
            The number of bits set to True in the mask.
        """
        return self._bytes.reduce_bit_count()

    @always_inline
    fn get_indices(self, out result: _BitMaskIndexIter):
        """Returns the indices of the bits that are set.

        Creates an iterator that yields the index of each bit set to True.

        Returns:
            An iterator over the indices of the bits that are set.
        """
        result = _BitMaskIndexIter(self._bytes)
