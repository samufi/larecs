from bitmask import Mask


# Filter is the interface for logic filters.
# Filters are required to query entities using [World.Query].
#
# See [Mask], [MaskFilter] anf [RelationFilter] for basic filters.
# For type-safe generics queries, see package [github.com/mlange-42/arche/generic].
# For advanced filtering, see package [github.com/mlange-42/arche/filter].

# type Filter interface:
#     # matches the filter against a mask, i.e. a component composition.
#     matches(bits Mask): Bool

@value
struct MaskFilter:
    """MaskFilter is a [Filter] for including and excluding certain components.

    See [all], [Mask.without] and [Mask.exclusive].
    """
    var include: Mask # Components to include.
    var exclude: Mask # Components to exclude.

    fn matches(self, bits: Mask) -> Bool:
        """Matches the filter against a mask."""
        return bits.contains(self.include) and (self.exclude.is_zero() or not bits.contains_any(self.exclude))

# # RelationFilter is a [Filter] for a [Relation] target, in addition to components.
# #
# # See [Relation] for details and examples.
# struct RelationFilter:
#     Filter Filter # Components filter.
#     Target Entity # Relation target entity.

# # NewRelationFilter creates a new [RelationFilter].
# # It is a [Filter] for a [Relation] target, in addition to components.
# fn NewRelationFilter(filter Filter, target Entity) RelationFilter:
#     return RelationFilter{
#         Filter: filter,
#         Target: target,
    

# # matches the filter against a mask.
# fn (f *RelationFilter) matches(bits Mask): Bool:
#     return f.Filter.matches(bits)

# # CachedFilter is a filter that is cached by the world.
# #
# # Create a cached filter from any other filter using [Cache.Register].
# # For details on caching, see [Cache].
# type CachedFilter struct:
#     filter Filter
#     id     uint32

# # matches the filter against a mask.
# fn (f *CachedFilter) matches(bits Mask): Bool:
#     return f.filter.matches(bits)
