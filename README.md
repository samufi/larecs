# Larecs - lucid archetype-based ECS

This is a Mojo port of the archetype-based ECS [Arche](https://github.com/mlange-42/arche).

This software is under construction and not fully working at the moment.

## Installation

### Prerequisites

This project is written in [Mojo](https://docs.modular.com/mojo/manual/get-started), which needs to be installed in order to compile, test, or use the software.
If Mojo and the command line interface [Magic](https://docs.modular.com/magic/) are available, dependencies can be installed by navigating to the project directory and executing the following command: 

```
magic install
```

If parts of the program should be executed afterwards, execute the following command in the project folder, making `mojo` available on the command line:

```
magic shell
```

This includes `magic install`, so it is okay to omit the former step.

### Build a package

You can build larecs as a standalaone package as follows:

1. Clone the repository / download the files.
2. Navigate to the `src/` subfolder.
3. Execute `mojo package larecs`
4. Move the newly created file `larecs.mojopkg` to your project's source directory.

### Include source directly for compiler and LSP

To better see what larecs does, access the source while debugging, and adjust the larecs 
source, you can include it into the run command as follows:

```
mojo run -I "path/to/larecs/src" example.mojo
```

To let VSCode and the LSP know of larecs, include it as follows:

1. Go to VSCode's `File -> Preferences -> Settings` page
2. Go to the `Extensions -> Mojo` section
3. Look for the setting `Lsp: Include Dirs`
4. Click on `add item` and insert the path to the `larecs` subdirectory.

## Next steps

The next mile stones are the following
- Add further useful functionality for queries, e.g. batches.
- Improve the usability and performance of the ECS. 

## License

The repository currently contains code Go code by Martin Lange, licensed under the [MIT license](https://github.com/mlange-42/arche/blob/main/LICENSE). This code will be removed eventually. The Mojo files are licensed under the [LGPL3](https://www.gnu.org/licenses/lgpl-3.0.de.html). 
