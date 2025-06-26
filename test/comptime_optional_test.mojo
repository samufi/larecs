from testing import *

from larecs.test_utils import *
from larecs.static_optional import StaticOptional


def test_static_optional_init():
    opt = StaticOptional[Int, False]()
    assert_false(opt.has_value)
    _ = opt._value
    l = List[Int](42)
    opt_with_value = StaticOptional(l)
    assert_true(opt_with_value.has_value)
    assert_equal(opt_with_value[][0], 42)


def test_static_optional_copy():
    opt_with_value = StaticOptional(42)
    opt_copy = opt_with_value.copy()
    assert_true(opt_copy.has_value)
    assert_equal(opt_copy[], 42)
    opt_without_value = StaticOptional[Int, False]()
    opt_copy_without = opt_without_value.copy()
    _ = opt_copy_without._value
    opt_copy_without = opt_without_value
    _ = opt_copy_without


@fieldwise_init
struct TestStruct[origin: MutableOrigin]:
    var del_conuter: Pointer[Int, origin]

    fn __del__(owned self):
        self.del_conuter[] += 1


def test_static_optional_move_del():
    fn factory(
        owned val: MemTestStruct,
        out result: StaticOptional[MemTestStruct, True],
    ):
        result = __type_of(result)(val^)

    fn getter(
        container: StaticOptional[MemTestStruct, True]
    ) raises -> UnsafePointer[MemTestStruct]:
        return UnsafePointer(to=container[])

    test_copy_move_del[factory, getter](1, 0, 1)


def test_static_optional_value():
    opt_with_value = StaticOptional[Int, True](42)
    assert_equal(opt_with_value[], 42)


def test_static_optional_size():
    assert_equal(sizeof[StaticOptional[UInt16, True]](), 2)
    assert_equal(sizeof[StaticOptional[UInt16, False]](), 0)


fn optional_argument_application[
    has_value: Bool = False
](opt: StaticOptional[Int, has_value] = None) -> Bool:
    return opt.has_value


def test_optional_argument_application():
    assert_false(optional_argument_application())
    assert_true(optional_argument_application(123))


def test_or_else():
    opt = StaticOptional[Int, False]()
    assert_equal(opt.or_else(42), 42)
    opt2 = StaticOptional(10)
    assert_equal(opt2.or_else(42), 10)


fn recipient_comperator(
    compare: SIMD[DType.uint8, 16],
    owned optional: StaticOptional[SIMD[DType.uint8, 16], True] = None,
) raises:
    assert_true(
        (optional[] == compare).reduce_and(),
        String("Received {} but expected {}").format(optional[], compare),
    )


fn recipient_comperator_for_inline_array(
    compare: SIMD[DType.uint8, 16],
    owned optional: InlineArray[SIMD[DType.uint8, 16], 1],
) raises:
    assert_true(
        (optional[0] == compare).reduce_and(),
        String("Received {} but expected {}").format(optional[0], compare),
    )


def test_handover_to_callee():
    data = SIMD[DType.uint8, 16](255)
    for i in range(5):
        data[i] = i * i
    optional = StaticOptional(data)
    recipient_comperator(data, optional)
    recipient_comperator(data, data)


def test_inline_array_handover_to_callee():
    data = SIMD[DType.uint8, 16](255)
    for i in range(5):
        data[i] = i * i
    optional = InlineArray[SIMD[DType.uint8, 16], 1](data)
    recipient_comperator_for_inline_array(data, optional)
    recipient_comperator_for_inline_array(data, data)


def main():
    print("Running tests...")
    test_static_optional_size()
    test_static_optional_init()
    test_static_optional_copy()
    test_static_optional_move_del()
    test_static_optional_value()
    test_optional_argument_application()
    test_handover_to_callee()
    test_inline_array_handover_to_callee()
    test_or_else()
    print("All tests passed.")
