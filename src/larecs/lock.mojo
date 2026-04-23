from .bitmask import BitMask
from .pool import BitPool


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
    def lock(mut self) raises -> Int:
        """
        Locks the world and gets the Lock bit for later unlocking.

        Raises:
            Error: If the number of locks exceeds 256.
        """
        lock = self.bit_pool.get()
        self.locks.set[True](lock)
        return lock

    @always_inline
    def unlock(mut self, lock: Int) raises:
        """
        Unlocks the given lock bit.

        Raises:
            Error: If the lock is not set.
        """
        if not self.locks.get(lock):
            raise Error(
                "Unbalanced unlock. Did you close a query that was already"
                " iterated?"
            )

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
    def __enter__(mut self) raises -> Self:
        """
        Locks the world.

        Returns:
            The LockedContext.

        Raises:
            Error: If the number of locks exceeds 256.
        """
        self._lock = self._locks[].lock()
        return self

    @always_inline
    def __exit__(mut self) raises:
        """
        Unlocks the world.

        Raises:
            Error: If the number of locks exceeds 256.
        """
        self._locks[].unlock(self._lock)
