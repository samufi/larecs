from .component import ComponentManager

alias IdType = Int


trait TypeMapping(CollectionElement):
    fn __init__(out self):
        """Initializes the type mapping."""
        ...


trait IdentifiableCollectionElement(CollectionElement):
    alias id: IdType


trait StaticlyTypeMapping(TypeMapping):
    @always_inline
    @staticmethod
    fn get_id[T: CollectionElement]() -> Int:
        ...


@value
struct StaticTypeMap[*Ts: CollectionElement](TypeMapping):
    """Maps types to resource IDs.

    Parameters:
        Ts: The types to map.
    """

    alias InputTrait = ComponentType

    alias manager = ComponentManager[*Ts]()

    @always_inline
    @staticmethod
    fn get_id[T: Self.InputTrait]() -> Int:
        return Int(Self.manager.get_id[T]())


@value
struct DynamicTypeMap(TypeMapping):
    @always_inline
    @staticmethod
    fn get_id[T: IdentifiableCollectionElement]() -> UInt:
        """Gets the ID of a type.

        Parameters:
            T: The type to get the ID for.
        """
        return T.id
