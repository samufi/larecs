from .bitmask import BitMask
from .pool import BitPool


@fieldwise_init
struct LockError(Equatable, ImplicitlyCopyable, Writable):
    """
    Typed errors raised by lock operations.
    """

    var _variant: Int

    comptime UNKNOWN = LockError(_variant=0)
    comptime out_of_locks = LockError(_variant=1)
    comptime unbalanced_unlock = LockError(_variant=2)

    def variant_name(self) -> String:
        """
        Returns the variant name.

        Returns:
            The name of the error variant.
        """
        if self._variant == Self.out_of_locks._variant:
            return "out_of_locks"
        elif self._variant == Self.unbalanced_unlock._variant:
            return "unbalanced_unlock"
        else:
            return "unknown"

    def msg(self) -> String:
        """
        Returns the error message.

        Returns:
            The human-readable error message.
        """
        if self._variant == Self.out_of_locks._variant:
            return "The number of locks exceeds the maximum limit of 256."
        elif self._variant == Self.unbalanced_unlock._variant:
            return (
                "Unbalanced unlock. Did you close a query that was already"
                " iterated?"
            )
        else:
            return "Unknown error."

    def write_to(self, mut writer: Some[Writer]):
        """
        Writes the error to the given writer.

        Args:
            writer: The writer to write to.
        """
        writer.write("LockError.", self.variant_name(), ": ", self.msg())


@fieldwise_init
struct LockManager(Copyable, Movable):
    """
    Manages locks by mask bits.

    The number of simultaneous locks at a given time is limited to [..bitmask.BitMask.total_bits].
    """

    var locks: BitMask  # The actual locks.
    var bit_pool: BitPool  # The bit pool for getting and recycling bits.

    @always_inline
    def __init__(out self):
        self.locks = BitMask()
        self.bit_pool = BitPool()

    @always_inline
    def lock(mut self, out lock: Int) raises LockError:
        """
        Locks the world and gets the Lock bit for later unlocking.

        Raises:
            LockError: If the number of locks exceeds 256.
        """
        try:
            lock = self.bit_pool.get()
        except Error:
            raise LockError.out_of_locks

        self.locks.set[True](lock)

    @always_inline
    def unlock(mut self, lock: Int) raises LockError:
        """
        Unlocks the given lock bit.

        Raises:
            LockError: If the lock is not set.
        """
        if not self.locks.get(lock):
            raise LockError.unbalanced_unlock

        self.locks.set[False](lock)
        self.bit_pool.recycle(lock)

    @always_inline
    def is_locked(self) -> Bool:
        """
        IsLocked returns whether the world is locked by any queries.
        """
        return not self.locks.is_zero()

    @always_inline
    def reset(mut self):
        """
        Reset the locks and the pool.
        """
        self.locks = BitMask()
        self.bit_pool.reset()

    @always_inline
    def locked(mut self) -> LockedContext[origin_of(self)]:
        """
        Returns a locked context.
        """
        return LockedContext(Pointer(to=self))


@fieldwise_init
struct LockedContext[origin: MutOrigin](ImplicitlyCopyable, Movable):
    """
    A context manager for locking and unlocking the world.

    Parameters:
        origin: The origin of the LockManager to handle.
    """

    var _locks: Pointer[LockManager, Self.origin]
    var _lock: Int

    @always_inline
    def __init__(out self, locks: Pointer[LockManager, Self.origin]):
        """
        Initializes the LockedContext.

        Args:
            locks: The LockManager to handle.
        """
        self._locks = locks
        self._lock = 0

    @always_inline
    def __enter__(mut self) raises LockError -> Self:
        """
        Locks the world.

        Returns:
            The LockedContext.

        Raises:
            LockError: If the number of locks exceeds 256.
        """
        self._lock = self._locks[].lock()
        return self

    @always_inline
    def __exit__(mut self) raises LockError:
        """
        Unlocks the world.

        Raises:
            LockError: If the number of locks exceeds 256.
        """
        self._locks[].unlock(self._lock)
