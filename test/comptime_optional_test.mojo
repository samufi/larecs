from testing import *

from larecs.test_utils import *
from larecs.comptime_optional import ComptimeOptional


def test_comptime_optional_init():
    opt = ComptimeOptional[Int, False]()
    assert_false(opt.has_value)

    l = List[Int](42)
    opt_with_value = ComptimeOptional(l)
    assert_true(opt_with_value.has_value)
    assert_equal(opt_with_value.value()[0], 42)


def test_comptime_optional_copy():
    opt_with_value = ComptimeOptional(42)
    opt_copy = opt_with_value.copy()
    assert_true(opt_copy.has_value)
    assert_equal(opt_copy.value(), 42)


@value
struct TestStruct[origin: MutableOrigin]:
    var del_conuter: Pointer[Int, origin]

    fn __del__(owned self):
        self.del_conuter[] += 1


def test_comptime_optional_move_del():
    fn factory(
        owned val: MemTestStruct,
        out result: ComptimeOptional[MemTestStruct, True],
    ):
        result = __type_of(result)(val^)

    test_copy_move_del[factory](1, 1)


def test_comptime_optional_value():
    opt_with_value = ComptimeOptional[Int, True](42)
    assert_equal(opt_with_value.value(), 42)


def test_comptime_optional_size():
    assert_equal(sizeof[ComptimeOptional[UInt16, True]](), 2)
    assert_equal(sizeof[ComptimeOptional[UInt16, False]](), 0)


def main():
    print("Running tests...")
    test_comptime_optional_size()
    test_comptime_optional_init()
    test_comptime_optional_copy()
    test_comptime_optional_move_del()
    test_comptime_optional_value()
    print("All tests passed.")
