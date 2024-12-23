//===-- HelloWorld.cpp - Example Transformations --------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/Transforms/Utils/HelloWorld.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

void addControlFlowChecks(Function &F) {
  int sign = 0;
  DenseMap<BasicBlock *, int> blockSign; // si
  DenseMap<BasicBlock *, int> signDiff;  // di
  BasicBlock *BB = &F.getEntryBlock();
  while (BB != nullptr) {
    sign++;
    blockSign[BB] = sign;
    BB = BB->getSingleSuccessor();
  }
  BB = &F.getEntryBlock();
  while (BB->getSingleSuccessor() != nullptr) {
    signDiff[BB] = blockSign[BB] ^ blockSign[BB->getSingleSuccessor()];
    BB = BB->getSingleSuccessor();
  }

  // TO CALCULATE SUCCESSIVE DIFFERENCE (XOR) WITH THE PREDECESSOR
}

PreservedAnalyses HelloWorldPass::run(Function &F,
                                      FunctionAnalysisManager &AM) {
  errs() << "Hello, World!\n";
  addControlFlowChecks(F);

  return PreservedAnalyses::none();
}