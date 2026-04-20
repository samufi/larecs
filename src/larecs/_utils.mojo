from std.memory import UnsafePointer, memcpy
from std.math import log2
from std.sys import bit_width_of, size_of


@always_inline
def next_pow2[
    dtype: DType = DType.uint
](var value: Scalar[dtype]) -> Scalar[dtype] where dtype.is_integral():
    """Returns the next power of two greater than or equal to the given value.

    Efficiently computes the smallest power of 2 that is greater than or equal to the
    input value using bit manipulation techniques.

    **Example:**
    ```mojo
    # Archetype capacity management
    var required_entities = 100
    var optimal_capacity = next_pow2(required_entities)  # Returns 128

    # Component pool sizing
    var component_count = 50
    var pool_size = next_pow2(component_count)  # Returns 64

    # Memory alignment for SIMD operations
    var data_size = 200
    var aligned_size = next_pow2(data_size)  # Returns 256
    ```

    **Mathematical Properties:**
    - `next_pow2(0)` returns 1 (special case for zero input)
    - `next_pow2(n)` returns `n` if `n` is already a power of 2
    - `next_pow2(n)` returns the smallest `2^k` where `2^k >= n`

    Parameters:
        dtype: The scalar data type. Must be an integral type for bit operations.

    Args:
        value: The value to find the next power of two for. Modified during computation.

    Returns:
        The next power of two greater than or equal to the given value.

    **Reference:**
    Based on the bit-smearing algorithm from Stanford Graphics Lab's bit manipulation
    reference: https://graphics.stanford.edu/~seander/bithacks.html#RoundUpPowerOf2.
    """
    if value == 0:
        return 1

    value -= 1
    comptime exp = Scalar[dtype](log2(Float32(bit_width_of[dtype]())))
    comptime for i in range(exp):
        comptime shift = 2**i
        value |= value >> shift

    return value + 1


@always_inline
def concatenate_inline_arrays[
    ElementType: Copyable & Movable, a_size: Int, b_size: Int
](
    a: InlineArray[ElementType, a_size],
    b: InlineArray[ElementType, b_size],
    out result: InlineArray[ElementType, a_size + b_size],
):
    result = {uninitialized = True}

    memcpy(dest=result.unsafe_ptr(), src=a.unsafe_ptr(), count=a_size)

    memcpy(
        dest=result.unsafe_ptr() + a_size * size_of[ElementType](),
        src=b.unsafe_ptr(),
        count=b_size,
    )
