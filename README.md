# Larecs - lucid archetype-based ECS

This is a Mojo port of the archetype-based ECS [Arche](https://github.com/mlange-42/arche).

This software is under construction and not fully working at the moment.

## Installation

This project is written in [Mojo](https://docs.modular.com/mojo/manual/get-started), which needs to be installed in order to compile, test, or use the software.
If Mojo and the command line interface [Magic](https://docs.modular.com/magic/) are available, dependencies can be installed by navigating to the project directory and executing the following command: 

```
magic install
```

If parts of the program should be executed afterwards, it is advisable to execute the following command, which makes `mojo` available on the command line:

```
magic shell
```

This includes `magic install`, so it is okay to omit the former step.


## Next steps

The next mile stones are the following
- Gain a minimal functionality of the ECS.
- Improve the usability and performance of the ECS. 

## License

The repository currently contains code Go code by Martin Lange, licensed under the [MIT license](https://github.com/mlange-42/arche/blob/main/LICENSE). This code will be removed eventually. The Mojo files are licensed under the [LGPL3](https://www.gnu.org/licenses/lgpl-3.0.de.html). 
