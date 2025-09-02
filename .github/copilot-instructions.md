# Copilot Instructions for Larecs

## Project Overview
Larecs is a high-performance Entity Component System (ECS) library written in Mojo. It provides efficient data structures and algorithms for game development and simulation applications.

## Key Components
- **Entities**: Unique identifiers for game objects
- **Components**: Data containers that can be attached to entities
- **Systems**: Logic that operates on entities with specific components
- **World**: Central container managing entities, components, and systems
- **Archetypes**: Efficient storage for entities with the same component composition
- **Queries**: Fast iteration over entities matching specific criteria

## Code Style Guidelines
- Follow Mojo naming conventions (snake_case for functions/variables, PascalCase for types)
- Use `fn` for functions with static semantics, `def` for Python-like dynamic functions
- Prefer `var` for mutable variables, immutable by default
- Use type hints consistently with Mojo's progressive typing system
- Prefer SIMD operations where applicable for performance
- Use `@parameter` for compile-time constants and `@always_inline` for critical paths
- Leverage traits like `Copyable`, `Movable`, `Stringable` appropriately
- Include docstrings for public APIs
- Write comprehensive tests for new features

## Mojo-Specific Guidelines
- Use `inout` parameters for mutation, not returning modified values
- Prefer stack allocation and RAII patterns for memory management
- Leverage SIMD types `SIMD[type, width]` for vectorization
- Use manual memory management with `UnsafePointer` when needed
- Apply the borrow checker principles for memory safety
- Reference the official Mojo LLMs documentation: https://docs.modular.com/llms-mojo.txt

## File Structure
- `src/larecs/`: Core library implementation
- `test/`: Unit tests
- `benchmark/`: Performance benchmarks
- `examples/`: Usage examples
- `docs/`: Documentation (mostly generated from docstrings)

## Performance Considerations
- This is a performance-critical library
- Vectorization and SIMD optimizations are important
- Memory layout and cache efficiency matter
- Benchmarks should be updated when making performance-related changes

## Testing
- All new features should include corresponding tests
- Run benchmarks to ensure performance regressions don't occur
- Use the existing test utilities in `test_utils.mojo`

## Running Tests
The project uses Mojo's built-in testing framework. Use pixi to manage the environment and run tests:

### Running All Tests
```bash
# Run all tests in the test directory
pixi run mojo test -I src/ test/

# Alternative: run tests from the project root
cd /path/to/larecs
pixi run mojo test -I src/ test/
```

### Running Specific Test Files
```bash
# Run a specific test file
pixi run mojo test -I src/ test/world_test.mojo
pixi run mojo test -I src/ test/query_test.mojo
pixi run mojo test -I src/ test/entity_test.mojo
```

### Running Individual Test Functions
```bash
# Note: mojo test runs ALL test functions in a file, not individual functions
# To test specific functionality, temporarily comment out other test functions or create a separate test file with only the tested function.
pixi run mojo test -I src/ test/<name_of_test_file>.mojo
```

### Test Structure
- Test files are located in the `test/` directory
- Each test file should have a `main()` function that calls all test functions
- Use the testing utilities from `test_utils.mojo` for common test components
- Follow the naming convention `test_<functionality>.mojo` for test files
- Use descriptive function names like `test_add_entity()`, `test_batch_remove()`, etc.

### Before Committing
Always run the full test suite before committing changes:
```bash
pixi run mojo test -I src/ test/
```
Ensure all tests pass (100% success rate) before submitting pull requests.

