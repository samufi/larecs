# Agent Guidelines for Larecs

## Build/Test Commands

- Run all tests: `pixi run mojo run -D ASSERT=all -I src/ test/_all.mojo`
- Run single test: `pixi run mojo run -D ASSERT=all -I src/ test/<filename>.mojo`
- Format code: `pixi run mojo format src test benchmark`
- Generate docs: `pixi run mojo doc -o docs/src/larecs.json src/larecs`

## Code Style

- Use snake_case for functions/variables, PascalCase for types
- Always use `def` for functions
- Prefer `var` for mutable, immutable by default
- Use `mut` parameters for mutation, not return modified values
- Include comprehensive type hints with Mojo's progressive typing
- Use `comptime` for compile-time constants, `@always_inline` for critical paths
- Leverage SIMD types `SIMD[type, width]` for vectorization
- Apply traits: `Copyable`, `ImplicitlyCopyable`, `Movable`, `Writable`, `ImplicitlyDestructible`, `RegisterPassable`, `TriviallyRegisterPassable` appropriately
- Use manual memory management with `UnsafePointer` ONLY when needed
- Every function needs a docstrings including a description of all parameters, raises and returns.
  Use this example as a template:

  ```mojo
    def <function_name>[<parameters>](<arguments>) raises? -> <return type>:
        """<short description>

        <long description>(optional)

        Parameters:
            <parameter name>: <description for one parameter>

        Args:
            <argument name>: <description for one argument>

        Raises:
            <description when and what Exceptions can be raised>

        Returns:
            <description what gets returned>

        Constraints:
            <description of one comptime constraint (indicated by `comptime assert`)>
        """
  ```

- Reference Mojo docs via the `mojo-syntax` skill

## Error Handling & Safety

- Follow borrow checker principles for memory safety
- Prefer stack allocation and RAII patterns
- Use `debug_warn()` utility for debug messages
- Use `debug_assert()` for critical checks when they introduce no performance overhead

## Performance Focus

- This is a performance-critical ECS library
- Memory layout and cache efficiency are crucial
- Always consider vectorization opportunities
- Update benchmarks when making performance changes
