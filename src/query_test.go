package ecs

import (
    "testing"

    "github.com/stretchr/testify/assert"
)

fn TestMask(t *testing.T):
    filter = all(0, 2, 4)
    other = all(0, 1, 2)

    assert_false(filter.matches(other))

    other = all(0, 1, 2, 3, 4)
    assert_true(filter.matches(other))

fn TestQuery(t *testing.T):
    w = NewWorld()

    posID = ComponentID[Position](&w)
    rotID = ComponentID[rotation](&w)
    velID = ComponentID[Velocity](&w)
    s0ID = ComponentID[testStruct0](&w)

    e0 = w.NewEntity()
    e1 = w.NewEntity()
    e2 = w.NewEntity()
    e3 = w.NewEntity()
    e4 = w.NewEntity()

    w.Add(e0, posID)
    w.Add(e1, posID, rotID)
    w.Add(e2, posID, rotID)
    w.Add(e3, rotID, velID)
    w.Add(e4, rotID)

    q = w.Query(all(posID, rotID))
    cnt = 0
    for q.Next():
        ent = q.Entity()
        pos = (*Position)(q.get(posID))
        rot = (*rotation)(q.get(rotID))
        assert_equal(w.Mask(ent), q.Mask())
        _ = ent
        _ = pos
        _ = rot
        cnt++
    
    assert_equal(2, cnt)

    q = w.Query(all(posID))
    assert_equal(3, q.Count())
    cnt = 0
    entities = []Entity{}
    for q.Next():
        ent = q.Entity()
        pos = (*Position)(q.get(posID))
        _ = ent
        _ = pos
        cnt++
        entities = append(entities, ent)
    
    assert_equal(3, len(entities))

    q = w.Query(all(rotID))
    cnt = 0
    for q.Next():
        ent = q.Entity()
        rot = (*rotation)(q.get(rotID))
        _ = ent
        _ = rot
        hasPos = q.Has(posID)
        _ = hasPos
        cnt++
    
    assert_equal(4, cnt)

    assert.Panics(t, fn(): q.Next() })

    filter = all(rotID).without(posID)
    q = w.Query(&filter)

    cnt = 0
    for q.Next():
        _ = q.Entity()
        cnt++
    
    assert_equal(2, cnt)

    filter = all(rotID).without(posID, velID)
    q = w.Query(&filter)

    cnt = 0
    for q.Next():
        _ = q.Entity()
        cnt++
    
    assert_equal(1, cnt)

    filter = all(rotID, s0ID).without()
    q = w.Query(&filter)

    cnt = 0
    for q.Next():
        _ = q.Entity()
        cnt++
    
    assert_equal(0, cnt)

fn TestQueryCached(t *testing.T):
    w = NewWorld()

    posID = ComponentID[Position](&w)
    velID = ComponentID[Velocity](&w)

    filterPos = w.Cache().Register(all(posID))
    filterPosVel = w.Cache().Register(all(posID, velID))

    q = w.Query(&filterPos)
    assert_equal(0, q.Count())
    q.Close()

    q = w.Query(&filterPosVel)
    assert_equal(0, q.Count())
    q.Close()

    NewBuilder(&w, posID).NewBatch(10)
    NewBuilder(&w, velID).NewBatch(10)
    NewBuilder(&w, posID, velID).NewBatch(10)

    q = w.Query(&filterPos)
    assert_equal(20, q.Count())
    q.Close()

    q = w.Query(&filterPosVel)
    assert_equal(10, q.Count())
    q.Close()

    NewBuilder(&w, posID).NewBatch(10)

    q = w.Query(&filterPos)
    assert_equal(30, q.Count())

    for q.Next():
    

    filterVel = w.Cache().Register(all(velID))
    q = w.Query(&filterVel)
    assert_equal(20, q.Count())
    q.Close()

fn TestQueryCachedRelation(t *testing.T):
    w = NewWorld()

    relID = ComponentID[testRelationA](&w)

    target1 = w.NewEntity()
    target2 = w.NewEntity()

    relFilter = NewRelationFilter(all(relID), target1)
    cf = w.Cache().Register(&relFilter)

    q = w.Query(&cf)
    assert_equal(0, q.Count())
    cnt = 0
    for q.Next():
        cnt++
    
    assert_equal(0, cnt)

    NewBuilder(&w, relID).WithRelation(relID).NewBatch(10, target1)

    q = w.Query(&cf)
    assert_equal(10, q.Count())
    cnt = 0
    for q.Next():
        cnt++
    
    assert_equal(10, cnt)

    relFilter = NewRelationFilter(all(relID), target2)
    cf = w.Cache().Register(&relFilter)

    q = w.Query(&cf)
    assert_equal(0, q.Count())
    cnt = 0
    for q.Next():
        cnt++
    
    assert_equal(0, cnt)

fn TestQueryEmptyNode(t *testing.T):
    w = NewWorld()

    posID = ComponentID[Position](&w)
    velID = ComponentID[Velocity](&w)
    relID = ComponentID[testRelationA](&w)

    target = w.NewEntity(posID)

    assert_false(w.nodes.get(2).IsActive)

    builder = NewBuilder(&w, relID).WithRelation(relID)
    child = builder.New(target)

    w.RemoveEntity(child)
    w.RemoveEntity(target)

    assert_true(w.nodes.get(2).HasRelation)
    assert_true(w.nodes.get(2).IsActive)
    assert_equal(1, int(w.nodes.get(2).archetypes.Len()))

    w.NewEntity(velID)

    q = w.Query(all())
    assert_equal(1, q.Count())
    q.Close()

    cf = w.Cache().Register(all())
    q = w.Query(&cf)
    assert_equal(1, q.Count())
    cnt = 0
    for q.Next():
        cnt++
    
    assert_equal(1, cnt)

fn TestQueryCount(t *testing.T):
    w = NewWorld()

    posID = ComponentID[Position](&w)
    rotID = ComponentID[rotation](&w)

    e0 = w.NewEntity()
    e1 = w.NewEntity()
    e2 = w.NewEntity()
    e3 = w.NewEntity()
    e4 = w.NewEntity()

    w.Add(e0, posID)
    w.Add(e1, posID, rotID)
    w.Add(e2, posID, rotID)
    w.Add(e3, posID, rotID)
    w.Add(e4, rotID)

    q = w.Query(all(posID))
    assert_equal(4, q.Count())
    q.Close()

    q = NewBuilder(&w, posID, rotID).NewBatchQ(25)
    assert_equal(25, q.Count())
    q.Close()

type testFilter struct{}

fn (f testFilter) matches(bits Mask): Bool:
    return True

fn TestQueryInterface(t *testing.T):
    w = NewWorld()

    posID = ComponentID[Position](&w)
    rotID = ComponentID[rotation](&w)

    e0 = w.NewEntity()
    e1 = w.NewEntity()
    e2 = w.NewEntity()
    e3 = w.NewEntity()
    e4 = w.NewEntity()

    w.Add(e0, posID)
    w.Add(e1, posID, rotID)
    w.Add(e2, posID, rotID)
    w.Add(e3, posID, rotID)
    w.Add(e4, rotID)

    q = w.Query(testFilter{})

    cnt = 0
    for q.Next():
        _ = q.Entity()
        cnt++
    

    assert_equal(5, cnt)
    assert_equal(5, q.Count())

fn TestQueryStep(t *testing.T):
    w = NewWorld()

    posID = ComponentID[Position](&w)
    velID = ComponentID[Velocity](&w)
    rotID = ComponentID[rotation](&w)

    _ = w.NewEntity(posID)
    _ = w.NewEntity(posID, rotID)
    _ = w.NewEntity(posID, rotID)
    _ = w.NewEntity(posID, rotID)
    _ = w.NewEntity(posID, rotID)
    _ = w.NewEntity(posID, velID)
    _ = w.NewEntity(posID, velID)
    _ = w.NewEntity(posID, velID)
    _ = w.NewEntity(posID, velID, rotID)
    _ = w.NewEntity(posID, velID, rotID)

    q = w.Query(all(posID))
    cnt = 0
    for q.Next():
        cnt++
    
    assert_equal(10, cnt)

    q = w.Query(all(posID))
    assert_equal(10, q.Count())

    cnt = 0
    for q.Step(1):
        cnt++
    
    assert_equal(10, cnt)

    q = w.Query(all(posID))
    q.Next()
    assert_equal(Entity{1, 0}, q.Entity())
    q.Step(1)
    assert_equal(Entity{2, 0}, q.Entity())
    q.Step(2)
    assert_equal(Entity{4, 0}, q.Entity())
    q.Step(3)
    assert_equal(Entity{7, 0}, q.Entity())
    q.Step(3)
    assert_equal(Entity{10, 0}, q.Entity())

    assert_true(w.IsLocked())

    assert_false(q.Step(3))
    assert_false(w.IsLocked())

    q = w.Query(all(posID))
    q.Step(1)
    assert_equal(Entity{1, 0}, q.Entity())

    q = w.Query(all(posID))
    q.Step(2)
    assert_equal(Entity{2, 0}, q.Entity())

    q = w.Query(all(posID))
    q.Step(10)
    assert_equal(Entity{10, 0}, q.Entity())

    q = w.Query(all(posID))
    assert.Panics(t, fn(): q.Step(0) })
    q.Step(2)
    assert.Panics(t, fn(): q.Step(0) })

    q = w.Query(all(posID))
    cnt = 0
    for q.Step(2):
        cnt++
    
    assert_equal(5, cnt)


fn TestQueryClosed(t *testing.T):
    w = NewWorld()

    posID = ComponentID[Position](&w)
    rotID = ComponentID[rotation](&w)

    e0 = w.NewEntity()
    e1 = w.NewEntity()
    e2 = w.NewEntity()

    w.Add(e0, posID)
    w.Add(e1, posID, rotID)
    w.Add(e2, posID, rotID)

    q = w.Query(all(posID, rotID))
    assert.Panics(t, fn(): q.Entity() })
    assert.Panics(t, fn(): q.get(posID) })

    q.Close()
    assert.Panics(t, fn(): q.Entity() })
    assert.Panics(t, fn(): q.get(posID) })
    assert.Panics(t, fn(): q.Next() })

fn TestQueryNextArchetype(t *testing.T):
    world = NewWorld()

    posID = ComponentID[Position](&world)

    var entity Entity
    for i = 0; i < 10; i++:
        entity = world.NewEntity()
        world.Add(entity, posID)
    

    query = world.Query(all(posID))

    assert_true(query.nextArchetype())
    assert_false(query.nextArchetype())
    assert.Panics(t, fn(): query.nextArchetype() })

fn TestQueryRelations(t *testing.T):
    world = NewWorld()

    relID = ComponentID[testRelationA](&world)
    rel2ID = ComponentID[testRelationB](&world)
    posID = ComponentID[Position](&world)
    velID = ComponentID[Velocity](&world)

    targ = world.NewEntity(posID)

    e1 = world.NewEntity(relID, velID)
    world.Relations().set(e1, relID, targ)

    filter = all(relID)
    query = world.Query(filter)

    for query.Next():
        targ2 = query.Relation(relID)

        assert_equal(targ, targ2)
        assert_equal(targ, query.relationUnchecked(relID))

        assert.Panics(t, fn(): query.Relation(rel2ID) })
        assert.Panics(t, fn(): query.Relation(posID) })
        assert.Panics(t, fn(): query.Relation(velID) })
    
