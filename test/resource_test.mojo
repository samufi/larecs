from larecs.resource import Resources
from testing import *


@value
struct Resource1:
    var value: Int


@value
struct Resource2:
    var value: Int


def test_resources_initialization():
    resource1 = Resource1(value=10)
    resource2 = Resource2(value=20)
    resources = Resources(resource1, resource2)

    assert_equal(resources._resources[0].value, 10)
    assert_equal(resources._resources[1].value, 20)


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

struct S[*Ts: AnyType]():
    var r: Resources[*_]

    fn __init__(out self, r: Resources[*_]):
        self.r = Resources(1, 2.2)

def main():

    r = Resources(1, 2.1)



    test_resources_initialization()
    test_resources_get()
    test_resources_get_ptr()
