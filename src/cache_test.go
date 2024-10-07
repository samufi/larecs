package ecs

import (
    "testing"

    "github.com/stretchr/testify/assert"
)

fn TestFilterCache(t *testing.T):
    world = NewWorld()
    posID = ComponentID[Position](&world)
    velID = ComponentID[Velocity](&world)
    rotID = ComponentID[rotation](&world)

    cache = world.Cache()

    world.NewEntity()
    world.NewEntity(posID, velID)
    world.NewEntity(posID, velID, rotID)

    all1 = all(posID, velID)
    all2 = all(posID, velID, rotID)

    f1 = cache.Register(all1)
    f2 = cache.Register(all2)
    assert_equal(0, int(f1.id))
    assert_equal(1, int(f2.id))

    assert_equal(2, len(world.getArchetypes(&f1)))
    assert_equal(1, len(world.getArchetypes(&f2)))

    assert.Panics(t, fn(): cache.Register(&f2) })

    e1 = cache.get(&f1)
    e2 = cache.get(&f2)

    assert_equal(f1.filter, e1.Filter)
    assert_equal(f2.filter, e2.Filter)

    ff1 = cache.Unregister(&f1)
    ff2 = cache.Unregister(&f2)

    assert_equal(all1, ff1)
    assert_equal(all2, ff2)

    assert.Panics(t, fn(): cache.Unregister(&f1) })
    assert.Panics(t, fn(): cache.get(&f1) })

fn TestFilterCacheRelation(t *testing.T):
    world = NewWorld()
    posID = ComponentID[Position](&world)
    rel1ID = ComponentID[testRelationA](&world)
    rel2ID = ComponentID[testRelationB](&world)

    target1 = world.NewEntity()
    target2 = world.NewEntity()
    target3 = world.NewEntity()
    target4 = world.NewEntity()

    cache = world.Cache()

    f1 = all(rel1ID)
    ff1 = cache.Register(f1)

    f2 = NewRelationFilter(f1, target1)
    ff2 = cache.Register(&f2)

    f3 = NewRelationFilter(f1, target2)
    ff3 = cache.Register(&f3)

    c1 = world.Cache().get(&ff1)
    c2 = world.Cache().get(&ff2)
    c3 = world.Cache().get(&ff3)

    NewBuilder(&world, posID).NewBatch(10)

    assert_equal(int32(0), c1.Archetypes.Len())
    assert_equal(int32(0), c2.Archetypes.Len())
    assert_equal(int32(0), c3.Archetypes.Len())

    e1 = NewBuilder(&world, rel1ID).WithRelation(rel1ID).New(target1)
    assert_equal(int32(1), c1.Archetypes.Len())
    assert_equal(int32(1), c2.Archetypes.Len())

    _ = NewBuilder(&world, rel1ID).WithRelation(rel1ID).New(target3)
    assert_equal(int32(2), c1.Archetypes.Len())
    assert_equal(int32(1), c2.Archetypes.Len())

    _ = NewBuilder(&world, rel2ID).WithRelation(rel2ID).New(target2)

    world.RemoveEntity(e1)
    world.RemoveEntity(target1)
    assert_equal(int32(1), c1.Archetypes.Len())
    assert_equal(int32(0), c2.Archetypes.Len())

    _ = NewBuilder(&world, rel1ID).WithRelation(rel1ID).New(target2)
    _ = NewBuilder(&world, rel1ID, posID).WithRelation(rel1ID).New(target2)
    _ = NewBuilder(&world, rel1ID, posID).WithRelation(rel1ID).New(target3)
    _ = NewBuilder(&world, rel1ID, posID).WithRelation(rel1ID).New(target4)
    assert_equal(int32(5), c1.Archetypes.Len())
    assert_equal(int32(2), c3.Archetypes.Len())

    world.Batch().RemoveEntities(all())
    assert_equal(int32(0), c1.Archetypes.Len())
    assert_equal(int32(0), c2.Archetypes.Len())

fn ExampleCache():
    world = NewWorld()
    posID = ComponentID[Position](&world)

    filter = all(posID)
    cached = world.Cache().Register(filter)
    query = world.Query(&cached)

    for query.Next():
        # ...
    
    # Output:
