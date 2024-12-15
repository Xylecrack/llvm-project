//===-- HelloWorld.cpp - Example Transformations --------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/Transforms/Utils/HelloWorld.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Pass.h"
using namespace llvm;

PreservedAnalyses HelloWorldPass::run(Function &F, FunctionAnalysisManager &AM) {
  errs() << "Running HelloWorldPass on function: " << F.getName() << "\n";

  // Iterate through the basic blocks in the function
  for (BasicBlock &BB : F) {
    errs() << "Inspecting basic block: " << BB.getName() << "\n";
    errs() << "Basic block has " << BB.size() << " instructions.\n";

    // Iterate through each instruction in the basic block
    for (Instruction &I : BB) {
      errs() << "  Instruction: " << I << "\n";
    }
  }

  return PreservedAnalyses::all();
}
