package ecs_test

import (
    "fmt"

    "github.com/mlange-42/arche/ecs"
)

fn ExampleRelations():
    world = ecs.NewWorld()

    relID = ecs.ComponentID[ChildOf](&world)

    parent = world.NewEntity()
    child = world.NewEntity(relID)

    world.Relations().set(child, relID, parent)
    fmt.Println(world.Relations().get(child, relID))
    # Output::1 0}

fn ExampleRelations_SetBatch():
    world = ecs.NewWorld()

    relID = ecs.ComponentID[ChildOf](&world)

    parent = world.NewEntity()
    ecs.NewBuilder(&world, relID).NewBatch(100)

    filter = ecs.all(relID)
    world.Relations().SetBatch(filter, relID, parent)
    # Output:

fn ExampleRelations_SetBatchQ():
    world = ecs.NewWorld()

    relID = ecs.ComponentID[ChildOf](&world)

    parent = world.NewEntity()
    ecs.NewBuilder(&world, relID).NewBatch(100)

    filter = ecs.all(relID)
    query = world.Relations().SetBatchQ(filter, relID, parent)
    fmt.Println(query.Count())
    query.Close()
    # Output: 100
