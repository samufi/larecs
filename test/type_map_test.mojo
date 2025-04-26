from testing import *

from larecs.type_map import (
    TypeId,
    DynamicTypeMap,
    IdentifiableCollectionElement,
)


# Mock struct for testing IdentifiableCollectionElement
@value
struct MockElement(IdentifiableCollectionElement):
    alias id = TypeId("test_package.test_module.MockElement")


def test_type_id_initialization_with_name():
    type_id = TypeId("test_package.test_module.TestType")
    assert_equal(type_id._name, StaticString("test_package.test_module.TestType"))
    assert_equal(type_id._id, StaticString("test_package.test_module.TestType").__hash__())


def test_type_id_initialization_with_id():
    type_id = TypeId(12345)
    assert_equal(type_id._id, 12345)
    assert_equal(type_id._name, "")


def test_type_id_equality():
    type_id1 = TypeId("test_package.test_module.TestType")
    type_id2 = TypeId("test_package.test_module.TestType")
    type_id3 = TypeId(12345)
    assert_equal(type_id1, type_id2)
    assert_not_equal(type_id1, type_id3)


def test_type_id_hash():
    type_id = TypeId("test_package.test_module.TestType")
    assert_equal(
        type_id.__hash__(), StaticString("test_package.test_module.TestType").__hash__()
    )


def test_dynamic_type_map_get_id():
    type_id = DynamicTypeMap.get_id[MockElement]()
    assert_equal(type_id, MockElement.id)


from sys.info import sizeof


def main():
    test_type_id_initialization_with_name()
    test_type_id_initialization_with_id()
    test_type_id_equality()
    test_type_id_hash()
    test_dynamic_type_map_get_id()
    print("All type map tests passed!")
