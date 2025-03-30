from larecs.resource import Resources
from larecs.type_map import StaticTypeMap, TypeMapping, TypeId

from testing import *


@value
struct Resource1:
    alias id = TypeId(1)
    var value: Int


@value
struct Resource2:
    alias id = TypeId(2)
    var value: Int


@value
struct Resource3:
    alias id = TypeId(3)
    var value: Int


def test_reseource_init_static():
    resources = Resources(StaticTypeMap[Resource1, Resource2, Resource3]())
    with assert_raises():
        _ = resources.get[Resource1]()
        _ = resources.get[Resource2]()
        _ = resources.get[Resource3]()

    resources.add(Resource1(2), Resource2(4))
    assert_equal(resources.get[Resource1]().value, 2)
    assert_equal(resources.get[Resource2]().value, 4)
    with assert_raises():
        _ = resources.get[Resource3]()

    resources.set[add_if_not_found=True](
        Resource1(2), Resource2(4), Resource3(6)
    )
    assert_equal(resources.get[Resource1]().value, 2)
    assert_equal(resources.get[Resource2]().value, 4)
    assert_equal(resources.get[Resource3]().value, 6)


def test_reseource_init():
    resources = Resources()
    with assert_raises():
        _ = resources.get[Resource1]()
        _ = resources.get[Resource2]()
        _ = resources.get[Resource3]()

    resources.add(Resource1(2), Resource2(4))
    assert_equal(resources.get[Resource1]().value, 2)
    assert_equal(resources.get[Resource2]().value, 4)
    with assert_raises():
        _ = resources.get[Resource3]()

    resources.set[add_if_not_found=True](
        Resource1(2), Resource2(4), Resource3(6)
    )
    assert_equal(resources.get[Resource1]().value, 2)
    assert_equal(resources.get[Resource2]().value, 4)
    assert_equal(resources.get[Resource3]().value, 6)


def test_resources_add_set_static():
    resources = Resources[StaticTypeMap[Resource1, Resource2, Resource3]]()

    with assert_raises():
        resources.set(Resource1(10))

    resources.add(Resource1(30))

    with assert_raises():
        resources.add(Resource1(30))

    with assert_raises():
        resources.set[add_if_not_found=False](Resource2(40))

    resources.set[add_if_not_found=True](Resource2(40))

    assert_equal(resources.get[Resource1]().value, 30)
    assert_equal(resources.get[Resource2]().value, 40)

    resources.set(Resource1(50), Resource2(60))

    assert_equal(resources.get[Resource1]().value, 50)
    assert_equal(resources.get[Resource2]().value, 60)


def test_resources_add_set():
    resources = Resources()

    with assert_raises():
        resources.set(Resource1(10))

    resources.add(Resource1(30))

    with assert_raises():
        resources.add(Resource1(30))

    with assert_raises():
        resources.set[add_if_not_found=False](Resource2(40))

    resources.set[add_if_not_found=True](Resource2(40))

    assert_equal(resources.get[Resource1]().value, 30)
    assert_equal(resources.get[Resource2]().value, 40)

    resources.set(Resource1(50), Resource2(60))

    assert_equal(resources.get[Resource1]().value, 50)
    assert_equal(resources.get[Resource2]().value, 60)


def test_reseource_has():
    resources = Resources()

    assert_false(resources.has[Resource1]())
    assert_false(resources.has[Resource2]())

    resources.add[Resource1](Resource1(30))
    assert_true(resources.has[Resource1]())

    resources.add[Resource2](Resource2(40))
    assert_true(resources.has[Resource2]())


def test_reseource_has_static():
    resources = Resources(StaticTypeMap[Resource1, Resource2, Resource3]())

    assert_false(resources.has[Resource1]())
    assert_false(resources.has[Resource2]())

    resources.add[Resource1](Resource1(30))
    assert_true(resources.has[Resource1]())

    resources.add[Resource2](Resource2(40))
    assert_true(resources.has[Resource2]())


def test_resources_get_static():
    resources = Resources(StaticTypeMap[Resource1, Resource2, Resource3]())
    resources.add(Resource1(value=10), Resource2(value=20))

    assert_equal(resources.get[Resource1]().value, 10)
    assert_equal(resources.get[Resource2]().value, 20)

    resources.get[Resource1]() = Resource1(30)
    resources.get[Resource2]().value = 40

    assert_equal(resources.get[Resource1]().value, 30)
    assert_equal(resources.get[Resource2]().value, 40)


def test_resources_get():
    resources = Resources()
    resources.add(Resource1(value=10), Resource2(value=20))

    assert_equal(resources.get[Resource1]().value, 10)
    assert_equal(resources.get[Resource2]().value, 20)

    resources.get[Resource1]() = Resource1(30)
    resources.get[Resource2]().value = 40

    assert_equal(resources.get[Resource1]().value, 30)
    assert_equal(resources.get[Resource2]().value, 40)


def test_resource_remove_static():
    resources = Resources(StaticTypeMap[Resource1, Resource2, Resource3]())
    resources.add(Resource1(10), Resource2(20))
    resources.remove[Resource1]()
    with assert_raises():
        _ = resources.get[Resource1]()

    resources.remove[Resource2]()
    with assert_raises():
        _ = resources.get[Resource2]()

    resources.add[Resource1](Resource1(30))
    resources.add[Resource2](Resource2(40))

    resources.remove[Resource1]()
    assert_false(resources.has[Resource1]())

    resources.remove[Resource2]()
    assert_false(resources.has[Resource2]())


def test_resource_remove():
    resources = Resources()
    resources.add(Resource1(10), Resource2(20))
    resources.remove[Resource1]()
    with assert_raises():
        _ = resources.get[Resource1]()

    resources.remove[Resource2]()
    with assert_raises():
        _ = resources.get[Resource2]()

    resources.add[Resource1](Resource1(30))
    resources.add[Resource2](Resource2(40))

    resources.remove[Resource1]()
    assert_false(resources.has[Resource1]())

    resources.remove[Resource2]()
    assert_false(resources.has[Resource2]())


def test_resources_get_ptr_static():
    resources = Resources(StaticTypeMap[Resource1, Resource2, Resource3]())
    resources.add(Resource1(10), Resource2(20))

    ptr = resources.get_ptr[Resource1]()
    assert_equal(ptr[].value, 10)

    ptr[].value = 30
    assert_equal(resources.get[Resource1]().value, 30)


def test_resources_get_ptr():
    resources = Resources()
    resources.add(Resource1(10), Resource2(20))

    ptr = resources.get_ptr[Resource1]()
    assert_equal(ptr[].value, 10)

    ptr[].value = 30
    assert_equal(resources.get[Resource1]().value, 30)


def main():
    test_reseource_init()
    test_reseource_init_static()
    test_reseource_has()
    test_reseource_has_static()
    test_resources_add_set()
    test_resources_add_set_static()
    test_resource_remove()
    test_resource_remove_static()
    test_resources_get()
    test_resources_get_static()
    test_resources_get_ptr()
    test_resources_get_ptr_static()
    print("All tests passed!")
