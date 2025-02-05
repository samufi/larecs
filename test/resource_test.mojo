from larecs.resource import Resources, ResourceManaging, ResourceType
from testing import *


@value
struct Resource1:
    var value: Int


@value
struct Resource2:
    var value: Int


@value
struct Resource3:
    var value: Int


def test_reseource_init():
    resources = Resources[Resource1, Resource2, Resource3]()
    with assert_raises():
        _ = resources.get[Resource1]()
        _ = resources.get[Resource2]()
        _ = resources.get[Resource3]()

    resources = Resources[Resource1, Resource2, Resource3](
        Resource1(2), Resource2(4)
    )
    assert_equal(resources.get[Resource1]().value, 2)
    assert_equal(resources.get[Resource2]().value, 4)
    with assert_raises():
        _ = resources.get[Resource3]()

    resources = Resources[Resource1, Resource2, Resource3](
        Resource1(2), Resource2(4), Resource3(6)
    )
    assert_equal(resources.get[Resource1]().value, 2)
    assert_equal(resources.get[Resource2]().value, 4)
    assert_equal(resources.get[Resource3]().value, 6)


def test_resources_add_set():
    resources = Resources[Resource1, Resource2]()

    with assert_raises():
        resources.set[Resource1](Resource1(10))

    resources.add[Resource1](Resource1(30))

    with assert_raises():
        resources.add[Resource1](Resource1(30))

    with assert_raises():
        resources.set[Resource2, add_if_not_found=False](Resource2(40))

    resources.set[Resource2, add_if_not_found=True](Resource2(40))

    assert_equal(resources.get[Resource1]().value, 30)
    assert_equal(resources.get[Resource2]().value, 40)

    resources.set(Resource1(50), Resource2(60))

    assert_equal(resources.get[Resource1]().value, 50)
    assert_equal(resources.get[Resource2]().value, 60)


def test_reseource_has():
    resources = Resources[Resource1, Resource2]()
    assert_false(resources.has[Resource1]())
    assert_false(resources.has[Resource2]())

    resources.add[Resource1](Resource1(30))
    assert_true(resources.has[Resource1]())

    resources.add[Resource2](Resource2(40))
    assert_true(resources.has[Resource2]())


def test_resources_get():
    resource1 = Resource1(value=10)
    resource2 = Resource2(value=20)
    resources = Resources(resource1, resource2)

    assert_equal(resources.get[Resource1]().value, 10)
    assert_equal(resources.get[Resource2]().value, 20)

    resources.get[Resource1]() = Resource1(30)
    resources.get[Resource2]().value = 40

    assert_equal(resources.get[Resource1]().value, 30)
    assert_equal(resources.get[Resource2]().value, 40)


def test_resource_remove():
    resources = Resources(Resource1(10), Resource2(20))
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


def test_resources_get_ptr():
    resource1 = Resource1(value=10)
    resource2 = Resource2(value=20)
    resources = Resources(resource1, resource2)

    ptr = resources.get_ptr[Resource1]()
    assert_equal(ptr[].value, 10)

    ptr[].value = 30
    assert_equal(resources.get[Resource1]().value, 30)


struct S[*Ts: AnyType, R: ResourceManaging]():
    var r: R

    fn __init__(out self, r: R):
        self.r = r

    fn get[T: ResourceType](self) raises -> T:
        return self.r.get[T]()


def test_resources_usage():
    s = S[UInt32, Float32](Resources(5, 2.2))
    assert_equal(s.get[Int](), 5)


def main():
    r = Resources(1, 2.1)
    test_reseource_init()
    test_reseource_has()
    test_resources_add_set()
    test_resource_remove()
    test_resources_get()
    test_resources_get_ptr()
    test_resources_usage()

    print("All tests passed!")
