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
// REF:https://www.researchgate.net/publication/3152520_Control-flow_checking_by_software_signatures
void addControlFlowChecks(Function &F) {
  int sign = 0;
  DenseMap<BasicBlock *, int> blockSign;                                  // si
  DenseMap<BasicBlock *, int> signDiff;                                   // dj
  DenseMap<std::pair<BasicBlock *, BasicBlock *>, int> runtimeAdjustSign; // Dim

  // Step 1: Assign unique signatures to each basic block

  int counter = 0;
  int secondBlockSignature = 0;

  for (BasicBlock &BB : F) {
    if (counter == 1) {
      blockSign[&BB] = sign++;
      secondBlockSignature = sign;
    } else if (counter == 2) {
      blockSign[&BB] = secondBlockSignature;
    } else {
      blockSign[&BB] = ++sign;
    }
    counter++;
  }

  // Step 2: Calculate signature differences for branch fan-in nodes
  for (BasicBlock &BB : F) {
    SmallVector<BasicBlock *, 4> Preds;
    for (BasicBlock *Pred : predecessors(&BB)) {
      Preds.push_back(Pred);
    }

    if (!Preds.empty()) {
      BasicBlock *vi1 = Preds[0];
      signDiff[&BB] = blockSign[vi1] ^ blockSign[&BB];
      for (size_t m = 1; m < Preds.size(); ++m) {
        BasicBlock *vim = Preds[m];
        runtimeAdjustSign[{vim, &BB}] = blockSign[vi1] ^ blockSign[vim];
      }
    }
  }

  // Step 3: Insert instructions to update and check the runtime signature
  LLVMContext &Context = F.getContext();
  IntegerType *Int32Ty = Type::getInt32Ty(Context);

  BasicBlock *errorBlock = BasicBlock::Create(Context, "errorblock", &F);
  IRBuilder<> errorBuilder(errorBlock);

  errorBuilder.CreateCall(
      Intrinsic::getDeclaration(F.getParent(), Intrinsic::trap));
  errorBuilder.CreateUnreachable();
  // Insert a signature variable at the function entry block
  IRBuilder<> entryBuilder(&F.getEntryBlock(), F.getEntryBlock().begin());
  AllocaInst *runtimeSign =
      entryBuilder.CreateAlloca(Int32Ty, nullptr, "runtimeSign");
  entryBuilder.CreateStore(ConstantInt::get(Int32Ty, 0), runtimeSign);

  // Insert instructions in each basic block
  for (BasicBlock &BB : F) {
    Instruction *secondInst = &*std::next(BB.begin(), 2);
    IRBuilder<> builder(secondInst);
    Value *currentSign = builder.CreateLoad(Int32Ty, runtimeSign);

    // XOR runtimeSign with blockSign
    Value *blockSignature = builder.getInt32(blockSign[&BB]);
    Value *updatedSign = builder.CreateXor(currentSign, blockSignature);
    builder.CreateStore(updatedSign, runtimeSign);

    // Compare runtimeSign and signDiff
    for (BasicBlock *Succ : successors(&BB)) {
      Value *currSignDiff = builder.getInt32(signDiff[Succ]);
      Value *expectedSign = builder.CreateXor(updatedSign, currSignDiff);
      Value *loadedSign = builder.CreateLoad(Int32Ty, runtimeSign);
      Value *cmp = builder.CreateICmpNE(loadedSign, expectedSign);

      builder.CreateCondBr(cmp, errorBlock, Succ);
      SmallVector<BasicBlock *, 4> Preds;
      for (BasicBlock *Pred : predecessors(Succ)) {
        Preds.push_back(Pred);
      }

      if (Preds.size() > 1) {
        for (size_t m = 1; m < Preds.size(); ++m) {
          BasicBlock *vim = Preds[m];
          if (vim == &BB) {
            Value *adjustSign =
                builder.getInt32(runtimeAdjustSign[{vim, Succ}]);
            Value *adjustedSign = builder.CreateXor(updatedSign, adjustSign);
            builder.CreateStore(adjustedSign, runtimeSign);
          }
        }
      }
    }
  }
}

PreservedAnalyses HelloWorldPass::run(Function &F,
                                      FunctionAnalysisManager &AM) {
  addControlFlowChecks(F);
  F.dump();
  return PreservedAnalyses::none();
}