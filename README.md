# Stardrive

Stardrive's goal is to reimplement the engine of the video game Starbound by Chucklefish in the **D** language.

## Why not contribute to OpenStarbound?

A rebuild of the engine from the ground up will allow many architectural issues (such as it being single-threaded) of the engine to be addressed directly, instead of bandaid fixes.
A blank slate also means that the engine can be written with consciousness towards new features and optimizations, and with a more modular architecture that supports future expansion.
Finally, as OpenStarbound is built off leaked code, it's legal status is dubious at *best* - and while the original copyright owners may not seek legal action - some may wish to avoid association because of the percieved risk.

## Why D?

D has many features that make it ideal to address the issues with the vanilla Starbound engine:
- It uses a conservative stop-the-world style garbage collector, which makes it "memory safe" and ideal for multi-threaded applications
- Unlike most other garbage collected languages, it's machine compiled which means it is very fast
- It has a very familiar syntax for those coming from C++ or Java
- It has an expansive centralized package repository, and a rich standard library ([Phobos](https://github.com/dlang/phobos))
- It has a few features that are new to C++, or C++ just doesn't have, such as compile-time reflection

## Long-Term Goals

Feature parity with the vanilla engine comes first and foremost, of course.
Additional goals include:
- Multi-threading
- Porting (select) OpenStarbound features and Lua bindings
- Optimized Lua runtime with [Ravi](https://github.com/dibyendumajumdar/ravi)
- New asset format with richer metadata, and optimized for streaming over networks and into memory
- Built-in mod distribution tooling for non-Steam users

## Building

Compiling and building the project requires CMake, the DUB package manager, and any D2 compiler (LDC2 preferred).
At the moment, only POSIX-compatible systems are supported. Windows support will be added once I have a Windows machine or VM.
