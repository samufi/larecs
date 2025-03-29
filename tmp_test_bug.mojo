from collections import Dict


@value
@register_passable
struct BitMask(KeyElement):
    alias total_bytes = 16

    var _bytes: SIMD[DType.uint8, Self.total_bytes]

    @always_inline
    fn __hash__(self) -> UInt:
        print("__hash__")
        return hash(self._bytes)

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        print("__eq__")
        return (self._bytes == other._bytes).reduce_and()

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        print("__ne__")
        return not self.__eq__(other)


def main():
    map = Dict[BitMask, Int]()
    simd = SIMD[DType.uint8, BitMask.total_bytes]()
    print("Setting mask with 0")
    bm = BitMask(simd)
    map[bm] = 0
    simd[0] = 1
    bm = BitMask(simd)
    print("Setting mask with 1")
    map[BitMask(simd)] = 0
    print("Done")
