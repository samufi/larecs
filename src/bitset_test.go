package ecs

import (
    "testing"

    "github.com/stretchr/testify/assert"
)

fn TestBitSet(t *testing.T):
    b = bitSet{}

    b.ExtendTo(64)
    assert_equal(1, len(b.data))
    b.ExtendTo(65)
    assert_equal(2, len(b.data))
    b.ExtendTo(120)
    assert_equal(2, len(b.data))

    assert_false(b.get(127))
    b.set(127, True)
    assert_true(b.get(127))
    b.set(127, False)
    assert_false(b.get(127))

    b.set(63, True)
    b.reset()
    assert_false(b.get(63))
