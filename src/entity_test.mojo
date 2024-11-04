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
    print("All tests passed.")
    # report = benchmark.run[benchmark_entity_is_zero]()
    # report.print()
