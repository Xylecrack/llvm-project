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
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

void addControlFlowChecks(Function &F) {
  int sign = 0;
  DenseMap<BasicBlock *, int> blockSign; // si
  DenseMap<BasicBlock *, int> signDiff;  // di

  for (BasicBlock &BB : F) {
    sign++;
    blockSign[&BB] = sign;
  }
  for (BasicBlock &BB : F) {
    for (BasicBlock *Succ : successors(&BB)) {
      signDiff[Succ] = blockSign[&BB] ^ blockSign[Succ];
    }
  }

  // TO CALCULATE SUCCESSIVE DIFFERENCE (XOR) WITH THE PREDECESSOR
  // Insert instructions to update and check the runtime signature
  LLVMContext &Context = F.getContext();
  IntegerType *Int32Ty = Type::getInt32Ty(Context);

  // Insert a signature variable at the function entry block
  IRBuilder<> entryBuilder(&F.getEntryBlock(), F.getEntryBlock().begin());
  AllocaInst *runtimeSign = entryBuilder.CreateAlloca(Int32Ty, nullptr, "runtimeSign");
  entryBuilder.CreateStore(ConstantInt::get(Int32Ty, 0), runtimeSign);

  // Insert instructions in each basic block
  for (BasicBlock &BB : F) {
    IRBuilder<> builder(&BB, BB.getFirstInsertionPt());

    // Load the current runtime signature
    Value *currentSign = builder.CreateLoad(Int32Ty, runtimeSign);

    // Update the runtime signature with the block's unique signature
    Value *blockSignature = builder.getInt32(blockSign[&BB]);
    Value *updatedSign = builder.CreateXor(currentSign, blockSignature);
    builder.CreateStore(updatedSign, runtimeSign);

    // Verify the runtime signature with the block's signature difference
    for (BasicBlock *Succ : successors(&BB)) {
      Value *currSignDiff = builder.getInt32(signDiff[Succ]);
      Value *expectedSign = builder.CreateXor(updatedSign, currSignDiff);
      Value *loadedSign = builder.CreateLoad(Int32Ty, runtimeSign);
      Value *cmp = builder.CreateICmpNE(loadedSign, expectedSign);
      Function *errorFunc = Intrinsic::getDeclaration(F.getParent(), Intrinsic::trap);
      BasicBlock *errorBB = BasicBlock::Create(Context, "error", &F);
      builder.CreateCondBr(cmp, errorBB, Succ);
    }
  }
}


PreservedAnalyses HelloWorldPass::run(Function &F,
                                      FunctionAnalysisManager &AM) {
  errs() << "Hello, World!\n";
  addControlFlowChecks(F);

  return PreservedAnalyses::none();
}