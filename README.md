# Running

Make sure the submodules are in sync with:

```
git submodule update --init --recursive`
```

## Desktop

This should work on Linux, macOS and Windows. On Windows you'll need WSL for
the 'run.sh' script, but that could be worked on. Make sure you have:

- Nim 1.4 installed with choosenim
- CMake

Then just run:

```
./run.sh release
```

The first time you ever build, it takes a while because SDL-gpu builds GLEW.
Subsequent builds should be much quicker though (unless you clear the 'build/'
directory).

You can also do this to run with Valgrind if you have it installed (to check for leaks):

```
VALGRIND=on ./run.sh release
```

Use `MAIN=` to set the entrypoint module.

```
MAIN=src/core/kernel_test.nim ./run.sh release
```

You can combine `VALGRIND=on` with `MAIN=...` too.

## Web

Install the Emscripten SDK in '../emsdk' relative to this repository. Then run:

```
./run.sh web-release
```

## Mobile

This CMake setup has worked for iOS native builds of C++ projects for me, so I
think it's likely to work for this too. I'll try that out soon. I haven't tried
Android at all with this setup yet, but it's definitely a medium-term goal.

