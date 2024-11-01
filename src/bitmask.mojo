from bit import pop_count
from filter import MaskFilter


@value
@register_passable
struct BitMask(Stringable):
    """BitMask is a 128 bit bitmask.
    It is also a [Filter] for including certain components.
    
    Use [all] to create a mask for a list of component IDs.
    A mask can be further specified using [Mask.without] or [Mask.exclusive].
    """
    alias word_size: Int = 64
    alias total_bits: Int = 2 * Self.word_size
    alias IndexType = UInt8
    var lo: UInt64 # First 64 bits of the mask
    var hi: UInt64 # Second 64 bits of the mask

    fn matches(self, bits: Self) -> Bool:
        """Matches the mask as filter against another mask.
        """
        return bits.contains(self)

    fn without(self, *comps: Self.IndexType) -> MaskFilter:
        """Creates a [MaskFilter] which filters for including the mask's components
        and excludes the components given as arguments.
        """
        return MaskFilter(
            include=self,
            exclude=all(comps),
        )

    fn exclusive(self) -> MaskFilter:
        """Creates a [MaskFilter] which filters for exactly the mask's components.
        matches only entities that have exactly the given components, and no other.
        """
        return MaskFilter(
            include=self,
            exclude=self.invert(),
        )

    fn get(self, bit: Self.IndexType) -> Bool:
        """Reports whether the bit at the given index is set.
        
        Returns False for bit >= Self.total_bits.
        """
        if bit < Self.word_size:
            mask = 1 << bit.cast[DType.uint64]()
            return (self.lo & mask) == mask
        else:
            mask = 1 << (bit - Self.word_size).cast[DType.uint64]()
            return (self.hi & mask) == mask
    

    fn set(inout self, bit: Self.IndexType, value: Bool):
        """Sets the state of bit at the given index.

        Has no effect for bit >= Self.word_size.
        """
        alias one: UInt64 = 1
        if bit < Self.word_size:
            if value:
                self.lo |= one << bit.cast[DType.uint64]()
            else:
                self.lo &= ~(one << bit.cast[DType.uint64]())
        else: 
            if value:
                self.hi |= one << (bit - Self.word_size).cast[DType.uint64]()
            else:
                self.hi &= ~(one << (bit - Self.word_size).cast[DType.uint64]())

    fn invert(self) -> BitMask:
        """Returns the inversion of this mask."""
        return BitMask(
            lo=~self.lo,
            hi=~self.hi,
        )

    fn is_zero(self) -> Bool:
        """Returns whether no bits are set in the mask."""
        return self.lo == 0 and self.hi == 0

    fn reset(inout self):
        """Resets the mask setting all bits to False."""
        self.lo = 0
        self.hi = 0

    fn contains(self, other: Self) -> Bool:
        """Reports if the other mask is a subset of this mask."""
        return ((self.lo & other.lo) == other.lo) and ((self.hi & other.hi) == other.hi)

    fn contains_any(self, other: Self) -> Bool:
        """Reports if any bit of the other mask is in this mask."""
        return (self.lo & other.lo) != 0 or self.hi&other.hi != 0

    fn total_bits_set(self) -> Int:
        """Returns how many bits are set in this mask."""
        return int(pop_count(self.hi) + pop_count(self.lo))

    fn __str__(self) -> String:
        """Implements str(...)."""
        var result: String = "["
        for i in range(Self.total_bits):
            if self.get(i): 
                result += "1"
            else:
                result += "0"
        result += "]"
        return result
    
    fn __repr__(self) -> String:
        """Representation string of the Mask."""
        return self.__str__()


    
fn all(ids: VariadicList[BitMask.IndexType]) -> BitMask:
    """
    Creates a new Mask from a list of IDs.
    matches all entities that have the respective components, and potentially further components.

    See also [Mask.without] and [Mask.exclusive]

    If any [ID_TYPE] is greater than or equal to [MASK_TOTAL_BITS], it will not be added to the mask.
    """
    mask = BitMask(0, 0)
    for id in ids:
        mask.set(id, True)
    
    return mask

fn all(*ids: BitMask.IndexType) -> BitMask:
    return all(ids)

