from testing import *
from larecs.bitmask import BitMask
from larecs.graph import Node, BitMaskGraph


def test_node_initialization():
    bit_mask = BitMask(1, 3, 4)
    value = 42
    node = Node(bit_mask, value)
    assert_equal(node.value, value)
    assert_equal(node.bit_mask, bit_mask)
    assert_equal(len(node.neighbours), 256)
    for i in range(256):
        assert_equal(node.neighbours[i], node.null_index)


def test_graph_initialization():
    graph = BitMaskGraph[-1]()
    assert_equal(len(graph._nodes), 1)
    assert_equal(len(graph._map), 1)


def test_add_node():
    graph = BitMaskGraph[-1]()
    bit_mask = BitMask(0, 2)
    value = 42
    node_index = graph.add_node(bit_mask, value)
    assert_equal(node_index, 1)
    assert_equal(len(graph._nodes), 2)
    assert_equal(graph._nodes[1].value, value)
    assert_equal(graph._nodes[1].bit_mask, bit_mask)
    assert_equal(graph._map[bit_mask], 1)


def test_getitem():
    alias null_value = -1
    graph = BitMaskGraph[null_value]()
    bit_mask = BitMask(0, 2)
    value = 42
    node_index = graph.add_node(bit_mask, value)
    assert_equal(graph[node_index], value)
    bit_mask = BitMask(0, 2, 3)
    node_index = graph.add_node(bit_mask)
    assert_equal(graph[node_index], null_value)


def test_create_link():
    graph = BitMaskGraph[-1]()
    bit_mask1 = BitMask(0, 2)
    bit_mask2 = BitMask(0)
    _ = graph.add_node(bit_mask1, 42)
    to_node_index = graph.create_link(0, 0)
    assert_equal(to_node_index, 2)
    assert_equal(len(graph._nodes), 3)
    assert_equal(graph._nodes[0].neighbours[0], 2)
    assert_equal(graph._nodes[2].neighbours[0], 0)
    assert_equal(graph._nodes[2].bit_mask, bit_mask2)


def test_get_node_index():
    graph = BitMaskGraph[-1]()
    bit_mask2 = BitMask(0, 2)
    bit_mask1 = BitMask(0)
    node_index = graph.get_node_index(InlineArray[UInt8, 2](0, 2))
    assert_equal(node_index, 2)
    assert_equal(graph._nodes[1].bit_mask, bit_mask1)
    assert_equal(graph._nodes[node_index].bit_mask, bit_mask2)

    assert_equal(graph.get_node_index(InlineArray[UInt8, 2](5, 5), 0), 0)
    assert_equal(graph._nodes[3].bit_mask, BitMask(5))


def test_get_node_mask():
    graph = BitMaskGraph[-1]()
    bit_mask = BitMask(0, 2)
    node_index = graph.add_node(bit_mask, 42)
    assert_equal(graph.get_node_mask(node_index), bit_mask)


struct S:
    var l: List[Node[Int]]

    fn __init__(mut self):
        self.l = List[Node[Int]]()
        self.add(BitMask(), -1)

    fn add(mut self, owned node_mask: BitMask, owned value: Int):
        self.l.append(Node(node_mask, value))


def test_has_value():
    graph = BitMaskGraph[-1]()
    bit_mask = BitMask(0, 2)
    value = 42
    node_index = graph.add_node(bit_mask, value)
    assert_equal(graph.has_value(node_index), True)
    assert_equal(graph.has_value(0), False)


def main():
    print("Running tests...")
    test_node_initialization()
    test_graph_initialization()
    test_add_node()
    test_getitem()
    test_create_link()
    test_get_node_index()
    test_get_node_mask()
    print("All tests passed.")
