// (c) Copyright 2020 Xilinx Inc. All Rights Reserved.

#include <cassert>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <thread>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <dlfcn.h>

#include <xaiengine.h>

#include "air_host.h"
#include "air_tensor.h"

#define IMAGE_WIDTH 32
#define IMAGE_HEIGHT 16
#define IMAGE_SIZE  (IMAGE_WIDTH * IMAGE_HEIGHT)

#define TILE_WIDTH 16
#define TILE_HEIGHT 8
#define TILE_SIZE  (TILE_WIDTH * TILE_HEIGHT)

namespace air::herds::herd_0 {
void mlir_aie_write_buffer_scratch_0_0(aie_libxaie_ctx_t*, int, int32_t);
};
using namespace air::herds::herd_0;

int
main(int argc, char *argv[])
{
  uint64_t row = 4;
  uint64_t col = 5;
  
  aie_libxaie_ctx_t *xaie = air_init_libxaie1();

  // create the queue
  queue_t *q = nullptr;
  auto ret = air_queue_create(MB_QUEUE_SIZE, HSA_QUEUE_TYPE_SINGLE, &q, AIR_VCK190_SHMEM_BASE);
  assert(ret == 0 && "failed to create queue!");

  for (int i=0; i<TILE_SIZE; i++)
    mlir_aie_write_buffer_scratch_0_0(xaie, i, 0xfadefade);

  printf("loading aie_ctrl.so\n");
  auto handle = air_module_load_from_file(nullptr,q);
  assert(handle && "failed to open aie_ctrl.so");

  auto graph_fn = (void (*)(void*,void *))dlsym((void*)handle, "_mlir_ciface_graph");
  assert(graph_fn && "failed to locate _mlir_ciface_graph in .so");

  tensor_t<uint32_t,2> input;
  tensor_t<uint32_t,2> output;

  input.shape[0] = IMAGE_WIDTH; input.shape[1] = IMAGE_HEIGHT;
  output.shape[0] = IMAGE_WIDTH; output.shape[1] = IMAGE_HEIGHT;

  XAieLib_MemInst *mem_i = XAieLib_MemAllocate(sizeof(uint32_t)*input.shape[0]*input.shape[1], 0);
  input.d = input.aligned = (uint32_t*)XAieLib_MemGetPaddr(mem_i);
  input.uses_pa = true;
  uint32_t *in = (uint32_t*)XAieLib_MemGetVaddr(mem_i); 

  XAieLib_MemInst *mem_o = XAieLib_MemAllocate(sizeof(uint32_t)*output.shape[0]*output.shape[1], 0);
  output.d = output.aligned = (uint32_t*)XAieLib_MemGetPaddr(mem_o);
  output.uses_pa = true;
  uint32_t *out = (uint32_t*)XAieLib_MemGetVaddr(mem_o);

  for (int i=0; i<IMAGE_SIZE; i++) {
    in[i] = i+0x1000;
    out[i] = 0x00defaced;
  }

  XAieLib_MemSyncForDev(mem_i);
  XAieLib_MemSyncForDev(mem_o);

  void *i, *o;
  i = &input;
  o = &output;
  graph_fn(i, o);

  int errors = 0;

  // Now look at the image, should have the bottom left filled in
  for (int i=0;i<IMAGE_SIZE;i++) {
    u32 rb = out[i];

    u32 row = i / IMAGE_WIDTH;
    u32 col = i % IMAGE_WIDTH;

    if ((row >= TILE_HEIGHT) && (col < TILE_WIDTH)) {
      if (!(rb == 0x1000+i)) {
        printf("IM %d [%d, %d] should be %08X, is %08X\n", i, col, row, i+0x1000, rb);
        errors++;
      }
    }
    else {
      if (rb != 0x00defaced) {
        printf("IM %d [%d, %d] should be 0xdefaced, is %08X\n", i, col, row, rb);
        errors++;
      }
    }
  }

  XAieLib_MemFree(mem_i);
  XAieLib_MemFree(mem_o);

  if (!errors) {
    printf("PASS!\n");
    return 0;
  }
  else {
    printf("fail %d/%d.\n", (TILE_SIZE+IMAGE_SIZE-errors), TILE_SIZE+IMAGE_SIZE);
    return -1;
  }

}