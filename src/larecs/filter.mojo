from .bitmask import BitMask


# Filter is the interface for logic filters.
# Filters are required to query entities using [World.Query].
#
# See [BitMask], [MaskFilter] anf [RelationFilter] for basic filters.
# For type-safe generics queries, see package [github.com/mlange-42/arche/generic].
# For advanced filtering, see package [github.com/mlange-42/arche/filter].

# type Filter interface:
#     # matches the filter against a mask, i.e. a component composition.
#     matches(bits BitMask): Bool


@value
struct MaskFilter:
    """MaskFilter is a filter for including and excluding certain components.

    See [..bitmask.BitMask.without] and [..bitmask.BitMask.exclusive].
    """

    var include: BitMask  # Components to include.
    var exclude: BitMask  # Components to exclude.

    fn matches(self, bits: BitMask) -> Bool:
        """Matches the filter against a mask."""
        return bits.contains(self.include) and (
            self.exclude.is_zero() or not bits.contains_any(self.exclude)
        )


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
# fn (f *RelationFilter) matches(bits BitMask): Bool:
#     return f.Filter.matches(bits)

# # CachedFilter is a filter that is cached by the world.
# #
# # Create a cached filter from any other filter using [Cache.Register].
# # For details on caching, see [Cache].
# type CachedFilter struct:
#     filter Filter
#     id     uint32

# # matches the filter against a mask.
# fn (f *CachedFilter) matches(bits BitMask): Bool:
#     return f.filter.matches(bits)
