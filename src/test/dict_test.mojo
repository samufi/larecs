from collections import Dict
import random
from larecs.bitmask import BitMask
from memory import UnsafePointer
from testing import *
from larecs.stupid_dict import StupidDict
from larecs.test_utils import get_random_bitmask_list


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
