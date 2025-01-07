from testing import *
from component import *
from sys.info import sizeof
from collections import InlineList


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
        return "DummyComponentType(x: " + str(self.x) + ")"

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
        return "FlexibleDummyComponentType(x: " + str(self.x) + ")"


def test_component_info_initialization():
    info = ComponentInfo.new[DummyComponentType](1)
    assert_equal(info.id, 1)
    assert_equal(info.size, 4)


def test_component_initialization():
    test_value = DummyComponentType(123)
    component = ComponentReference(1, test_value)
    assert_equal(component._id, 1)
    assert_not_equal(component._data, UnsafePointer[UInt8]())


def test_component_value_getting():
    dummy_value = DummyComponentType(456)
    component = ComponentReference(1, dummy_value)
    assert_equal(component.unsafe_get_value[DummyComponentType](), dummy_value)


def test_referencing():
    dummy_value = DummyComponentType(123)
    ptr_1 = UnsafePointer.address_of(dummy_value)
    component = ComponentReference(1, dummy_value)
    ptr_2 = component.get_unsafe_ptr()
    assert_equal(int(ptr_1), int(ptr_2))


def test_origin():
    dummy_value = DummyComponentType(456)
    component = ComponentReference(1, dummy_value)
    _ = component.get_unsafe_ptr()


def test_component_reference_copy():
    original = DummyComponentType(789)
    component = ComponentReference(1, original)
    copied_component = component
    assert_equal(copied_component._id, component._id)
    assert_equal(copied_component._data, component._data)


def test_component_reference_move():
    original = DummyComponentType(789)
    component = ComponentReference(1, original)
    moved_component = component^
    assert_equal(moved_component._id, 1)
    assert_not_equal(moved_component._data, UnsafePointer[UInt8]())


def test_component_manager_get_info():
    manager = ComponentManager[DummyComponentType]()
    info = manager.get_info[DummyComponentType]()
    assert_equal(info.id, 0)
    assert_equal(info.size, sizeof[DummyComponentType]())


def test_component_manager_get_ref():
    manager = ComponentManager[
        DummyComponentType, FlexibleDummyComponentType[1]
    ]()
    component_ref = manager.get_ref(DummyComponentType(123))
    assert_equal(component_ref._id, 0)
    assert_not_equal(component_ref._data, UnsafePointer[UInt8]())
    component_ref2 = manager.get_ref(FlexibleDummyComponentType[1](123))
    assert_equal(component_ref2._id, 1)


def test_component_manager_get_info_arr():
    manager = ComponentManager[
        DummyComponentType, FlexibleDummyComponentType[1]
    ]()
    info_arr = manager.get_info_arr[
        DummyComponentType, FlexibleDummyComponentType[1]
    ]()
    assert_equal(info_arr[0].id, 0)
    assert_equal(info_arr[1].id, 1)
    assert_equal(info_arr[0].size, sizeof[DummyComponentType]())
    assert_equal(info_arr[1].size, sizeof[FlexibleDummyComponentType[1]]())


def main():
    test_component_info_initialization()
    test_component_initialization()
    test_component_value_getting()
    test_referencing()
    test_origin()
    test_component_reference_copy()
    test_component_reference_move()
    test_component_manager_get_info()
    test_component_manager_get_ref()
    test_component_manager_get_info_arr()

    print("All tests passed.")
