from testing import *
from larecs.test_utils import *
from larecs import Entity, Query
from larecs.archetype import Archetype as _Archetype
from larecs.component import ComponentManager
from larecs.query import _ArchetypeIterator


def test_query_length():
    world = SmallWorld()

    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)
    c3 = FlexibleComponent[3](7.0, 8.0)

    n = 50

    for _ in range(n):
        _ = world.add_entity(c0, c1, c2)
        _ = world.add_entity(c0, c1, c3)
        _ = world.add_entity(c0, c2, c3)
        _ = world.add_entity(c1, c2, c3)
        _ = world.add_entity(c0, c1, c2, c3)

    assert_equal(len(world.query[FlexibleComponent[0]]()), 4 * n)
    assert_equal(len(world.query[FlexibleComponent[1]]()), 4 * n)
    assert_equal(len(world.query[FlexibleComponent[2]]()), 4 * n)
    assert_equal(len(world.query[FlexibleComponent[3]]()), 4 * n)

    assert_equal(
        len(world.query[FlexibleComponent[0], FlexibleComponent[1]]()),
        3 * n,
    )
    assert_equal(
        len(world.query[FlexibleComponent[0], FlexibleComponent[2]]()),
        3 * n,
    )
    assert_equal(
        len(world.query[FlexibleComponent[0], FlexibleComponent[3]]()),
        3 * n,
    )
    assert_equal(
        len(world.query[FlexibleComponent[1], FlexibleComponent[2]]()),
        3 * n,
    )
    assert_equal(
        len(world.query[FlexibleComponent[1], FlexibleComponent[3]]()),
        3 * n,
    )
    assert_equal(
        len(world.query[FlexibleComponent[2], FlexibleComponent[3]]()),
        3 * n,
    )

    assert_equal(
        len(
            world.query[
                FlexibleComponent[0], FlexibleComponent[1], FlexibleComponent[2]
            ]()
        ),
        2 * n,
    )
    assert_equal(
        len(
            world.query[
                FlexibleComponent[0], FlexibleComponent[1], FlexibleComponent[3]
            ]()
        ),
        2 * n,
    )
    assert_equal(
        len(
            world.query[
                FlexibleComponent[0], FlexibleComponent[2], FlexibleComponent[3]
            ]()
        ),
        2 * n,
    )
    assert_equal(
        len(
            world.query[
                FlexibleComponent[1], FlexibleComponent[2], FlexibleComponent[3]
            ]()
        ),
        2 * n,
    )

    assert_equal(
        len(
            world.query[
                FlexibleComponent[0],
                FlexibleComponent[1],
                FlexibleComponent[2],
                FlexibleComponent[3],
            ]()
        ),
        n,
    )
    assert_equal(len(world.query()), 5 * n)

    iterator = world.query[FlexibleComponent[0]]()
    iter = iterator.__iter__()
    size = len(iter)
    while iter.__has_next__():
        _ = iter.__next__()
        size -= 1
        assert_equal(size, len(iter))


def test_query_result_ids():
    world = SmallWorld()

    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 50

    entities = List[Entity]()

    for i in range(n):
        entities.append(world.add_entity(FlexibleComponent[0](1.0, i), c1, c2))
    for i in range(n, 2 * n):
        entities.append(world.add_entity(FlexibleComponent[0](1.0, i), c2))

    i = 0
    for entity in world.query[FlexibleComponent[0]]():
        entity.set(FlexibleComponent[0](1.0, i))
        assert_equal(
            entity.get[FlexibleComponent[0]]().y,
            world.get[FlexibleComponent[0]](entities[i]).y,
            "Entity " + String(i) + " is incorrect.",
        )
        i += 1


def test_query_get_set():
    world = SmallWorld()

    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 50

    entities = List[Entity]()

    for _ in range(n):
        entities.append(world.add_entity(c0, c1, c2))

    i = 0
    for entity in world.query[FlexibleComponent[0]]():
        entity.get[FlexibleComponent[0]]().y = i
        i += 1

    i = 0
    for entity in world.query[FlexibleComponent[0]]():
        assert_equal(entity.get[FlexibleComponent[0]]().y, i)
        assert_equal(world.get[FlexibleComponent[0]](entities[i]).y, i)
        i += 1


def test_query_component_reference():
    world = SmallWorld()

    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 50

    entities = List[Entity]()

    for _ in range(n):
        entities.append(world.add_entity(c0, c1, c2))

    i = 0
    for entity in world.query[FlexibleComponent[0]]():
        a = entity.get_ptr[FlexibleComponent[0]]()
        a[].y = i
        i += 1

    i = 0
    for entity in world.query[FlexibleComponent[0]]():
        assert_equal(entity.get[FlexibleComponent[0]]().y, i)
        assert_equal(world.get[FlexibleComponent[0]](entities[i]).y, i)
        i += 1


def test_query_has_component():
    world = SmallWorld()

    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 50

    entities = List[Entity]()

    for _ in range(n):
        entities.append(world.add_entity(c0, c1, c2))

    for entity in world.query[FlexibleComponent[0]]():
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_true(entity.has[FlexibleComponent[1]]())
        assert_true(entity.has[FlexibleComponent[2]]())
        assert_false(entity.has[FlexibleComponent[3]]())


fn test_query_empty() raises:
    world = SmallWorld()
    query = world.query[FlexibleComponent[0]]()
    cnt = 0
    for entity in query:
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_true(world.is_locked())
        cnt += 1
    assert_equal(cnt, 0)


def test_query_without():
    world = SmallWorld()
    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    n = 10

    for _ in range(n):
        _ = world.add_entity(c0)
        _ = world.add_entity(c0, c1)
        _ = world.add_entity(c0, c1, c2)
        _ = world.add_entity(c2)

    query = world.query[FlexibleComponent[0]]().without[FlexibleComponent[1]]()
    query2 = world.query[FlexibleComponent[0]]()

    assert_equal(len(query), n)

    count = 0
    for entity in query:
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_false(entity.has[FlexibleComponent[1]]())
        assert_true(world.is_locked())
        count += 1
    assert_equal(count, n)
    assert_false(world.is_locked())

    for entity in query2:
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_true(world.is_locked())

    for _ in range(n):
        _ = world.add_entity(c0, c2)

    count = 0
    for entity in query:
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_false(entity.has[FlexibleComponent[1]]())
        assert_true(world.is_locked())
        count += 1
    assert_equal(count, 2 * n)

    assert_false(world.is_locked())


def test_query_exclusive():
    world = SmallWorld()
    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)

    n = 10

    for _ in range(n):
        _ = world.add_entity(c0)
        _ = world.add_entity(c0, c1)

    query = world.query[FlexibleComponent[0]]().exclusive()
    assert_equal(len(query), n)

    count = 0
    for entity in query:
        assert_true(entity.has[FlexibleComponent[0]]())
        assert_false(entity.has[FlexibleComponent[1]]())
        assert_true(world.is_locked())
        count += 1

    assert_equal(count, n)
    assert_false(world.is_locked())


struct QueryOwner[
    world_origin: MutableOrigin,
    *ComponentTypes: ComponentType,
]:
    alias WorldPointer = Pointer[World[*ComponentTypes], world_origin]
    alias Query = Query[
        world_origin,
        *ComponentTypes,
        has_without_mask=_,
    ]

    var _query: Self.Query[has_without_mask=True]

    fn __init__(
        world: Self.WorldPointer,
        out self,
    ) raises:
        self._query = (
            world[]
            .query[FlexibleComponent[0]]()
            .without[FlexibleComponent[1]]()
        )

    fn update(self) raises:
        for entity in self._query:
            f = entity.get_ptr[FlexibleComponent[0]]()
            f[].x += 1


fn test_query_in_system() raises:
    world = SmallWorld()
    sys1 = QueryOwner(Pointer(to=world))
    sys2 = QueryOwner(Pointer(to=world))

    c0 = FlexibleComponent[0](1.0, 2.0)

    n = 10
    for _ in range(n):
        _ = world.add_entity(c0)

    for _ in range(10):
        sys1.update()
        sys2.update()

    for entity in world.query[FlexibleComponent[0]]():
        f = entity.get_ptr[FlexibleComponent[0]]()
        assert_equal(f[].x, 21)


def test_query_lock():
    world = SmallWorld()

    c0 = FlexibleComponent[0](1.0, 2.0)
    c1 = FlexibleComponent[1](3.0, 4.0)
    c2 = FlexibleComponent[2](5.0, 6.0)

    _ = world.add_entity(c0, c1)
    entity = world.add_entity(c0, c1)

    first = True
    for _ in world.query[FlexibleComponent[0]]():
        if not first:
            break
        assert_true(world.is_locked())
        with assert_raises():
            _ = world.add_entity(c0, c1, c2)
        with assert_raises():
            _ = world.add(entity, c2)
        with assert_raises():
            _ = world.remove[FlexibleComponent[0]](entity)

        for _ in world.query[FlexibleComponent[0]]():
            if not first:
                break
            assert_true(world.is_locked())
            with assert_raises():
                _ = world.add_entity(c0, c1, c2)
            with assert_raises():
                _ = world.add(entity, c2)
            with assert_raises():
                _ = world.remove[FlexibleComponent[0]](entity)

    assert_false(world.is_locked())
    _ = world.add_entity(c0, c1, c2)
    _ = world.add(entity, c2)
    _ = world.remove[FlexibleComponent[1]](entity)

    try:
        for _ in world.query[FlexibleComponent[0]]():
            _ = world.add_entity(c0, c1, c2)
    except:
        assert_false(world.is_locked())
        _ = world.add_entity(c0, c1, c2)


def test_query_archetype_iterator():
    alias Archetype = _Archetype[
        FlexibleComponent[0],
        component_manager = ComponentManager[FlexibleComponent[0]](),
    ]

    a = Archetype(0, BitMask(0))
    _ = a.add(Entity(0, 0))
    l = List[Archetype](a, a, a)
    var count = 0

    for _ in _ArchetypeIterator[
        __origin_of(l),
        FlexibleComponent[0],
        component_manager = ComponentManager[FlexibleComponent[0]](),
    ](Pointer(to=l), BitMask(0)):
        count += 1

    assert_equal(count, 3)


def run_all_query_tests():
    test_query_lock()
    test_query_component_reference()
    test_query_result_ids()
    test_query_length()
    test_query_get_set()
    test_query_has_component()
    test_query_empty()
    test_query_without()
    test_query_archetype_iterator()


def main():
    print("Running tests...")
    run_all_query_tests()
    print("All tests passed.")
