# Stardrive

Stardrive's goal is to reimplement the engine of the video game Starbound by Chucklefish in the **D** language.

## Why not contribute to OpenStarbound?

OpenStarbound, being built off the leaked source code of the game, has always been and will always be legally dubious *at best*.
The lack of a response from Chucklefish indicates they may be alright with it, however it's also not a blatant "go ahead" signal and remains a grey area.
Additionally, a rebuild from the ground up allows many of the issues with the engine to be addressed at an architectural level, instead of just bandaid fixes.

## Why D?

Admittedly the decision to use D was impulsive, however that does not mean it is a terrible pick.
D is a very unique language that has some real benefits for this use case:
- It's garbage collected, which has been proven to be an excellent choice for video games and shines in multi-threaded applications
- Unlike most other garbage collected languages, it's machine compiled which means it's comparatively fast
- It has a very familiar syntax for those coming from C++ or Java
- It has a very expansive centralized package repository
- Compile-time reflection has been a feature of D for a very long time, while it's only recently being introduced to C++ in C++26

## Long-Term Goals

Feature parity with the vanilla engine comes first and foremost, of course.
Additional goals include:
- Porting OpenStarbound features and Lua bindings
- Optimized Lua runtime with [Ravi](https://github.com/dibyendumajumdar/ravi)
- Multi-threading
- New asset format with richer metadata, and optimized for streaming over networks and into memory
- Built-in mod distribution tooling for non-Steam users

## Building

Compiling and building the project requires CMake, the DUB package manager, and any D2 compiler (LDC2 preferred).
Support for POSIX-compatible systems comes first and foremost, building on Windows may require Cygwin or similar.
