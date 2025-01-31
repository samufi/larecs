from testing import *
from sys.info import sizeof
from collections import InlineList
from larecs.component import *


struct DummyComponentType(EqualityComparable, Stringable):
    var x: Int32

    @staticmethod
    @always_inline
    fn get_type_identifier() -> Int:
        return 12345

    fn __init__(mut self, x: Int32):
        self.x = x

    fn __eq__(self, other: Self) -> Bool:
        return self.x == other.x

    fn __ne__(self, other: Self) -> Bool:
        return self.x != other.x

    fn __str__(self) -> String:
        return "DummyComponentType(x: " + String(self.x) + ")"

    fn __copyinit__(mut self, existing: Self):
        self.x = existing.x

    fn __moveinit__(mut self, owned existing: Self):
        self.x = existing.x

    fn __del__(owned self):
        pass


@value
struct FlexibleDummyComponentType[type_hash: Int = 12345](
    EqualityComparable, Stringable
):
    var x: Int32

    fn __eq__(self, other: Self) -> Bool:
        return self.x == other.x

    fn __ne__(self, other: Self) -> Bool:
        return self.x != other.x

    fn __str__(self) -> String:
        return "FlexibleDummyComponentType(x: " + String(self.x) + ")"


def main():
    print("All tests passed.")
