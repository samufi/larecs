from bit import bit_reverse

from .types import EntityId
from .archetype import Archetype

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

    Entities are only created via the [..world.World], using [..world.World.add_entity].

    ⚠️ Important:
    Entities are intended to be stored and passed around via copy, not via pointers!
    The zero value should be used to indicate "nil", and can be checked with [.Entity.is_zero].
    """

    var _id: EntityId
    """Entity ID"""
    var _generation: UInt32
    """Entity generation"""

    @doc_private
    @always_inline
    fn __init__(mut self, id: EntityId = 0, generation: UInt32 = 0):
        self._id = id
        self._generation = generation

    @always_inline
    fn __eq__(self, other: Entity) -> Bool:
        """
        Compares two entities for equality.

        Args:
            other: The other entity to compare to.
        """
        return self._id == other._id and self._generation == other._generation

    @always_inline
    fn __ne__(self, other: Entity) -> Bool:
        """
        Compares two entities for inequality.

        Args:
            other: The other entity to compare to.
        """
        return not (self == other)

    @always_inline
    fn __bool__(self) -> Bool:
        """
        Returns whether this entity is not the zero entity.
        """
        return self._id != 0

    @always_inline
    fn __str__(self) -> String:
        """
        Returns a string representation of the entity.
        """
        return (
            "Entity(" + String(self._id) + ", " + String(self._generation) + ")"
        )

    @always_inline
    fn __hash__(self, out output: UInt):
        """Returns a unique hash of the entity."""
        output = Int(self._id)
        output |= bit_reverse(Int(self._generation))

    @always_inline
    fn get_id(self) -> EntityId:
        """Returns the entity's ID."""
        return self._id

    @always_inline
    fn get_generation(self) -> UInt32:
        """Returns the entity's generation."""
        return self._generation

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns whether this entity is the reserved zero entity."""
        return self._id == 0


@value
@register_passable("trivial")
struct EntityIndex:
    """Indicates where an entity is currently stored."""

    # Entity's current index in the archetype
    var index: UInt32

    # Entity's current archetype
    var archetype_index: UInt32
