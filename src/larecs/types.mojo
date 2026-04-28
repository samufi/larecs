# Eid is the entity identifier/index type.
comptime EntityId = Int

# ID is the component identifier type.
comptime Id = UInt8


def get_max_size[dType: DType]() -> Int:
    """Returns how many different numbers could be expressed with a Int with the same size as dType.

    Parameters:
        dType: The type to get the size of.
    """
    return Int(Scalar[dType].MAX) + 1


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
