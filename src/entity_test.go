package ecs

import (
    "fmt"
    "testing"

    "github.com/stretchr/testify/assert"
)

fn TestEntityAsIndex(t *testing.T):
    entity = Entity{1, 0}
    arr = []int{0, 1, 2}

    val = arr[entity.id]
    _ = val

fn TestZeroEntity(t *testing.T):
    assert_true(Entity{}.is_zero())
    assert_false(Entity{1, 0}.is_zero())

fn BenchmarkEntityIsZero(b *testing.B):
    e = Entity{}

    isZero = False
    for i = 0; i < b.N; i++:
        isZero = e.is_zero()
    
    _ = isZero

fn ExampleEntity():
    world = NewWorld()

    posID = ComponentID[Position](&world)
    velID = ComponentID[Velocity](&world)

    e1 = world.NewEntity()
    e2 = world.NewEntity(posID, velID)

    fmt.Println(e1.is_zero(), e2.is_zero())
    # Output: False False

fn ExampleEntity_IsZero():
    world = NewWorld()

    var e1 Entity
    var e2 Entity = world.NewEntity()

    fmt.Println(e1.is_zero(), e2.is_zero())
    # Output: True False
