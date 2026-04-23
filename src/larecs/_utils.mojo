from std.memory import memcpy
from std.sys import size_of


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
