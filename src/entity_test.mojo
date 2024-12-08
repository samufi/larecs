from testing import *
from custom_benchmark import Bencher, keep, Bench, BenchId, BenchConfig
from entity import Entity, EntityIndex
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


fn benchmark_entity_is_zero(inout bencher: Bencher) capturing:
    e = Entity()

    @parameter
    fn bench_fn(calls: Int) capturing -> Int:
        for _ in range(calls):
            keep(e.is_zero())
        return calls

    bencher.iter_custom[bench_fn]()


fn run_all_bitmask_benchmarks() raises:
    bench = Bench(BenchConfig(min_runtime_secs=0.1))
    bench.bench_function[benchmark_entity_is_zero](
        BenchId("benchmark_entity_is_zero")
    )
    bench.dump_report()


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
    run_all_bitmask_benchmarks()
    # report = benchmark.run[benchmark_entity_is_zero]()
    # report.print()
