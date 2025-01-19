file /home/dhruvank/llvm-build/build/bin/opt
set args temp.ll -passes=helloworld
set breakpoint pending on
b addControlFlowChecks
r