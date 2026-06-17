from std.sys.defines import is_defined


@always_inline
def warn(msg: Some[Writable]) -> None:
    """Prints a warning message."""
    print("Warning: ", msg)


@always_inline
def debug_warn(msg: Some[Writable]) -> None:
    """Prints a debug warning message."""

    comptime if is_defined["DEBUG_MODE"]():
        warn(msg)
