#!/usr/bin/env bash

##===- utils/clone-mlir-aie.sh - Clone MLIR-AIE --------------*- Script -*-===##
#
# Copyright (C) 2022, Advanced Micro Devices, Inc.
# SPDX-License-Identifier: MIT

##===----------------------------------------------------------------------===##
#
# This script checks out MLIR-AIE.  We use this instead of a git submodule to 
# manage commithash synchronization with LLVM.
#
# This script is called from the github workflows.
#
##===----------------------------------------------------------------------===##

export HASH=d07ee8ee44b5f0fa9b48ceb0f38878cb71c6533f
target_dir=mlir-aie

if [[ ! -d $target_dir ]]; then
  git clone --depth 1 https://github.com/Xilinx/mlir-aie.git $target_dir
fi

pushd $target_dir
git fetch --depth=1 origin $HASH
git checkout $HASH
git submodule update --init
cd runtime_lib/xaiengine/aie-rt
git checkout -b phoenix_v2023.2 origin/phoenix_v2023.2
popd
