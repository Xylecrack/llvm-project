file /home/dhruvank/llvm-build/build/bin/opt
set args temp.ll -passes=helloworld
set breakpoint pending on
b /home/dhruvank/llvm-build/llvm/lib/Transforms/Utils/HelloWorld.cpp:82
r