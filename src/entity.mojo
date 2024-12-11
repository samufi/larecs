from types import EntityId
from bit import bit_reverse
from archetype import Archetype
from types import TrivialIntable

# # Reflection type of an [Entity].
# var entityType = reflect.TypeOf(Entity{})

# # Size of an [Entity] in memory, in bytes.
# var entitySize uint32 = uint32(entityType.Size())

# # Size of an [entityIndex] in memory.
# var entityIndexSize uint32 = uint32(reflect.TypeOf(entityIndex{}).Size())


@register_passable("trivial")
struct Entity(EqualityComparable, Stringable, Hashable):
    """Entity identifier.
    Holds an entity ID and it's generation for recycling.

    Entities are only created via the [World], using [World.NewEntity] or [World.NewEntityWith].
    Batch creation of entities is possible via [Builder].

    ⚠️ Important:
    Entities are intended to be stored and passed around via copy, not via pointers!
    The zero value should be used to indicate "nil", and can be checked with [Entity.is_zero].
    """

    var id: EntityId  # Entity ID
    var gen: UInt16  # Entity generation

    @always_inline
    fn __init__(inout self, id: EntityId = 0, gen: UInt16 = 0):
        self.id = id
        self.gen = gen

    @always_inline
    fn __eq__(self, other: Entity) -> Bool:
        return self.id == other.id and self.gen == other.gen

    @always_inline
    fn __ne__(self, other: Entity) -> Bool:
        return not (self == other)

    @always_inline
    fn __bool__(self) -> Bool:
        return self.id != 0

    @always_inline
    fn __str__(self) -> String:
        return "Entity(" + str(self.id) + ", " + str(self.gen) + ")"

    @always_inline
    fn __hash__(self) -> UInt as output:
        """Returns a unique hash."""
        output = int(self.id)
        output |= bit_reverse(int(self.gen))

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns whether this entity is the reserved zero entity."""
        return self.id == 0


@value
@register_passable("trivial")
struct EntityIndex:
    """Indicates where an entity is currently stored."""

    # Entity's current index in the archetype
    var index: UInt32

    # Entity's current archetype
    var archetype_index: UInt32
