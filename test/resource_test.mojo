from larecs.resource import Resources, ResourceManaging, ResourceType
from testing import *


@value
struct Resource1:
    var value: Int


@value
struct Resource2:
    var value: Int


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

    fn get[T: ResourceType](self) -> T:
        return self.r.get[T]()

def test_resources_usage():
    s = S[UInt32, Float32](Resources(5, 2.2))
    assert_equal(s.get[Int](), 5)


def main():

    r = Resources(1, 2.1)

    test_resources_get()
    test_resources_get_ptr()
    test_resources_usage()

    print("All tests passed!")
