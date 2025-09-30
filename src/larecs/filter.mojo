from .bitmask import BitMask
from .static_optional import StaticOptional


# Filter is the interface for logic filters.
# Filters are required to query entities using [World.Query].
#
# See [BitMask], [MaskFilter] anf [RelationFilter] for basic filters.
# For type-safe generics queries, see package [github.com/mlange-42/arche/generic].
# For advanced filtering, see package [github.com/mlange-42/arche/filter].

# type Filter interface:
#     # matches the filter against a mask, i.e. a component composition.
#     matches(bits BitMask): Bool


struct MaskFilter[is_excluding: Bool = False](ImplicitlyCopyable, Movable):
    """MaskFilter is a filter for including and excluding certain components.

    This struct can be constructed implicitly from a [.Query] instance.
    Therefore, [.Query] instances can be used instead of MaskFilter in function
    arguments.

    Parameters:
        is_excluding: If True, the filter excludes components given in the exclude mask.
    """

    var include: BitMask  # Components to include.
    var exclude: StaticOptional[BitMask, is_excluding]  # Components to exclude.

    fn __init__(
        out self,
        include: BitMask,
        exclude: StaticOptional[BitMask, is_excluding] = None,
    ):
        self.include = include
        self.exclude = exclude.copy()

    @implicit
    fn __init__(
        out self,
        query: Query[has_without_mask=is_excluding],
    ):
        """
        Takes the filter from an existing query.

        Args:
            query: The query the filter information should be taken from.
        """
        self = query._mask_filter

    fn __copyinit__(out self, other: MaskFilter[is_excluding]):
        self.include = other.include
        self.exclude = other.exclude.copy()

    fn matches(self, bits: BitMask) -> Bool:
        """Matches the filter against a mask."""

        include_matches = bits.contains(self.include)

        @parameter
        if is_excluding:
            return (
                include_matches
                and self.exclude[].is_zero()
                or bits.contains_any(self.exclude[])
            )

        return include_matches

    fn without(self, exclude: BitMask) -> MaskFilter[is_excluding=True]:
        """Returns a new MaskFilter that excludes the given components in addition to the existing ones.
        """

        new_exclude = exclude.copy()

        @parameter
        if is_excluding:
            new_exclude |= self.exclude[]

        return MaskFilter[is_excluding=True](self.include, new_exclude)

    fn exclusive(self) -> MaskFilter[is_excluding=True]:
        """Returns a new MaskFilter that includes only the currently set components and excludes all others.
        """

        return MaskFilter[is_excluding=True](self.include, ~self.include)


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
