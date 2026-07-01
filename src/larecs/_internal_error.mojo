from std.builtin.globals import global_constant


@fieldwise_init
struct InternalError(Equatable, ImplicitlyCopyable, Writable):
    """
    Errors raised by internal operations.

    These indicate that something went wrong in the logic of Larecs and should be fixed internally.
    """

    var _variant: Int
    """Numeric discriminator for the error variant."""

    comptime UNKNOWN = InternalError(_variant=0)
    """Fallback error variant."""

    comptime out_of_locks = InternalError(_variant=1)
    """Error raised when no lock remain available."""
    comptime unbalanced_unlock = InternalError(_variant=2)
    """Error raised when unlocking a lock that was not locked."""

    comptime ran_out_of_capacity = InternalError(_variant=3)
    """Error raised when the current capacity is exceeded."""

    def variant_name(self) -> StaticString:
        """
        Returns the variant name.

        Returns:
            The name of the error variant.
        """
        comptime INTERNAL_ERROR_VARIANT_NAMES: InlineArray[StaticString, 4] = [
            "unknown",
            "out_of_locks",
            "unbalanced_unlock",
            "ran_out_of_capacity",
        ]
        ref global_variant_names = global_constant[
            INTERNAL_ERROR_VARIANT_NAMES
        ]()
        return global_variant_names[self._variant]

    def msg(self) -> StaticString:
        """
        Returns the error message.

        Returns:
            The human-readable error message.
        """
        comptime INTERNAL_ERROR_VARIANT_MESSAGES: InlineArray[
            StaticString, 4
        ] = [
            "Unknown error.",
            "The number of locks exceeds the maximum limit of 256.",
            (
                "Unbalanced unlock. Did you close a query that was already"
                " iterated?"
            ),
            "No more capacity available.",
        ]

        ref global_variant_messages = global_constant[
            INTERNAL_ERROR_VARIANT_MESSAGES
        ]()
        return global_variant_messages[self._variant]

    def write_to(self, mut writer: Some[Writer]):
        """
        Writes the error to the given writer.

        Args:
            writer: The writer to write to.
        """
        writer.write("LockError.", self.variant_name(), ": ", self.msg())
