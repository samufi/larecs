# Agent Guidelines for Larecs

## Build/Test Commands
- Run all tests: `pixi run mojo test -I src/ test/`
- Run single test: `pixi run mojo test -I src/ test/<filename>.mojo`
- Format code: `pixi run mojo format src test benchmark`
- Generate docs: `pixi run mojo doc -o docs/src/larecs.json src/larecs`

## Code Style
- Use snake_case for functions/variables, PascalCase for types
- Use `fn` for static functions, `def` for dynamic functions
- Prefer `var` for mutable, immutable by default
- Use `inout` parameters for mutation, not return modified values
- Include comprehensive type hints with Mojo's progressive typing
- Use `@parameter` for compile-time constants, `@always_inline` for critical paths
- Leverage SIMD types `SIMD[type, width]` for vectorization
- Apply traits: `Copyable`, `Movable`, `Stringable` appropriately
- Use manual memory management with `UnsafePointer` when needed
- Include docstrings for public APIs
- Reference Mojo docs for LLMs: https://docs.modular.com/llms-mojo.txt

## Error Handling & Safety
- Follow borrow checker principles for memory safety
- Prefer stack allocation and RAII patterns
- Use `debug_warn()` utility for debug messages

## Performance Focus
- This is a performance-critical ECS library
- Memory layout and cache efficiency are crucial
- Always consider vectorization opportunities
- Update benchmarks when making performance changes