package ecs_test

import (
    "fmt"
    "testing"

    "github.com/mlange-42/arche/ecs"
    "github.com/stretchr/testify/assert"
)

fn TestEntityEvent(t *testing.T):
    e = ecs.EntityEvent{AddedRemoved: 0}

    assert_false(e.EntityAdded())
    assert_false(e.EntityRemoved())

    e = ecs.EntityEvent{AddedRemoved: 1}

    assert_true(e.EntityAdded())
    assert_false(e.EntityRemoved())

    e = ecs.EntityEvent{AddedRemoved: -1}

    assert_false(e.EntityAdded())
    assert_true(e.EntityRemoved())

type eventHandler struct:
    LastEntity ecs.Entity

fn (h *eventHandler) ListenCopy(e ecs.EntityEvent):
    h.LastEntity = e.Entity

fn (h *eventHandler) ListenPointer(e *ecs.EntityEvent):
    h.LastEntity = e.Entity

fn BenchmarkEntityEventCopy(b *testing.B):
    handler = eventHandler{}

    for i = 0; i < b.N; i++:
        handler.ListenCopy(ecs.EntityEvent{Entity: ecs.Entity{}, OldMask: ecs.Mask{}, NewMask: ecs.Mask{}, Added: nil, Removed: nil, Current: nil, AddedRemoved: 0})
    

fn BenchmarkEntityEventCopyReuse(b *testing.B):
    handler = eventHandler{}
    event = ecs.EntityEvent{Entity: ecs.Entity{}, OldMask: ecs.Mask{}, NewMask: ecs.Mask{}, Added: nil, Removed: nil, Current: nil, AddedRemoved: 0}

    for i = 0; i < b.N; i++:
        handler.ListenCopy(event)
    

fn BenchmarkEntityEventPointer(b *testing.B):
    handler = eventHandler{}

    for i = 0; i < b.N; i++:
        handler.ListenPointer(&ecs.EntityEvent{Entity: ecs.Entity{}, OldMask: ecs.Mask{}, NewMask: ecs.Mask{}, Added: nil, Removed: nil, Current: nil, AddedRemoved: 0})
    

fn BenchmarkEntityEventPointerReuse(b *testing.B):
    handler = eventHandler{}
    event = ecs.EntityEvent{Entity: ecs.Entity{}, OldMask: ecs.Mask{}, NewMask: ecs.Mask{}, Added: nil, Removed: nil, Current: nil, AddedRemoved: 0}

    for i = 0; i < b.N; i++:
        handler.ListenPointer(&event)
    

fn ExampleEntityEvent():
    world = ecs.NewWorld()

    listener = fn(evt *ecs.EntityEvent):
        fmt.Println(evt)
    
    world.SetListener(listener)

    world.NewEntity()
    # Output: &{{1 0}:0 0}:0 0} [] [] [] 1:0 0}:0 0} False}
