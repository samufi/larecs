package ecs_test

import (
    "testing"

    "github.com/mlange-42/arche/ecs"
    "github.com/stretchr/testify/assert"
)

fn TestConfig(t *testing.T):
    c = ecs.NewConfig()
    c = c.WithCapacityIncrement(16)
    assert_equal(16, c.CapacityIncrement)
    assert_equal(0, c.RelationCapacityIncrement)

    c = c.WithRelationCapacityIncrement(8)
    assert_equal(8, c.RelationCapacityIncrement)

    _ = ecs.NewWorld(c)

fn ExampleConfig():
    config =
        ecs.NewConfig().
            WithCapacityIncrement(1024).       # Optionally set capacity increment
            WithRelationCapacityIncrement(128) # Optionally set capacity increment for relations

    world = ecs.NewWorld(config)

    world.NewEntity()
    # Output:
