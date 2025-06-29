# Changelog

## [Unreleased](https://github.com/samufi/larecs/compare/v0.3.0...main)

### Breaking changes
- ...

### Other changes
- ...

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