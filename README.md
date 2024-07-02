# odin-metal-window

test

An app that renders using the **Apple Metal API** into the window.

## Building the App with `build.sh`

To build the app using the `build.sh` script, follow these steps:

1. Open a terminal or command prompt.
2. Navigate to the root directory of the project.
3. Run the following command to build the app without running it:

```bash
./build.sh
```

This command will execute the `build.sh` script and initiate the build process. However, it will not run the app. If you want to run the app after building it, use the command `./build.sh run`.

4. Wait for the build process to complete. Any errors or warnings will be displayed in the terminal.

## Building the Shader Files with macOS Metal using `xcrun -sdk`

To build the shader files using macOS Metal and `xcrun -sdk`, follow these steps:

1. Open a terminal or command prompt.
2. Navigate to the root directory of the project.
3. Run the following command to build the shader files:

```bash
xcrun -sdk macosx metal -c Shaders.metal -o Shaders.air
```

This command will compile the `Shaders.metal` file and generate the corresponding intermediate representation file `Shaders.air`.

4. If you have multiple shader files, you can include them all in the command by separating them with spaces:

```bash
xcrun -sdk macosx metal -c Shaders1.metal Shaders2.metal -o Shaders.air
```

## Compiling the Intermediate Representation File into a Metal Library

To further compile the intermediate representation file (`Shaders.ir`) into a final Metal library (`Shaders.metallib`), you can use the `xcrun -sdk macosx metallib` command. Here's how you can do it:

1. Open a terminal or command prompt.
2. Navigate to the root directory of the project.
3. Run the following command to compile the intermediate representation file into a Metal library:

```bash
xcrun -sdk macosx metallib -o ./built/Shaders.metallib ./built/Shaders.ir
```

This command will compile the `Shaders.ir` file and generate the final Metal library `Shaders.metallib` in the `./built` directory.

4. Wait for the compilation process to complete. Any errors or warnings will be displayed in the terminal.

Once the compilation is successful, you can use the generated `Shaders.metallib` file in your app by referencing it in your code or build process.

Remember to update your build script or build process to include the compilation of the intermediate representation file into a Metal library using `xcrun -sdk macosx metallib`.
