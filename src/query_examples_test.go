package ecs_test

import (
    "fmt"

    "github.com/mlange-42/arche/ecs"
)

fn ExampleQuery():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    filter = ecs.all(posID, velID)
    query = world.Query(filter)
    for query.Next():
        pos = (*Position)(query.get(posID))
        vel = (*Velocity)(query.get(velID))
        pos.X += vel.X
        pos.Y += vel.Y
    
    # Output:

fn ExampleQuery_Count():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)
    world.NewEntity(posID)

    query = world.Query(ecs.all(posID))
    cnt = query.Count()
    fmt.Println(cnt)

    query.Close()
    # Output: 1

fn ExampleQuery_Close():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)
    world.NewEntity(posID)

    query = world.Query(ecs.all(posID))
    cnt = query.Count()
    fmt.Println(cnt)

    query.Close()
    # Output: 1
