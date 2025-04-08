from os import os
from python import Python, PythonObject
from time import perf_counter_ns

import larecs as lx

alias RESULTS_DIR = "results"
"""Output directory for benchmark results."""

alias FILE_NAME = "aos_benchmark"
"""Base name of benchmark output file."""

alias TARGET_ITERATIONS = 10**9
"""Target number of total entity iterations for each benchmark."""


@value
struct BenchResult:
    var components: Int
    var entities: Int
    var nanos_ecs: Float64
    var nanos_aos: Float64


@value
struct BenchConfig[max_comp_exp: Int]:
    var max_entity_exp: Int
    var target_iters: Int


def plot(config: BenchConfig, results: List[BenchResult]):
    plt = Python.import_module("matplotlib.pyplot")

    var component_ticks: PythonObject = [2, 4, 8, 16, 32]

    csv_file = os.path.join(RESULTS_DIR, FILE_NAME + ".csv")

    df = to_dataframe(results)
    df.to_csv(csv_file, index=False)

    fig_and_ax = plt.subplots(ncols=2, figsize=(10, 4))
    fig = fig_and_ax[0]
    ax = fig_and_ax[1]

    ax1 = ax[0]
    ax2 = ax[1]

    var handles: PythonObject = []
    var labels: PythonObject = []
    for comp_exp in range(1, config.max_comp_exp + 1):
        comp = 2**comp_exp
        var entities: PythonObject = []
        var nanos_ecs: PythonObject = []
        var nanos_aos: PythonObject = []
        for row in results:
            if row[].components == comp:
                entities.append(row[].entities)
                nanos_ecs.append(row[].nanos_ecs)
                nanos_aos.append(row[].nanos_aos)

        lw = 0.5 + comp_exp / 4
        ax1.plot(
            entities,
            nanos_ecs,
            "-",
            c="k",
            lw=lw,
        )
        ax1.plot(
            entities,
            nanos_aos,
            "--",
            c="b",
            lw=lw,
        )
        if comp_exp == 1:
            labels.append("Larecs")
            handles.append(plt.Line2D([0], [0], color="k", lw=1, linestyle="-"))
            labels.append("Array of Structs")
            handles.append(
                plt.Line2D([0], [0], color="b", lw=1, linestyle="--")
            )
        labels.append(String("{0} components").format(String(comp)))
        handles.append(plt.Line2D([0], [0], color="k", lw=lw, linestyle="-"))

    ax1.set_xscale("log")
    ax1.set_xlabel("Entities")
    ax1.set_ylabel("Time per entity [ns]")
    ax1.legend(
        loc="upper left",
        fontsize="small",
        handles=handles,
        labels=labels,
    )

    handles = []
    labels = []
    for entity_exp in range(2, config.max_entity_exp + 1):
        num_entities = 10**entity_exp
        var components: PythonObject = []
        var nanos_ecs: PythonObject = []
        var nanos_aos: PythonObject = []
        for row in results:
            if row[].entities == num_entities:
                components.append(row[].components)
                nanos_ecs.append(row[].nanos_ecs)
                nanos_aos.append(row[].nanos_aos)

        lw = 0.5 + entity_exp / 4
        ax2.plot(
            components,
            nanos_ecs,
            "-",
            c="k",
            lw=lw,
        )
        ax2.plot(
            components,
            nanos_aos,
            "--",
            c="b",
            lw=lw,
        )
        if entity_exp == 2:
            labels.append("Larecs")
            handles.append(plt.Line2D([0], [0], color="k", lw=1, linestyle="-"))
            labels.append("Array of Structs")
            handles.append(
                plt.Line2D([0], [0], color="b", lw=1, linestyle="--")
            )
        labels.append(String("10^{0} entities").format(String(entity_exp)))
        handles.append(plt.Line2D([0], [0], color="k", lw=lw, linestyle="-"))

    ax2.set_xscale("log")
    ax2.set_xlabel("Components")
    ax2.set_ylabel("Time per entity [ns]")
    ax2.set_xticks(component_ticks)
    ax2.set_xticklabels(component_ticks)
    ax2.legend(
        loc="upper left",
        fontsize="small",
        handles=handles,
        labels=labels,
    )

    fig.tight_layout()
    fig.savefig(os.path.join(RESULTS_DIR, FILE_NAME + ".svg"))
    fig.savefig(os.path.join(RESULTS_DIR, FILE_NAME + ".png"))


def to_dataframe(results: List[BenchResult]) -> PythonObject:
    pd = Python.import_module("pandas")
    var entities: PythonObject = []
    var components: PythonObject = []
    var nanos_ecs: PythonObject = []
    var nanos_aos: PythonObject = []
    for result in results:
        entities.append(result[].entities)
        components.append(result[].components)
        nanos_ecs.append(result[].nanos_ecs)
        nanos_aos.append(result[].nanos_aos)

    var data = Python.dict()
    data["entities"] = entities
    data["components"] = components
    data["nanos_ecs"] = nanos_ecs
    data["nanos_aos"] = nanos_aos

    return pd.DataFrame(data)


fn run_benchmarks(config: BenchConfig) raises -> List[BenchResult]:
    results = List[BenchResult]()

    for ent_exp in range(2, config.max_entity_exp + 1):
        entities = 10**ent_exp
        rounds = config.target_iters // entities
        print(entities, "entities")

        @parameter
        for compExp in range(1, config.max_comp_exp + 1):
            result = benchmark[compExp](rounds, entities)
            results.append(result)

    return results


fn benchmark[
    components_exp: Int
](rounds: Int, entities: Int) raises -> BenchResult:
    w1 = create_ecs_world[components_exp](entities)
    var start_ecs: Float64 = perf_counter_ns()
    for _ in range(rounds):
        for entity in w1.query[Position, Velocity]():
            position = entity.get_ptr[Position]()
            velocity = entity.get[Velocity]()
            position[].x += velocity.x
            position[].y += velocity.y
    dur_ecs = (perf_counter_ns() - start_ecs) / (entities * rounds)

    w2 = AosWorld[components_exp](entities)
    var start_aos: Float64 = perf_counter_ns()
    for _ in range(rounds):
        w2.update()
    dur_aos = (perf_counter_ns() - start_aos) / (entities * rounds)

    return BenchResult(
        entities=entities,
        components=2**components_exp,
        nanos_ecs=dur_ecs,
        nanos_aos=dur_aos,
    )


fn create_ecs_world[components_exp: Int](entities: Int, out w: World) raises:
    w = World()
    for _ in range(entities):
        _ = create_ecs_entity[components_exp](w)


fn create_ecs_entity[
    components_exp: Int
](mut w: World, out e: lx.Entity) raises:
    e = w.add_entity(Position(1, 2), Velocity(1, 2))

    @parameter
    for i in range(2**components_exp):
        w.add(e, PayloadComponent[i](1.0, 2.0))


struct AosWorld[components_exp: Int]:
    var entities: List[AosEntity[components_exp]]

    fn __init__(out self, entities: Int):
        self.entities = List[AosEntity[components_exp]]()
        for _ in range(entities):
            self.entities.append(AosEntity[components_exp]())

    @always_inline
    fn update(mut self):
        for entity in self.entities:
            entity[].update()


@value
struct AosEntity[components_exp: Int]:
    var comps: InlineArray[Position, 2**components_exp]

    fn __init__(out self):
        self.comps = InlineArray[Position, 2**components_exp](
            Position(1.0, 2.0)
        )

    @always_inline
    fn update(mut self):
        self.comps[0].x += self.comps[1].x
        self.comps[0].y += self.comps[1].y


@value
struct Position(lx.ComponentType):
    var x: Float64
    var y: Float64


@value
struct Velocity(lx.ComponentType):
    var x: Float64
    var y: Float64


@value
struct PayloadComponent[i: UInt](lx.ComponentType):
    var x: Float64
    var y: Float64


alias World = lx.World[
    Position,
    Velocity,
    PayloadComponent[0],
    PayloadComponent[1],
    PayloadComponent[2],
    PayloadComponent[3],
    PayloadComponent[4],
    PayloadComponent[5],
    PayloadComponent[6],
    PayloadComponent[7],
    PayloadComponent[8],
    PayloadComponent[9],
    PayloadComponent[10],
    PayloadComponent[11],
    PayloadComponent[12],
    PayloadComponent[13],
    PayloadComponent[14],
    PayloadComponent[15],
    PayloadComponent[16],
    PayloadComponent[17],
    PayloadComponent[18],
    PayloadComponent[19],
    PayloadComponent[20],
    PayloadComponent[21],
    PayloadComponent[22],
    PayloadComponent[23],
    PayloadComponent[24],
    PayloadComponent[25],
    PayloadComponent[26],
    PayloadComponent[27],
    PayloadComponent[28],
    PayloadComponent[29],
    PayloadComponent[30],
    PayloadComponent[31],
]


fn main() raises:
    config = BenchConfig[max_comp_exp=5](
        max_entity_exp=6, target_iters=TARGET_ITERATIONS
    )

    results = run_benchmarks(config)

    if not os.path.exists(RESULTS_DIR):
        os.mkdir(RESULTS_DIR)

    plot(config, results)
