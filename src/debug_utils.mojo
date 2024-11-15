from sys.param_env import is_defined

@always_inline
fn warn(msg: String) -> None:
    """Prints a warning message."""
    print("Warning: " + msg)


@always_inline
fn debug_warn(msg: String) -> None:
    """Prints a debug warning message."""
    @parameter
    if is_defined["DEBUG_MODE"]():
        warn(msg)