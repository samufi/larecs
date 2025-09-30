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


struct MaskFilter[has_exclude: Bool = False](ImplicitlyCopyable, Movable):
    """MaskFilter is a filter for including and excluding certain components.

    This struct can be constructed implicitly from a [.Query] instance.
    Therefore, [.Query] instances can be used instead of MaskFilter in function
    arguments.

    Parameters:
        has_exclude: If True, the filter excludes components given in the exclude mask.
    """

    var include: BitMask  # Components to include.
    var exclude: StaticOptional[BitMask, has_exclude]  # Components to exclude.

    fn __init__(
        out self,
        include: BitMask,
        exclude: StaticOptional[BitMask, has_exclude] = None,
    ):
        self.include = include
        self.exclude = exclude.copy()

    @implicit
    fn __init__(
        out self,
        query: Query[has_exclude=has_exclude],
    ):
        """
        Takes the filter from an existing query.

        Args:
            query: The query the filter information should be taken from.
        """
        self = query._mask_filter

    fn __copyinit__(out self, other: MaskFilter[has_exclude]):
        self.include = other.include
        self.exclude = other.exclude.copy()

    fn matches(self, bits: BitMask) -> Bool:
        """Matches the filter against a mask."""

        is_matching = bits.contains(self.include)

        @parameter
        if has_exclude:
            is_matching &= self.exclude[].is_zero() or not bits.contains_any(
                self.exclude[]
            )

        return is_matching

    fn without(self, exclude: BitMask) -> MaskFilter[has_exclude=True]:
        """Returns a new MaskFilter that excludes the given components in addition to the existing ones.
        """

        new_exclude = exclude.copy()

        @parameter
        if has_exclude:
            new_exclude |= self.exclude[]

        return MaskFilter[has_exclude=True](self.include, new_exclude)

    fn exclusive(self) -> MaskFilter[has_exclude=True]:
        """Returns a new MaskFilter that includes only the currently set components and excludes all others.
        """

        return MaskFilter[has_exclude=True](self.include, ~self.include)


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
