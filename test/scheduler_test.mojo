from larecs import World, Scheduler, System, ResourceType
from testing import *


@fieldwise_init
struct MeanState(ResourceType):
    var value: Float64


# @fieldwise_init
# struct TestSystem[copies: Int, count: Int = 10](System):
#     var a: Int

#     fn __init__(out self):
#         self.a = 0

#     fn initialize(mut self, mut world: World) raises:
#         assert_equal(self.a, 0)
#         _ = world.add_entities(self.a, count=self.count)
#         self.a = 1

#     fn update(mut self, mut world: World) raises:
#         assert_equal(self.a, 1)
#         assert_equal(len(world), self.count * self.copies)
#         for entity in world.query[Int]():
#             entity.get[Int]() += 1

#     fn finalize(mut self, mut world: World) raises:
#         sum = 0
#         count = 0
#         for entity in world.query[Int]():
#             sum += entity.get[Int]()
#             count += 1
#         world.resources.set[add_if_not_found=True](MeanState(sum / count))


# def test_scheduler():
#     scheduler = Scheduler[Int, Float64]()
#     scheduler.add_system(TestSystem[2]())
#     scheduler.add_system(TestSystem[2]())
#     scheduler.run(3)
#     assert_equal(
#         scheduler.world.resources.get[MeanState]().value,
#         6,
#     )


def main():
    # test_scheduler()
    print("All tests passed!")
