from .component import ComponentType
from .resource import Resources
from .type_map import DynamicTypeMap
from .world import World


struct Manager[*ComponentTypes: ComponentType]:
    alias system = System[*ComponentTypes]()
    alias World = Self.system.World
    alias Data = Self.system.Data
    alias FunctionType = fn (mut w: Self.World, mut data: Self.Data) raises

    var _systems: List[Tuple[Self.FunctionType, Self.Data]]

    fn __init__(out self, world: Self.World):
        self._systems = List[Tuple[Self.FunctionType, Self.Data]]()

    fn add_system(
        mut self,
        func: fn (mut w: Self.World, mut data: Self.Data) raises,
    ):
        self._systems.append(Tuple(func, Self.Data()))

    fn run_systems(mut self, mut world: Self.World) raises:
        for system_and_data in self._systems:
            system_and_data[][0](world, system_and_data[][1])


@value
struct System[*ComponentTypes: ComponentType]:
    alias World = World[*ComponentTypes]
    alias Data = Resources[DynamicTypeMap]
