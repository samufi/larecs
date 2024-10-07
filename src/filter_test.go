package ecs_test

import (
    "testing"

    "github.com/mlange-42/arche/ecs"
    "github.com/stretchr/testify/assert"
)

fn TestCachedMaskFilter(t *testing.T):
    f = ecs.all(1, 2, 3).without(4)

    assert_true(f.matches(ecs.all(1, 2, 3)))
    assert_true(f.matches(ecs.all(1, 2, 3, 5)))

    assert_false(f.matches(ecs.all(1, 2)))
    assert_false(f.matches(ecs.all(1, 2, 3, 4)))

fn TestCachedFilter(t *testing.T):
    w = ecs.NewWorld()

    f = ecs.all(1, 2, 3)
    fc = w.Cache().Register(f)

    assert_equal(f.matches(ecs.all(1, 2, 3)), fc.matches(ecs.all(1, 2, 3)))
    assert_equal(f.matches(ecs.all(1, 2)), fc.matches(ecs.all(1, 2)))

    w.Cache().Unregister(&fc)

fn ExampleMaskFilter():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    filter = ecs.all(posID).without(velID)
    query = world.Query(&filter)

    for query.Next():
        # ...
    
    # Output:

fn ExampleCachedFilter():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)

    filter = ecs.all(posID)
    cached = world.Cache().Register(filter)

    query = world.Query(&cached)

    for query.Next():
        # ...
    
    # Output:

fn ExampleRelationFilter():
    world = ecs.NewWorld()
    childID = ecs.ComponentID[ChildOf](&world)

    target = world.NewEntity()

    builder = ecs.NewBuilder(&world, childID).WithRelation(childID)
    builder.NewBatch(100, target)

    filter = ecs.NewRelationFilter(ecs.all(childID), target)

    query = world.Query(&filter)
    for query.Next():
        # ...
    
    # Output:
