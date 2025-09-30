from benchmark import (
    keep,
    BenchId,
    BenchConfig as BenchConfig_,
    Bench as Bench_,
    Format,
)
from pathlib import Path
from time import perf_counter_ns
from collections import Dict
from larecs.bitmask import BitMask


fn DefaultConfig() raises -> BenchConfig_:
    """Returns the default configuration for benchmarking."""
    config = BenchConfig_(min_runtime_secs=2, max_batch_size=50)
    config.verbose_timing = True
    return config^


struct ArgTypes:
    alias path = "--path"
    alias format = "--format"


struct FormatStrings:
    alias csv = "csv"
    alias table = "table"
    alias tabular = "tabular"

    @staticmethod
    fn contains(str: StringSlice[StaticConstantOrigin]) -> Bool:
        return (
            str == FormatStrings.csv
            or str == FormatStrings.table
            or str == FormatStrings.tabular
        )


@fieldwise_init
struct Arg(Copyable, Movable):
    var type: StringSlice[StaticConstantOrigin]
    var value: List[StringSlice[StaticConstantOrigin]]

    fn __eq__(self: Self, other: Arg) -> Bool:
        return self.type == other.type

    fn __eq__(self: Self, other: StringSlice[StaticConstantOrigin]) -> Bool:
        return self.type == other


@register_passable("trivial")
struct ParserError(EqualityComparable):
    var type: BitMask.IndexType
    alias unknown_arg = ParserError(0)
    alias format_missing = ParserError(1)
    alias path_missing = ParserError(2)

    fn __init__(out self, type: BitMask.IndexType):
        self.type = type

    fn __eq__(self: Self, other: ParserError) -> Bool:
        return self.type == other.type


@fieldwise_init
struct ParserErrors(ImplicitlyCopyable, Movable):
    var error_mask: BitMask

    fn __init__(out self):
        self.error_mask = BitMask()

    fn has_errors(self: Self) -> Bool:
        return not self.error_mask.is_zero()

    fn has_error(self: Self, error: ParserError) -> Bool:
        return self.error_mask.get(error.type)

    fn add_error(mut self: Self, error: ParserError):
        self.error_mask.set[True](error.type)

    fn clear_error(mut self: Self, error: ParserError):
        self.error_mask.set[False](error.type)

    fn get_errors(self: Self) -> List[ParserError]:
        errors = List[ParserError]()
        for error_bit in self.error_mask.get_indices():
            errors.append(ParserError(error_bit))
        return errors^


struct Parser:
    var args: List[StringSlice[StaticConstantOrigin]]
    var index: Int
    var errors: ParserErrors

    fn __init__(out self, var args: List[StringSlice[StaticConstantOrigin]]):
        self.args = args^
        self.index = 0
        self.errors = ParserErrors()

    fn has_next(self: Self) -> Bool:
        return self.index < len(self.args)

    fn parse_next(mut self: Self) raises -> Arg:
        type = self.args[self.index]
        self.index += 1

        value = List[StringSlice[StaticConstantOrigin]]()
        if type == ArgTypes.path:
            if not self.has_next():
                raise Error("Expected a value after --path")

            value.append(self.args[self.index])
            self.index += 1

            if self.errors.has_error(ParserError.format_missing):
                raise Error(
                    "--path specified without --format. Please provide --format"
                    " first."
                )
            elif self.errors.has_error(ParserError.path_missing):
                self.errors.clear_error(ParserError.path_missing)
            else:
                self.errors.add_error(ParserError.format_missing)

        elif type == ArgTypes.format:
            if not self.has_next():
                raise Error("Expected a value after --format")

            format_str = self.args[self.index]
            if not FormatStrings.contains(format_str):
                raise Error("Unknown format: " + format_str)

            value.append(format_str)
            self.index += 1

            # but this arg should only appear if the --path arg is also given
            if self.errors.has_error(ParserError.format_missing):
                self.errors.clear_error(ParserError.format_missing)
            elif self.errors.has_error(ParserError.path_missing):
                raise Error(
                    "--format specified without --path. Please provide --path"
                    " first."
                )
            else:
                self.errors.add_error(ParserError.path_missing)

        else:
            raise Error("Unknown argument: " + type)

        return Arg(type, value^)

    fn parse_all(mut self: Self) raises -> List[Arg]:
        parsed_args = List[Arg]()
        while self.has_next():
            parsed_args.append(self.parse_next())
        return parsed_args^


fn config_from_args(
    args: VariadicList[StringSlice[StaticConstantOrigin]],
) raises -> BenchConfig_:
    """Parses command line arguments to create a BenchConfig.

    Currently supports:
        --json : Outputs results in JSON format.

    Args:
        args: The command line arguments.

    Returns:
        A BenchConfig with the parsed settings.
    """
    config = DefaultConfig()

    args_list = List[StringSlice[StaticConstantOrigin]](capacity=len(args))
    for arg in args:
        args_list.append(arg)

    parser = Parser(args_list[1:])
    parsed_args = parser.parse_all()

    if parser.errors.has_errors():
        error_msgs = List[String]()
        for error in parser.errors.get_errors():
            if error == ParserError.format_missing:
                error_msgs.append("--format specified without --path")
            elif error == ParserError.path_missing:
                error_msgs.append("--path specified without --format")
            elif error == ParserError.unknown_arg:
                error_msgs.append("Unknown argument")
        raise Error("Argument parsing errors:\n" + "\n".join(error_msgs^))

    for arg in parsed_args:
        if arg == ArgTypes.format:
            config.out_file_format = Format(arg.value[0])
        elif arg == ArgTypes.path:
            config.out_file = Path(arg.value[0])

    return config^


fn DefaultBench() raises -> Bench_:
    """Returns the default benchmarking struct."""
    return Bench_(DefaultConfig())


@fieldwise_init
struct Bencher:
    """A helper struct for benchmarking functions.

    It mimics some features of benchmark.Bencher

    Attributes:
        num_iters: The number of iterations to run per call of iter_custom.
        _time_ns: The total time spent in nanoseconds.
        _iters: The total number of iterations conducted.
    """

    var num_iters: Int
    var _time_ns: Int
    var _iters: Int

    fn __init__(out self, num_iters: Int):
        """Initializes the Bencher with the given number of iterations.

        Args:
            num_iters: The number of iterations to run per call of iter_custom.
        """

        self.num_iters = num_iters
        self._time_ns = 0
        self._iters = 0

    fn iter_custom[iter_fn: fn (Int) capturing -> Int](mut self: Self):
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

    fn reset_time(mut self: Self):
        """Resets the time and iteration counters."""
        self._time_ns = 0
        self._iters = 0


@fieldwise_init
struct BenchConfig(Copyable, Movable):
    """A configuration struct for benchmarking.

    It mimics some features of benchmark.BenchConfig
    """

    var warmup_iters: Int
    var max_iters: Int
    var num_repetitions: Int
    var min_iter_runtime_ns: Int
    var initial_batch_size: Int
    var max_runtime_secs: Float64
    var min_runtime_secs: Float64
    var show_progress: Bool

    fn __init__(
        out self,
        *,
        warmup_iters: Int = 3,
        min_iter_runtime_ns: Int = 100000,
        max_iters: Int = 10_000_000_000,
        max_runtime_secs: Float64 = 10,
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


struct Bench:
    """A benchmarking struct mimicing the features of benchmark.Bench."""

    var config: BenchConfig
    var _results: List[Tuple[BenchId, Bencher]]

    fn __init__(out self, config: BenchConfig):
        """Initializes the Bench with the given configuration.

        Args:
            config: The configuration for the benchmarking.
        """
        self.config = config
        self._results = List[Tuple[BenchId, Bencher]]()

    fn _bench_function_once[
        bench_fn: fn (mut Bencher) capturing -> None
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
                    Int(
                        bencher.num_iters
                        * self.config.min_iter_runtime_ns
                        / time_passed
                    )
                    + 1
                )
            bencher.reset_time()
            return self._bench_function_once[bench_fn](bencher)

    fn bench_function[
        bench_fn: fn (mut Bencher) capturing -> None
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
            and bencher._time_ns * 1e-9 < self.config.max_runtime_secs
            and (
                bencher._iters < self.config.num_repetitions
                or bencher._time_ns * 1e-9 < self.config.min_runtime_secs
            )
        ):
            self._bench_function_once[bench_fn](bencher)

        self._results.append((bench_id, bencher))

    fn dump_report(mut self):
        """Prints the results of the benchmarking."""

        for tuple in self._results:
            bench_id, bencher = tuple[]
            mean_time = bencher._time_ns / bencher._iters
            print(
                bench_id.func_name + ":",
                mean_time,
                "ns per iteration (" + String(bencher._iters),
                "iterations in",
                bencher._time_ns * 1e-9,
                "seconds)",
            )
