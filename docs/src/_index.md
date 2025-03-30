---
title: "Larecs🌲"
type: docs
summary: Larecs🌲 – Lightweight archetype-based ECS for Mojo.
---
# Larecs🌲 – Lightweight archetype-based ECS

Larecs🌲 is a performance-oriented archetype-based ECS for [Mojo](https://www.modular.com/mojo)🔥. 
Its architecture is based on the Go ECS [Arche](https://github.com/mlange-42/arche). The package is still under construction, so be aware that the API might change in future versions.

## Features

- Clean and simple API
- High performance due to archetypes and Mojo's compile-time programming
- Support for SIMD via a [`vectorize`](https://docs.modular.com/mojo/stdlib/algorithm/functional/vectorize/)-like syntax
- Compile-time checks thanks to usage of parameters
- Native support for [resources](https://mlange-42.github.io/arche/guide/resources/) and scheduling.
- Tested and benchmarked
- No external dependencies
- More features coming soon... 