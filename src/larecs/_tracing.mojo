from std.sys.defines import is_defined
from std.time import global_perf_counter_ns


@always_inline
def _trace_function[inout: StaticString](name: StaticString):
    """Prints a function trace when tracing is enabled.

    Parameters:
        inout: The trace marker direction. Constraints: `inout` must be either `"IN"` or `"OUT"`.

    Args:
        name: The function name to emit.

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


@fieldwise_init
struct TraceGuard(ImplicitlyCopyable):
    """A guard object for function tracing.

    When created, it emits an "IN" trace, and when dropped, it emits an "OUT" trace.
    """

    var name: StaticString
    """The function name emitted by the trace guard."""

    @always_inline
    def __enter__(mut self):
        """Emits the function-entry trace message."""
        _trace_function["IN"](self.name)

    @always_inline
    def __exit__(mut self):
        """Emits the function-exit trace message."""
        _trace_function["OUT"](self.name)

    @always_inline
    def __exit__[
        ErrType: AnyType
    ](mut self, err: ErrType) raises ErrType -> Bool:
        """Emits the function-exit trace message and propagates the error.

        Args:
            err: The error to propagate.

        Returns:
            False to indicate the error should be propagated.
        """
        self.__exit__()
        return False
