from .component import ComponentManager


trait TypeMapping(CollectionElement):
    fn __init__(out self):
        """Initializes the type mapping."""
        ...


@register_passable("trivial")
struct TypeId(KeyElement):
    """An ID to distinguish different types.

    By convention, every type implementing
    `.IdentifiableCollectionElement` should have a `TypeId` that contains
    its package, module, and class name.
    For example, the ID for a `MyStruct` in the
    module `my_module` in the package `my_package` would be
    assigned as follows:

    ```mojo
    struct MyStruct(IdentifiableCollectionElement):
        alias id = TypeId("my_package.my_module.MyStruct")
    ```

    The ID is generated as a hash of the string. There remains
    a risk that two different types could have the same ID, but this is
    rather unlikely. Nontheless, this approach of identifying types
    is unsafe and will be replaced once reflections are available in Mojo.

    To ensure that the ID is unique in a limited context, you can
    set the `id` manually by passing an integer to the constructor.
    """

    alias IdType = UInt
    """The type of the internal ID."""

    var _id: UInt

    @always_inline
    fn __init__(out self, name: String):
        """Initializes the ID with a given name.

        The name should be a string that uniquely identifies the type.
        By convention, this should be the package, module, and class name of the type.

        Args:
            name: The name of the type.
        """
        self._id = name.__hash__()

    @always_inline
    fn __init__(out self, id: UInt):
        """Initializes the ID with a given value.

        Use this if the context is limited and you want
        to ensure that the ID is unique. In general,
        this should be avoided.

        Args:
            id: The ID of the type.
        """
        self._id = id

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        """Checks if two IDs are equal.

        Args:
            other: The other ID to compare with.

        Returns:
            True if the IDs are equal, False otherwise.
        """
        return self._id == other._id

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        """Checks if two IDs are not equal.

        Args:
            other: The other ID to compare with.

        Returns:
            True if the IDs are not equal, False otherwise.
        """
        return self._id != other._id

    @always_inline
    fn __hash__(self) -> UInt:
        """Gets the hash of the ID.

        Returns:
            The hash of the ID.
        """
        return self._id

    @always_inline
    fn id(self) -> UInt:
        """Gets the ID.

        Returns:
            The ID.
        """
        return self._id


trait IdentifiableCollectionElement(CollectionElement):
    """A Type that is uniquely identifiable via a given ID.

    By convention, the ID should contain the package, module,
    and class name. For example, the ID for a `MyStruct` in the
    module `my_module` in the package `my_package` would be
    assigned as follows:

    ```mojo
    struct MyStruct(IdentifiableCollectionElement):
        alias id = TypeId("my_package.my_module.MyStruct")
    ```

    As the ID is generated as a hash of a string, there remains
    a (small) risk that two different types could have the same ID.

    To ensure that the ID is unique in a limited context, you can
    set the `id` manually by passing an integer to the constructor.
    """

    alias id: TypeId
    """The ID of the type."""


trait StaticlyTypeMapping(TypeMapping):
    """A mapping from types to IDs."""

    @always_inline
    @staticmethod
    fn get_id[T: CollectionElement]() -> Int:
        """Gets the ID of a type.

        Parameters:
            T: The type to get the ID for.

        Returns:
            The ID of the type.
        """
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
    fn get_id[T: Self.InputTrait]() -> UInt:
        return UInt(Self.manager.get_id[T]())


@value
struct DynamicTypeMap(TypeMapping):
    @always_inline
    @staticmethod
    fn get_id[T: IdentifiableCollectionElement]() -> TypeId.IdType:
        """Gets the ID of a type.

        Parameters:
            T: The type to get the ID for.
        
        Returns:
            The ID of the type.
        """
        return T.id.id()
