from types import EntityId, get_max_uint_size_of_half_type, TrivialIntable
from entity import Entity
from constants import MAX_UINT16


trait IntableCollectionElement(Intable):
    fn __init__[IndexerTy: Indexer](out self, value: IndexerTy):
        ...


struct EntityPool:
    """EntityPool is an implementation using implicit linked lists.

    Implements https:#skypjack.github.io/2019-05-06-ecs-baf-part-3/
    """

    var _entities: List[Entity]
    var _next: EntityId
    var _available: UInt32

    fn __init__(inout self):
        self._entities = List[Entity]()
        self._entities.append(Entity(0, MAX_UINT16))
        self._next = 0
        self._available = 0

    fn get(inout self) -> Entity:
        """Returns a fresh or recycled entity."""
        if self._available == 0:
            return self._get_new()

        curr = self._next
        self._entities[int(self._next)].id, self._next = (
            self._next,
            self._entities[int(self._next)].id,
        )
        self._available -= 1
        return self._entities[int(curr)]

    fn _get_new(inout self) -> Entity as entity:
        """Allocates and returns a new entity. For internal use."""
        entity = Entity(EntityId(len(self._entities)))
        self._entities.append(entity)

    fn recycle(inout self, enitity: Entity) raises:
        """Hands an entity back for recycling."""
        if enitity.id == 0:
            raise Error("Can't recycle reserved zero entity")

        self._entities[int(enitity.id)].gen += 1
        self._next, self._entities[int(enitity.id)].id = enitity.id, self._next
        self._available += 1

    fn reset(inout self):
        """Recycles all entities. Does NOT free the reserved memory."""
        self._entities.resize(1)
        self._next = 0
        self._available = 0

    fn is_alive(self, entity: Entity) -> Bool:
        """Returns whether an entity is still alive, based on the entity's generations.
        """
        return entity.gen == self._entities[int(entity.id)].gen

    fn __len__(self) -> Int:
        """Returns the current number of used entities."""
        return len(self._entities) - 1 - int(self._available)

    fn capacity(self) -> Int:
        """Returns the current capacity (used and recycled entities)."""
        return len(self._entities) - 1

    fn available(self) -> Int:
        """Returns the current number of available/recycled entities."""
        return int(self._available)


struct BitPool[LengthDType: DType = DType.uint16]:
    """BitPool is a pool of bits with ability to obtain an un-set bit and to recycle it for later use.

    This implementation uses an implicit list.

    Parameters:
        LengthDType: The data type of the length attribute of the pool.
                     This controls how many bits can be stored in the pool,
                     namely 2 ** (number_of_bits(LengthType) / 2).
    """

    alias LengthType = SIMD[LengthDType, 1]

    # The length must be able to express that the pool is full.
    # Hence, the capacity must be smaller than the maximum value of the length type.
    # Since the capacity must be a power of 2, the largest possible capacity is
    # half of the maximum value.
    alias capacity = get_max_uint_size_of_half_type[Self.LengthType]()

    var _bits: SIMD[DType.uint8, Self.capacity]
    var _next: UInt8
    var _length: Self.LengthType
    var _available: UInt8

    fn __init__(inout self):
        self._bits = SIMD[DType.uint8, Self.capacity]()
        self._next = 0
        self._length = 0
        self._available = 0

    fn get(inout self) raises -> UInt8:
        """Returns a fresh or recycled bit."""
        if self._available == 0:
            return self._get_new()

        curr = self._next
        self._next, self._bits[int(self._next)] = (
            self._bits[int(self._next)],
            self._next,
        )
        self._available -= 1
        return self._bits[int(curr)]

    fn _get_new(inout self) raises -> UInt8 as bit:
        """Allocates and returns a new bit. For internal use."""
        if int(self._length) >= Self.capacity:
            raise Error(
                String("Ran out of the capacity of {} bits").format(
                    Self.capacity
                )
            )

        bit = UInt8(int(self._length))
        self._bits[int(self._length)] = bit
        self._length += 1
        return

    fn recycle(inout self, bit: UInt8):
        """Hands a bit back for recycling."""
        self._next, self._bits[int(bit)] = bit, self._next
        self._available += 1

    fn reset(inout self):
        """Recycles all bits."""
        self._next = 0
        self._length = 0
        self._available = 0


struct IntPool[ElementType: IntableCollectionElement = Int]:
    """IntPool is a pool implementation using implicit linked lists.

    Implements https:#skypjack.github.io/2019-05-06-ecs-baf-part-3/
    """

    var _pool: List[ElementType, True]
    var _next: ElementType
    var _available: UInt32

    fn __init__(inout self):
        """Creates a new, initialized entity pool."""
        self._pool = List[ElementType, True]()
        self._next = ElementType(0)
        self._available = 0

    fn get(inout self) -> ElementType:
        """Returns a fresh or recycled entity."""
        if self._available == 0:
            return self._get_new()

        curr = self._next
        self._next, self._pool[int(self._next)] = (
            self._pool[int(self._next)],
            self._next,
        )
        self._available -= 1
        return self._pool[int(curr)]

    fn _get_new(inout self) -> ElementType:
        """Allocates and returns a new entity. For internal use."""
        element = ElementType(len(self._pool))
        self._pool.append(element)
        return element

    fn recycle(inout self, element: ElementType):
        """Hands an entity back for recycling."""
        self._next, self._pool[int(element)] = element, self._next
        self._available += 1

    fn reset(inout self):
        """Recycles all _entities. Does NOT free the reserved memory."""
        self._pool.clear()
        self._next = ElementType(0)
        self._available = 0
