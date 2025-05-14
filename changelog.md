# Changelog

## [Unreleased](https://github.com/samufi/larecs/compare/v0.1.0...main)

- ...

## [v0.2.0 (2025-05-14)](https://github.com/samufi/larecs/tree/v0.2.0)

### Breaking changes
- Introduce a trait `ResourceType` to define the type of resources and replace the old `IdentifiableCollectionElement` trait.

### Other changes
- Switch to explicit trait conformance.
- Use trait composition instead of inheritance where possible.
- Introduce a new `TypeIdentifiable` trait for types that can be identified by a type ID.
- Move resources into the storage instead of copying them. This is much more performant if resources are large.

## [v0.1.0 (2025-04-08)](https://github.com/samufi/larecs/tree/v0.1.0)

Initial release of Larecs🌲.