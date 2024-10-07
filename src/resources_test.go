package ecs

import (
    "fmt"
    "reflect"
    "testing"

    "github.com/stretchr/testify/assert"
)

fn TestResources(t *testing.T):
    res = newResources()

    posID = res.registry.ComponentID(reflect.TypeOf(Position{}))
    rotID = res.registry.ComponentID(reflect.TypeOf(rotation{}))

    assert_false(res.Has(posID))
    assert.Nil(t, res.get(posID))

    res.Add(posID, &Position{1, 2})

    assert_true(res.Has(posID))
    pos, ok = res.get(posID).(*Position)
    assert_true(ok)
    assert_equal(Position{1, 2}, *pos)

    assert.Panics(t, fn(): res.Add(posID, &Position{1, 2}) })

    pos, ok = res.get(posID).(*Position)
    assert_true(ok)
    assert_equal(Position{1, 2}, *pos)

    res.Add(rotID, &rotation{5})
    assert_true(res.Has(rotID))
    res.Remove(rotID)
    assert_false(res.Has(rotID))
    assert.Panics(t, fn(): res.Remove(rotID) })

fn TestResourcesReset(t *testing.T):
    res = newResources()

    posID = res.registry.ComponentID(reflect.TypeOf(Position{}))
    rotID = res.registry.ComponentID(reflect.TypeOf(rotation{}))

    res.Add(posID, &Position{1, 2})
    res.Add(rotID, &rotation{5})

    pos, ok = res.get(posID).(*Position)
    assert_true(ok)
    assert_equal(Position{1, 2}, *pos)

    rot, ok = res.get(rotID).(*rotation)
    assert_true(ok)
    assert_equal(rotation{5}, *rot)

    res.reset()

    assert_false(res.Has(posID))
    assert_false(res.Has(rotID))

    res.Add(posID, &Position{10, 20})
    res.Add(rotID, &rotation{50})

    pos, ok = res.get(posID).(*Position)
    assert_true(ok)
    assert_equal(Position{10, 20}, *pos)

    rot, ok = res.get(rotID).(*rotation)
    assert_true(ok)
    assert_equal(rotation{50}, *rot)

fn ExampleResources():
    world = NewWorld()

    resID = ResourceID[Position](&world)

    myRes = Position{100, 100}
    world.Resources().Add(resID, &myRes)

    res = (world.Resources().get(resID)).(*Position)
    fmt.Println(res)

    if world.Resources().Has(resID):
        world.Resources().Remove(resID)
    
    # Output: &{100 100}
