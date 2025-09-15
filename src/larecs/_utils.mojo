from memory import UnsafePointer
import math


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
    return UInt(next_pow2[DType.index](value))


@always_inline
fn next_pow2[dtype: DType](var value: Scalar[dtype]) -> Scalar[dtype]:
    """Returns the next power of two greater than or equal to the given value.
        See https://graphics.stanford.edu/~seander/bithacks.html#RoundUpPowerOf2.

    Args:
        value: The value to find the next power of two for.

    Returns:
        The next power of two greater than or equal to the given value.
    """
    constrained[dtype.is_integral(), "expected integral dtype"]()

    if value == 0:
        return 1

    @parameter
    for i in range(Scalar[dtype](math.log2(Float32(dtype.bitwidth())))):
        value |= value >> (2**i)

    return value + 1
