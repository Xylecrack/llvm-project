# LLVM Compiler Infrastructure

This is a local build of LLVM

Tests are in /llvm-test
### Command to compile a c program to llvm IR
```bash
clang -S -emit-llvm hello.c -o hello.ll
```
### Command to run a pass on the IR
```bash
⁠build/bin/opt <input.ll> -disable-output -passes=<pass-name>
```