from memory import UnsafePointer
from math import log2


@always_inline
fn unsafe_take[T: Movable](mut arg: T, out result: T):
    """
    Takes a value and moves it to a different location in memory.

    [!Caution]
    This function leaves the original value in an invalid state.
    The value passed to this function should not be used after the call!
    Also, you need to prevent calling the destructors of the elements.
    You may use `__disable_del` for that.

    Parameters:
        T: The type of the value to be moved.

    Args:
        arg: The value to be moved.

    Returns:
        Result: The moved value.
    """
    result = UnsafePointer.take_pointee(UnsafePointer(to=arg))


# Implementing a function generically over all integral types is not currently possible in Mojo.
# For details see: https://github.com/modular/modular/issues/2776.
@always_inline
fn next_pow2(var value: UInt) -> UInt:
    """Returns the next power of two greater than or equal to the given value.

    Efficiently computes the smallest power of 2 that is greater than or equal to the
    input value using bit manipulation techniques.

    Args:
        value: The UInt value to find the next power of two for.

    Returns:
        The next power of two greater than or equal to the given value.
    """
    return UInt(next_pow2[DType.uint](value))


@always_inline
fn next_pow2[dtype: DType](var value: Scalar[dtype]) -> Scalar[dtype]:
    """Returns the next power of two greater than or equal to the given value.

    Efficiently computes the smallest power of 2 that is greater than or equal to the
    input value using bit manipulation techniques.

    **Algorithm Context:**
    Uses the classic bit-smearing technique from "Bit Twiddling Hacks" by Sean Elers Anderson.
    The algorithm works by propagating the highest set bit to all lower positions,
    then adding 1 to get the next power of 2.

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

    **Performance Benefits in ECS:**
    - **Memory Allocators**: Most allocators are optimized for power-of-2 sizes
    - **Cache Alignment**: Power-of-2 sizes align with CPU cache line boundaries
    - **SIMD Vectorization**: Enables efficient vectorized operations on component data
    - **Fragmentation Reduction**: Reduces memory fragmentation in long-running systems

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
    constrained[dtype.is_integral(), "expected integral dtype"]()

    if value == 0:
        return 1

    @parameter
    for i in range(Scalar[dtype](log2(Float32(dtype.bit_width())))):
        value |= value >> (2**i)

    return value + 1
