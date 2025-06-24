from .types import EntityId
from .entity import Entity
from .constants import MAX_UINT16


struct EntityPool(Copyable, Movable, Sized):
    """EntityPool is an implementation using implicit linked lists.

    Implements https:#skypjack.github.io/2019-05-06-ecs-baf-part-3/
    """

    var _entities: List[Entity]
    var _next: EntityId
    var _available: Int

    @always_inline
    fn __init__(out self):
        self._entities = List[Entity]()
        self._entities.append(Entity(0, MAX_UINT16))
        self._next = 0
        self._available = 0

    fn __copyinit__(out self, other: Self):
        self._entities = other._entities
        self._next = other._next
        self._available = other._available

    fn __moveinit__(out self, owned other: Self):
        self._entities = other._entities^
        self._next = other._next
        self._available = other._available

    fn get(mut self) -> Entity:
        """Returns a fresh or recycled entity."""
        if self._available == 0:
            return self._get_new()

        curr = self._next
        self._entities[self._next]._id, self._next = (
            self._next,
            self._entities[self._next].get_id(),
        )
        self._available -= 1
        return self._entities[curr]

    @always_inline
    fn _get_new(mut self, out entity: Entity):
        """Allocates and returns a new entity. For internal use."""
        entity = Entity(EntityId(len(self._entities)))
        self._entities.append(entity)

    fn recycle(mut self, entity: Entity) raises:
        """Hands an entity back for recycling."""
        if entity.get_id() == 0:
            raise Error("Can't recycle reserved zero entity")

        self._entities[entity.get_id()]._generation += 1

        tmp = self._next
        self._next = entity.get_id()
        self._entities[entity.get_id()]._id = tmp
        self._available += 1

    @always_inline
    fn reset(mut self):
        """Recycles all entities. Does NOT free the reserved memory."""
        self._entities.shrink(1)
        self._next = 0
        self._available = 0

    @always_inline
    fn is_alive(self, entity: Entity) -> Bool:
        """Returns whether an entity is still alive, based on the entity's generations.
        """
        return entity._generation == self._entities[entity.get_id()]._generation

    @always_inline
    fn __len__(self) -> Int:
        """Returns the current number of used entities."""
        return len(self._entities) - 1 - self._available

    @always_inline
    fn capacity(self) -> Int:
        """Returns the current capacity (used and recycled entities)."""
        return len(self._entities) - 1

    @always_inline
    fn available(self) -> Int:
        """Returns the current number of available/recycled entities."""
        return self._available


@fieldwise_init
struct BitPool(Copyable, Movable):
    """BitPool is a pool of bits with ability to obtain an un-set bit and to recycle it for later use.

    This implementation uses an implicit list.
    """

    alias capacity = Int(UInt8.MAX_FINITE) + 1
    var _bits: SIMD[DType.uint8, Self.capacity]
    var _next: UInt8
    var _available: UInt8

    # The length must be able to express that the pool is full.
    # Hence, the data type must be larger than the index
    # data type.
    var _length: UInt16

    @always_inline
    fn __init__(out self):
        self._bits = SIMD[DType.uint8, Self.capacity]()
        self._next = 0
        self._length = 0
        self._available = 0

    fn get(mut self) raises -> UInt8:
        """Returns a fresh or recycled bit.

        Raises:
            Error: If the pool is full.
        """
        if self._available == 0:
            return self._get_new()

        curr = self._next
        self._next, self._bits[index(self._next)] = (
            self._bits[index(self._next)],
            self._next,
        )
        self._available -= 1
        return self._bits[index(curr)]

    fn _get_new(mut self) raises -> UInt8:
        """Allocates and returns a new bit. For internal use.

        Raises:
            Error: If the pool is full.
        """
        if self._length >= Self.capacity:
            raise Error(
                String("Ran out of the capacity of {} bits").format(
                    Self.capacity
                )
            )

        bit = self._length.cast[DType.uint8]()
        self._bits[index(self._length)] = bit
        self._length += 1
        return bit

    @always_inline
    fn recycle(mut self, bit: UInt8):
        """Hands a bit back for recycling."""
        self._next, self._bits[index(bit)] = bit, self._next
        self._available += 1

    @always_inline
    fn reset(mut self):
        """Recycles all bits."""
        self._next = 0
        self._length = 0
        self._available = 0


struct IntPool:
    """IntPool is a pool implementation using implicit linked lists.

    Implements https:#skypjack.github.io/2019-05-06-ecs-baf-part-3/
    """

    var _pool: List[Int, True]
    var _next: Int
    var _available: UInt32

    @always_inline
    fn __init__(out self):
        """Creates a new, initialized entity pool."""
        self._pool = List[Int, True]()
        self._next = 0
        self._available = 0

    fn get(mut self) -> Int:
        """Returns a fresh or recycled entity."""
        if self._available == 0:
            return self._get_new()

        curr = self._next
        self._next, self._pool[self._next] = (
            self._pool[self._next],
            self._next,
        )
        self._available -= 1
        return self._pool[curr]

    @always_inline
    fn _get_new(mut self) -> Int:
        """Allocates and returns a new entity. For internal use."""
        element = len(self._pool)
        self._pool.append(element)
        return element

    @always_inline
    fn recycle(mut self, element: Int):
        """Hands an entity back for recycling."""
        self._next, self._pool[element] = element, self._next
        self._available += 1

    @always_inline
    fn reset(mut self):
        """Recycles all _entities. Does NOT free the reserved memory."""
        self._pool.clear()
        self._next = 0
        self._available = 0
