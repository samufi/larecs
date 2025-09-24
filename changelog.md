# Changelog

## [Unreleased](https://github.com/samufi/larecs/compare/v0.4.0...main)

### Breaking changes
- Rename `_ArchetypeIterator` to `_ArchetypeByMaskIterator`

### Other changes
- Implement batch component addition as overload of `world.add`
- Implement batch component removal as overload of `world.remove`
- Add `StaticVariant`
- Add `_ArchetypeByListIterator` to iterate over a given list of archetypes
- Optimize `archetype.reserve` to reduce frequent reallocations
- Add function `_utils.next_pow2` to calculate next power of 2 fast
- Add helper `QueryInfo.matches` to encapsulate query matching logic
- Add `BitMask.__or__` 

## [Unreleased](https://github.com/samufi/larecs/compare/v0.3.0...v0.4.0)

### Breaking changes
- Update the utilized Mojo version to 25.5 and adjust the code accordingly.

### Other changes
- Use the builtin dict for better performance.
- Change StaticOptional to build on `InlineArray` for simpler code.
- Remove boilerplate code that can now be synthesized automatically.
- Disable some tests that cannot be executed in the new Mojo version due to a bug.

## [v0.3.0 (2025-06-23)](https://github.com/samufi/larecs/compare/v0.2.0...v0.3.0)

### Breaking changes
- Update the utilized Mojo version to 25.4 and adjust the code accordingly.
- Remove the `TypeIdentifiable` trait, the `TypeId` struct, as well as the TypeMaps. 
  Instead, resources now use the built-in reflections module to identify types.
- Remove all `get_ptr` functions, since getting a reference is now sufficient if 
  using the `ref` keyword. This applies to entities as well as resources.
- Make `Resources` explicitly copyable only.

### Other changes
- Remove the `@value` decorator in favour of the `@fieldwise_init` decorator and explicit trait conformance.
- Refactor the internal type `ComptimeOptional` to `StaticOptional` so as to match the naming conventions of the standard library.

## [v0.2.0 (2025-05-14)](https://github.com/samufi/larecs/compare/v0.1.0...v0.2.0)

### Breaking changes
- Introduce a trait `ResourceType` to define the type of resources and replace the old `IdentifiableCollectionElement` trait.

### Other changes
- Switch to explicit trait conformance.
- Use trait composition instead of inheritance where possible.
- Introduce a new `TypeIdentifiable` trait for types that can be identified by a type ID.
- Move resources into the storage instead of copying them. This is much more performant if resources are large.

## [v0.1.0 (2025-04-08)](https://github.com/samufi/larecs/tree/v0.1.0)

Initial release of Larecs🌲.