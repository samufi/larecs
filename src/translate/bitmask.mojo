from math.bit import ctpop
from filter import MaskFilter

# Moved to constants
# # MASK_TOTAL_BITS is the size of Mask in bits.
# #
# # It is the maximum number of component types that may exist in any [World].
# alias MASK_TOTAL_BITS = 128
# alias ID_TYPE = UInt8
# alias WORD_SIZE: ID_TYPE = 64

@value
struct Mask(Stringable):
    """Mask is a 128 bit bitmask.
    It is also a [Filter] for including certain components.
    
    Use [all] to create a mask for a list of component IDs.
    A mask can be further specified using [Mask.without] or [Mask.exclusive].
    """
    var lo: UInt64 # First 64 bits of the mask
    var hi: UInt64 # Second 64 bits of the mask

    fn matches(self, bits: Mask) -> Bool:
        """Matches the mask as filter against another mask.
        """
        return bits.contains(self)

    fn without(self, *comps: ID_TYPE) -> MaskFilter:
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

    fn get(self, bit: ID_TYPE) -> Bool:
        """Reports whether the bit at the given index [ID_TYPE] is set.
        
        Returns False for bit >= [MASK_TOTAL_BITS].
        """
        if bit < WORD_SIZE:
            let mask = 1 << bit.cast[DType.uint64]()
            return (self.lo & mask) == mask
        else:
            let mask = 1 << (bit - WORD_SIZE).cast[DType.uint64]()
            return (self.hi & mask) == mask
    

    fn set(inout self, bit: ID_TYPE, value: Bool):
        """Sets the state of bit at the given index.

        Has no effect for bit >= [MASK_TOTAL_BITS].
        """
        let one: UInt64 = 1
        if bit < WORD_SIZE:
            if value:
                self.lo |= one << bit.cast[DType.uint64]()
            else:
                self.lo &= ~(one << bit.cast[DType.uint64]())
        else: 
            if value:
                self.hi |= one << (bit - WORD_SIZE).cast[DType.uint64]()
            else:
                self.hi &= ~(one << (bit - WORD_SIZE).cast[DType.uint64]())

    fn invert(self) -> Mask:
        """Returns the inversion of this mask."""
        return Mask(
            lo=~self.lo,
            hi=~self.hi,
        )

    fn is_zero(self) -> Bool:
        """Returns whether no bits are set in the mask."""
        return self.lo == 0 and self.hi == 0

    fn reset(inout self):
        """Resets the mask setting all bits to False."""
        self.lo = False
        self.hi = False

    fn contains(self, other: Mask) -> Bool:
        """Reports if the other mask is a subset of this mask."""
        return ((self.lo & other.lo) == other.lo) and ((self.hi & other.hi) == other.hi)

    fn contains_any(self, other: Mask) -> Bool:
        """Reports if any bit of the other mask is in this mask."""
        return (self.lo & other.lo) != 0 or self.hi&other.hi != 0

    fn total_bits_set(self) -> Int:
        """Returns how many bits are set in this mask."""
        return (ctpop[DType.uint64, 1](self.hi) + ctpop[DType.uint64, 1](self.lo)).to_int()

    fn __str__(self) -> String:
        """Implements str(...)"""
        var result: String = "["
        for i in range(MASK_TOTAL_BITS):
            if self.get(i): 
                result += "1, "
            else:
                result += "0, "
        result += "]"
        return result
    
    fn __repr__(self) -> String:
        """Representation string of the Mask"""
        return self.__str__()


    
fn all(ids: VariadicList[ID_TYPE]) -> Mask:
    """
    Creates a new Mask from a list of IDs.
    matches all entities that have the respective components, and potentially further components.

    See also [Mask.without] and [Mask.exclusive]

    If any [ID_TYPE] is greater than or equal to [MASK_TOTAL_BITS], it will not be added to the mask.
    """
    var mask = Mask(0, 0)
    for id in ids:
        mask.set(id, True)
    
    return mask

fn all(*ids: ID_TYPE) -> Mask:
    return all(ids)

