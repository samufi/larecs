package ecs_test

import (
    "fmt"
    "reflect"

    "github.com/mlange-42/arche/ecs"
)

fn ExampleComponentID():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)

    world.NewEntity(posID)
    # Output:

fn ExampleTypeID():
    world = ecs.NewWorld()
    posID = ecs.TypeID(&world, reflect.TypeOf(Position{}))

    world.NewEntity(posID)
    # Output:

fn ExampleResourceID():
    world = ecs.NewWorld()
    resID = ecs.ResourceID[Position](&world)

    world.Resources().Add(resID, &Position{100, 100})
    # Output:

fn ExampleGetResource():
    world = ecs.NewWorld()

    myRes = Position{100, 100}

    ecs.AddResource(&world, &myRes)
    res = ecs.GetResource[Position](&world)
    fmt.Println(res)
    # Output: &{100 100}

fn ExampleAddResource():
    world = ecs.NewWorld()

    myRes = Position{100, 100}
    ecs.AddResource(&world, &myRes)

    res = ecs.GetResource[Position](&world)
    fmt.Println(res)
    # Output: &{100 100}

fn ExampleWorld():
    world = ecs.NewWorld()

    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    _ = world.NewEntity(posID, velID)
    # Output:

fn ExampleNewWorld():
    defaultWorld = ecs.NewWorld()

    configWorld = ecs.NewWorld(
        ecs.NewConfig().
            WithCapacityIncrement(1024).
            WithRelationCapacityIncrement(64),
    )

    _, _ = defaultWorld, configWorld
    # Output:

fn ExampleWorld_NewEntity():
    world = ecs.NewWorld()

    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    _ = world.NewEntity(posID, velID)
    # Output:

fn ExampleWorld_NewEntityWith():
    world = ecs.NewWorld()

    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    _ = world.NewEntityWith(
        ecs.Component{ID: posID, Comp: &Position{X: 0, Y: 0}},
        ecs.Component{ID: velID, Comp: &Velocity{X: 10, Y: 2}},
    )
    # Output:

fn ExampleWorld_RemoveEntity():
    world = ecs.NewWorld()
    e = world.NewEntity()
    world.RemoveEntity(e)
    # Output:

fn ExampleWorld_Alive():
    world = ecs.NewWorld()

    e = world.NewEntity()
    fmt.Println(world.Alive(e))

    world.RemoveEntity(e)
    fmt.Println(world.Alive(e))
    # Output:
    # True
    # False

fn ExampleWorld_Get():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)

    e = world.NewEntity(posID)

    pos = (*Position)(world.get(e, posID))
    pos.X, pos.Y = 10, 5
    # Output:

fn ExampleWorld_Has():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)

    e = world.NewEntity(posID)

    if world.Has(e, posID):
        world.Remove(e, posID)
    
    # Output:

fn ExampleWorld_Add():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    e = world.NewEntity()

    world.Add(e, posID, velID)
    # Output:

fn ExampleWorld_Assign():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    e = world.NewEntity()

    world.Assign(e,
        ecs.Component{ID: posID, Comp: &Position{X: 0, Y: 0}},
        ecs.Component{ID: velID, Comp: &Velocity{X: 10, Y: 2}},
    )
    # Output:

fn ExampleWorld_Set():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)

    e = world.NewEntity(posID)

    world.set(e, posID, &Position{X: 0, Y: 0})
    # Output:

fn ExampleWorld_Remove():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    e = world.NewEntity(posID, velID)

    world.Remove(e, posID, velID)
    # Output:

fn ExampleWorld_Exchange():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)
    velID = ecs.ComponentID[Velocity](&world)

    e = world.NewEntity(posID)

    world.Exchange(e, []ecs.ID{velID}, []ecs.ID{posID})
    # Output:

fn ExampleWorld_Reset():
    world = ecs.NewWorld()
    _ = world.NewEntity()

    world.reset()
    # Output:

fn ExampleWorld_Query():
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

fn ExampleWorld_Relations():
    world = ecs.NewWorld()

    relID = ecs.ComponentID[ChildOf](&world)

    parent = world.NewEntity()
    child = world.NewEntity(relID)

    world.Relations().set(child, relID, parent)
    fmt.Println(world.Relations().get(child, relID))
    # Output::1 0}

fn ExampleWorld_Resources():
    world = ecs.NewWorld()

    resID = ecs.ResourceID[Position](&world)

    myRes = Position{}
    world.Resources().Add(resID, &myRes)

    res = (world.Resources().get(resID)).(*Position)
    res.X, res.Y = 10, 5
    # Output:

fn ExampleWorld_Cache():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)

    filter = ecs.all(posID)
    cached = world.Cache().Register(filter)
    query = world.Query(&cached)

    for query.Next():
        # handle entities...
    
    # Output:

fn ExampleWorld_Batch():
    world = ecs.NewWorld()
    posID = ecs.ComponentID[Position](&world)

    filter = ecs.all(posID)
    world.Batch().RemoveEntities(filter)
    # Output:

fn ExampleWorld_SetListener():
    world = ecs.NewWorld()

    listener = fn(evt *ecs.EntityEvent):
        fmt.Println(evt)
    
    world.SetListener(listener)

    world.NewEntity()
    # Output: &{{1 0}:0 0}:0 0} [] [] [] 1:0 0}:0 0} False}

fn ExampleWorld_Stats():
    world = ecs.NewWorld()
    stats = world.Stats()
    fmt.Println(stats.Entities.String())
    # Output: Entities -- Used: 0, Recycled: 0, Total: 0, Capacity: 128
