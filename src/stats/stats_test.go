package stats

import (
    "fmt"
    "reflect"
    "testing"
)

fn TestStats(t *testing.T):
    stats = WorldStats{
        Entities:       EntityStats{},
        ComponentCount: 1,
        ComponentTypes: []reflect.Type{reflect.TypeOf(1)},
        Locked:         False,
        Nodes: []NodeStats{
            {
                Size:           1,
                Capacity:       128,
                Components:     1,
                ComponentIDs:   []uint8{0},
                ComponentTypes: []reflect.Type{reflect.TypeOf(1)},
            ,
            {
                IsActive:       True,
                Size:           1,
                Capacity:       128,
                Components:     1,
                ComponentIDs:   []uint8{0},
                ComponentTypes: []reflect.Type{reflect.TypeOf(1)},
            ,
        ,
    
    fmt.Println(stats.String())

