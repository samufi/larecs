from entity import Entity
from bitmask import BitMask
from component import ComponentType, ComponentManager
from chained_array_list import ChainedArrayList
from archetype import Archetype
from world import World


struct _EntityAccessor[
    archetype_mutability: Bool, //,
    archetype_origin: Origin[archetype_mutability],
    *component_types: ComponentType,
]:
    """Accessor for an Entity.

    Caution: use this only in the context it was created in.
    In particular, do not store it anywhere.

    Parameters:
        archetype_mutability: Whether the reference to the list is mutable.
        archetype_origin: The lifetime of the List
        component_types: The types of the components.
    """

    var _component_manager: ComponentManager[*component_types]
    var _archetype: Pointer[Archetype, archetype_origin]
    var _index_in_archetype: Int

    @always_inline
    fn __init__(
        out self,
        component_manager: ComponentManager[*component_types],
        archetype: Pointer[Archetype, archetype_origin],
        index_in_archetype: Int,
    ):
        """
        Parameters:
            component_manager: The component manager.
            archetype: The archetype of the entity.
            index_in_archetype: The index of the entity in the archetype.
        """
        self._component_manager = component_manager
        self._archetype = archetype
        self._index_in_archetype = index_in_archetype

    @always_inline
    fn get[T: ComponentType](inout self) raises -> ref [self._archetype] T:
        """Returns a reference to the given component of the Entity."""
        return (
            self._archetype[]
            .get_component_ptr(
                self._index_in_archetype,
                self._component_manager.get_id[T](),
            )
            .bitcast[T]()[0]
        )

    @always_inline
    fn get_ptr[
        T: ComponentType
    ](inout self) raises -> Pointer[T, __origin_of(self._archetype)]:
        """Returns a reference to the given component of the Entity.

        Raises:
            Error: If the entity does not have the component.
        """
        return Pointer[origin = __origin_of(self._archetype)].address_of(
            self._archetype[]
            .get_component_ptr(
                self._index_in_archetype,
                self._component_manager.get_id[T](),
            )
            .bitcast[T]()[0]
        )

    @always_inline
    fn has[T: ComponentType](self) -> Bool:
        """
        Returns whether an [Entity] has a given component.
        """
        return self._archetype[].has_component(
            self._component_manager.get_id[T]()
        )


@value
struct _EntityIterator[
    archetype_mutability: Bool, //,
    archetype_origin: Origin[archetype_mutability],
    *component_types: ComponentType,
]:
    """Iterator for over all entities corresponding to a mask.

    Parameters:
        archetype_mutability: Whether the reference to the list is mutable.
        archetype_origin: The lifetime of the List
        component_types: The types of the components.
    """

    var _archetypes: Pointer[ChainedArrayList[Archetype], archetype_origin]
    var _current_archetype: Pointer[Archetype, archetype_origin]
    var _archetype_list_index: Int
    var _archetype_indices: List[Int]
    var _entity_index: Int
    var _mask: BitMask
    var _size: UInt
    var _returned_elements: Int
    var _component_manager: ComponentManager[*component_types]

    fn __init__(
        out self,
        component_manager: ComponentManager[*component_types],
        owned archetypes: Pointer[
            ChainedArrayList[Archetype], archetype_origin
        ],
        owned mask: BitMask,
    ):
        """
        Parameters:
            component_manager: The component manager.
            archetypes: The archetypes to iterate over.
            mask: The mask of the components to iterate over.

        Args:
            component_manager: The component manager.
            archetypes: a pointer to the world's archetypes.
            mask: The mask of the components to iterate over.
        """
        self._archetypes = archetypes
        self._component_manager = component_manager

        # We start indexing at -1, because we want that the
        # index after returning __next__ always
        # corresponds to the last returned entity.
        self._archetype_list_index = -1
        self._entity_index = -1

        self._mask = mask^
        self._current_archetype = self._archetypes[].get_ptr(0)
        self._archetype_indices = List[Int]()
        self._returned_elements = 0
        self._size = 0
        self._find_archetypes()
        if self._size > 0:
            self._next_archetype()

            # We need to reset the index to -1, because the
            # first call to __next__ will increment it.
            self._entity_index = -1

    @always_inline
    fn __iter__(self) -> Self:
        return self

    @always_inline
    fn _find_archetypes(inout self):
        """
        Find all archetypes that contain the mask.

        Fills the _archetype_indices list with the indices of the
        archetypes that contain the mask.
        """
        self._archetype_indices.clear()
        for i in range(len(self._archetypes[])):
            if (
                self._archetypes[][i].get_mask().contains(self._mask)
                and self._archetypes[][i]
            ):
                self._archetype_indices.append(i)
                self._size += len(self._archetypes[][i])

    @always_inline
    fn _next_archetype(inout self):
        """
        Move to the next archetype.
        """
        self._archetype_list_index += 1
        self._entity_index = 0
        self._current_archetype = self._archetypes[].get_ptr(
            self._archetype_indices[self._archetype_list_index]
        )

    fn __next__(
        inout self,
    ) -> _EntityAccessor[
        __origin_of(self._current_archetype[]), *component_types
    ]:
        self._entity_index += 1
        self._returned_elements += 1
        if self._entity_index >= len(self._current_archetype[]):
            self._next_archetype()
        return _EntityAccessor(
            self._component_manager,
            self._current_archetype,
            self._entity_index,
        )

    @always_inline
    fn __has_next__(self) -> Bool:
        return self._returned_elements < self._size

    @always_inline
    fn __len__(self) -> Int:
        return self._size

    @always_inline
    fn __bool__(self) -> Bool:
        return self.__has_next__()
