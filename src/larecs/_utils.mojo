from memory import UnsafePointer


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
