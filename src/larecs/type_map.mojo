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

    ```mojo {doctest="type_id" global=true hide=true}
    from larecs import TypeId, IdentifiableCollectionElement
    ```

    ```mojo {doctest="type_id" global=true}
    struct MyStruct(IdentifiableCollectionElement):
        alias id = TypeId("my_package.my_module.MyStruct")
    ```

    If the ID is used in a limited context only, you can
    set the `id` manually by passing an integer to the constructor.
    """

    var _id: UInt
    var _name: StringLiteral

    @always_inline
    fn __init__(out self, name: StringLiteral):
        """Initializes the ID with a given name.

        The name should be a string that uniquely identifies the type.
        By convention, this should be the package, module, and class name of the type.

        Args:
            name: The name of the type.
        """
        self._id = name.__hash__()
        self._name = name

    @always_inline
    fn __init__(out self, id: UInt):
        """Initializes the ID with a given value.

        Use this only if the context is limited and you can
        manually ensure that the ID is unique. In general,
        this should be avoided.

        Args:
            id: The ID of the type.
        """
        self._id = id
        self._name = ""

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        """Checks if two IDs are equal.

        Args:
            other: The other ID to compare with.

        Returns:
            True if the IDs are equal, False otherwise.
        """
        return self._id == other._id and self._name == other._name

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        """Checks if two IDs are not equal.

        Args:
            other: The other ID to compare with.

        Returns:
            True if the IDs are not equal, False otherwise.
        """
        return self._id != other._id or self._name != other._name

    @always_inline
    fn __hash__(self) -> UInt:
        """Gets the hash of the ID.

        Returns:
            The hash of the ID.
        """
        return self._id

    @always_inline
    fn __str__(self) -> String:
        """Gets the string representation of the ID.

        Returns:
            The string representation of the ID.
        """
        return String(self._name) + " (" + self._id.__str__() + ")"


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

    If the ID is used in a limited context only, you can
    set the `id` manually by passing an integer to the constructor.
    """

    alias id: TypeId
    """The ID of the type."""


trait StaticlyTypeMapping(TypeMapping):
    """A mapping from types to IDs."""

    @always_inline
    @staticmethod
    fn get_id[T: CollectionElement]() -> TypeId:
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
    """The trait of the input type."""

    alias manager = ComponentManager[*Ts]()
    """The component manager for the types."""

    @always_inline
    @staticmethod
    fn get_id[T: Self.InputTrait]() -> TypeId:
        """Gets the ID of a type.

        Parameters:
            T: The type to get the ID for.

        Returns:
            The ID of the type.
        """
        return TypeId(Int(Self.manager.get_id[T]()))


@value
struct DynamicTypeMap(TypeMapping):
    """
    A dynamic mapping from types to IDs.

    The types need to implement the [.IdentifiableCollectionElement] trait.
    """

    @always_inline
    @staticmethod
    fn get_id[T: IdentifiableCollectionElement]() -> TypeId:
        """Gets the ID of a type.

        Parameters:
            T: The type to get the ID for.

        Returns:
            The ID of the type.
        """
        return T.id
