from testing import *

from larecs.test_utils import *
from larecs.unsafe_box import UnsafeBox


@fieldwise_init
struct TestStruct:
    var value_1: Int
    var value_2: Float32


def test_unsafe_box_copy_move_del():
    fn factory(
        owned val: MemTestStruct,
        out result: UnsafeBox,
    ):
        result = __type_of(result)(val^)

    test_copy_move_del[factory](init_moves=1)


def test_unsafe_box_value():
    box = UnsafeBox(42)
    assert_equal(box.unsafe_get[Int](), 42)


def main():
    test_unsafe_box_copy_move_del()
    test_unsafe_box_value()
    print("All tests passed!")
