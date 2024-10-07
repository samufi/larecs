package ecs

import (
    "fmt"
    "math/rand"
    "reflect"
    "runtime"
    "testing"

    "github.com/stretchr/testify/assert"
)

fn TestWorldConfig(t *testing.T):
    _ = NewWorld(NewConfig())

    assert.Panics(t, fn(): _ = NewWorld(Config{}) })
    assert.Panics(t, fn(): _ = NewWorld(Config{}, Config{}) })

    world = NewWorld(
        NewConfig().WithCapacityIncrement(32).WithRelationCapacityIncrement(8),
    )

    relID = ComponentID[testRelationA](&world)

    world.NewEntity()
    world.NewEntity(relID)

    assert_equal(uint32(32), world.nodes.get(0).capacityIncrement)
    assert_equal(uint32(8), world.nodes.get(1).capacityIncrement)

fn TestWorldEntites(t *testing.T):
    w = NewWorld()

    assert_equal(newEntityGen(1, 0), w.NewEntity())
    assert_equal(newEntityGen(2, 0), w.NewEntity())
    assert_equal(newEntityGen(3, 0), w.NewEntity())

    assert_equal(0, int(w.entities[0].index))
    assert_equal(0, int(w.entities[1].index))
    assert_equal(1, int(w.entities[2].index))
    assert_equal(2, int(w.entities[3].index))
    w.RemoveEntity(newEntityGen(2, 0))
    assert_false(w.Alive(newEntityGen(2, 0)))

    assert_equal(0, int(w.entities[1].index))
    assert_equal(1, int(w.entities[3].index))

    assert_equal(newEntityGen(2, 1), w.NewEntity())
    assert_false(w.Alive(newEntityGen(2, 0)))
    assert_true(w.Alive(newEntityGen(2, 1)))

    assert_equal(2, int(w.entities[2].index))

    w.RemoveEntity(newEntityGen(3, 0))
    w.RemoveEntity(newEntityGen(2, 1))
    w.RemoveEntity(newEntityGen(1, 0))

    assert.Panics(t, fn(): w.RemoveEntity(newEntityGen(3, 0)) })
    assert.Panics(t, fn(): w.RemoveEntity(newEntityGen(2, 1)) })
    assert.Panics(t, fn(): w.RemoveEntity(newEntityGen(1, 0)) })

fn TestWorldNewEntites(t *testing.T):
    w = NewWorld(NewConfig().WithCapacityIncrement(32))

    posID = ComponentID[Position](&w)
    velID = ComponentID[Velocity](&w)
    rotID = ComponentID[rotation](&w)

    e0 = w.NewEntity()
    e1 = w.NewEntity(posID, velID, rotID)
    e2 = w.NewEntityWith(
        Component{posID, &Position{1, 2}},
        Component{velID, &Velocity{3, 4}},
        Component{rotID, &rotation{5}},
    )
    e3 = w.NewEntityWith()

    assert_equal(all(), w.Mask(e0))
    assert_equal(all(posID, velID, rotID), w.Mask(e1))
    assert_equal(all(posID, velID, rotID), w.Mask(e2))
    assert_equal(all(), w.Mask(e3))

    pos = (*Position)(w.get(e2, posID))
    vel = (*Velocity)(w.get(e2, velID))
    rot = (*rotation)(w.get(e2, rotID))

    assert_equal(&Position{1, 2}, pos)
    assert_equal(&Velocity{3, 4}, vel)
    assert_equal(&rotation{5}, rot)

    w.RemoveEntity(e0)
    w.RemoveEntity(e1)
    w.RemoveEntity(e2)
    w.RemoveEntity(e3)

    for i = 0; i < 35; i++:
        e = w.NewEntityWith(
            Component{posID, &Position{i + 1, i + 2}},
            Component{velID, &Velocity{i + 3, i + 4}},
            Component{rotID, &rotation{i + 5}},
        )

        pos = (*Position)(w.get(e, posID))
        vel = (*Velocity)(w.get(e, velID))
        rot = (*rotation)(w.get(e, rotID))

        assert_equal(&Position{i + 1, i + 2}, pos)
        assert_equal(&Velocity{i + 3, i + 4}, vel)
        assert_equal(&rotation{i + 5}, rot)
    

fn TestWorldComponents(t *testing.T):
    w = NewWorld()

    posID = ComponentID[Position](&w)
    rotID = ComponentID[rotation](&w)

    tPosID = TypeID(&w, reflect.TypeOf(Position{}))
    tRotID = TypeID(&w, reflect.TypeOf(rotation{}))

    assert_equal(posID, tPosID)
    assert_equal(rotID, tRotID)

    e0 = w.NewEntity()
    e1 = w.NewEntity()
    e2 = w.NewEntity()

    assert_equal(int32(1), w.archetypes.Len())

    w.Add(e0, posID)
    assert_equal(int32(2), w.archetypes.Len())
    w.Add(e1, posID, rotID)
    assert_equal(int32(3), w.archetypes.Len())
    w.Add(e2, posID, rotID)
    assert_equal(int32(3), w.archetypes.Len())

    assert_equal(all(posID), w.Mask(e0))
    assert_equal(all(posID, rotID), w.Mask(e1))

    w.Remove(e2, posID)

    maskNone = all()
    maskPos = all(posID)
    maskRot = all(rotID)
    maskPosRot = all(posID, rotID)

    archNone, ok = w.findArchetypeSlow(maskNone)
    assert_true(ok)
    archPos, ok = w.findArchetypeSlow(maskPos)
    assert_true(ok)
    archRot, ok = w.findArchetypeSlow(maskRot)
    assert_true(ok)
    archPosRot, ok = w.findArchetypeSlow(maskPosRot)
    assert_true(ok)

    assert_equal(0, int(archNone.archetype.Len()))
    assert_equal(1, int(archPos.archetype.Len()))
    assert_equal(1, int(archRot.archetype.Len()))
    assert_equal(1, int(archPosRot.archetype.Len()))

    w.Remove(e1, posID)

    assert_equal(0, int(archNone.archetype.Len()))
    assert_equal(1, int(archPos.archetype.Len()))
    assert_equal(2, int(archRot.archetype.Len()))
    assert_equal(0, int(archPosRot.archetype.Len()))

    w.Add(e0, rotID)
    assert_equal(0, int(archPos.archetype.Len()))
    assert_equal(1, int(archPosRot.archetype.Len()))

    w.Remove(e2, rotID)
    # No-op add/remove
    w.Add(e0)
    w.Remove(e0)

    w.RemoveEntity(e0)
    assert.Panics(t, fn(): w.Has(newEntityGen(1, 0), posID) })
    assert.Panics(t, fn(): w.get(newEntityGen(1, 0), posID) })

fn TestWorldLabels(t *testing.T):
    w = NewWorld()

    posID = ComponentID[Position](&w)
    labID = ComponentID[label](&w)

    e0 = w.NewEntity()
    e1 = w.NewEntity()
    e2 = w.NewEntity()

    w.Add(e0, posID, labID)
    w.Add(e1, labID)
    w.Add(e1, posID)

    lab0 = (*label)(w.get(e0, labID))
    assert.NotNil(t, lab0)

    lab1 = (*label)(w.get(e1, labID))
    assert.NotNil(t, lab1)

    assert_true(w.Has(e0, labID))
    assert_true(w.Has(e1, labID))
    assert_false(w.Has(e2, labID))

    assert_equal(lab0, lab1)

fn TestWorldExchange(t *testing.T):
    w = NewWorld()

    posID = ComponentID[Position](&w)
    velID = ComponentID[Velocity](&w)
    rotID = ComponentID[rotation](&w)
    rel1ID = ComponentID[testRelationA](&w)
    rel2ID = ComponentID[testRelationB](&w)

    e0 = w.NewEntity()
    e1 = w.NewEntity()
    e2 = w.NewEntity()

    w.Exchange(e0, []ID{posID}, []ID{})
    w.Exchange(e1, []ID{posID, rotID}, []ID{})
    w.Exchange(e2, []ID{rotID}, []ID{})

    assert_true(w.Has(e0, posID))
    assert_false(w.Has(e0, rotID))

    assert_true(w.Has(e1, posID))
    assert_true(w.Has(e1, rotID))

    assert_false(w.Has(e2, posID))
    assert_true(w.Has(e2, rotID))

    w.Exchange(e2, []ID{posID}, []ID{})
    assert_true(w.Has(e2, posID))
    assert_true(w.Has(e2, rotID))

    w.Exchange(e0, []ID{rotID}, []ID{posID})
    assert_false(w.Has(e0, posID))
    assert_true(w.Has(e0, rotID))

    w.Exchange(e1, []ID{velID}, []ID{posID})
    assert_false(w.Has(e1, posID))
    assert_true(w.Has(e1, rotID))
    assert_true(w.Has(e1, velID))

    assert.Panics(t, fn(): w.Exchange(e1, []ID{velID}, []ID{}) })
    assert.Panics(t, fn(): w.Exchange(e1, []ID{}, []ID{posID}) })

    w.RemoveEntity(e0)
    _ = w.NewEntity()
    assert.Panics(t, fn(): w.Exchange(e0, []ID{posID}, []ID{}) })

    target = w.NewEntity()
    e0 = w.NewEntity(rel1ID)

    assert.Panics(t, fn(): w.exchange(e0, []ID{rel2ID}, nil, int8(rel2ID), target) })
    assert.Panics(t, fn(): w.exchange(e0, []ID{posID}, nil, int8(posID), target) })

    w.Remove(e0, rel1ID)
    assert.Panics(t, fn(): w.exchange(e0, []ID{posID}, nil, int8(rel1ID), target) })

fn TestWorldExchangeBatch(t *testing.T):
    w = NewWorld()

    events = []EntityEvent{}
    w.SetListener(fn(e *EntityEvent):
        events = append(events, *e)
    )

    posID = ComponentID[Position](&w)
    velID = ComponentID[Velocity](&w)
    relID = ComponentID[testRelationA](&w)

    target1 = w.NewEntity(velID)
    target2 = w.NewEntity(velID)

    builder = NewBuilder(&w, posID, relID).WithRelation(relID)
    builder.NewBatch(100, target1)
    builder.NewBatch(100, target2)

    filter = all(posID, relID)
    query = w.Batch().ExchangeQ(filter, []ID{velID}, []ID{posID})
    assert_equal(200, query.Count())
    for query.Next():
        assert_true(query.Has(velID))
        assert_true(query.Has(relID))
        assert_false(query.Has(posID))
    

    query = w.Query(all(posID))
    assert_equal(0, query.Count())
    query.Close()

    filter2 = NewRelationFilter(all(relID), target1)
    query = w.Batch().ExchangeQ(&filter2, []ID{posID}, []ID{velID})
    assert_equal(100, query.Count())
    for query.Next():
        assert_true(query.Has(posID))
        assert_true(query.Has(relID))
        assert_false(query.Has(velID))
        assert_equal(target1, query.Relation(relID))
    

    query = w.Query(all(posID))
    assert_equal(100, query.Count())
    query.Close()

    w.Batch().Exchange(all(posID), nil, nil)

    relFilter = NewRelationFilter(all(relID), target2)
    w.Batch().Exchange(&relFilter, nil, []ID{relID})
    w.Batch().Exchange(all(relID), nil, []ID{relID})

    w.Batch().RemoveEntities(all(posID))

    assert_equal(802, len(events))
    assert_equal(1, events[0].AddedRemoved)
    assert_equal(1, events[1].AddedRemoved)
    assert_equal(1, events[2].AddedRemoved)
    assert_equal(1, events[201].AddedRemoved)

    assert_equal(0, events[202].AddedRemoved)
    assert_equal([]ID{velID}, events[202].Added)
    assert_equal([]ID{posID}, events[202].Removed)

    filter = all(velID)
    w.Batch().Remove(filter, velID)

    filter = all(velID)
    q = w.Query(filter)
    assert_equal(0, q.Count())
    q.Close()

    filter = all()
    w.Batch().Add(filter, velID)

    w.reset()

    target1 = w.NewEntity(velID)
    builder = NewBuilder(&w, posID, relID).WithRelation(relID)
    builder.NewBatch(100, target1)

    filter = all(velID)
    q = w.Batch().RemoveQ(filter, velID)
    assert_equal(1, q.Count())
    q.Close()

    filter = all()
    q = w.Batch().AddQ(filter, velID)
    assert_equal(101, q.Count())
    q.Close()

fn TestWorldAssignSet(t *testing.T):
    w = NewWorld()

    posID = ComponentID[Position](&w)
    velID = ComponentID[Velocity](&w)
    rotID = ComponentID[rotation](&w)

    e0 = w.NewEntity()
    e1 = w.NewEntity()

    assert.Panics(t, fn(): w.Assign(e0) })

    w.Assign(e0, Component{posID, &Position{2, 3}})
    pos = (*Position)(w.get(e0, posID))
    assert_equal(2, pos.X)
    pos.X = 5

    pos = (*Position)(w.get(e0, posID))
    assert_equal(5, pos.X)

    assert.Panics(t, fn(): w.Assign(e0, Component{posID, &Position{2, 3}}) })
    assert.Panics(t, fn(): _ = (*Position)(w.copyTo(e1, posID, &Position{2, 3})) })

    e2 = w.NewEntity()
    w.Assign(e2,
        Component{posID, &Position{4, 5}},
        Component{velID, &Velocity{1, 2}},
        Component{rotID, &rotation{3}},
    )
    assert_true(w.Has(e2, velID))
    assert_true(w.Has(e2, rotID))
    assert_true(w.Has(e2, posID))

    pos = (*Position)(w.get(e2, posID))
    rot = (*rotation)(w.get(e2, rotID))
    vel = (*Velocity)(w.get(e2, velID))
    assert_equal(&Position{4, 5}, pos)
    assert_equal(&rotation{3}, rot)
    assert_equal(&Velocity{1, 2}, vel)

    _ = (*Position)(w.set(e2, posID, &Position{7, 8}))
    pos = (*Position)(w.get(e2, posID))
    assert_equal(7, pos.X)

    *pos = Position{8, 9}
    pos = (*Position)(w.get(e2, posID))
    assert_equal(8, pos.X)

    w.RemoveEntity(e0)
    _ = w.NewEntity()
    assert.Panics(t, fn(): w.Assign(e0, Component{posID, &Position{2, 3}}) })

fn TestWorldGetComponents(t *testing.T):
    w = NewWorld()

    posID = ComponentID[Position](&w)
    rotID = ComponentID[rotation](&w)

    e0 = w.NewEntity()
    e1 = w.NewEntity()
    e2 = w.NewEntity()

    w.Add(e0, posID, rotID)
    w.Add(e1, posID, rotID)
    w.Add(e2, rotID)

    assert_false(w.Has(e2, posID))
    assert_true(w.Has(e2, rotID))
    assert_false(w.HasUnchecked(e2, posID))
    assert_true(w.HasUnchecked(e2, rotID))

    pos1 = (*Position)(w.get(e1, posID))
    assert_equal(&Position{}, pos1)

    pos1.X = 100
    pos1.Y = 101

    pos0 = (*Position)(w.get(e0, posID))
    pos1 = (*Position)(w.get(e1, posID))
    assert_equal(&Position{}, pos0)
    assert_equal(&Position{100, 101}, pos1)

    pos0 = (*Position)(w.GetUnchecked(e0, posID))
    pos1 = (*Position)(w.GetUnchecked(e1, posID))
    assert_equal(&Position{}, pos0)
    assert_equal(&Position{100, 101}, pos1)

    w.RemoveEntity(e0)
    assert.Panics(t, fn(): w.get(e0, posID) })
    assert.Panics(t, fn(): w.Mask(e0) })

    _ = w.NewEntity(posID)
    assert.Panics(t, fn(): w.get(e0, posID) })
    assert.Panics(t, fn(): w.Mask(e0) })

    pos1 = (*Position)(w.get(e1, posID))
    assert_equal(&Position{100, 101}, pos1)

    pos2 = (*Position)(w.get(e2, posID))
    assert_true(pos2 == nil)

fn TestWorldIter(t *testing.T):
    world = NewWorld()

    posID = ComponentID[Position](&world)
    rotID = ComponentID[rotation](&world)

    for i = 0; i < 1000; i++:
        entity = world.NewEntity()
        world.Add(entity, posID, rotID)
    

    world.NewEntity(rotID)

    for i = 0; i < 10; i++:
        query = world.Query(all(posID, rotID))
        cnt = 0
        for query.Next():
            pos = (*Position)(query.get(posID))
            _ = pos
            cnt++
        
        assert_equal(1000, cnt)
        assert.Panics(t, fn(): query.Next() })
    

    for i = 0; i < MASK_TOTAL_BITS-1; i++:
        query = world.Query(all(posID, rotID))
        for query.Next():
            pos = (*Position)(query.get(posID))
            _ = pos
            break
        
    
    query = world.Query(all(posID, rotID))

    assert.Panics(t, fn(): world.Query(all(posID, rotID)) })

    query.Close()
    assert.Panics(t, fn(): query.Close() })

fn TestWorldNewEntities(t *testing.T):
    world = NewWorld(NewConfig().WithCapacityIncrement(16))

    events = []EntityEvent{}
    world.SetListener(fn(e *EntityEvent):
        assert_equal(world.IsLocked(), e.EntityRemoved())
        events = append(events, *e)
    )

    posID = ComponentID[Position](&world)
    rotID = ComponentID[rotation](&world)

    world.NewEntity(posID, rotID)
    assert_equal(2, len(world.entities))

    assert.Panics(t, fn(): world.newEntitiesQuery(0, -1, Entity{}, posID, rotID) })

    query = world.newEntitiesQuery(100, -1, Entity{}, posID, rotID)
    assert_equal(100, query.Count())
    assert_equal(102, len(world.entities))
    assert_equal(1, len(events))

    cnt = 0
    for query.Next():
        pos = (*Position)(query.get(posID))
        pos.X = cnt + 1
        pos.Y = cnt + 1
        cnt++
    
    assert_equal(100, cnt)
    assert_equal(101, len(events))

    query = world.Query(all(posID, rotID))
    assert_equal(101, query.Count())

    cnt = 0
    for query.Next():
        pos = (*Position)(query.get(posID))
        assert_equal(cnt, pos.X)
        cnt++
    

    world.reset()
    assert_equal(1, len(world.entities))

    query = world.newEntitiesQuery(100, -1, Entity{}, posID, rotID)
    assert_equal(100, query.Count())
    assert_equal(101, len(events))

    entities = make([]Entity, query.Count())
    cnt = 0
    for query.Next():
        entities[cnt] = query.Entity()
        cnt++
    
    assert_equal(100, cnt)
    assert_equal(201, len(events))

    for _, e = range entities:
        world.RemoveEntity(e)
    
    assert_equal(301, len(events))
    assert_equal(101, len(world.entities))

    query = world.newEntitiesQuery(100, -1, Entity{}, posID, rotID)
    assert_equal(301, len(events))
    query.Close()
    assert_equal(401, len(events))
    assert_equal(101, len(world.entities))

    world.newEntities(100, -1, Entity{}, posID, rotID)
    assert_equal(501, len(events))
    assert_equal(201, len(world.entities))

fn TestWorldNewEntitiesWith(t *testing.T):
    world = NewWorld(NewConfig().WithCapacityIncrement(16))

    events = []EntityEvent{}
    world.SetListener(fn(e *EntityEvent):
        assert_equal(world.IsLocked(), e.EntityRemoved())
        events = append(events, *e)
    )

    posID = ComponentID[Position](&world)
    rotID = ComponentID[rotation](&world)

    comps = []Component{
        {ID: posID, Comp: &Position{100, 200}},
        {ID: rotID, Comp: &rotation{300}},
    

    world.NewEntity(posID, rotID)
    assert_equal(1, len(events))

    assert.Panics(t, fn(): world.newEntitiesWithQuery(0, -1, Entity{}, comps...) })
    assert_equal(1, len(events))

    query = world.newEntitiesWithQuery(1, -1, Entity{})
    assert_equal(1, len(events))
    query.Close()
    assert_equal(2, len(events))

    query = world.newEntitiesWithQuery(100, -1, Entity{}, comps...)
    assert_equal(100, query.Count())
    assert_equal(2, len(events))

    cnt = 0
    for query.Next():
        pos = (*Position)(query.get(posID))
        assert_equal(100, pos.X)
        assert_equal(200, pos.Y)
        pos.X = cnt + 1
        pos.Y = cnt + 1
        cnt++
    
    assert_equal(100, cnt)
    assert_equal(102, len(events))

    query = world.Query(all(posID, rotID))
    assert_equal(101, query.Count())

    cnt = 0
    for query.Next():
        pos = (*Position)(query.get(posID))
        assert_equal(cnt, pos.X)
        cnt++
    

    world.reset()

    query = world.newEntitiesWithQuery(100, -1, Entity{},
        Component{ID: posID, Comp: &Position{100, 200}},
        Component{ID: rotID, Comp: &rotation{300}},
    )
    assert_equal(100, query.Count())
    assert_equal(102, len(events))

    cnt = 0
    for query.Next():
        cnt++
    
    assert_equal(100, cnt)
    assert_equal(202, len(events))

    world.newEntitiesWith(100, -1, Entity{}, comps...)
    assert_equal(302, len(events))

fn TestWorldRemoveEntities(t *testing.T):
    world = NewWorld(NewConfig().WithCapacityIncrement(16))

    events = []EntityEvent{}
    world.SetListener(fn(e *EntityEvent):
        assert_equal(world.IsLocked(), e.EntityRemoved())
        events = append(events, *e)
    )

    posID = ComponentID[Position](&world)
    rotID = ComponentID[rotation](&world)

    query = world.newEntitiesQuery(100, -1, Entity{}, posID)
    assert_equal(100, query.Count())
    query.Close()
    assert_equal(100, len(events))

    query = world.newEntitiesQuery(100, -1, Entity{}, posID, rotID)
    assert_equal(100, query.Count())
    query.Close()
    assert_equal(200, len(events))

    query = world.Query(all())
    assert_equal(200, query.Count())
    query.Close()

    filter = all(posID).exclusive()
    cnt = world.Batch().RemoveEntities(&filter)
    assert_equal(100, cnt)
    assert_equal(300, len(events))

    query = world.Query(all())
    assert_equal(100, query.Count())
    query.Close()

    query = world.Query(all(posID, rotID))
    assert_equal(100, query.Count())
    query.Close()

fn TestWorldRelationSet(t *testing.T):
    world = NewWorld()

    events = []EntityEvent{}
    world.SetListener(fn(e *EntityEvent):
        events = append(events, *e)
    )

    rotID = ComponentID[rotation](&world)
    relID = ComponentID[testRelationA](&world)
    rel2ID = ComponentID[testRelationB](&world)

    targ = world.NewEntity()
    e1 = world.NewEntity(relID, rotID)
    e2 = world.NewEntity(relID, rotID)

    assert_equal(int32(3), world.nodes.Len())
    assert_equal(int32(1), world.nodes.get(2).archetypes.Len())
    assert_equal(int32(1), world.archetypes.Len())

    assert_equal(Entity{}, world.Relations().get(e1, relID))
    assert_equal(Entity{}, world.Relations().GetUnchecked(e1, relID))
    world.Relations().set(e1, relID, targ)

    assert_equal(targ, world.Relations().get(e1, relID))
    assert_equal(targ, world.Relations().GetUnchecked(e1, relID))
    assert_equal(int32(3), world.nodes.Len())
    assert_equal(int32(2), world.nodes.get(2).archetypes.Len())
    assert_equal(int32(1), world.archetypes.Len())

    world.Relations().set(e1, relID, Entity{})

    assert.Panics(t, fn(): world.Relations().get(e1, rotID) })
    assert.Panics(t, fn(): world.Relations().get(e1, rel2ID) })
    assert.Panics(t, fn(): world.Relations().set(e1, rotID, Entity{}) })
    assert.Panics(t, fn(): world.Relations().set(e1, rel2ID, Entity{}) })

    # Should do nothing
    world.Relations().set(e1, relID, Entity{})

    assert_equal(Entity{}, world.Relations().get(e1, relID))
    assert_equal(int32(3), world.nodes.Len())
    assert_equal(int32(1), world.archetypes.Len())

    world.Remove(e2, relID)

    assert.Panics(t, fn(): world.Relations().get(e2, relID) })
    assert.Panics(t, fn(): world.Relations().set(e2, relID, Entity{}) })

    assert.Panics(t, fn(): world.NewEntity(relID, rel2ID) })
    assert.Panics(t, fn(): world.Add(e1, rel2ID) })

    world.RemoveEntity(e1)
    assert.Panics(t, fn(): world.Relations().get(e1, relID) })
    assert.Panics(t, fn(): world.Relations().set(e1, relID, targ) })

    e3 = world.NewEntity(relID, rotID)
    world.RemoveEntity(targ)
    assert.Panics(t, fn(): world.Relations().set(e3, relID, targ) })

    assert_equal(int32(2), world.nodes.get(2).archetypes.Len())
    assert_true(world.nodes.get(2).archetypes.get(0).IsActive())
    assert_false(world.nodes.get(2).archetypes.get(1).IsActive())

    assert_equal(9, len(events))

fn TestWorldRelationSetBatch(t *testing.T):
    world = NewWorld()

    events = []EntityEvent{}
    world.SetListener(fn(e *EntityEvent):
        events = append(events, *e)
    )

    posID = ComponentID[Position](&world)
    rotID = ComponentID[rotation](&world)
    relID = ComponentID[testRelationA](&world)

    targ1 = world.NewEntity(posID)
    targ2 = world.NewEntity(posID)
    targ3 = world.NewEntity(posID)

    builder = NewBuilder(&world, rotID, relID).WithRelation(relID)
    builder.NewBatch(100, targ1)
    builder.NewBatch(100, targ2)
    builder.NewBatch(100, targ3)

    relFilter = NewRelationFilter(all(relID), targ2)
    q = world.Batch().SetRelationQ(&relFilter, relID, targ1)
    assert_equal(100, q.Count())
    cnt = 0
    for q.Next():
        assert_equal(targ1, q.Relation(relID))
        cnt++
    
    assert_equal(100, cnt)

    q = world.Batch().SetRelationQ(all(relID), relID, targ3)
    assert_equal(300, q.Count())
    cnt = 0
    for q.Next():
        assert_equal(targ3, q.Relation(relID))
        cnt++
    
    assert_equal(300, cnt)

    relFilter = NewRelationFilter(all(relID), targ3)
    q = world.Batch().SetRelationQ(&relFilter, relID, Entity{})
    assert_equal(300, q.Count())
    cnt = 0
    for q.Next():
        assert_true(q.Relation(relID).is_zero())
        cnt++
    
    assert_equal(300, cnt)

    relFilter = NewRelationFilter(all(relID), Entity{})
    world.Batch().SetRelation(&relFilter, relID, targ1)

    world.RemoveEntity(targ3)
    assert.Panics(t, fn():
        world.Batch().SetRelation(all(relID), relID, targ3)
    )

    assert_equal(1304, len(events))

    world.Relations().SetBatch(all(relID), relID, targ1)

    q = world.Relations().SetBatchQ(all(relID), relID, targ2)
    assert_equal(300, q.Count())
    q.Close()

    fmt.Println(debugPrintWorld(&world))

    world.reset()

fn TestWorldRelationRemove(t *testing.T):
    world = NewWorld()

    events = []EntityEvent{}
    world.SetListener(fn(e *EntityEvent): events = append(events, *e) })

    rotID = ComponentID[rotation](&world)
    relID = ComponentID[testRelationA](&world)

    targ = world.NewEntity()
    targ2 = world.NewEntity()
    targ3 = world.NewEntity()

    e1 = world.NewEntity(relID, rotID)
    e2 = world.NewEntity(relID, rotID)

    filter = NewRelationFilter(all(relID), targ)
    world.Cache().Register(&filter)

    assert_equal(int32(3), world.nodes.Len())
    assert_equal(int32(1), world.nodes.get(2).archetypes.Len())
    assert_equal(int32(1), world.archetypes.Len())

    world.Relations().set(e1, relID, targ)
    world.Relations().set(e2, relID, targ)

    assert_equal(int32(2), world.nodes.get(2).archetypes.Len())
    assert_equal(int32(1), world.archetypes.Len())

    world.RemoveEntity(targ)
    assert_equal(int32(1), world.archetypes.Len())

    world.Relations().set(e1, relID, Entity{})
    world.Relations().set(e2, relID, Entity{})

    assert_equal(int32(2), world.nodes.get(2).archetypes.Len())
    assert_equal(int32(1), world.archetypes.Len())

    world.Relations().set(e1, relID, targ2)
    world.Relations().set(e2, relID, targ2)

    assert_equal(int32(2), world.nodes.get(2).archetypes.Len())
    assert_equal(int32(1), world.archetypes.Len())

    world.Relations().set(e1, relID, Entity{})
    world.Relations().set(e2, relID, Entity{})

    _ = world.Stats()

    world.RemoveEntity(targ2)
    assert_equal(int32(1), world.archetypes.Len())

    world.Relations().set(e1, relID, targ3)
    world.Relations().set(e2, relID, targ3)

    assert_equal(int32(2), world.nodes.get(2).archetypes.Len())
    assert_equal(targ3, world.nodes.get(2).archetypes.get(1).RelationTarget)
    assert_equal(int32(1), world.archetypes.Len())

    world.Batch().RemoveEntities(all())
    world.Batch().RemoveEntities(all())

    assert_equal(int32(2), world.nodes.get(2).archetypes.Len())
    assert_true(world.nodes.get(2).archetypes.get(0).IsActive())
    assert_false(world.nodes.get(2).archetypes.get(1).IsActive())

fn TestWorldRelationQuery(t *testing.T):
    world = NewWorld()

    rotID = ComponentID[rotation](&world)
    relID = ComponentID[testRelationA](&world)

    targ0 = world.NewEntityWith(Component{ID: rotID, Comp: &rotation{Angle: 0}})

    targ1 = world.NewEntityWith(Component{ID: rotID, Comp: &rotation{Angle: 1}})
    targ2 = world.NewEntityWith(Component{ID: rotID, Comp: &rotation{Angle: 2}})
    targ3 = world.NewEntityWith(Component{ID: rotID, Comp: &rotation{Angle: 3}})

    e1 = world.NewEntity(relID)
    world.Relations().set(e1, relID, targ0)

    for i = 0; i < 4; i++:
        e1 = world.NewEntity(relID)
        world.Relations().set(e1, relID, targ1)

        e2 = world.NewEntity(relID)
        world.Relations().set(e2, relID, targ2)
    

    world.RemoveEntity(e1)
    world.RemoveEntity(targ0)

    filter = all(relID)
    query = world.Query(filter)
    assert_equal(8, query.Count())
    cnt = 0
    for query.Next():
        cnt++
    
    assert_equal(8, cnt)

    filter2 = NewRelationFilter(all(relID), targ1)
    query = world.Query(&filter2)
    assert_equal(4, query.Count())
    query.Close()

    filter2 = NewRelationFilter(all(relID), targ2)
    query = world.Query(&filter2)
    assert_equal(4, query.Count())
    query.Close()

    filter2 = NewRelationFilter(all(relID), targ3)
    query = world.Query(&filter2)
    assert_equal(0, query.Count())
    cnt = 0
    for query.Next():
        cnt++
    
    assert_equal(0, cnt)

fn TestWorldRelationQueryCached(t *testing.T):
    world = NewWorld()

    rotID = ComponentID[rotation](&world)
    relID = ComponentID[testRelationA](&world)

    targ0 = world.NewEntityWith(Component{ID: rotID, Comp: &rotation{Angle: 0}})

    targ1 = world.NewEntityWith(Component{ID: rotID, Comp: &rotation{Angle: 1}})
    targ2 = world.NewEntityWith(Component{ID: rotID, Comp: &rotation{Angle: 2}})
    targ3 = world.NewEntityWith(Component{ID: rotID, Comp: &rotation{Angle: 3}})

    e1 = world.NewEntity(relID)
    world.Relations().set(e1, relID, targ0)

    for i = 0; i < 4; i++:
        e1 = world.NewEntity(relID)
        world.Relations().set(e1, relID, targ1)

        e2 = world.NewEntity(relID)
        world.Relations().set(e2, relID, targ2)
    

    world.RemoveEntity(e1)
    world.RemoveEntity(targ0)

    filter = all(relID)
    regFilter = world.Cache().Register(filter)
    query = world.Query(&regFilter)
    assert_equal(8, query.Count())
    cnt = 0
    for query.Next():
        cnt++
    
    assert_equal(8, cnt)
    world.Cache().Unregister(&regFilter)

    filter2 = NewRelationFilter(all(relID), targ1)
    regFilter2 = world.Cache().Register(&filter2)
    query = world.Query(&regFilter2)
    assert_equal(4, query.Count())
    query.Close()
    world.Cache().Unregister(&regFilter2)

    filter2 = NewRelationFilter(all(relID), targ2)
    regFilter2 = world.Cache().Register(&filter2)
    query = world.Query(&regFilter2)
    assert_equal(4, query.Count())
    query.Close()
    world.Cache().Unregister(&regFilter2)

    filter2 = NewRelationFilter(all(relID), targ3)
    regFilter2 = world.Cache().Register(&filter2)
    query = world.Query(&regFilter2)
    assert_equal(0, query.Count())
    query.Close()
    world.Cache().Unregister(&regFilter2)

fn TestWorldRelation(t *testing.T):
    world = NewWorld()

    posID = ComponentID[Position](&world)
    relID = ComponentID[testRelationA](&world)

    parents = make([]Entity, 25)
    for i = 0; i < 25; i++:
        parents[i] = world.NewEntityWith(Component{ID: posID, Comp: &Position{X: i, Y: 0}})
    

    for i = 0; i < 2500; i++:
        par = parents[i/100]
        e = world.NewEntity(relID)
        world.Relations().set(e, relID, par)
    

    parFilter = all(posID)
    parQuery = world.Query(parFilter)
    assert_equal(25, parQuery.Count())
    for parQuery.Next():
        targ = (*Position)(parQuery.get(posID))
        filter = NewRelationFilter(all(relID), parQuery.Entity())
        query = world.Query(&filter)
        assert_equal(100, query.Count())
        for query.Next():
            targ.Y++
        
    

    parQuery = world.Query(parFilter)
    for parQuery.Next():
        targ = (*Position)(parQuery.get(posID))
        assert_equal(100, targ.Y)
    

fn TestWorldRelationCreate(t *testing.T):
    world = NewWorld()
    world.SetListener(fn(e *EntityEvent):})

    posID = ComponentID[Position](&world)
    relID = ComponentID[testRelationA](&world)

    alive = world.NewEntity()
    dead = world.NewEntity()
    world.RemoveEntity(dead)

    world.newEntities(5, int8(relID), alive, posID, relID)
    assert.Panics(t, fn(): world.newEntitiesNoNotify(5, int8(relID), dead, posID, relID) })

    world.newEntityTarget(relID, alive, posID, relID)
    assert.Panics(t, fn(): world.newEntityTarget(relID, dead, posID, relID) })

    world.newEntitiesWith(5, int8(relID), alive,
        Component{ID: posID, Comp: &Position{}},
        Component{ID: relID, Comp: &testRelationA{}},
    )
    assert.Panics(t, fn():
        world.newEntitiesWith(5, int8(relID), dead,
            Component{ID: posID, Comp: &Position{}},
            Component{ID: relID, Comp: &testRelationA{}},
        )
    )

    world.newEntityTargetWith(relID, alive,
        Component{ID: posID, Comp: &Position{}},
        Component{ID: relID, Comp: &testRelationA{}},
    )
    assert.Panics(t, fn():
        world.newEntityTargetWith(relID, dead,
            Component{ID: posID, Comp: &Position{}},
            Component{ID: relID, Comp: &testRelationA{}},
        )
    )

fn TestWorldRelationMove(t *testing.T):
    world = NewWorld()
    world.SetListener(fn(e *EntityEvent):})

    posID = ComponentID[Position](&world)
    relID = ComponentID[testRelationA](&world)

    target1 = world.NewEntity()
    target2 = world.NewEntity()

    entities = []Entity{}
    for _, trg = range [...]Entity{target1, target2}:
        query = NewBuilder(&world, relID).WithRelation(relID).NewBatchQ(100, trg)
        for query.Next():
            entities = append(entities, query.Entity())
        
    

    for _, e = range entities:
        world.Add(e, posID)
    

    for i, e = range entities:
        trg = world.Relations().get(e, relID)

        if i < 100:
            assert_equal(target1, trg)
         else:
            assert_equal(target2, trg)
        
    

    for _, e = range entities:
        world.Remove(e, posID)
    

    for i, e = range entities:
        trg = world.Relations().get(e, relID)

        if i < 100:
            assert_equal(target1, trg)
         else:
            assert_equal(target2, trg)
        
    

    for _, e = range entities:
        world.Remove(e, relID)
    

fn TestWorldLock(t *testing.T):
    world = NewWorld()

    posID = ComponentID[Position](&world)
    rotID = ComponentID[rotation](&world)

    var entity Entity
    for i = 0; i < 100; i++:
        entity = world.NewEntity()
        world.Add(entity, posID)
    

    query1 = world.Query(all(posID))
    query2 = world.Query(all(posID))
    assert_true(world.IsLocked())
    query1.Close()
    assert_true(world.IsLocked())
    query2.Close()
    assert_false(world.IsLocked())

    query1 = world.Query(all(posID))

    assert.Panics(t, fn(): world.NewEntity() })
    assert.Panics(t, fn(): world.RemoveEntity(entity) })
    assert.Panics(t, fn(): world.Add(entity, rotID) })
    assert.Panics(t, fn(): world.Remove(entity, posID) })

fn TestWorldStats(t *testing.T):
    w = NewWorld()

    posID = ComponentID[Position](&w)
    rotID = ComponentID[rotation](&w)
    velID = ComponentID[Velocity](&w)
    relID = ComponentID[testRelationA](&w)

    _ = w.Stats()

    e0 = w.NewEntity()
    e1 = w.NewEntity(posID, rotID)
    w.NewEntity(posID, rotID)

    stats = w.Stats()
    _ = stats.Nodes[1].String()
    s = stats.Nodes[2].String()
    fmt.Println(s)

    assert_equal(3, len(stats.Nodes))
    assert_equal(3, stats.Entities.Used)
    _ = w.Stats()

    w.Add(e0, posID)

    w.NewEntity(velID)
    stats = w.Stats()
    assert_equal(4, len(stats.Nodes))
    assert_equal(4, stats.Entities.Used)

    stats = w.Stats()
    assert_equal(4, len(stats.Nodes))

    builder = NewBuilder(&w, relID).WithRelation(relID)

    builder.NewBatch(10)
    builder.NewBatch(10, e0)
    _ = w.Stats()

    builder.NewBatch(5, e1)

    stats = w.Stats()
    assert_equal(29, stats.Entities.Used)
    assert_equal(5, len(stats.Nodes))

    node = &stats.Nodes[4]
    assert_equal(3, len(node.Archetypes))
    assert_equal(10, node.Archetypes[0].Size)
    assert_equal(10, node.Archetypes[1].Size)
    assert_equal(5, node.Archetypes[2].Size)

    f = all(relID).exclusive()
    w.Batch().RemoveEntities(&f)
    w.RemoveEntity(e0)
    stats = w.Stats()

    s = stats.String()
    fmt.Println(s)

fn TestWorldResources(t *testing.T):
    w = NewWorld()

    posID = ResourceID[Position](&w)
    rotID = ResourceID[rotation](&w)

    assert_false(w.Resources().Has(posID))
    assert.Nil(t, w.Resources().get(posID))

    AddResource(&w, &Position{1, 2})

    assert_true(w.Resources().Has(posID))
    pos, ok = w.Resources().get(posID).(*Position)

    assert_true(ok)
    assert_equal(Position{1, 2}, *pos)

    assert.Panics(t, fn(): w.Resources().Add(posID, &Position{1, 2}) })

    pos = GetResource[Position](&w)
    assert_equal(Position{1, 2}, *pos)

    w.Resources().Add(rotID, &rotation{5})
    assert_true(w.Resources().Has(rotID))
    w.Resources().Remove(rotID)
    assert_false(w.Resources().Has(rotID))
    assert.Panics(t, fn(): w.Resources().Remove(rotID) })

fn TestWorldComponentType(t *testing.T):
    w = NewWorld()

    posID = ComponentID[Position](&w)
    rotID = ComponentID[rotation](&w)

    tp, ok = w.ComponentType(posID)
    assert_true(ok)
    assert_equal(reflect.TypeOf(Position{}), tp)

    tp, ok = w.ComponentType(rotID)
    assert_true(ok)
    assert_equal(reflect.TypeOf(rotation{}), tp)

    _, ok = w.ComponentType(2)
    assert_false(ok)

fn TestRegisterComponents(t *testing.T):
    world = NewWorld()

    ComponentID[Position](&world)

    assert_equal(ID(0), ComponentID[Position](&world))
    assert_equal(ID(1), ComponentID[rotation](&world))

fn TestWorldBatchRemove(t *testing.T):
    world = NewWorld()

    rotID = ComponentID[rotation](&world)
    relID = ComponentID[testRelationA](&world)

    target1 = world.NewEntity()
    target2 = world.NewEntity()
    target3 = world.NewEntity()

    builder = NewBuilder(&world, rotID, relID).WithRelation(relID)

    builder.NewBatch(10, target1)
    builder.NewBatch(10, target2)
    builder.NewBatch(10, target3)

    filter = all(rotID).exclusive()
    filter2 = world.Cache().Register(&filter)
    world.Batch().RemoveEntities(&filter)
    world.Cache().Unregister(&filter2)

    relFilter = NewRelationFilter(all(rotID, relID), target1)
    world.Batch().RemoveEntities(&relFilter)

    relFilter = NewRelationFilter(all(rotID, relID), target2)
    world.Batch().RemoveEntities(&relFilter)

    filter = all().exclusive()
    world.Batch().RemoveEntities(&filter)

    relFilter = NewRelationFilter(all(rotID, relID), target3)
    world.Batch().RemoveEntities(&relFilter)

    query = world.Query(all())
    assert_equal(0, query.Count())
    query.Close()

fn TestWorldReset(t *testing.T):
    world = NewWorld()

    world.SetListener(fn(e *EntityEvent):})
    AddResource(&world, &rotation{100})

    posID = ComponentID[Position](&world)
    velID = ComponentID[Velocity](&world)
    relID = ComponentID[testRelationA](&world)

    target1 = world.NewEntity()
    target2 = world.NewEntity()

    world.NewEntity(velID)
    world.NewEntity(posID, velID)
    world.NewEntity(posID, velID)
    e1 = world.NewEntity(posID, relID)
    e2 = world.NewEntity(posID, relID)

    world.Relations().set(e1, relID, target1)
    world.Relations().set(e2, relID, target2)

    world.RemoveEntity(e1)
    world.RemoveEntity(target1)

    world.reset()

    assert_equal(0, int(world.archetypes.get(0).Len()))
    assert_equal(0, int(world.archetypes.get(1).Len()))
    assert_equal(0, world.entityPool.Len())
    assert_equal(1, len(world.entities))

    query = world.Query(all())
    assert_equal(0, query.Count())
    query.Close()

    e1 = world.NewEntity(posID)
    e2 = world.NewEntity(velID)
    world.NewEntity(posID, velID)
    world.NewEntity(posID, velID)

    assert_equal(Entity{1, 0}, e1)
    assert_equal(Entity{2, 0}, e2)

    query = world.Query(all())
    assert_equal(4, query.Count())
    query.Close()

fn TestArchetypeGraph(t *testing.T):
    world = NewWorld()

    posID = ComponentID[Position](&world)
    velID = ComponentID[Velocity](&world)
    rotID = ComponentID[rotation](&world)

    archEmpty = world.archetypes.get(0)
    arch0 = world.findOrCreateArchetype(archEmpty, []ID{posID, velID}, []ID{}, Entity{})
    archEmpty2 = world.findOrCreateArchetype(arch0, []ID{}, []ID{velID, posID}, Entity{})
    assert_equal(archEmpty, archEmpty2)
    assert_equal(int32(2), world.archetypes.Len())
    assert_equal(int32(3), world.nodes.Len())

    archEmpty3 = world.findOrCreateArchetype(arch0, []ID{}, []ID{posID, velID}, Entity{})
    assert_equal(archEmpty, archEmpty3)
    assert_equal(int32(2), world.archetypes.Len())
    assert_equal(int32(4), world.nodes.Len())

    arch01 = world.findOrCreateArchetype(arch0, []ID{velID}, []ID{}, Entity{})
    arch012 = world.findOrCreateArchetype(arch01, []ID{rotID}, []ID{}, Entity{})

    assert_equal([]ID{0, 1, 2}, arch012.node.ids)

    archEmpty4 = world.findOrCreateArchetype(arch012, []ID{}, []ID{posID, rotID, velID}, Entity{})
    assert_equal(archEmpty, archEmpty4)

fn TestWorldListener(t *testing.T):
    events = []EntityEvent{}
    listen = fn(e *EntityEvent):
        events = append(events, *e)
    

    w = NewWorld()

    w.SetListener(listen)

    posID = ComponentID[Position](&w)
    velID = ComponentID[Velocity](&w)
    rotID = ComponentID[rotation](&w)

    e0 = w.NewEntity()
    assert_equal(1, len(events))
    assert_equal(EntityEvent{
        Entity: e0, AddedRemoved: 1,
        Current: []ID{},
    , events[len(events)-1])

    w.RemoveEntity(e0)
    assert_equal(2, len(events))
    assert_equal(EntityEvent{
        Entity: e0, AddedRemoved: -1,
        Removed: []ID{},
    , events[len(events)-1])

    e0 = w.NewEntity(posID, velID)
    assert_equal(3, len(events))
    assert_equal(EntityEvent{
        Entity:       e0,
        NewMask:      all(posID, velID),
        Added:        []ID{posID, velID},
        Current:      []ID{posID, velID},
        AddedRemoved: 1,
    , events[len(events)-1])

    w.RemoveEntity(e0)
    assert_equal(4, len(events))
    assert_equal(EntityEvent{
        Entity:       e0,
        OldMask:      all(posID, velID),
        NewMask:      Mask{},
        Removed:      []ID{posID, velID},
        Current:      nil,
        AddedRemoved: -1,
    , events[len(events)-1])

    e0 = w.NewEntityWith(Component{posID, &Position{}}, Component{velID, &Velocity{}})
    assert_equal(5, len(events))
    assert_equal(EntityEvent{
        Entity:       e0,
        NewMask:      all(posID, velID),
        Added:        []ID{posID, velID},
        Current:      []ID{posID, velID},
        AddedRemoved: 1,
    , events[len(events)-1])

    w.Add(e0, rotID)
    assert_equal(6, len(events))
    assert_equal(EntityEvent{
        Entity:       e0,
        OldMask:      all(posID, velID),
        NewMask:      all(posID, velID, rotID),
        Added:        []ID{rotID},
        Current:      []ID{posID, velID, rotID},
        AddedRemoved: 0,
    , events[len(events)-1])

    w.Remove(e0, posID)
    assert_equal(7, len(events))
    assert_equal(EntityEvent{
        Entity:       e0,
        OldMask:      all(posID, velID, rotID),
        NewMask:      all(velID, rotID),
        Removed:      []ID{posID},
        Current:      []ID{velID, rotID},
        AddedRemoved: 0,
    , events[len(events)-1])


type withSlice struct:
    Slice []int

fn TestWorldRemoveGC(t *testing.T):
    w = NewWorld()
    compID = ComponentID[withSlice](&w)

    runtime.GC()
    mem1 = runtime.MemStats{}
    mem2 = runtime.MemStats{}
    runtime.ReadMemStats(&mem1)

    entities = []Entity{}
    for i = 0; i < 100; i++:
        e = w.NewEntity(compID)
        ws = (*withSlice)(w.get(e, compID))
        ws.Slice = make([]int, 10000)
        entities = append(entities, e)
    

    runtime.GC()
    runtime.ReadMemStats(&mem2)
    heap = int(mem2.HeapInuse - mem1.HeapInuse)
    assert.Greater(t, heap, 8000000)
    assert.Less(t, heap, 10000000)

    rand.Shuffle(len(entities), fn(i, j int):
        entities[i], entities[j] = entities[j], entities[i]
    )

    for _, e = range entities:
        w.RemoveEntity(e)
    

    runtime.GC()
    runtime.ReadMemStats(&mem2)
    heap = int(mem2.HeapInuse - mem1.HeapInuse)
    assert.Less(t, heap, 800000)

    w.NewEntity(compID)

fn TestWorldResetGC(t *testing.T):
    w = NewWorld()
    compID = ComponentID[withSlice](&w)

    runtime.GC()
    mem1 = runtime.MemStats{}
    mem2 = runtime.MemStats{}
    runtime.ReadMemStats(&mem1)

    for i = 0; i < 100; i++:
        e = w.NewEntity(compID)
        ws = (*withSlice)(w.get(e, compID))
        ws.Slice = make([]int, 10000)
    

    runtime.ReadMemStats(&mem2)
    heap = int(mem2.HeapInuse - mem1.HeapInuse)
    assert.Greater(t, heap, 8000000)
    assert.Less(t, heap, 10000000)

    runtime.GC()
    runtime.ReadMemStats(&mem2)
    heap = int(mem2.HeapInuse - mem1.HeapInuse)
    assert.Greater(t, heap, 8000000)
    assert.Less(t, heap, 10000000)

    w.reset()

    runtime.GC()
    runtime.ReadMemStats(&mem2)
    heap = int(mem2.HeapInuse - mem1.HeapInuse)
    assert.Less(t, heap, 800000)

    w.NewEntity(compID)

fn Test1000Archetypes(t *testing.T):
    _ = testStruct0{1}
    _ = testStruct1{1}
    _ = testStruct2{1}
    _ = testStruct3{1}
    _ = testStruct4{1}
    _ = testStruct5{1}
    _ = testStruct6{1}
    _ = testStruct7{1}
    _ = testStruct8{1}
    _ = testStruct9{1}
    _ = testStruct10{1}

    w = NewWorld()

    ids = [10]ID{}
    ids[0] = ComponentID[testStruct0](&w)
    ids[1] = ComponentID[testStruct1](&w)
    ids[2] = ComponentID[testStruct2](&w)
    ids[3] = ComponentID[testStruct3](&w)
    ids[4] = ComponentID[testStruct4](&w)
    ids[5] = ComponentID[testStruct5](&w)
    ids[6] = ComponentID[testStruct6](&w)
    ids[7] = ComponentID[testStruct7](&w)
    ids[8] = ComponentID[testStruct8](&w)
    ids[9] = ComponentID[testStruct9](&w)

    for i = 0; i < 1024; i++:
        mask = Mask{uint64(i), 0}
        add = make([]ID, 0, 10)
        for j = 0; j < 10; j++:
            id = ID(j)
            if mask.get(id):
                add = append(add, id)
            
        
        entity = w.NewEntity()
        w.Add(entity, add...)
    
    assert_equal(int32(1024), w.archetypes.Len())

    cnt = 0
    query = w.Query(all(0, 7))
    for query.Next():
        cnt++
    

    assert_equal(256, cnt)

fn TestTypeSizes(t *testing.T):
    printTypeSize[Entity]()
    printTypeSize[entityIndex]()
    printTypeSize[Mask]()
    printTypeSize[World]()
    printTypeSizeName[pagedSlice[archetype]]("pagedArr32")
    printTypeSize[archetype]()
    printTypeSize[archetypeAccess]()
    printTypeSize[archetypeData]()
    printTypeSize[archNode]()
    printTypeSize[NodeData]()
    printTypeSize[layout]()
    printTypeSize[entityPool]()
    printTypeSizeName[componentRegistry[ID]]("componentRegistry")
    printTypeSize[bitPool]()
    printTypeSize[Query]()
    printTypeSize[Resources]()
    printTypeSizeName[reflect.Value]("reflect.Value")
    printTypeSize[EntityEvent]()
    printTypeSize[Cache]()
    printTypeSizeName[idMap[uint32]]("idMap")

fn printTypeSize[T any]():
    tp = reflect.TypeOf((*T)(nil)).Elem()
    fmt.Printf("%18s: %5d B\n", tp.Name(), tp.Size())

fn printTypeSizeName[T any](name string):
    tp = reflect.TypeOf((*T)(nil)).Elem()
    fmt.Printf("%18s: %5d B\n", name, tp.Size())
