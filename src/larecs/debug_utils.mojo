from std.sys.defines import is_defined

from tracy import Zone


@always_inline
def warn(msg: Some[Writable]) -> None:
    """Prints a warning message."""
    with Zone(function_name="debug_utils.warn(msg: Some[Writable])"):
        print("Warning: ", msg)


@always_inline
def debug_warn(msg: Some[Writable]) -> None:
    """Prints a debug warning message."""

    with Zone(function_name="debug_utils.debug_warn(msg: Some[Writable])"):
        comptime if is_defined["DEBUG_MODE"]():
            warn(msg)
