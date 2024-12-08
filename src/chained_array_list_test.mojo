from testing import *
from chained_array_list import ChainedArrayList
from memory import ArcPointer


struct TestElement(CollectionElementNew):
    var value: Int
    var dealloc_counter: ArcPointer[Int]

    fn __init__(inout self, value: Int, dealloc_counter: ArcPointer[Int]):
        self.value = value
        self.dealloc_counter = dealloc_counter

    fn __init__(inout self, other: Self):
        self.value = other.value
        self.dealloc_counter = other.dealloc_counter

    fn __moveinit__(inout self, owned other: Self):
        self.value = other.value
        self.dealloc_counter = other.dealloc_counter

    fn __del__(owned self):
        self.dealloc_counter[] += 1


def test_chained_array_list_init():
    list = ChainedArrayList[Int]()
    assert_equal(len(list), 0)
    assert_false(bool(list))


def test_chained_array_list_append():
    list = ChainedArrayList[Int]()
    list.append(1)
    list.append(2)
    list.append(3)
    assert_equal(len(list), 3)
    assert_true(bool(list))
    assert_equal(list[0], 1)
    assert_equal(list[1], 2)
    assert_equal(list[2], 3)


# def test_chained_array_list_iter():
#     list = ChainedArrayList[Int]()
#     values = List[Int](4, 2, 1)

#     for i in values:
#         list.append(i[])

#     counter = 0
#     for i in list:
#         assert_equal(i[], values[counter])
#         counter += 1


def test_chained_array_list_moveinit():
    list1 = ChainedArrayList[Int]()
    list1.append(1)
    list1.append(2)
    list2 = list1^
    assert_equal(len(list2), 2)
    assert_equal(list2[0], 1)
    assert_equal(list2[1], 2)


def test_chained_list_deallocation():
    dealloc_counter = ArcPointer[Int](0)
    list = ChainedArrayList[TestElement]()
    n = 100
    for i in range(n):
        list.append(TestElement(i, dealloc_counter))
    assert_equal(dealloc_counter[], 0)
    _ = list^
    assert_equal(dealloc_counter[], n)


def main():
    print("Running tests...")
    test_chained_array_list_init()
    test_chained_array_list_append()
    # test_chained_array_list_iter()
    test_chained_array_list_moveinit()
    test_chained_list_deallocation()
    print("All tests passed.")
