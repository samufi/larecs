from std.testing import *

from larecs._utils import concatenate_inline_arrays, next_pow2


def test_concatenate_inline_arrays_uint8() raises:
    left: InlineArray[UInt8, 3] = [1, 2, 3]
    right: InlineArray[UInt8, 2] = [4, 5]

    result = concatenate_inline_arrays(left, right)

    assert_equal(len(result), 5)
    assert_equal(result[0], 1)
    assert_equal(result[1], 2)
    assert_equal(result[2], 3)
    assert_equal(result[3], 4)
    assert_equal(result[4], 5)


def test_concatenate_inline_arrays_uint16() raises:
    left: InlineArray[UInt16, 0] = []
    right: InlineArray[UInt16, 2] = [3003, 4004]

    result = concatenate_inline_arrays(left, right)

    assert_equal(len(result), 2)
    assert_equal(result[0], 3003)
    assert_equal(result[1], 4004)


def test_next_pow2_uint8() raises:
    value_zero = UInt8(0)
    value_one = UInt8(1)
    value_two = UInt8(2)
    value_eight = UInt8(8)
    value_three = UInt8(3)
    value_five = UInt8(5)
    value_nine = UInt8(9)

    assert_equal(
        next_pow2(value_zero), UInt8(1), "next_pow2(0) should return 1"
    )
    assert_equal(next_pow2(value_one), UInt8(1), "next_pow2(1) should return 1")
    assert_equal(next_pow2(value_two), UInt8(2), "next_pow2(2) should return 2")
    assert_equal(
        next_pow2(value_eight), UInt8(8), "next_pow2(8) should return 8"
    )
    assert_equal(
        next_pow2(value_three), UInt8(4), "next_pow2(3) should return 4"
    )
    assert_equal(
        next_pow2(value_five), UInt8(8), "next_pow2(5) should return 8"
    )
    assert_equal(
        next_pow2(value_nine), UInt8(16), "next_pow2(9) should return 16"
    )


def test_next_pow2_uint16() raises:
    value_255 = UInt16(255)
    value_256 = UInt16(256)
    value_257 = UInt16(257)
    value_1023 = UInt16(1023)
    value_1024 = UInt16(1024)

    assert_equal(
        next_pow2(value_255), UInt16(256), "next_pow2(255) should return 256"
    )
    assert_equal(
        next_pow2(value_256), UInt16(256), "next_pow2(256) should return 256"
    )
    assert_equal(
        next_pow2(value_257), UInt16(512), "next_pow2(257) should return 512"
    )
    assert_equal(
        next_pow2(value_1023),
        UInt16(1024),
        "next_pow2(1023) should return 1024",
    )
    assert_equal(
        next_pow2(value_1024),
        UInt16(1024),
        "next_pow2(1024) should return 1024",
    )


def test_next_pow2_int8() raises:
    value_zero = Int8(0)
    value_one = Int8(1)
    value_two = Int8(2)
    value_eight = Int8(8)
    value_three = Int8(3)
    value_five = Int8(5)
    value_nine = Int8(9)

    assert_equal(next_pow2(value_zero), Int8(1), "next_pow2(0) should return 1")
    assert_equal(next_pow2(value_one), Int8(1), "next_pow2(1) should return 1")
    assert_equal(next_pow2(value_two), Int8(2), "next_pow2(2) should return 2")
    assert_equal(
        next_pow2(value_eight), Int8(8), "next_pow2(8) should return 8"
    )
    assert_equal(
        next_pow2(value_three), Int8(4), "next_pow2(3) should return 4"
    )
    assert_equal(next_pow2(value_five), Int8(8), "next_pow2(5) should return 8")
    assert_equal(
        next_pow2(value_nine), Int8(16), "next_pow2(9) should return 16"
    )


def test_next_pow2_int16() raises:
    value_255 = Int16(255)
    value_256 = Int16(256)
    value_257 = Int16(257)
    value_1023 = Int16(1023)
    value_1024 = Int16(1024)

    assert_equal(
        next_pow2(value_255), Int16(256), "next_pow2(255) should return 256"
    )
    assert_equal(
        next_pow2(value_256), Int16(256), "next_pow2(256) should return 256"
    )
    assert_equal(
        next_pow2(value_257), Int16(512), "next_pow2(257) should return 512"
    )
    assert_equal(
        next_pow2(value_1023), Int16(1024), "next_pow2(1023) should return 1024"
    )
    assert_equal(
        next_pow2(value_1024), Int16(1024), "next_pow2(1024) should return 1024"
    )


def test_next_pow2_uint32() raises:
    value_65535 = UInt32(65535)
    value_65536 = UInt32(65536)
    value_65537 = UInt32(65537)
    value_1048575 = UInt32(1048575)
    value_1048576 = UInt32(1048576)

    assert_equal(
        next_pow2(value_65535), UInt32(65536), "next_pow2(65535) should return 65536"
    )
    assert_equal(
        next_pow2(value_65536), UInt32(65536), "next_pow2(65536) should return 65536"
    )
    assert_equal(
        next_pow2(value_65537), UInt32(131072), "next_pow2(65537) should return 131072"
    )
    assert_equal(
        next_pow2(value_1048575),
        UInt32(1048576),
        "next_pow2(1048575) should return 1048576",
    )
    assert_equal(
        next_pow2(value_1048576),
        UInt32(1048576),
        "next_pow2(1048576) should return 1048576",
    )


def test_next_pow2_int32() raises:
    value_65535 = Int32(65535)
    value_65536 = Int32(65536)
    value_65537 = Int32(65537)
    value_1048575 = Int32(1048575)
    value_1048576 = Int32(1048576)

    assert_equal(
        next_pow2(value_65535), Int32(65536), "next_pow2(65535) should return 65536"
    )
    assert_equal(
        next_pow2(value_65536), Int32(65536), "next_pow2(65536) should return 65536"
    )
    assert_equal(
        next_pow2(value_65537), Int32(131072), "next_pow2(65537) should return 131072"
    )
    assert_equal(
        next_pow2(value_1048575),
        Int32(1048576),
        "next_pow2(1048575) should return 1048576",
    )
    assert_equal(
        next_pow2(value_1048576),
        Int32(1048576),
        "next_pow2(1048576) should return 1048576",
    )


def test_next_pow2_uint64() raises:
    value_4294967295 = UInt64(4294967295)
    value_4294967296 = UInt64(4294967296)
    value_4294967297 = UInt64(4294967297)
    value_1099511627775 = UInt64(1099511627775)
    value_1099511627776 = UInt64(1099511627776)

    assert_equal(
        next_pow2(value_4294967295),
        UInt64(4294967296),
        "next_pow2(4294967295) should return 4294967296",
    )
    assert_equal(
        next_pow2(value_4294967296),
        UInt64(4294967296),
        "next_pow2(4294967296) should return 4294967296",
    )
    assert_equal(
        next_pow2(value_4294967297),
        UInt64(8589934592),
        "next_pow2(4294967297) should return 8589934592",
    )
    assert_equal(
        next_pow2(value_1099511627775),
        UInt64(1099511627776),
        "next_pow2(1099511627775) should return 1099511627776",
    )
    assert_equal(
        next_pow2(value_1099511627776),
        UInt64(1099511627776),
        "next_pow2(1099511627776) should return 1099511627776",
    )


def test_next_pow2_int64() raises:
    value_4294967295 = Int64(4294967295)
    value_4294967296 = Int64(4294967296)
    value_4294967297 = Int64(4294967297)
    value_1099511627775 = Int64(1099511627775)
    value_1099511627776 = Int64(1099511627776)

    assert_equal(
        next_pow2(value_4294967295),
        Int64(4294967296),
        "next_pow2(4294967295) should return 4294967296",
    )
    assert_equal(
        next_pow2(value_4294967296),
        Int64(4294967296),
        "next_pow2(4294967296) should return 4294967296",
    )
    assert_equal(
        next_pow2(value_4294967297),
        Int64(8589934592),
        "next_pow2(4294967297) should return 8589934592",
    )
    assert_equal(
        next_pow2(value_1099511627775),
        Int64(1099511627776),
        "next_pow2(1099511627775) should return 1099511627776",
    )
    assert_equal(
        next_pow2(value_1099511627776),
        Int64(1099511627776),
        "next_pow2(1099511627776) should return 1099511627776",
    )


comptime functions = __functions_in_module()


def main() raises:
    TestSuite.discover_tests[functions]().run()
