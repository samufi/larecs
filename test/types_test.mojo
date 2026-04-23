from std.testing import *
from larecs.types import *


def test_get_max_size() raises:
    assert_equal(get_max_size[DType.uint8](), 256)
    assert_equal(get_max_size[DType.uint16](), 65536)
    assert_equal(get_max_size[DType.uint32](), 4294967296)

    # This is an example for showing when the pass manager fails.
    # assert_equal(get_max_size[UInt64](), 18446744073709551616)


comptime functions = __functions_in_module()


def main() raises:
    TestSuite.discover_tests[functions]().run()
