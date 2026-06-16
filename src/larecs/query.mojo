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
    """Numeric discriminator for the query error variant."""

    comptime UNKNOWN = QueryError(_variant=0)
    """Fallback query error variant."""
    comptime could_not_create_iterator = QueryError(_variant=1)
    """Error raised when an iterator cannot be constructed."""

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
    archetype_mutability: Bool,
    //,
    archetypes_origin: Origin[mut=archetype_mutability],
    locks_origin: MutOrigin,
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
        archetype_mutability: Whether the archetypes are mutable.
        archetypes_origin: The origin of the archetypes.
        locks_origin: The origin of the lock manager.
        ComponentTypes: The types of the components to include in the query.
        has_without_mask: Whether the query has excluded components.
    """

    comptime World = World[*Self.ComponentTypes]
    """The world type for this query."""
    comptime ArchetypeIterator = _ArchetypeIterator[
        _,
        *Self.ComponentTypes,
    ]
    """The archetype iterator type for this query."""
    comptime EntityIterator = _EntityIterator[
        _,
        *Self.ComponentTypes,
    ]
    """The entity iterator type for this query."""

    comptime QueryWithWithout = Query[
        Self.archetypes_origin,
        Self.locks_origin,
        *Self.ComponentTypes,
        has_without_mask=True,
    ]
    """The query type with an active exclusion mask."""

    var _archetypes: Pointer[Self.World.Archetypes, Self.archetypes_origin]
    """Pointer to the world's archetypes."""
    var _lock_ptr: Pointer[LockManager, Self.locks_origin]
    """Pointer to the world's lock manager."""

    var _mask: BitMask
    """Component mask that archetypes must contain."""
    var _without_mask: StaticOptional[BitMask, Self.has_without_mask]
    """Optional component mask that archetypes must not contain."""

    @doc_hidden
    def __init__(
        out self,
        archetypes: Pointer[Self.World.Archetypes, Self.archetypes_origin],
        lock_ptr: Pointer[LockManager, Self.locks_origin],
        var mask: BitMask,
        var without_mask: StaticOptional[BitMask, Self.has_without_mask] = None,
    ):
        """
        Creates a new query.

        The constructors should not be used directly, but through the [..world.World.query] method.

        Args:
            archetypes: A pointer to the world's archetypes.
            lock_ptr: A pointer to the world's lock manager.
            mask: The mask of the components to iterate over.
            without_mask: The mask for components to exclude.
        """
        with TraceGuard(name="Query.__init__"):
            self._archetypes = archetypes
            self._lock_ptr = lock_ptr
            self._mask = mask^
            self._without_mask = without_mask^

    def __init__(out self, *, copy: Self):
        """
        Copy constructor.

        Args:
            copy: The query to copy.
        """
        with TraceGuard(name="Query.__init__ copy"):
            self._archetypes = copy._archetypes
            self._lock_ptr = copy._lock_ptr
            self._mask = copy._mask
            self._without_mask = copy._without_mask.copy()

    def __len__(self, out size: Int):
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
            for i in range(len(self._archetypes[])):
                archetype = Pointer(to=self._archetypes[].unsafe_get(i))
                if archetype[] and query_info.matches(archetype[].get_mask()):
                    size += len(archetype[])

    def _iter_archetypes(
        self,
        out iterator: Self.ArchetypeIterator[Self.archetypes_origin],
    ):
        """
        Creates an archetype iterator for the query.

        Note: For internal use only! Do not expose to users.

        Returns:
            An archetype iterator for the query.
        """
        with TraceGuard(name="Query._archetype_iterator"):
            query_info = QueryInfo[has_without_mask=Self.has_without_mask](
                self._mask,
                self._without_mask,
            )

            archetype_indices = List[Int]()

            for i in range(len(self._archetypes[])):
                archetype = Pointer(to=self._archetypes[].unsafe_get(i))
                if archetype[] and query_info.matches(archetype[].get_mask()):
                    archetype_indices.append(i)

            iterator = {
                self._archetypes,
                archetype_indices^,
            }

    @always_inline
    def __iter__(
        var self,
        out iterator: _WorldIterator[
            Self.archetypes_origin,
            Self.locks_origin,
            *Self.ComponentTypes,
            has_start_indices=False,
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
            try:
                iterator = {
                    self._iter_archetypes(),
                    self._lock_ptr,
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
                self._archetypes,
                self._lock_ptr,
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
            query = Self.QueryWithWithout(
                self._archetypes, self._lock_ptr, self._mask, ~self._mask
            )


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
    """Component mask that matching archetypes must contain."""
    var without_mask: StaticOptional[BitMask, Self.has_without_mask]
    """Optional component mask that matching archetypes must not contain."""

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

    def matches(self, archetype_mask: BitMask, out is_valid: Bool):
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


struct _ArchetypeIterator[
    archetype_mutability: Bool,
    //,
    archetype_origin: Origin[mut=archetype_mutability],
    *ComponentTypes: ComponentType,
](Boolable, Copyable, Iterator, Movable, Sized):
    """
    Iterator over non-empty archetypes corresponding to given list of Archetype IDs.

    Note: For internal use only! Do not expose to users.

    Parameters:
        archetype_mutability: Whether the reference to the archetypes is mutable.
        archetype_origin: The origin of the archetypes.
        ComponentTypes: The types of the components.
    """

    comptime Archetype = _Archetype[*Self.ComponentTypes]
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
        with TraceGuard(name="_ArchetypeIterator.__init__"):
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
        with TraceGuard(name="_ArchetypeIterator.__init__ copy"):
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
        with TraceGuard(name="_ArchetypeIterator.__iter__"):
            iterator = self^

    @always_inline
    def __next__(mut self, out archetype: Self.Element) raises StopIteration:
        """
        Returns the next archetype in the iteration.

        Returns:
            The next archetype as a pointer.
        """
        with TraceGuard(name="_ArchetypeIterator.__next__"):
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
        with TraceGuard(name="_ArchetypeIterator.__len__"):
            return len(self._archetype_indices) - self._index

    @always_inline
    def __has_next__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        with TraceGuard(name="_ArchetypeIterator.__has_next__"):
            return self._index < len(self._archetype_indices)

    @always_inline
    def __bool__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        with TraceGuard(name="_ArchetypeIterator.__bool__"):
            return self.__has_next__()


struct _EntityIterator[
    archetype_origin: Origin,
    *ComponentTypes: ComponentType,
](Boolable, IterableOwned, Iterator, Movable, Sized):
    """
    Iterator over entities in an archetype.

    Note: For internal use only! Do not expose to users.

    Parameters:
        archetype_origin: The origin of the archetypes.
        ComponentTypes: The types of the components.
    """

    comptime Archetype = _Archetype[*Self.ComponentTypes]
    comptime Element = Self.Archetype.EntityAccessor[Self.archetype_origin]

    comptime IteratorOwnedType = _EntityIterator[
        Self.archetype_origin,
        *Self.ComponentTypes,
    ]

    var archetype: Pointer[Self.Archetype, Self.archetype_origin]
    var _index: Int

    def __init__(
        out self,
        archetype: Pointer[Self.Archetype, Self.archetype_origin],
        _index: Int = 0,
    ):
        """
        Creates an entity iterator for the given archetype.

        Args:
            archetype: A pointer to the archetype to iterate over.
            _index: The index of the entity to start iterating from.
        """
        with TraceGuard(name="_EntityIterator.__init__"):
            self.archetype = archetype
            self._index = _index

    def __has_next__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        with TraceGuard(name="_EntityIterator.__has_next__"):
            return self._index < len(self.archetype[])

    def __bool__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        with TraceGuard(name="_EntityIterator.__bool__"):
            return self.__has_next__()

    def __len__(self) -> Int:
        """
        Returns the number of entities remaining in the iterator.
        """
        with TraceGuard(name="_EntityIterator.__len__"):
            return len(self.archetype[]) - self._index

    def __iter__(var self, out iterator: Self):
        """
        Returns self as an iterator usable in for loops.

        Returns:
            Self as an iterator usable in for loops.
        """
        with TraceGuard(name="_EntityIterator.__iter__"):
            iterator = self^

    def __next__(mut self, out accessor: Self.Element) raises StopIteration:
        """
        Returns the next entity in the iteration.

        Raises:
            StopIteration: If there are no more entities to iterate.

        Returns:
            An [..archetype.EntityAccessor] to the entity.
        """
        with TraceGuard(name="_EntityIterator.__next__"):
            if not self.__has_next__():
                raise StopIteration()
            accessor = self.archetype[].get_entity_accessor(
                self._index,
            )
            self._index += 1


struct _WorldIterator[
    archetype_mutability: Bool,
    //,
    archetype_origin: Origin[mut=archetype_mutability],
    lock_origin: MutOrigin,
    *ComponentTypes: ComponentType,
    has_start_indices: Bool = False,
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
    """

    comptime Archetype = _Archetype[*Self.ComponentTypes]
    comptime ArchetypeIterator = _ArchetypeIterator[
        Self.archetype_origin,
        *Self.ComponentTypes,
    ]

    comptime Element = Self.Archetype.EntityAccessor[Self.archetype_origin]

    comptime IteratorOwnedType = _WorldIterator[
        Self.archetype_origin,
        Self.lock_origin,
        *Self.ComponentTypes,
        has_start_indices=Self.has_start_indices,
    ]

    var _lock_ptr: Pointer[LockManager, Self.lock_origin]
    var _lock: Int

    comptime StartIndices = StaticOptional[List[Int], Self.has_start_indices]
    var _start_indices: Self.StartIndices
    var _current_archetype_index: Int

    var _archetype_iterator: Self.ArchetypeIterator
    var _entity_iterator: Optional[
        _EntityIterator[
            Self.archetype_origin,
            *Self.ComponentTypes,
        ]
    ]

    def __init__(
        out self,
        var archetype_iter: Self.ArchetypeIterator,
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

            self._archetype_iterator = archetype_iter^
            self._entity_iterator = None

            self._current_archetype_index = 0

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
    def __next__(mut self, out accessor: Self.Element) raises StopIteration:
        """
        Returns the next entity in the iteration.

        Raises:
            StopIteration: If there are no more entities to iterate.

        Returns:
            An [..archetype.EntityAccessor] to the entity.
        """
        with TraceGuard(name="_EntityIterator.__next__"):
            if (
                not self._entity_iterator
                or not self._entity_iterator.unsafe_value().__has_next__()
            ):
                if not self._archetype_iterator.__has_next__():
                    raise StopIteration()

                comptime if Self.has_start_indices:
                    start_idx = self._start_indices[][
                        self._current_archetype_index
                    ]
                else:
                    start_idx = 0

                self._current_archetype_index += 1

                self._entity_iterator = _EntityIterator(
                    Pointer(to=self._archetype_iterator.__next__()[]),
                    start_idx,
                )

            accessor = self._entity_iterator.unsafe_value().__next__()

    def __len__(self, out size: Int):
        """
        Returns the number of entities remaining in the iterator.

        Note that this requires iterating over all archetypes
        and may be a complex operation.
        """
        with TraceGuard(name="_EntityIterator.__len__"):
            size = 0

            if not self.__has_next__():
                return

            if self._entity_iterator:
                size += len(self._entity_iterator.unsafe_value())

            archetype_iter_copy = self._archetype_iterator.copy()

            archetype_idx = self._current_archetype_index

            for archetype in archetype_iter_copy^:
                comptime if Self.has_start_indices:
                    start_idx = self._start_indices[][archetype_idx]
                else:
                    start_idx = 0
                archetype_idx += 1

                entity_iter = _EntityIterator(
                    Pointer(to=archetype[]), start_idx
                )
                size += len(entity_iter)

    @always_inline
    def __has_next__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        with TraceGuard(name="_EntityIterator.__has_next__"):
            if (
                self._entity_iterator
                and self._entity_iterator.unsafe_value().__has_next__()
            ):
                return True

            if self._archetype_iterator.__has_next__():
                return True

            return False

    @always_inline
    def __bool__(self) -> Bool:
        """
        Returns whether the iterator has at least one more element.

        Returns:
            Whether there are more elements to iterate.
        """
        with TraceGuard(name="_EntityIterator.__bool__"):
            return self.__has_next__()
