from testing import *
from collections import InlineArray
from larecs.entity import Entity, EntityIndex
from larecs.archetype import Archetype
from larecs.test_utils import SmallWorld, Position


def test_entity_as_index():
    entity = Entity(1, 0)
    arr = List[Int](0, 1, 2)

    val = arr[entity.get_id()]
    _ = val


def test_zero_entity():
    assert_true(Entity().is_zero())
    assert_false(Entity(1, 0).is_zero())


def test_implicit_constructor():
    world = SmallWorld()
    entity = world.add_entity(Position(1, 0))
    storage = List[Entity]()
    for e in world.query[Position]():
        storage.append(e)

    assert_equal(storage[0], entity)


# TODO
# fn example_entity():
#     world = new_world()

#     pos_id = component_id[Position](&world)
#     vel_id = component_id[Velocity](&world)

#     e1 = world.add_entity()
#     e2 = world.add_entity(pos_id, vel_id)

#     fmt.Println(e1.is_zero(), e2.is_zero())
#     # Output: False False

# fn example_entity_is_zero():
#     world = new_world()

#     var e1 Entity
#     var e2 Entity = world.add_entity()

#     fmt.Println(e1.is_zero(), e2.is_zero())
#     # Output: True False


def main():
    print("Running tests...")
    test_entity_as_index()
    test_zero_entity()
    test_implicit_constructor()
    print("All tests passed.")
    # report = benchmark.run[benchmark_entity_is_zero]()
    # report.print()
