

from collections import InlineArray, InlineList
from component import ComponentInfo, ComponentReference
from sys.info import sizeof
from sys.mem import memcpy
from entitiy import Entity

struct Archetype[Id: Intable]: 
    """Archetype represents an ECS archetype
    """
    alias max_size = 2 ** (sizeof(Id) - 1)
    alias NullPtr = UnsafePointer[UInt8]()

    var _data:       InlineArray[UnsafePointer[UInt8], max_size, ​run_destructors=True] # Pointers to the component data.
    var _size:       UInt32                        # Current number of entities.
    var _capacity:   UInt32                        # Current capacity.
    var _item_sizes: InlineArray[UInt32, max_size] # Sizes of the component types by column
    var _ids:        InlineList[Id, max_size]      # The indices of the present components
    var _entities:   List[Entity]                  # The entities in the archetype


    fn __init__(inout self, capacity: UInt32, *components: ComponentInfo):
        self._size = 0
        self._capacity = capacity
        self._data = InlineArray[UnsafePointer[UInt8], max_size, ​run_destructors=True](UnsafePointer[UInt8]())
        self._item_sizes = InlineArray[UInt32, max_size, ​run_destructors=True](0)
        self._ids = InlineList[Id, max_size]
        self._entities = List[Entity]()

        for component in components:
            self._item_sizes[component.id] = component.size
            self._ids.append(component.id)
            self._data[component.id] = UnsafePointer[UInt8].alloc(self._capacity * component.size)

    fn __len__(self) -> UInt32:
        """Returns the number of entities in the archetype.
        """
        return self._size

    @always_inline
    fn reserve(inout self):
        """Extend the capacity of the archetype by factor 2
        """
        self.reserve(self._capacity * 2)    


    fn reserve(inout self, new_capacity: UInt32):
        """Extend the capacity of the archetype to a given number.

        Does nothing if the new capacity is not larger than the current capacity.

        Args:
            new_capacity: The new capacity of the archetype.
        """
        if new_capacity <= self._capacity:
            return
        self._capacity = new_capacity
        for i in self.ids:
            new_memory = UnsafePointer[UInt8].alloc(self._capacity)
            memcpy(new_memory, self._data[i], self._size * self._item_sizes[i])
            self._data[i].free()
            self._data[i] = new_memory


    @always_inline
    fn get_entity(self, index: UInt32) -> ref [self] Entity:
        """Returns the entity at the given index
        """
        return self._entities[int(index)]


    @always_inline
    fn _get_component_ptr(self, index: UInt32, id: id) -> UnsafePointer[UInt8]:
        """Returns the component with the given id at the given index
        """
        return self._data[id] + index * self._item_sizes[id]


    @always_inline
    fn has_component(self, id: Id) -> bool:
        """Returns whether the archetype contains the given component id.
        """
        return self._data[id] != NullPtr


    @always_inline
    fn has_relation(self) -> bool:
        """Returns whether the archetype has self relation component.
        """
        # TODO
        # return self.has_relation_component
        return False


    fn add(inout self, entity: Entity, components: ...ComponentReference) raises -> UInt32:
        """Adds an entity with components to the archetype.
        """
        if len(components) != len(self.ids):
            raise Error("Invalid number of components")
        
        idx = self._size
        
        if idx == self._capacity:
            self.extend()

        self.entities.append(entity)

        for i, component in components:
            id = component.get_id()
            if not self.ids[i] == id:
                raise Error("Component not in archetype")
            var size = self._sizes[component.get_id()]
            if not size:
                continue
            
            memcpy(self._get_component_ptr(idx, component.id), component.get_unsafe_ptr(), size)
        
        self._size += 1
        return idx


    fn remove(inout self, index: UInt32) raises -> bool:
        """Removes an entity and its components from the archetype.
        
        Performs a swap-remove and reports whether a swap was necessary
        (i.e. not the last entity that was removed).
        """
        
        self.size -= 1

        var swapped = index != self.size
        
        if swapped:
            self._entities[index] = self._entities.pop()

            for _, id in enumerate(self.node.ids):
                var size = self._sizes[id]
                if size == 0:
                    continue
                
                memcpy(self._get_component_ptr(index, id), self._get_component_ptr(self.size, id), size)
        else:
            _ = self._entities.pop()
        
        # TODO
        # self.zero_all(old)

        return swapped