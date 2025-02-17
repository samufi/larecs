from testing import *

from larecs.experimental import Resource, Resources, ResourceId


@value
struct ListResource(Resource):
    alias ID = ResourceId("larecs/test/resources/ListResource")

    var data: List[Int]

    fn __init__(out self, len: Int):
        self.data = List[Int]()
        for i in range(len):
            self.data.append(i)

    fn __del__(owned self):
        self.data.clear()
        print("destroyed ListResource")


@value
struct OtherResource(Resource):
    alias ID = ResourceId("larecs/test/resources/OtherResource")

    var dummy: Int

    fn __del__(owned self):
        print("destroyed OtherResource")


fn test_resources() raises:
    r = Resources()

    print("add")
    r.add(ListResource(100))
    assert_true(r.has[ListResource]())

    r.add(OtherResource(42))

    print("get")
    res = r.get_ptr[ListResource]()
    assert_equal(len(res[].data), 100)
    assert_equal(res[].data[99], 99)

    print("remove")
    r.remove[ListResource]()
    assert_false(r.has[ListResource]())

    print("last access")
    assert_equal(len(r), 2)

    print("end")
    raise Error()
