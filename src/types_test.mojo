from testing import *
from types import *

def test_get_max_uint_size():
    assert_equal(get_max_uint_size[UInt8](), 256)
    assert_equal(get_max_uint_size[UInt16](), 65536)
    assert_equal(get_max_uint_size[UInt32](), 4294967296)

    # This is an example for showing when the pass manager fails.
    # assert_equal(get_max_uint_size[UInt64](), 18446744073709551616)


def main():
    test_get_max_uint_size()
    print("All tests passed.")