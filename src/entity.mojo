from types import EntityId
from bit import bit_reverse

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
    var id: EntityId # Entity ID
    var gen: UInt16  # Entity generation

    fn __init__(inout self, id: EntityId = 0, gen: UInt16 = 0):
        self.id = id
        self.gen = gen

    fn __eq__(self, other: Entity) -> Bool:
        return self.id == other.id and self.gen == other.gen

    fn __ne__(self, other: Entity) -> Bool:
        return not (self == other)

    fn __str__(self) -> String:
        return "Entity(" + str(self.id) + ", " + str(self.gen) + ")"

    fn __hash__(self) -> UInt:
        var output: UInt = int(self.id)
        output |= bit_reverse(int(self.gen))
        return output

    fn is_zero(self) -> Bool:
        """Returns whether this entity is the reserved zero entity.
        """
        return self.id == 0

@register_passable("trivial")
struct EntityIndex:
    """Indicates where an entity is currently stored.
    """
    var index UInt32       # Entity's current index in the archetype
    # TODO
    # arch  *archetype # Entity's current archetype
