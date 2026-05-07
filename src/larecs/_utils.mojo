from std.memory import memcpy
from std.sys.defines import is_defined
from std.time import global_perf_counter_ns


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
        dest=result.unsafe_ptr() + a_size,
        src=b.unsafe_ptr(),
        count=b_size,
    )


def _assert_index_in_bounds(index: Int, size: Int):
    """Asserts that an index refers to a valid element.

    Args:
        index: The candidate index to validate.
        size: The logical number of available elements.
    """
    assert 0 <= index and index < size, "Index out of bounds"


def _assert_range_in_bounds(start_index: Int, count: Int, size: Int):
    """Asserts that a consecutive range fits into a logical size.

    Args:
        start_index: The index of the first element in the range.
        count: The number of elements in the range.
        size: The logical number of available elements.
    """
    debug_assert(0 <= count, "Count must be non-negative.")

    if count == 0:
        return

    _assert_index_in_bounds(start_index, size)
    _assert_index_in_bounds(start_index + count - 1, size)


@always_inline
def _trace_function[inout: StaticString](name: StaticString):
    """Prints a function trace when tracing is enabled.

    Parameters:
        inout: The trace marker direction. Supported values are `"IN"` and `"OUT"`.

    Args:
        name: The function name to emit.

    Constraints:
        `inout` must be either `"IN"` or `"OUT"`.
    """
    comptime assert (
        inout == "IN" or inout == "OUT"
    ), "Trace direction must be IN or OUT."

    comptime if is_defined["TRACE_FUNCTIONS"]():
        timestamp_ns = global_perf_counter_ns()
        comptime if inout == "IN":
            print(t"[IN] , {name}, {timestamp_ns} ns")
        elif inout == "OUT":
            print(t"[OUT], {name}, {timestamp_ns} ns")
