import std.random
from std.testing import *
from std.benchmark import keep
from larecs.bitmask import BitMask
from std.io.write import Writable, Writer
from std.memory import Span


# ------ Helper functions ------


@always_inline
def get_random_bitmask() -> BitMask:
    mask = BitMask()
    for i in range(BitMask.total_bits):
        if std.random.random_float64() < 0.5:
            mask.set(UInt8(i), True)
    return mask


@always_inline
def get_random_uint8_list(size: Int, out vals: List[UInt8]):
    vals = List[UInt8](capacity=size)
    std.random.randint(
        vals[0:size],
        0,
        Int(BitMask.total_bits),
    )


def unique(l: List[UInt8], out result: List[UInt8]):
    mask = InlineArray[Bool, 256](fill=False)
    result = List[UInt8]()
    for v in l:
        if not mask[v]:
            mask[v] = True
            result.append(v)


@fieldwise_init
struct StringWriter(Movable, Writer):
    """Simple in-memory Writer implementation for tests."""

    var value: String

    def write_string(mut self, s: StringSlice):
        self.value += s


def write_to_string[T: Writable](value: T) -> String:
    """Writes a writable value into a string.

    Args:
        value: The writable value to write.

    Returns:
        The string representation produced by value.write_to(...).
    """
    writer = StringWriter("")
    value.write_to(writer)
    return writer.value


@always_inline
def get_random_1_true_bitmasks(size: Int, out vals: List[BitMask]):
    vals = List[BitMask](capacity=size)
    for _ in range(size):
        vals.append(
            BitMask(
                std.random.random_ui64(0, UInt64(BitMask.total_bits)).cast[
                    DType.uint8
                ]()
            )
        )


# ------ Tests ------


def test_bit_mask() raises:
    var mask = BitMask(UInt8(1), UInt8(2), UInt8(13), UInt8(27))

    assert_equal(4, mask.total_bits_set())

    assert_true(mask.get(1))
    assert_true(mask.get(2))
    assert_true(mask.get(13))
    assert_true(mask.get(27))

    assert_equal(
        String(mask),
        "[0110000000000100000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000]",
    )

    assert_false(mask.get(0))
    assert_false(mask.get(3))

    mask.set(UInt8(0), True)
    mask.set(UInt8(1), False)

    assert_true(mask.get(0))
    assert_false(mask.get(1))

    mask.flip(UInt8(0))
    mask.flip(UInt8(1))

    assert_false(mask.get(0))
    assert_true(mask.get(1))

    mask.flip(UInt8(0))
    mask.flip(UInt8(1))

    var other1 = BitMask(UInt8(1), UInt8(2), UInt8(32))
    var other2 = BitMask(UInt8(0), UInt8(2))

    assert_false(mask.contains(other1))
    assert_true(mask.contains(other2))

    mask.reset()
    assert_equal(0, mask.total_bits_set())

    mask = BitMask(UInt8(1), UInt8(2), UInt8(13), UInt8(27))
    other1 = BitMask(UInt8(1), UInt8(32))
    other2 = BitMask(UInt8(0), UInt8(32))

    assert_true(mask.contains_any(other1))
    assert_false(mask.contains_any(other2))


def test_bit_mask_without_exclusive() raises:
    mask = BitMask(UInt8(1), UInt8(2), UInt8(13))
    assert_true(mask.matches(BitMask(UInt8(1), UInt8(2), UInt8(13))))
    assert_true(mask.matches(BitMask(UInt8(1), UInt8(2), UInt8(13), UInt8(27))))

    assert_false(mask.matches(BitMask(UInt8(1), UInt8(2))))

    excl = mask.exclusive()

    assert_true(excl.matches(BitMask(UInt8(1), UInt8(2), UInt8(13))))
    assert_false(
        excl.matches(BitMask(UInt8(1), UInt8(2), UInt8(13), UInt8(27)))
    )
    assert_false(excl.matches(BitMask(UInt8(1), UInt8(2), UInt8(3), UInt8(13))))


def test_bit_mask_eq() raises:
    mask1 = get_random_bitmask()
    mask2 = mask1

    assert_true(mask1 == mask2)

    mask2.flip(3)

    assert_false(mask1 == mask2)


def test_bit_mask_256() raises:
    for i in range(BitMask.total_bits):
        mask = BitMask(UInt8(i))
        assert_equal(1, mask.total_bits_set())
        assert_true(mask.get(UInt8(i)))

    mask = BitMask()
    assert_equal(0, mask.total_bits_set())

    for i in range(BitMask.total_bits - 1):
        mask.set(UInt8(i), True)
        assert_equal(i + 1, mask.total_bits_set())
        assert_true(mask.get(UInt8(i)))

    mask = BitMask(
        UInt8(1),
        UInt8(2),
        UInt8(13),
        UInt8(27),
        UInt8(63),
        UInt8(64),
        UInt8(65),
    )

    assert_true(
        mask.contains(BitMask(UInt8(1), UInt8(2), UInt8(63), UInt8(64)))
    )
    assert_false(
        mask.contains(BitMask(UInt8(1), UInt8(2), UInt8(63), UInt8(90)))
    )

    assert_true(mask.contains_any(BitMask(UInt8(6), UInt8(65), UInt8(111))))
    assert_false(mask.contains_any(BitMask(UInt8(6), UInt8(66), UInt8(90))))


def test_bitmask_get_indices() raises:
    size = 100
    std.random.seed(0)
    indices = get_random_uint8_list(size)
    var mask = BitMask()
    for index in indices:
        mask.set(index, True)
    unique_indices = unique(indices)

    assert_equal(len(unique_indices), len(mask.get_indices()))
    size = 0
    for idx in mask.get_indices():
        keep(idx)

    for value in unique_indices:
        found = False
        for idx in mask.get_indices():
            if value == idx:
                found = True
                break
        assert_true(found, String(value) + " not found.")
        size += 1

    assert_equal(len(unique_indices), size)


def test_bitmask_writable() raises:
    mask = BitMask(UInt8(1), UInt8(2), UInt8(13), UInt8(27))
    assert_equal(String(mask), write_to_string(mask))

    empty_mask = BitMask()
    assert_equal(String(empty_mask), write_to_string(empty_mask))


comptime functions = __functions_in_module()


def main() raises:
    TestSuite.discover_tests[functions]().run()
