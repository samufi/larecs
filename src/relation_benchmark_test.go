package ecs

import (
    "testing"
)

fn benchmarkRelationGetQuery(b *testing.B, count int):
    b.StopTimer()

    world = NewWorld(NewConfig().WithCapacityIncrement(1024).WithRelationCapacityIncrement(128))
    relID = ComponentID[testRelationA](&world)

    target = world.NewEntity()

    builder = NewBuilder(&world, relID).WithRelation(relID)
    builder.NewBatch(count, target)

    filter = all(relID)
    b.StartTimer()

    var tempTarget Entity
    for i = 0; i < b.N; i++:
        query = world.Query(filter)
        for query.Next():
            tempTarget = query.Relation(relID)
        
    

    _ = tempTarget

fn benchmarkRelationGetQueryUnchecked(b *testing.B, count int):
    b.StopTimer()

    world = NewWorld(NewConfig().WithCapacityIncrement(1024).WithRelationCapacityIncrement(128))
    relID = ComponentID[testRelationA](&world)

    target = world.NewEntity()

    builder = NewBuilder(&world, relID).WithRelation(relID)
    builder.NewBatch(count, target)

    filter = all(relID)
    b.StartTimer()

    var tempTarget Entity
    for i = 0; i < b.N; i++:
        query = world.Query(filter)
        for query.Next():
            tempTarget = query.relationUnchecked(relID)
        
    

    _ = tempTarget

fn benchmarkRelationGetWorld(b *testing.B, count int):
    b.StopTimer()

    world = NewWorld(NewConfig().WithCapacityIncrement(1024).WithRelationCapacityIncrement(128))
    relID = ComponentID[testRelationA](&world)

    target = world.NewEntity()

    builder = NewBuilder(&world, relID).WithRelation(relID)
    q = builder.NewBatchQ(count, target)
    entities = make([]Entity, 0, count)
    for q.Next():
        entities = append(entities, q.Entity())
    
    b.StartTimer()

    var tempTarget Entity
    for i = 0; i < b.N; i++:
        for _, e = range entities:
            tempTarget = world.Relations().get(e, relID)
        
    

    _ = tempTarget

fn benchmarkRelationGetWorldUnchecked(b *testing.B, count int):
    b.StopTimer()

    world = NewWorld(NewConfig().WithCapacityIncrement(1024).WithRelationCapacityIncrement(128))
    relID = ComponentID[testRelationA](&world)

    target = world.NewEntity()

    builder = NewBuilder(&world, relID).WithRelation(relID)
    q = builder.NewBatchQ(count, target)
    entities = make([]Entity, 0, count)
    for q.Next():
        entities = append(entities, q.Entity())
    
    b.StartTimer()

    var tempTarget Entity
    for i = 0; i < b.N; i++:
        for _, e = range entities:
            tempTarget = world.Relations().GetUnchecked(e, relID)
        
    

    _ = tempTarget

fn benchmarkRelationSet(b *testing.B, count int):
    b.StopTimer()

    world = NewWorld(NewConfig().WithCapacityIncrement(1024).WithRelationCapacityIncrement(128))
    relID = ComponentID[testRelationA](&world)

    target = world.NewEntity()

    builder = NewBuilder(&world, relID).WithRelation(relID)
    q = builder.NewBatchQ(count)
    entities = make([]Entity, 0, count)
    for q.Next():
        entities = append(entities, q.Entity())
    
    b.StartTimer()

    var tempTarget Entity
    for i = 0; i < b.N; i++:
        trg = Entity{}
        if i%2 == 0:
            trg = target
        
        for _, e = range entities:
            world.Relations().set(e, relID, trg)
        
    

    _ = tempTarget

fn BenchmarkRelationGetQuery_1000(b *testing.B):
    benchmarkRelationGetQuery(b, 1000)

fn BenchmarkRelationGetQuery_10000(b *testing.B):
    benchmarkRelationGetQuery(b, 10000)

fn BenchmarkRelationGetQuery_100000(b *testing.B):
    benchmarkRelationGetQuery(b, 100000)

fn BenchmarkRelationGetQueryUnchecked_1000(b *testing.B):
    benchmarkRelationGetQueryUnchecked(b, 1000)

fn BenchmarkRelationGetQueryUnchecked_10000(b *testing.B):
    benchmarkRelationGetQueryUnchecked(b, 10000)

fn BenchmarkRelationGetQueryUnchecked_100000(b *testing.B):
    benchmarkRelationGetQueryUnchecked(b, 100000)

fn BenchmarkRelationGetWorld_1000(b *testing.B):
    benchmarkRelationGetWorld(b, 1000)

fn BenchmarkRelationGetWorld_10000(b *testing.B):
    benchmarkRelationGetWorld(b, 10000)

fn BenchmarkRelationGetWorld_100000(b *testing.B):
    benchmarkRelationGetWorld(b, 100000)

fn BenchmarkRelationGetWorldUnchecked_1000(b *testing.B):
    benchmarkRelationGetWorldUnchecked(b, 1000)

fn BenchmarkRelationGetWorldUnchecked_10000(b *testing.B):
    benchmarkRelationGetWorldUnchecked(b, 10000)

fn BenchmarkRelationGetWorldUnchecked_100000(b *testing.B):
    benchmarkRelationGetWorldUnchecked(b, 100000)

fn BenchmarkRelationSet_1000(b *testing.B):
    benchmarkRelationSet(b, 1000)

fn BenchmarkRelationSet_10000(b *testing.B):
    benchmarkRelationSet(b, 10000)

fn BenchmarkRelationSet_100000(b *testing.B):
    benchmarkRelationSet(b, 100000)
