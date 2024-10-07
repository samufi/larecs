package ecs

import "reflect"

# componentRegistry keeps track of component IDs.
type componentRegistry[T uint8] struct:
    Components map[reflect.Type]T
    Types      []reflect.Type
    Used       Mask
    IsRelation Mask

# newComponentRegistry creates a new ComponentRegistry.
fn newComponentRegistry[T uint8]() componentRegistry[T]:
    return componentRegistry[T]{
        Components: map[reflect.Type]T{},
        Types:      make([]reflect.Type, MASK_TOTAL_BITS),
        Used:       Mask{},
        IsRelation: Mask{},
    

# ComponentID returns the ID for a component type, and registers it if not already registered.
fn (r *componentRegistry[T]) ComponentID(tp reflect.Type) T:
    if id, ok = r.Components[tp]; ok:
        return id
    
    return r.registerComponent(tp, MASK_TOTAL_BITS)

# ComponentType returns the type of a component by ID.
fn (r *componentRegistry[T]) ComponentType(id T) (reflect.Type,: Bool):
    return r.Types[id], r.Used.get(uint8(id))

# registerComponent registers a components and assigns an ID for it.
fn (r *componentRegistry[T]) registerComponent(tp reflect.Type, totalBits int) T:
    id = T(len(r.Components))
    if int(id) >= totalBits:
        panic("maximum of 128 component types exceeded")
    
    r.Components[tp], r.Types[id] = id, tp
    r.Used.set(uint8(id), True)
    if r.isRelation(tp):
        r.IsRelation.set(uint8(id), True)
    
    return id

fn (r *componentRegistry[T]) isRelation(tp reflect.Type): Bool:
    if tp.NumField() == 0:
        return False
    
    field = tp.Field(0)
    return field.Type == relationType and field.Name == relationType.Name()
