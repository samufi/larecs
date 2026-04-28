from std.testing import TestSuite

from _utils_test import functions as utils_functions
from unsafe_box_test import functions as unsafe_box_functions
from types_test import functions as types_functions
from resource_test import functions as resource_functions
from static_optional_test import functions as static_optional_functions

# TODO: Crashes when running all tests together. Uncomment and investigate.
# from bitmask_test import functions as bitmask_functions
from component_test import functions as component_functions
from graph_test import functions as graph_functions
from archetype_test import functions as archetype_functions


def main() raises:
    TestSuite.discover_tests[
        Tuple()
        .concat(utils_functions)
        .concat(unsafe_box_functions)
        .concat(types_functions)
        # .concat(bitmask_functions)
        .concat(resource_functions)
        .concat(static_optional_functions)
        .concat(component_functions)
        .concat(graph_functions)
        .concat(archetype_functions)
    ]().run()
