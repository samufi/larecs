from testing import *

from larecs.test_utils import *
from larecs.static_variant import StaticVariant


def test_comptime_variant_init():
    var variant: StaticVariant[0, UInt8, Int8]
    variant = StaticVariant[
        0,
        UInt8,
        Int8,
    ](UInt8(42))
    assert_equal(variant[], 42)

    # BUG: conditional copy constructor does not work yet (see https://github.com/modular/modular/issues/5172)
    # var var_copy = variant
    # assert_equal(variant[], 42)


# def test_comptime_variant_copy():
#     var variant: StaticVariant[UInt8, Int8]
#     variant = StaticVariant(UInt8(42)) #     var_copy = variant.copy()
#     assert_true(var_copy.has_value)
#     assert_equal(var_copy[], 42)
#     var_without_value = StaticVariant[Int, False]()
#     var_copy_without = var_without_value.copy()
#     _ = var_copy_without._value
#     var_copy_without = var_without_value
#     _ = var_copy_without


# def test_comptime_variant_move_del():
#     fn factory(
#         var val: MemTestStruct,
#         out result: StaticVariant[MemTestStruct, True],
#     ):
#         result = __type_of(result)(val^)

#     test_copy_move_del[factory](init_moves=1, move_moves=1)


# def test_comptime_variant_value():
#     var_with_value = StaticVariant[Int, True](42)
#     assert_equal(var_with_value[], 42)


# def test_comptime_variant_size():
#     assert_equal(sizeof[StaticVariant[UInt16, True]](), 2)
#     assert_equal(sizeof[StaticVariant[UInt16, False]](), 0)


def main():
    print("Running tests...")
    # test_comptime_variant_size()
    test_comptime_variant_init()
    # test_comptime_variant_copy()
    # test_comptime_variant_move_del()
    # test_comptime_variant_value()
    print("All tests passed.")
