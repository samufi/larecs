from testing import *
import benchmark
from entity import Entity, EntityIndex
from time import now
from archetype import Archetype
from collections import InlineArray


def test_entity_as_index():
    entity = Entity(1, 0)
    arr = List[Int](0, 1, 2)

    val = arr[int(entity.id)]
    _ = val


def test_zero_entity():
    assert_true(Entity().is_zero())
    assert_false(Entity(1, 0).is_zero())


fn benchmark_entity_is_zero():
    e = Entity()

    is_zero = False

    var n: Int = 1000000

    for _ in range(n):
        is_zero = e.is_zero()

    if now() == 0:
        print(is_zero)


def test_entity_index():
    alias AType = Archetype[UInt8]
    arr = InlineArray[AType, 3](AType(5), AType(10), AType(20))
    index1 = EntityIndex(1, arr[1])
    index1b = EntityIndex(1, arr[1])
    index2 = EntityIndex(10, arr[2])
    assert_equal(index1.index, 1)
    assert_equal(index2.index, 10)
    assert_equal(index1.archetype[]._capacity, 10)
    assert_equal(index2.archetype[]._capacity, 20)
    index1b.archetype[] = AType(1)
    assert_equal(index1.archetype[]._capacity, 1)
    assert_equal(index1b.archetype[]._capacity, 1)


# TODO
# fn example_entity():
#     world = new_world()

#     pos_id = component_id[Position](&world)
#     vel_id = component_id[Velocity](&world)

#     e1 = world.new_entity()
#     e2 = world.new_entity(pos_id, vel_id)

#     fmt.Println(e1.is_zero(), e2.is_zero())
#     # Output: False False

# fn example_entity_is_zero():
#     world = new_world()

#     var e1 Entity
#     var e2 Entity = world.new_entity()

#     fmt.Println(e1.is_zero(), e2.is_zero())
#     # Output: True False


def main():
    print("Running tests...")
    test_entity_as_index()
    test_zero_entity()
    test_entity_index()
    print("All tests passed.")
    # report = benchmark.run[benchmark_entity_is_zero]()
    # report.print()
