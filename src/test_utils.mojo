from testing import assert_true, assert_false, assert_equal
from testing.testing import Testable


trait TestableCollectionElement(CollectionElement, Testable):
    pass


fn assert_equal_lists[
    T: TestableCollectionElement
](a: List[T], b: List[T], msg: String = "") raises:
    assert_equal(len(a), len(b), msg)
    for i in range(len(a)):
        assert_equal(a[i], b[i], msg)
