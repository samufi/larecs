# Maximal UInt16 number
comptime MAX_UINT16 = 2**16 - 1


# MASK_TOTAL_BITS is the size of Mask in bits.
# It is the maximum number of component types that may exist in any [World].
comptime MASK_TOTAL_BITS = 256

comptime ID_TYPE = UInt8
comptime WORD_SIZE: ID_TYPE = 64
