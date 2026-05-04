from std.benchmark import (
    keep,
    BenchId,
    BenchConfig as BenchConfig_,
    Bench as Bench_,
)
from std.time import perf_counter_ns
from std.collections import Dict


def DefaultConfig() raises -> BenchConfig_:
    """Returns the default configuration for benchmarking."""
    config = BenchConfig_(
        min_runtime_secs=2.0, max_runtime_secs=10.0, max_batch_size=50
    )
    config.verbose_timing = True
    return config^


def DefaultBench() raises -> Bench_:
    """Returns the default benchmarking struct."""
    return Bench_(DefaultConfig())


@fieldwise_init
struct Bencher(ImplicitlyCopyable):
    """A helper struct for benchmarking functions.

    It mimics some features of benchmark.Bencher

    Attributes:
        num_iters: The number of iterations to run per call of iter_custom.
        _time_ns: The total time spent in nanoseconds.
        _iters: The total number of iterations conducted.
    """

    var num_iters: Int
    var _time_ns: UInt
    var _iters: Int

    def __init__(out self, num_iters: Int):
        """Initializes the Bencher with the given number of iterations.

        Args:
            num_iters: The number of iterations to run per call of iter_custom.
        """

        self.num_iters = num_iters
        self._time_ns = 0
        self._iters = 0

    def iter_custom[iter_fn: def(Int) capturing -> Int](mut self: Self):
        """Times the execution of the given function.

        Parameters:
            iter_fn: The function to be benchmarked. It takes an Int representing
                     how many iterations to run per call and returns an Int
                     representing how many runs were actually conducted.
        """

        start = perf_counter_ns()
        self._iters += iter_fn(self.num_iters)
        time_passed = perf_counter_ns() - start
        self._time_ns += time_passed

    def reset_time(mut self: Self):
        """Resets the time and iteration counters."""
        self._time_ns = 0
        self._iters = 0


@fieldwise_init
struct BenchConfig(ImplicitlyCopyable):
    """A configuration struct for benchmarking.

    It mimics some features of benchmark.BenchConfig
    """

    var warmup_iters: Int
    var max_iters: Int
    var num_repetitions: Int
    var min_iter_runtime_ns: UInt
    var initial_batch_size: Int
    var max_runtime_secs: Float64
    var min_runtime_secs: Float64
    var show_progress: Bool

    def __init__(
        out self,
        *,
        warmup_iters: Int = 3,
        min_iter_runtime_ns: UInt = 100000,
        max_iters: Int = 10_000_000_000,
        max_runtime_secs: Float64 = 10.0,
        min_runtime_secs: Float64 = 0.5,
        num_repetitions: Int = 1,
        initial_batch_size: Int = 1,
        show_progress: Bool = False,
    ):
        """Initializes the BenchConfig with the given parameters.

        Args:
            warmup_iters:
                The number of warmup iterations to run.
            min_iter_runtime_ns:
                The minimum runtime in nanoseconds for each iteration.
                This number should be not too small, as measuring
                time in very small intervals can be inaccurate.
            max_iters:
                The maximum number of iterations to run.
            max_runtime_secs:
                The maximum runtime in seconds.
            min_runtime_secs:
                The minimal runtime in seconds. The benchmark will run
                at least until it reaches this time unless it reaches max_iters.
            num_repetitions:
                The number of repetitions to run. The benchmark will run
                at least until it reaches this number unless it reaches max_iters.
            initial_batch_size:
                The initial batch size of a benchmark. The batch size will be
                adjusted based on the runtime of the benchmark, but starting
                with a larger batch size can help to reduce the overhead of
                the benchmarking framework.
            show_progress:
                Whether to print progress messages.
        """
        self.warmup_iters = warmup_iters
        self.min_iter_runtime_ns = min_iter_runtime_ns
        self.max_iters = max_iters
        self.max_runtime_secs = max_runtime_secs
        self.num_repetitions = num_repetitions
        self.min_runtime_secs = min_runtime_secs
        self.initial_batch_size = initial_batch_size
        self.show_progress = show_progress


def copy_bench_id(input_id: BenchId) -> BenchId:
    """Creates a copy of the given BenchId.

    Args:
        input_id: The BenchId to be copied.

    Returns:
        A copy of the given BenchId.
    """
    if input_id.input_id is None:
        return BenchId(input_id.func_name)
    else:
        return BenchId(input_id.func_name, input_id.input_id)


struct BenchResult(ImplicitlyCopyable):
    """A struct combining a BenchId and a Bencher, representing the result of a benchmark.
    """

    var bench_id: BenchId
    var bencher: Bencher

    def __init__(out self, bench_id: BenchId, bencher: Bencher):
        """Initializes the BenchResult with the given parameters.

        Args:
            bench_id: The identifier for the benchmark.
            bencher: The Bencher containing the results of the benchmark.
        """
        self.bench_id = copy_bench_id(bench_id)
        self.bencher = bencher

    def __init__(out self, *, deinit take: Self):
        """Initializes the BenchResult with the given parameters.

        Args:
            take: The BenchResult to take from.
        """
        self.bench_id = copy_bench_id(take.bench_id)
        self.bencher = take.bencher^

    def __init__(out self, *, copy: Self):
        """Initializes the BenchResult with the given parameters.

        Args:
            copy: The BenchResult to copy from.
        """
        if copy.bench_id.input_id is None:
            self.bench_id = BenchId(copy.bench_id.func_name)
        else:
            self.bench_id = BenchId(
                copy.bench_id.func_name, copy.bench_id.input_id
            )
        self.bencher = copy.bencher.copy()


struct Bench:
    """A benchmarking struct mimicing the features of benchmark.Bench."""

    var config: BenchConfig
    var _results: List[BenchResult]

    def __init__(out self, config: BenchConfig):
        """Initializes the Bench with the given configuration.

        Args:
            config: The configuration for the benchmarking.
        """
        self.config = config
        self._results = List[BenchResult]()

    def _bench_function_once[
        bench_fn: def(mut Bencher) capturing -> None
    ](mut self, mut bencher: Bencher):
        """Benchmarks the given function once and adjusts the batch size if required.

        Parameters:
            bench_fn: The function to be benchmarked.

        Args:
            bencher: The Bencher to be used for benchmarking.
        """
        bench_fn(bencher)
        time_passed = bencher._time_ns
        if time_passed < self.config.min_iter_runtime_ns:
            if time_passed == 0:
                bencher.num_iters *= 2
            else:
                bencher.num_iters = (
                    bencher.num_iters
                    * Int(self.config.min_iter_runtime_ns / time_passed)
                    + 1
                )
            bencher.reset_time()
            return self._bench_function_once[bench_fn](bencher)

    def bench_function[
        bench_fn: def(mut Bencher) capturing -> None
    ](mut self, bench_id: BenchId):
        """Benchmarks the given function.

        Parameters:
            bench_fn: The function to be benchmarked.

        Args:
            bench_id: The identifier for the benchmark.
        """
        if self.config.show_progress:
            print("Benchmarking", bench_id.func_name)

        bencher = Bencher(self.config.initial_batch_size)

        while bencher._iters < self.config.warmup_iters:
            self._bench_function_once[bench_fn](bencher)

        bencher.reset_time()

        while (
            bencher._iters < self.config.max_iters
            and Float64(bencher._time_ns) * 1e-9 < self.config.max_runtime_secs
            and (
                bencher._iters < self.config.num_repetitions
                or Float64(bencher._time_ns) * 1e-9
                < self.config.min_runtime_secs
            )
        ):
            self._bench_function_once[bench_fn](bencher)

        self._results.append({bench_id, bencher})

    def dump_report(mut self):
        """Prints the results of the benchmarking."""

        for result in self._results:
            mean_time = result.bencher._time_ns / UInt(result.bencher._iters)
            print(
                result.bench_id.func_name + ":",
                mean_time,
                "ns per iteration (" + String(result.bencher._iters),
                "iterations in",
                result.bencher._time_ns * 1e-9,
                "seconds)",
            )
