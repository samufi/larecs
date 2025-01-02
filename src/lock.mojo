from bitmask import BitMask
from pool import BitPool


@value
struct LockMask:
    """
    Manages locks by mask bits.

    The number of simultaneous locks at a given time is limited to [MaskTotalBits].
    """

    var locks: BitMask  # The actual locks.
    var bit_pool: BitPool  # The bit pool for getting and recycling bits.

    @always_inline
    fn __init__(inout self):
        self.locks = BitMask()
        self.bit_pool = BitPool()

    @always_inline
    fn lock(inout self) raises -> UInt8:
        """
        Locks the world and gets the Lock bit for later unlocking.
        """
        lock = self.bit_pool.get()
        self.locks.set[True](lock)
        return lock

    @always_inline
    fn unlock(inout self, lock: UInt8) raises:
        """
        Unlocks the given lock bit.
        """
        if not self.locks.get(lock):
            raise Error(
                "Unbalanced unlock. Did you close a query that was already"
                " iterated?"
            )

        self.locks.set[False](lock)
        self.bit_pool.recycle(lock)

    @always_inline
    fn is_locked(self) -> Bool:
        """
        IsLocked returns whether the world is locked by any queries.
        """
        return not self.locks.is_zero()

    @always_inline
    fn reset(inout self):
        """
        Reset the locks and the pool.
        """
        self.locks = BitMask()
        self.bit_pool.reset()
