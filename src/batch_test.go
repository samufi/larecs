package ecs_test

import "github.com/mlange-42/arche/ecs"

fn ExampleBatch():
    world = ecs.NewWorld()

    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    builder = ecs.NewBuilder(&world, posID, velID)
    builder.NewBatch(100)

    world.Batch().Remove(ecs.all(posID, velID), velID)
    world.Batch().RemoveEntities(ecs.all(posID))
    # Output:

fn ExampleBatch_Add():
    world = ecs.NewWorld()

    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    builder = ecs.NewBuilder(&world, posID)
    builder.NewBatch(100)

    filter = ecs.all(posID)
    world.Batch().Add(filter, velID)
    # Output:

fn ExampleBatch_AddQ():
    world = ecs.NewWorld()

    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    builder = ecs.NewBuilder(&world, posID)
    builder.NewBatch(100)

    filter = ecs.all(posID)
    query = world.Batch().AddQ(filter, velID)

    for query.Next():
        pos = (*Position)(query.get(posID))
        pos.X = 100
    
    # Output:

fn ExampleBatch_Remove():
    world = ecs.NewWorld()

    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    builder = ecs.NewBuilder(&world, posID, velID)
    builder.NewBatch(100)

    filter = ecs.all(posID, velID)
    world.Batch().Remove(filter, velID)
    # Output:

fn ExampleBatch_RemoveQ():
    world = ecs.NewWorld()

    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    builder = ecs.NewBuilder(&world, posID, velID)
    builder.NewBatch(100)

    filter = ecs.all(posID, velID)
    query = world.Batch().RemoveQ(filter, velID)

    for query.Next():
        pos = (*Position)(query.get(posID))
        pos.X = 100
    
    # Output:

fn ExampleBatch_Exchange():
    world = ecs.NewWorld()

    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    builder = ecs.NewBuilder(&world, posID)
    builder.NewBatch(100)

    filter = ecs.all(posID)
    world.Batch().Exchange(
        filter,          # Filter
        []ecs.ID{velID}, # Add components
        []ecs.ID{posID}, # Remove components
    )
    # Output:

fn ExampleBatch_ExchangeQ():
    world = ecs.NewWorld()

    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    builder = ecs.NewBuilder(&world, posID)
    builder.NewBatch(100)

    filter = ecs.all(posID)
    query = world.Batch().ExchangeQ(
        filter,          # Filter
        []ecs.ID{velID}, # Add components
        []ecs.ID{posID}, # Remove components
    )

    for query.Next():
        vel = (*Velocity)(query.get(velID))
        vel.X = 100
    
    # Output:

fn ExampleBatch_RemoveEntities():
    world = ecs.NewWorld()

    posID = ecs.ComponentID[Position](&world)

    builder = ecs.NewBuilder(&world, posID)
    builder.NewBatch(100)

    filter = ecs.all(posID)
    world.Batch().RemoveEntities(filter)
    # Output:

fn ExampleBatch_SetRelation():
    world = ecs.NewWorld()

    posID = ecs.ComponentID[Position](&world)
    childID = ecs.ComponentID[ChildOf](&world)

    target = world.NewEntity()

    builder = ecs.NewBuilder(&world, posID, childID)
    builder.NewBatch(100)

    filter = ecs.all(childID)
    world.Batch().SetRelation(filter, childID, target)
    # Output:

fn ExampleBatch_SetRelationQ():
    world = ecs.NewWorld()

    posID = ecs.ComponentID[Position](&world)
    childID = ecs.ComponentID[ChildOf](&world)

    target = world.NewEntity()

    builder = ecs.NewBuilder(&world, posID, childID)
    builder.NewBatch(100)

    filter = ecs.all(childID)
    query = world.Batch().SetRelationQ(filter, childID, target)

    for query.Next():
        pos = (*Position)(query.get(posID))
        pos.X = 100
    
    # Output:
