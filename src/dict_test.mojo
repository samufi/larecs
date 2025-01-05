from collections import Dict
import random
from bitmask import BitMask
from memory import UnsafePointer
from testing import *
from stupid_dict import StupidDict
from custom_benchmark import Bencher, keep, Bench, BenchId, BenchConfig


fn get_random_bitmask_list(
    count: Int, range_start: Int = 0, range_end: Int = 1000
) -> List[BitMask] as list:
    list = List[BitMask]()
    list.reserve(count)
    for _ in range(count):
        bytes = SIMD[DType.uint64, 4]()
        bytes[0] = int(random.random_ui64(range_start, range_end))
        list.append(
            BitMask(
                bytes=UnsafePointer.address_of(bytes).bitcast[
                    SIMD[DType.uint8, 32]
                ]()[]
            )
        )


def _test_dict():
    correct_dict = Dict[BitMask, Int]()
    test_dict = StupidDict[BitMask, Int]()
    n = 10000
    bitmasks = get_random_bitmask_list(n)
    for i in range(n):
        mask = bitmasks[i]
        correct_dict[mask] = i
        test_dict[mask] = i
        assert_equal(len(test_dict), len(correct_dict))

    bitmasks = get_random_bitmask_list(n, 0, 2000)
    for mask_ in bitmasks:
        mask = mask_[]
        assert_equal(mask in correct_dict, mask in test_dict)

        if mask in correct_dict:
            assert_equal(correct_dict[mask], test_dict[mask])
        else:
            with assert_raises():
                _ = test_dict[mask]


def main():
    _test_dict()
