from testing import *
from chained_array_list import ChainedArrayList
from memory import ArcPointer


struct TestElement(CollectionElementNew):
    var value: Int
    var dealloc_counter: ArcPointer[Int]

    fn __init__(inout self, value: Int, dealloc_counter: ArcPointer[Int]):
        self.value = value
        self.dealloc_counter = dealloc_counter

    fn copy(self) -> Self as other:
        other = Self(self.value, self.dealloc_counter)

    fn __moveinit__(inout self, owned other: Self):
        self.value = other.value
        self.dealloc_counter = other.dealloc_counter

    fn __del__(owned self):
        self.dealloc_counter[] += 1


def test_chained_array_list_init():
    list = ChainedArrayList[Int]()
    assert_equal(len(list), 0)
    assert_false(bool(list))


def test_chained_array_list_add():
    list = ChainedArrayList[Int]()
    assert_equal(list.add(1), 0)
    assert_equal(list.add(2), 1)
    assert_equal(list.add(3), 2)
    assert_equal(len(list), 3)
    assert_true(bool(list))
    assert_equal(list[0], 1)
    assert_equal(list[1], 2)
    assert_equal(list[2], 3)
    list.remove(1)
    assert_equal(list.add(4), 1)
    assert_equal(list.add(5), 3)


# def test_chained_array_list_iter():
#     list = ChainedArrayList[Int]()
#     values = List[Int](4, 2, 1)

#     for i in values:
#         list.add(i[])

#     counter = 0
#     for i in list:
#         assert_equal(i[], values[counter])
#         counter += 1


def test_chained_array_list_moveinit():
    list1 = ChainedArrayList[Int]()
    _ = list1.add(1)
    _ = list1.add(2)
    list2 = list1^
    assert_equal(len(list2), 2)
    assert_equal(list2[0], 1)
    assert_equal(list2[1], 2)


def test_chained_list_deallocation():
    dealloc_counter = ArcPointer[Int](0)
    list = ChainedArrayList[TestElement]()
    n = 100
    for i in range(n):
        _ = list.add(TestElement(i, dealloc_counter))
    assert_equal(dealloc_counter[], 0)
    _ = list^
    assert_equal(dealloc_counter[], n)


def main():
    print("Running tests...")
    test_chained_array_list_init()
    test_chained_array_list_add()
    # test_chained_array_list_iter()
    test_chained_array_list_moveinit()
    test_chained_list_deallocation()
    print("All tests passed.")
