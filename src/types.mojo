from sys.info import sizeof

# Eid is the entity identifier/index type.
alias EntityId = UInt32

# ID is the component identifier type.
alias Id = UInt8


trait TrivialIntable(
    CollectionElement, Hashable
):  # Intable, CollectionElementNew, Hashable
    """A trait for trivial (register-passable) integer types.

    As of yet, there is no trait for register-passable types in
    Mojo. This trait will be added once introudced.

    In the end, this trait should be one of UInt8, UInt16, UInt32, UInt64, etc.
    """

    fn __init__(mut self, value: Int):
        ...

    fn __init__(mut self, value: UInt):
        ...

    fn __iadd__(mut self: Self, rhs: Self):
        ...


fn get_max_uint_size[T: TrivialIntable]() -> UInt:
    """Returns how many different numbers could be expressed with a UInt with the same size as T.

    Parameters:
        T: The type to get the size of.
    """
    return 2 ** (sizeof[T]() * 8)


fn get_max_uint_size_of_half_type[T: TrivialIntable]() -> UInt:
    """Returns how many different numbers could be expressed with a UInt with half the size of T.

    Parameters:
        T: The type to consider.
    """
    return 2 ** (sizeof[T]() * 4)


# # ResID is the resource identifier type.
# type ResID = uint8

# # Component is a component ID/pointer pair.
# #
# # It is a helper for [World.Assign], [World.NewEntityWith] and [NewBuilderWith].
# # It is not related to how components are implemented in Arche.
# type Component struct:
#     ID   ID          # Component ID.
#     Comp interface{} # The component, as a pointer to a struct.

# # componentType is a component ID with a data type
# type componentType struct:
#     ID
#     Type reflect.Type
