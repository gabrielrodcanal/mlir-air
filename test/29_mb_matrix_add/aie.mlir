// (c) Copyright 2020 Xilinx Inc. All Rights Reserved.

module {
  %t70 = AIE.tile(7, 0)
  %t71 = AIE.tile(7, 1)
  %t72 = AIE.tile(7, 2)

  AIE.flow(%t70, "DMA" : 0, %t72, "DMA" : 0)
  AIE.flow(%t70, "DMA" : 1, %t72, "DMA" : 1)
  AIE.flow(%t72, "DMA" : 0, %t70, "DMA" : 0)
  AIE.flow(%t72, "DMA" : 1, %t70, "DMA" : 1)

  %buf72_0 = AIE.buffer(%t72) { sym_name = "ping_a" } : memref<128xi32>
  %buf72_4 = AIE.buffer(%t72) { sym_name = "ping_b" } : memref<128xi32>
  %buf72_1 = AIE.buffer(%t72) { sym_name = "ping_c" } : memref<128xi32>
  %buf72_2 = AIE.buffer(%t72) { sym_name = "pong_a" } : memref<128xi32>
  %buf72_5 = AIE.buffer(%t72) { sym_name = "pong_b" } : memref<128xi32>
  %buf72_3 = AIE.buffer(%t72) { sym_name = "pong_c" } : memref<128xi32>

  %l72_0 = AIE.lock(%t72, 0)
  %l72_1 = AIE.lock(%t72, 1)
  %l72_2 = AIE.lock(%t72, 2)
  %l72_3 = AIE.lock(%t72, 3)
  %l72_4 = AIE.lock(%t72, 4)
  %l72_5 = AIE.lock(%t72, 5)

  %m72 = AIE.mem(%t72) {
      %srcDma1 = AIE.dmaStart("S2MM0", ^bd0, ^src1)
    ^src1:
      %srcDma2 = AIE.dmaStart("S2MM1", ^bd4, ^dma0)
    ^dma0:
      %dstDma = AIE.dmaStart("MM2S0", ^bd2, ^end)
    ^bd0:
      AIE.useLock(%l72_0, "Acquire", 0)
      AIE.dmaBd(<%buf72_0 : memref<128xi32>, 0, 128>, 0)
      AIE.useLock(%l72_0, "Release", 1)
      br ^bd1
    ^bd1:
      AIE.useLock(%l72_1, "Acquire", 0)
      AIE.dmaBd(<%buf72_2 : memref<128xi32>, 0, 128>, 0)
      AIE.useLock(%l72_1, "Release", 1)
      br ^bd0
    ^bd4:
      AIE.useLock(%l72_4, "Acquire", 0)
      AIE.dmaBd(<%buf72_4 : memref<128xi32>, 0, 128>, 0)
      AIE.useLock(%l72_4, "Release", 1)
      br ^bd5
    ^bd5:
      AIE.useLock(%l72_5, "Acquire", 0)
      AIE.dmaBd(<%buf72_5 : memref<128xi32>, 0, 128>, 0)
      AIE.useLock(%l72_5, "Release", 1)
      br ^bd4
    ^bd2:
      AIE.useLock(%l72_2, "Acquire", 1)
      AIE.dmaBd(<%buf72_1 : memref<128xi32>, 0, 128>, 0)
      AIE.useLock(%l72_2, "Release", 0)
      br ^bd3
    ^bd3:
      AIE.useLock(%l72_3, "Acquire", 1)
      AIE.dmaBd(<%buf72_3 : memref<128xi32>, 0, 128>, 0)
      AIE.useLock(%l72_3, "Release", 0)
      br ^bd2
    ^end:
      AIE.end
  }

  AIE.core(%t72) {
    %clp = constant 16 : index
    %c128 = constant 128 : index
    %c0 = constant 0 : index
    %c1 = constant 1 : index

    scf.for %arg5 = %c0 to %clp step %c1 {  
      AIE.useLock(%l72_0, "Acquire", 1)
      AIE.useLock(%l72_4, "Acquire", 1)
      AIE.useLock(%l72_2, "Acquire", 0)
      scf.for %arg3 = %c0 to %c128 step %c1 {
          %0 = memref.load %buf72_0[%arg3] : memref<128xi32>
          %1 = memref.load %buf72_4[%arg3] : memref<128xi32>
          %2 = addi %0, %1 : i32
          memref.store %2, %buf72_1[%arg3] : memref<128xi32>
      }
      AIE.useLock(%l72_0, "Release", 0)
      AIE.useLock(%l72_4, "Release", 0)
      AIE.useLock(%l72_2, "Release", 1)

      AIE.useLock(%l72_1, "Acquire", 1)
      AIE.useLock(%l72_5, "Acquire", 1)
      AIE.useLock(%l72_3, "Acquire", 0)
      scf.for %arg4 = %c0 to %c128 step %c1 {
          %3 = memref.load %buf72_2[%arg4] : memref<128xi32>
          %4 = memref.load %buf72_5[%arg4] : memref<128xi32>
          %5 = addi %3, %4 : i32
          memref.store %5, %buf72_3[%arg4] : memref<128xi32>
      }
      AIE.useLock(%l72_1, "Release", 0)
      AIE.useLock(%l72_5, "Release", 0)
      AIE.useLock(%l72_3, "Release", 1)
    }
    AIE.end

  }

}
