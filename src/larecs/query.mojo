from std.utils.type_functions import ConditionalType

from .entity import Entity
from .bitmask import BitMask
from .component import (
    ComponentType,
    ComponentManager,
    constrain_components_unique,
)
from .archetype import Archetype as _Archetype
from .world import World
from .lock import LockManager
from .debug_utils import debug_warn
from .static_optional import StaticOptional
from ._tracing import TraceGuard


@fieldwise_init
struct QueryError(Equatable, ImplicitlyCopyable, Writable):
    """
    Typed errors raised by query operations.
    """

    var _variant: Int

    comptime UNKNOWN = QueryError(_variant=0)
    comptime could_not_create_iterator = QueryError(_variant=1)

    def variant_name(self) -> String:
        """
        Returns the variant name.

        Returns:
            The name of the error variant.
        """
        with TraceGuard(name="QueryError.variant_name"):
            if self._variant == Self.could_not_create_iterator._variant:
                return "could_not_create_iterator"
            else:
                return "unknown"

    def msg(self) -> String:
        """
        Returns the error message.

        Returns:
            The human-readable error message.
        """
        with TraceGuard(name="QueryError.msg"):
            if self._variant == Self.could_not_create_iterator._variant:
                return "Could not create query iterator."
            else:
                return "Unknown error."

    def write_to(self, mut writer: Some[Writer]):
        """
        Writes the error to the given writer.

        Args:
            writer: The writer to write to.
        """
        with TraceGuard(name="QueryError.write_to"):
            writer.write("QueryError.", self.variant_name(), ": ", self.msg())


struct Query[
    world_origin: MutOrigin,
    *ComponentTypes: ComponentType,
    has_without_mask: Bool = False,
](ImplicitlyCopyable, SizedRaising):
    """Query builder for entities with and without specific components.

    This type should not be used directly, but through the [..world.World.query] method:

    ```mojo {doctest="query_init" global=true hide=true}
    from larecs import World, Resources, MutableEntityAccessor
    ```

    ```mojo {doctest="query_init"}
    world = World[Float64, Float32, Int]()
    _ = world.add_entity(Float64(1.0), Float32(2.0), 3)
    _ = world.add_entity(Float64(1.0), 3)

    for entity in world.query[Float64, Int]():
        ref f = entity.get[Float64]()
        f += 1
    ```

    Parameters:
        world_origin: The origin of the world.
        ComponentTypes: The types of the components to include in the query.
        has_without_mask: Whether the query has excluded components.
    """

    comptime World = World[*Self.ComponentTypes]

    comptime QueryWithWithout = Query[
        Self.world_origin,
        *Self.ComponentTypes,
        has_without_mask=True,
    ]

    var _world: Pointer[Self.World, Self.world_origin]
    var _mask: BitMask
    var _without_mask: StaticOptional[BitMask, Self.has_without_mask]

    @doc_hidden
    def __init__(
        out self,
        world: Pointer[Self.World, Self.world_origin],
        var mask: BitMask,
        var without_mask: StaticOptional[BitMask, Self.has_without_mask] = None,
    ):
        """
        Creates a new query.

        The constructors should not be used directly, but through the [..world.World.query] method.

        Args:
            world: A pointer to the world.
            mask: The mask of the components to iterate over.
            without_mask: The mask for components to exclude.
        """
        with TraceGuard(name="Query.__init__"):
            self._world = world
            self._mask = mask^
            self._without_mask = without_mask^

    def __init__(out self, *, copy: Self):
        """
        Copy constructor.

        Args:
            copy: The query to copy.
        """
        with TraceGuard(name="Query.__init__ copy"):
            self._world = copy._world
            self._mask = copy._mask
            self._without_mask = copy._without_mask.copy()

    def __len__(self) raises -> Int:
        """
        Returns the number of entities matching the query.

        Note that this requires the creation of an iterator from the query.
        If you intend to iterate anyway, get the iterator with [.Query.__iter__],
        and call `len` on it, instead.
        """
        with TraceGuard(name="Query.__len__"):
            size = 0
            query_info = QueryInfo[has_without_mask=Self.has_without_mask](
                self._mask,
                self._without_mask,
            )
            for i in range(len(self._world[]._archetypes)):
                archetype = Pointer(to=self._world[]._archetypes.unsafe_get(i))
                if archetype[] and query_info.matches(archetype[].get_mask()):
                    size += len(archetype[])

            return size

    @always_inline
    def __iter__(
        var self,
        out iterator: Self.World.Iterator[
            origin_of(self._world[]._archetypes),
            origin_of(self._world[]._locks),
            has_start_indices=False,
            has_without_mask=Self.has_without_mask,
        ],
    ) raises:
        """
        Creates an iterator over all entities that match the query.

        Raises:
            QueryError: If the iterator cannot acquire a lock.

        Returns:
            An iterator over all entities that match the query.
        """
        with TraceGuard(name="Query.__iter__"):
            comptime ArchetypeByMaskIterator = Self.World.ArchetypeByMaskIterator[
                origin_of(self._world[]._archetypes),
                has_without_mask=Self.has_without_mask,
            ]

            it = ArchetypeByMaskIterator(
                mask_iterator=ArchetypeByMaskIterator.mask_iterator(
                    Pointer(to=self._world[]._archetypes),
                    self._mask,
                    self._without_mask.copy(),
                )
            )

            try:
                iterator = {
                    it^,
                    Pointer(to=self._world[]._locks),
                    None,
                }
            except _:
                raise QueryError.could_not_create_iterator

    @always_inline
    def without[*Ts: ComponentType](var self, out query: Self.QueryWithWithout):
        """
        Excludes the given components from the query.

        ```mojo {doctest="query_without" global=true hide=true}
        from larecs import World, Resources, MutableEntityAccessor
        ```

        ```mojo {doctest="query_without"}
        world = World[Float64, Float32, Int]()
        _ = world.add_entity(Float64(1.0), Float32(2.0), 3)
        _ = world.add_entity(Float64(1.0), 3)

        for entity in world.query[Float64, Int]().without[Float32]():
            ref f = entity.get[Float64]()
            f += 1
        ```

        Parameters:
            Ts: The types of the components to exclude.

        Returns:
            The query, excluding the given components.
        """
        with TraceGuard(name="Query.without"):
            comptime assert constrain_components_unique[
                *Ts
            ](), "Duplicate component types in query are not allowed."

            query = Self.QueryWithWithout(
                self._world,
                self._mask,
                BitMask(Self.World.component_manager.get_id_arr[*Ts]()),
            )

    @always_inline
    def exclusive(var self, out query: Self.QueryWithWithout):
        """
        Makes the query only match entities with exactly the query's components.

        ```mojo {doctest="query_without" global=true hide=true}
        from larecs import World, Resources, MutableEntityAccessor
        ```

        ```mojo {doctest="query_without"}
        world = World[Float64, Float32, Int]()
        _ = world.add_entity(Float64(1.0), Float32(2.0), 3)
        _ = world.add_entity(Float64(1.0), 3)

        for entity in world.query[Float64, Int]().exclusive():
            ref f = entity.get[Float64]()
            f += 1
        ```

        Returns:
            The query, made exclusive.
        """
        with TraceGuard(name="Query.exclusive"):
            query = Self.QueryWithWithout(self._world, self._mask, ~self._mask)


struct QueryInfo[
    has_without_mask: Bool = False,
](ImplicitlyCopyable):
    """
    Class that holds the same information as a query but no reference to the world.

    This struct can be constructed implicitly from a [.Query] instance.
    Therefore, [.Query] instances can be used instead of QueryInfo in function
    arguments.

    Parameters:
        has_without_mask: Whether the query has excluded components.
    """

    var mask: BitMask
    var without_mask: StaticOptional[BitMask, Self.has_without_mask]

    @implicit
    def __init__(
        out self,
        query: Query[..., has_without_mask=Self.has_without_mask],
    ):
        """
        Takes the query info from an existing query.

        Args:
            query: The query the information should be taken from.
        """
        with TraceGuard(name="QueryInfo.__init__"):
            self.mask = query._mask
            self.without_mask = query._without_mask.copy()

    def __init__(
        out self,
        mask: BitMask,
        without_mask: StaticOptional[BitMask, Self.has_without_mask] = None,
    ):
        """
        Takes the query info from an existing query.

        Args:
            mask: The mask of the components to include.
            without_mask: The optional mask of the components to exclude.
        """
        with TraceGuard(name="QueryInfo.__init__ mask"):
            self.mask = mask

            comptime if Self.has_without_mask:
                self.without_mask = without_mask.copy()
            else:
                self.without_mask = None

    def __init__(out self, *, copy: Self):
        """
        Copy constructor.

        Args:
            copy: The query to copy.
        """
        with TraceGuard(name="QueryInfo.__init__ copy"):
            self.mask = copy.mask
            self.without_mask = copy.without_mask.copy()

    def matches(self, archetype_mask: BitMask) -> Bool:
        """
        Checks whether the given archetype mask matches the query.

        Args:
            archetype_mask: The mask of the archetype to check.

        Returns:
            Whether the archetype matches the query.
        """
        with TraceGuard(name="QueryInfo.matches"):
            is_valid = archetype_mask.contains(self.mask)

            comptime if Self.has_without_mask:
                is_valid &= not archetype_mask.contains_any(self.without_mask[])

            return is_valid


struct _ArchetypeByMaskIterator[
    archetype_mutability: Bool,
    //,
    archetype_origin: Origin[mut=archetype_mutability],
    *ComponentTypes: ComponentType,
    has_without_mask: Bool = False,
](Boolable, Copyable, Iterator, Movable, Sized):
    """
    Iterator over non-empty archetypes corresponding to given include and exclude masks.

    Note: For internal use only! Do not expose to users. Does not lock the world.

    Parameters:
        archetype_mutability: Whether the reference to the archetypes is mutable.
        archetype_origin: The origin of the archetypes.
        ComponentTypes: The types of the components.
        has_without_mask: Whether the iterator has excluded components.
    """

    comptime Archetype = _Archetype[*Self.ComponentTypes]
    comptime Element = Pointer[Self.Archetype, Self.archetype_origin]
    comptime QueryInfo = QueryInfo[has_without_mask=Self.has_without_mask]
    var _archetypes: Pointer[List[Self.Archetype], Self.archetype_origin]
    var _mask: BitMask
    var _without_mask: StaticOptional[BitMask, Self.has_without_mask]
    var _archetype_count: Int
    var _next_archetype_index: Int

    def __init__(
        out self,
        archetypes: Pointer[List[Self.Archetype], Self.archetype_origin],
        var mask: BitMask,
        var without_mask: StaticOptional[BitMask, Self.has_without_mask] = None,
    ):
        """
        Creates an archetype by mask iterator.

        Args:
            archetypes: a pointer to the world's archetypes.
            mask: The mask of the archetypes to iterate over.
            without_mask: An optional mask for archetypes to exclude.
        """
        with TraceGuard(name="_ArchetypeByMaskIterator.__init__"):
            self._archetypes = archetypes
            self._archetype_count = len(self._archetypes[])
            self._mask = mask^
            self._without_mask = without_mask^
            self._next_archetype_index = 0
            self._advance_to_next_match()

    @doc_hidden
    @always_inline
    def __init__(out self, *, copy: Self):
        """
        Copies the iterator state.

        Args:
            copy: The iterator to copy.
        """
        with TraceGuard(name="_ArchetypeByMaskIterator.__init__ copy"):
            self._archetypes = copy._archetypes
            self._archetype_count = copy._archetype_count
            self._mask = copy._mask
            self._without_mask = copy._without_mask.copy()
            self._next_archetype_index = copy._next_archetype_index

    @doc_hidden
    @always_inline
    def __init__(
        out self,
        archetypes: Pointer[List[Self.Archetype], Self.archetype_origin],
        var mask: BitMask,
        without_mask: StaticOptional[BitMask, Self.has_without_mask],
        archetype_count: Int,
        next_archetype_index: Int,
    ):
        """
        Initializes the iterator based on given field values.

        Args:
            archetypes: A pointer to the world's archetypes.
            mask: The mask of the archetypes to iterate over.
            without_mask: An optional mask for archetypes to exclude.
            archetype_count: The number of archetypes in the world.
            next_archetype_index: The next archetype index to inspect.
        """
        with TraceGuard(name="_ArchetypeByMaskIterator.__init__ fields"):
            self._archetypes = archetypes
            self._mask = mask^
            self._without_mask = without_mask.copy()
            self._archetype_count = archetype_count
            self._next_archetype_index = next_archetype_index

    def _advance_to_next_match(mut self):
        """
        Advances the iterator to the next matching archetype.
        """
        with TraceGuard(name="_ArchetypeByMaskIterator._advance_to_next_match"):
            query_info = Self.QueryInfo(
                mask=self._mask,
                without_mask=self._without_mask,
            )

            while self._next_archetype_index < self._archetype_count:
                is_valid = self._archetypes[].unsafe_get(
                    self._next_archetype_index
                ) and query_info.matches(
                    self._archetypes[]
                    .unsafe_get(self._next_archetype_index)
                    .get_mask()
                )
                if is_valid:
                    return
                self._next_archetype_index += 1

    @always_inline
    def __iter__(var self, out iterator: Self):
        """
        Returns self as an iterator usable in for loops.

        Returns:
            Self as an iterator usable in for loops.
        """
        with TraceGuard(name="_ArchetypeByMaskIterator.__iter__"):
            iterator = self^

    @always_inline
    def __next__(mut self, out archetype: Self.Element) raises StopIteration:
        """
        Returns the next archetype in the iteration.

        Returns:
            The next archetype as a pointer.
        """
        with TraceGuard(name="_ArchetypeByMaskIterator.__next__"):
            if not self.__has_next__():
                raise StopIteration()

            current_index = self._next_archetype_index
            self._next_archetype_index += 1
            self._advance_to_next_match()

            archetype = Pointer(to=self._archetypes[].unsafe_get(current_index))

    def __len__(self) -> Int:
        """
        Returns the number of archetypes remaining in the iterator.

        Note that this requires iterating over all archetypes
        and may be a complex operation.
        """
        with TraceGuard(name="_ArchetypeByMaskIterator.__len__"):
            size = 0
            query_info = Self.QueryInfo(
                mask=self._mask,
                without_mask=self._without_mask,
            )
            for i in range(self._next_archetype_index, len(self._archetypes[])):
                is_valid = self._archetypes[].unsafe_get(
                    i
                ) and query_info.matches(
                    self._archetypes[].unsafe_get(i).get_mask()
                )

                size += Int(is_valid)

            return size

    @always_inline
    def __has_next__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        with TraceGuard(name="_ArchetypeByMaskIterator.__has_next__"):
            return self._next_archetype_index < self._archetype_count

    @always_inline
    def __bool__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        with TraceGuard(name="_ArchetypeByMaskIterator.__bool__"):
            return self.__has_next__()


struct _ArchetypeByListIterator[
    archetype_mutability: Bool,
    //,
    archetype_origin: Origin[mut=archetype_mutability],
    *ComponentTypes: ComponentType,
](Boolable, Copyable, Iterator, Movable, Sized):
    """
    Iterator over non-empty archetypes corresponding to given list of Archetype IDs.

    Note: For internal use only! Do not expose to users. Does not lock the world.

    Parameters:
        archetype_mutability: Whether the reference to the archetypes is mutable.
        archetype_origin: The origin of the archetypes.
        ComponentTypes: The types of the components.
    """

    comptime buffer_size = 8
    comptime Archetype = _Archetype[*Self.ComponentTypes,]
    comptime Element = Pointer[Self.Archetype, Self.archetype_origin]
    var _archetypes: Pointer[List[Self.Archetype], Self.archetype_origin]
    var _archetype_indices: List[Int]
    var _index: Int

    def __init__(
        out self,
        archetypes: Pointer[List[Self.Archetype], Self.archetype_origin],
        var archetype_indices: List[Int],
    ):
        """
        Creates an archetype by list iterator.

        Args:
            archetypes: a pointer to the world's archetypes.
            archetype_indices: The indices of the archetypes in the list that are being iterated over.
        """
        with TraceGuard(name="_ArchetypeByListIterator.__init__"):
            self._archetypes = archetypes
            self._archetype_indices = archetype_indices^
            self._index = 0

    @doc_hidden
    @always_inline
    def __init__(out self, *, copy: Self):
        """
        Copies the iterator state.

        Args:
            copy: The iterator to copy.
        """
        with TraceGuard(name="_ArchetypeByListIterator.__init__ copy"):
            self._archetypes = copy._archetypes
            self._archetype_indices = copy._archetype_indices.copy()
            self._index = copy._index

    @always_inline
    def __iter__(var self, out iterator: Self):
        """
        Returns self as an iterator usable in for loops.

        Returns:
            Self as an iterator usable in for loops.
        """
        with TraceGuard(name="_ArchetypeByListIterator.__iter__"):
            iterator = self^

    @always_inline
    def __next__(mut self, out archetype: Self.Element) raises StopIteration:
        """
        Returns the next archetype in the iteration.

        Returns:
            The next archetype as a pointer.
        """
        with TraceGuard(name="_ArchetypeByListIterator.__next__"):
            if not self.__has_next__():
                raise StopIteration()
            archetype = Pointer(
                to=self._archetypes[].unsafe_get(
                    self._archetype_indices.unsafe_get(self._index)
                )
            )
            self._index += 1

    def __len__(self) -> Int:
        """
        Returns the number of archetypes remaining in the iterator.
        """
        with TraceGuard(name="_ArchetypeByListIterator.__len__"):
            return len(self._archetype_indices) - self._index

    @always_inline
    def __has_next__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        with TraceGuard(name="_ArchetypeByListIterator.__has_next__"):
            return self._index < len(self._archetype_indices)

    @always_inline
    def __bool__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        with TraceGuard(name="_ArchetypeByListIterator.__bool__"):
            return self.__has_next__()


struct ArchetypeIteratorVariant:
    comptime by_mask = ArchetypeIterator[0, ...]
    comptime by_list = ArchetypeIterator[1, ..., has_without_mask=False]


struct ArchetypeIterator[
    archetype_mutability: Bool,
    //,
    id: Int,
    archetype_origin: Origin[mut=archetype_mutability],
    *ComponentTypes: ComponentType,
    has_without_mask: Bool = False,
](Boolable, Copyable, IterableOwned, Iterator, Movable, Sized):
    comptime Element = Pointer[
        _Archetype[*Self.ComponentTypes,],
        Self.archetype_origin,
    ]

    comptime IteratorOwnedType = ArchetypeIterator[
        Self.id,
        Self.archetype_origin,
        *Self.ComponentTypes,
        has_without_mask=Self.has_without_mask,
    ]

    comptime mask_iterator = _ArchetypeByMaskIterator[
        Self.archetype_origin,
        *Self.ComponentTypes,
        has_without_mask=Self.has_without_mask,
    ]

    comptime list_iterator = _ArchetypeByListIterator[
        Self.archetype_origin,
        *Self.ComponentTypes,
    ]

    var _mask_iterator: StaticOptional[
        Self.mask_iterator, Self.id == ArchetypeIteratorVariant.by_mask.id
    ]
    var _list_iterator: StaticOptional[
        Self.list_iterator, Self.id == ArchetypeIteratorVariant.by_list.id
    ]

    def __init__(out self, *, var mask_iterator: Self.mask_iterator):
        """
        Creates an archetype iterator from a mask iterator.
        """
        with TraceGuard(name="ArchetypeIterator.__init__ mask"):
            comptime assert (
                Self.id == ArchetypeIteratorVariant.by_mask.id
            ), "Mask iterator should be initialized with a mask iterator."
            comptime assert (
                not Self.id == ArchetypeIteratorVariant.by_list.id
            ), "Mask iterator should be initialized with a mask iterator."
            self._mask_iterator = mask_iterator^
            self._list_iterator = None

    @doc_hidden
    @always_inline
    def __init__(out self, *, copy: Self):
        """
        Copies the iterator state.

        Args:
            copy: The iterator to copy.
        """
        with TraceGuard(name="ArchetypeIterator.__init__ copy"):
            self._mask_iterator = copy._mask_iterator.copy()
            self._list_iterator = copy._list_iterator.copy()

    def __init__(out self, *, var list_iterator: Self.list_iterator):
        """
        Creates an archetype iterator from a list iterator.
        """
        with TraceGuard(name="ArchetypeIterator.__init__ list"):
            comptime assert (
                Self.id == ArchetypeIteratorVariant.by_list.id
            ), "List iterator should be initialized with a list iterator."
            comptime assert (
                not Self.id == ArchetypeIteratorVariant.by_mask.id
            ), "List iterator should be initialized with a list iterator."
            self._list_iterator = list_iterator^
            self._mask_iterator = None

    def __next__(mut self, out archetype: Self.Element) raises StopIteration:
        """
        Returns the next archetype in the iteration.

        Returns:
            The next archetype as a pointer.
        """
        with TraceGuard(name="ArchetypeIterator.__next__"):
            comptime if Self.id == ArchetypeIteratorVariant.by_mask.id:
                archetype = self._mask_iterator[].__next__()
            else:
                archetype = self._list_iterator[].__next__()

    def __len__(self) -> Int:
        """
        Returns the number of archetypes remaining in the iterator.
        """
        with TraceGuard(name="ArchetypeIterator.__len__"):
            comptime if Self.id == ArchetypeIteratorVariant.by_mask.id:
                return len(self._mask_iterator[])
            else:
                return len(self._list_iterator[])

    def __bool__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        with TraceGuard(name="ArchetypeIterator.__bool__"):
            comptime if Self.id == ArchetypeIteratorVariant.by_mask.id:
                return self._mask_iterator[].__bool__()
            else:
                return self._list_iterator[].__bool__()

    def __iter__(var self, out iterator: Self.IteratorOwnedType):
        """
        Returns self as an iterator usable in for loops.

        Returns:
            Self as an iterator usable in for loops.
        """
        with TraceGuard(name="ArchetypeIterator.__iter__"):
            iterator = self^

    def __has_next__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        with TraceGuard(name="ArchetypeIterator.__has_next__"):
            comptime if Self.id == ArchetypeIteratorVariant.by_mask.id:
                return self._mask_iterator[].__has_next__()
            else:
                return self._list_iterator[].__has_next__()


struct _EntityIterator[
    archetype_mutability: Bool,
    //,
    archetype_origin: Origin[mut=archetype_mutability],
    lock_origin: MutOrigin,
    *ComponentTypes: ComponentType,
    has_start_indices: Bool = False,
    has_without_mask: Bool = False,
    archetype_iterator_variant_id: Int,
](Boolable, IterableOwned, Iterator, Movable, Sized):
    """Iterator over all entities corresponding to a mask.

    Locks the world while it exists.

    Parameters:
        archetype_mutability: Whether the reference to the archetypes is mutable.
        archetype_origin: The origin of the archetypes.
        lock_origin: The origin of the LockManager.
        ComponentTypes: The types of the components.
        has_start_indices: Whether the iterator starts iterating the
                           archetypes at given indices.
        has_without_mask: Whether the iterator has excluded components.
        archetype_iterator_variant_id: The variant id of the archetype iterator to use.
    """

    comptime Archetype = _Archetype[*Self.ComponentTypes,]
    comptime archetype_iterator = ArchetypeIterator[
        Self.archetype_iterator_variant_id,
        Self.archetype_origin,
        *Self.ComponentTypes,
        has_without_mask=Self.has_without_mask,
    ]

    comptime Element = Self.Archetype.EntityAccessor[Self.archetype_origin]

    comptime IteratorOwnedType = _EntityIterator[
        Self.archetype_origin,
        Self.lock_origin,
        *Self.ComponentTypes,
        has_start_indices=Self.has_start_indices,
        has_without_mask=Self.has_without_mask,
        archetype_iterator_variant_id=Self.archetype_iterator_variant_id,
    ]

    comptime buffer_size = 8
    comptime StartIndices = StaticOptional[List[Int], Self.has_start_indices]

    var _current_archetype: Optional[
        Pointer[Self.Archetype, Self.archetype_origin]
    ]
    var _lock_ptr: Pointer[LockManager, Self.lock_origin]
    var _lock: Int
    var _entity_index: Int
    var _last_entity_index: Int
    var _archetype_size: Int
    var _archetype_iterator: Self.archetype_iterator
    var _start_indices: Self.StartIndices
    var _processed_archetypes_count: StaticOptional[Int, Self.has_start_indices]

    def __init__(
        out self,
        var archetype_iter: Self.archetype_iterator,
        lock_ptr: Pointer[LockManager, Self.lock_origin],
        var start_indices: Self.StartIndices = None,
    ) raises:
        """
        Creates an entity iterator with or without excluded components.

        Args:
            archetype_iter: The variant of the archetype iterator to use.
            lock_ptr: a pointer to the world's locks.
            start_indices: The indices where the iterator starts iterating the
                           archetypes. Caution: the index order must
                           match the order of the archetypes that
                           are iterated.

        Raises:
            Error: If the lock cannot be acquired.
        """
        with TraceGuard(name="_EntityIterator.__init__"):
            self._lock_ptr = lock_ptr
            self._lock = self._lock_ptr[].lock()
            self._start_indices = start_indices^

            self._current_archetype = None
            self._entity_index = 0
            self._archetype_size = 0
            self._last_entity_index = 0
            self._archetype_iterator = archetype_iter^

            comptime if Self.has_start_indices:
                self._processed_archetypes_count = 0
            else:
                self._processed_archetypes_count = None

            if self._archetype_iterator:
                self._last_entity_index = Int.MAX
                try:
                    self._next_archetype()
                    # We need to reduce the index by 1, because the
                    # first call to __next__ will increment it.
                    self._entity_index -= 1
                except StopIteration:
                    self._current_archetype = None
                    self._entity_index = 0
                    self._last_entity_index = 0
                    self._archetype_size = 0

    def __del__(deinit self):
        """
        Releases the lock.
        """
        with TraceGuard(name="_EntityIterator.__del__"):
            try:
                self._lock_ptr[].unlock(self._lock)
            except _:
                debug_warn(
                    t"Failed to unlock the lock {self._lock}. This should not"
                    t" happen."
                )

    @always_inline
    def __iter__(var self, out iterator: Self):
        """
        Returns self as an iterator usable in for loops.

        Returns:
            Self as an iterator usable in for loops.
        """
        with TraceGuard(name="_EntityIterator.__iter__"):
            iterator = self^

    @always_inline
    def _next_archetype(mut self) raises StopIteration:
        """
        Moves to the next archetype.
        """
        with TraceGuard(name="_EntityIterator._next_archetype"):
            self._current_archetype = {self._archetype_iterator.__next__()}

            self._archetype_size = len(self._current_archetype.unsafe_value()[])

            comptime if Self.has_start_indices:
                self._entity_index = self._start_indices[][
                    self._processed_archetypes_count[]
                ]
                self._processed_archetypes_count[] += 1
            else:
                self._entity_index = 0

            # If we arrived at the last archetype, we
            # reset the last entity index so that the iterator
            # stops at the last entity of the last archetype.
            if not self._archetype_iterator:
                self._last_entity_index = self._archetype_size - 1

    @always_inline
    def __next__(mut self, out accessor: Self.Element) raises StopIteration:
        """
        Returns the next entity in the iteration.

        Returns:
            An [..archetype.EntityAccessor] to the entity.
        """
        with TraceGuard(name="_EntityIterator.__next__"):
            self._entity_index += 1
            if self._entity_index >= self._archetype_size:
                self._next_archetype()
            debug_assert(
                Bool(self._current_archetype), "No more archetypes to iterate."
            )
            accessor = (
                self._current_archetype.unsafe_value()[].get_entity_accessor(
                    self._entity_index,
                )
            )

    def __len__(self) -> Int:
        """
        Returns the number of entities remaining in the iterator.

        Note that this requires iterating over all archetypes
        and may be a complex operation.
        """
        with TraceGuard(name="_EntityIterator.__len__"):
            if not self.__has_next__():
                return 0

            assert Bool(
                self._current_archetype
            ), "No current archetype, but has next entity."

            # Elements in the current archetype
            size = (
                len(self._current_archetype.unsafe_value()[])
                - self._entity_index
                - 1
            )

            # Elements in the remaining archetypes
            if self._archetype_iterator:
                for archetype in self._archetype_iterator.copy():
                    size += len(archetype[])

            comptime if Self.has_start_indices:
                for i in range(
                    self._processed_archetypes_count[],
                    len(self._start_indices[]),
                ):
                    size -= self._start_indices[][i]

            return size

    @always_inline
    def __has_next__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        with TraceGuard(name="_EntityIterator.__has_next__"):
            return self._entity_index < self._last_entity_index

    @always_inline
    def __bool__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        with TraceGuard(name="_EntityIterator.__bool__"):
            return self.__has_next__()
