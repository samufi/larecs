from testing import assert_true
from testing import assert_false
from testing import assert_equal


struct Test:
    var state: Int
    var test_name: String

    fn __init__(inout self, test_name: String):
        self.state = 0
        self.test_name = test_name

    fn assert_equal(inout self, lhs: object, rhs: object, msg: String = "assert_equal") raises:
        if not lhs == rhs:
            raise Error("AssertionError " + self._get_test_message(msg))

    fn assert_true(inout self, this: object, msg: String = "assert_true") raises:
        assert_true(this, self._get_test_message(msg))
    
    fn assert_false(inout self, this: object, msg: String = "assert_false") raises:
        assert_false(this, self._get_test_message(msg))

    fn _get_test_message(inout self, subtest_name: String) -> String:
        self.state += 1
        return self.test_name + ": Failed at test " + str(self.state) + " (" + subtest_name + ")" 
