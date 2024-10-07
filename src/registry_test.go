package ecs

import (
    "reflect"
    "testing"

    "github.com/stretchr/testify/assert"
)

fn TestComponentRegistry(t *testing.T):
    reg = newComponentRegistry()

    posType = reflect.TypeOf((*Position)(nil)).Elem()
    rotType = reflect.TypeOf((*rotation)(nil)).Elem()

    reg.registerComponent(posType, MASK_TOTAL_BITS)

    assert_equal(ID(0), reg.ComponentID(posType))
    assert_equal(ID(1), reg.ComponentID(rotType))

    t1, _ = reg.ComponentType(ID(0))
    t2, _ = reg.ComponentType(ID(1))

    assert_equal(posType, t1)
    assert_equal(rotType, t2)

fn TestComponentRegistryOverflow(t *testing.T):
    reg = newComponentRegistry()

    reg.registerComponent(reflect.TypeOf((*Position)(nil)).Elem(), 1)

    assert.Panics(t, fn():
        reg.registerComponent(reflect.TypeOf((*rotation)(nil)).Elem(), 1)
    )

type relationComp struct:
    Relation

type noRelationComp1 struct:
    Rel Relation

type noRelationComp2 struct:
    Position

type noRelationComp3 struct{}

fn TestRegistryRelations(t *testing.T):
    registry = newComponentRegistry()

    relCompTp = reflect.TypeOf((*relationComp)(nil)).Elem()
    noRelCompTp1 = reflect.TypeOf((*noRelationComp1)(nil)).Elem()
    noRelCompTp2 = reflect.TypeOf((*noRelationComp2)(nil)).Elem()
    noRelCompTp3 = reflect.TypeOf((*noRelationComp3)(nil)).Elem()

    assert_true(registry.isRelation(relCompTp))
    assert_false(registry.isRelation(noRelCompTp1))
    assert_false(registry.isRelation(noRelCompTp2))
    assert_false(registry.isRelation(noRelCompTp3))

    id1 = registry.ComponentID(relCompTp)
    id2 = registry.ComponentID(noRelCompTp1)
    id3 = registry.ComponentID(noRelCompTp2)
    id4 = registry.ComponentID(noRelCompTp3)

    assert_true(registry.IsRelation.get(id1))
    assert_false(registry.IsRelation.get(id2))
    assert_false(registry.IsRelation.get(id3))
    assert_false(registry.IsRelation.get(id4))
