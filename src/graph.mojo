from collections import InlineArray  # , Dict
from bitmask import BitMask

# We use a stupid dict to circumvent a current
# bug in the compiler causing a segfault when
# using the Dict type.
from stupid_dict import StupidDict as Dict


@value
struct Node[DataType: KeyElement](CollectionElement):
    """Node in a BitMaskGraph.

    Parameters:
        DataType: The type of the value stored in the node.
    """

    # The index indicating a non-established link.
    alias null_index = -1

    # The value stored in the node.
    var value: DataType

    # The indices of the neighbouring nodes.
    # The node at index i difffers from the
    # current node by the i-th bit.
    var neighbours: InlineArray[Int, 256]

    # The mask of the node.
    var bit_mask: BitMask

    fn __init__(inout self, owned bit_mask: BitMask, owned value: DataType):
        """Initializes the node with the given mask and value.

        Args:
            bit_mask: The bit mask of the node.
            value:    The value stored in the node.
        """
        self.value = value
        self.neighbours = InlineArray[Int, 256](Self.null_index)
        self.bit_mask = bit_mask


struct BitMaskGraph[
    DataType: KeyElement, //,
    null_value: DataType,
    hint_trivial_type: Bool = False,
]:
    """A graph where each node is identified by a BitMask.

    The graph is intended to be used for fast lookup of data
    identified by bitmasks based on a known starting point
    differing only in a few bits from the sought-after node.

    Nodes that differ by exactly one bit are connected via edges.
    Edges are constructed upon first use.

    Parameters:
        DataType:   The type of the value stored in the nodes.
        null_value: The place holder stored in nodes by default.
        hint_trivial_type: Hint to the compiler whether the type
                    is trivially copyable.
    """

    # The node index indicating a non-established link.
    alias null_index = Node[DataType].null_index

    # The list of nodes in the graph.
    var _nodes: List[Node[DataType], hint_trivial_type=hint_trivial_type]

    # A mapping for random lookup of nodes by their mask.
    # Used for slow lookup of nodes.
    var _map: Dict[BitMask, Int]

    fn __init__(inout self, owned first_value: DataType = Self.null_value):
        """Initializes the graph.

        Args:
            first_value: The value stored in the first node,
                         corresponding to an empty bitmask.
        """
        self._nodes = List[
            Node[DataType], hint_trivial_type=hint_trivial_type
        ]()
        self._map = Dict[BitMask, Int]()
        _ = self.add_node(BitMask(), first_value)

    @always_inline
    fn add_node(
        inout self,
        owned node_mask: BitMask,
        owned value: DataType = Self.null_value,
    ) -> Int:
        """Adds a node to the graph.

        Args:
            node_mask: The mask of the node.
            value:     The value stored in the node.

        Returns:
            The index of the added node.
        """
        self._map[node_mask] = len(self._nodes)
        self._nodes.append(Node(node_mask, value))
        return len(self._nodes) - 1

    @always_inline
    fn create_link(
        inout self, from_node_index: Int, changed_bit: BitMask.IndexType
    ) -> Int:
        """Creates a link between two nodes.

        Note: this does not check whether the link is already established.

        Args:
            from_node_index: The index of the node from which the link is created.
            changed_bit:     The index of the bit that differs between the nodes.

        Returns:
            The index of the node to which the link is created.
        """
        new_mask = self._nodes[from_node_index].bit_mask
        new_mask.flip(changed_bit)
        optional_to_index = self._map.get(new_mask)
        if optional_to_index:
            to_node_index = optional_to_index.value()
        else:
            to_node_index = self.add_node(new_mask)

        self._nodes[from_node_index].neighbours[
            int(changed_bit)
        ] = to_node_index
        self._nodes[to_node_index].neighbours[
            int(changed_bit)
        ] = from_node_index

        return to_node_index

    fn get_node_index[
        T: Intable, size: Int
    ](
        inout self,
        different_bits: InlineArray[T, size],
        start_node_index: Int = 0,
    ) -> Int:
        """Returns the index of the node differing from the start node
        by the given indices.

        If necessary, creates a new node and links it to the start node.

        Parameters:
            T:                The type of the indices.
            size:             The number of indices.

        Args:
            different_bits:   The indices of the bits that differ between the nodes.
            start_node_index: The index of the start node.

        Returns:
            The index of the node differing from the start node by the given indices.
        """
        var current_node = start_node_index

        @parameter
        for i in range(size):
            var next_node = self._nodes[current_node].neighbours[
                int(different_bits[i])
            ]
            if next_node == Self.null_index:
                next_node = self.create_link(
                    current_node, int(different_bits[i])
                )
            current_node = next_node
        return current_node

    @always_inline
    fn __getitem__(
        ref [_]self: Self, owned node_index: Int
    ) -> ref [self._nodes[node_index].value] DataType:
        """Returns the value stored in the node at the given index.

        Args:
            node_index: The index of the node.
        """
        return self._nodes[node_index].value

    fn has_value(self: Self, node_index: Int) -> Bool:
        """Returns whether the node at the given index has a value.

        Args:
            node_index: The index of the node.
        """
        return self[node_index] != Self.null_value
