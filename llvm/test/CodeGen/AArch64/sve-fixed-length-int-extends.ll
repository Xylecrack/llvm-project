; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -aarch64-sve-vector-bits-min=256  < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_256
; RUN: llc -aarch64-sve-vector-bits-min=512  < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512
; RUN: llc -aarch64-sve-vector-bits-min=2048 < %s | FileCheck %s -check-prefixes=CHECK,VBITS_GE_512

target triple = "aarch64-unknown-linux-gnu"

;
; sext i1 -> i32
;

; NOTE: Covers the scenario where a SIGN_EXTEND_INREG is required, whose inreg
; type's element type is not byte based and thus cannot be lowered directly to
; an SVE instruction.
define void @sext_v8i1_v8i32(<8 x i1> %a, ptr %out) vscale_range(2,0) #0 {
; CHECK-LABEL: sext_v8i1_v8i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    uunpklo z0.h, z0.b
; CHECK-NEXT:    ptrue p0.s, vl8
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    lsl z0.s, z0.s, #31
; CHECK-NEXT:    asr z0.s, z0.s, #31
; CHECK-NEXT:    st1w { z0.s }, p0, [x0]
; CHECK-NEXT:    ret
  %b = sext <8 x i1> %a to <8 x i32>
  store <8 x i32> %b, ptr %out
  ret void
}

;
; sext i3 -> i64
;

; NOTE: Covers the scenario where a SIGN_EXTEND_INREG is required, whose inreg
; type's element type is not power-of-2 based and thus cannot be lowered
; directly to an SVE instruction.
define void @sext_v4i3_v4i64(<4 x i3> %a, ptr %out) vscale_range(2,0) #0 {
; CHECK-LABEL: sext_v4i3_v4i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    lsl z0.d, z0.d, #61
; CHECK-NEXT:    asr z0.d, z0.d, #61
; CHECK-NEXT:    st1d { z0.d }, p0, [x0]
; CHECK-NEXT:    ret
  %b = sext <4 x i3> %a to <4 x i64>
  store <4 x i64> %b, ptr %out
  ret void
}

;
; sext i8 -> i16
;

define void @sext_v16i8_v16i16(<16 x i8> %a, ptr %out) vscale_range(2,0) #0 {
; CHECK-LABEL: sext_v16i8_v16i16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    sunpklo z0.h, z0.b
; CHECK-NEXT:    ptrue p0.h, vl16
; CHECK-NEXT:    st1h { z0.h }, p0, [x0]
; CHECK-NEXT:    ret
  %b = sext <16 x i8> %a to <16 x i16>
  store <16 x i16>%b, ptr %out
  ret void
}

; NOTE: Extra 'add' is to prevent the extend being combined with the load.
define void @sext_v32i8_v32i16(ptr %in, ptr %out) #0 {
; VBITS_GE_256-LABEL: sext_v32i8_v32i16:
; VBITS_GE_256:       // %bb.0:
; VBITS_GE_256-NEXT:    ptrue p0.b, vl32
; VBITS_GE_256-NEXT:    mov x8, #16 // =0x10
; VBITS_GE_256-NEXT:    ld1b { z0.b }, p0/z, [x0]
; VBITS_GE_256-NEXT:    ptrue p0.h, vl16
; VBITS_GE_256-NEXT:    add z0.b, z0.b, z0.b
; VBITS_GE_256-NEXT:    sunpklo z1.h, z0.b
; VBITS_GE_256-NEXT:    ext z0.b, z0.b, z0.b, #16
; VBITS_GE_256-NEXT:    sunpklo z0.h, z0.b
; VBITS_GE_256-NEXT:    st1h { z1.h }, p0, [x1]
; VBITS_GE_256-NEXT:    st1h { z0.h }, p0, [x1, x8, lsl #1]
; VBITS_GE_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: sext_v32i8_v32i16:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    ptrue p0.b, vl32
; VBITS_GE_512-NEXT:    ld1b { z0.b }, p0/z, [x0]
; VBITS_GE_512-NEXT:    ptrue p0.h, vl32
; VBITS_GE_512-NEXT:    add z0.b, z0.b, z0.b
; VBITS_GE_512-NEXT:    sunpklo z0.h, z0.b
; VBITS_GE_512-NEXT:    st1h { z0.h }, p0, [x1]
; VBITS_GE_512-NEXT:    ret
  %a = load <32 x i8>, ptr %in
  %b = add <32 x i8> %a, %a
  %c = sext <32 x i8> %b to <32 x i16>
  store <32 x i16> %c, ptr %out
  ret void
}

define void @sext_v64i8_v64i16(ptr %in, ptr %out) vscale_range(8,0) #0 {
; CHECK-LABEL: sext_v64i8_v64i16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.b, vl64
; CHECK-NEXT:    ld1b { z0.b }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.h, vl64
; CHECK-NEXT:    add z0.b, z0.b, z0.b
; CHECK-NEXT:    sunpklo z0.h, z0.b
; CHECK-NEXT:    st1h { z0.h }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <64 x i8>, ptr %in
  %b = add <64 x i8> %a, %a
  %c = sext <64 x i8> %b to <64 x i16>
  store <64 x i16> %c, ptr %out
  ret void
}

define void @sext_v128i8_v128i16(ptr %in, ptr %out) vscale_range(16,0) #0 {
; CHECK-LABEL: sext_v128i8_v128i16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.b, vl128
; CHECK-NEXT:    ld1b { z0.b }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.h, vl128
; CHECK-NEXT:    add z0.b, z0.b, z0.b
; CHECK-NEXT:    sunpklo z0.h, z0.b
; CHECK-NEXT:    st1h { z0.h }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <128 x i8>, ptr %in
  %b = add <128 x i8> %a, %a
  %c = sext <128 x i8> %b to <128 x i16>
  store <128 x i16> %c, ptr %out
  ret void
}

;
; sext i8 -> i32
;

define void @sext_v8i8_v8i32(<8 x i8> %a, ptr %out) vscale_range(2,0) #0 {
; CHECK-LABEL: sext_v8i8_v8i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    sunpklo z0.h, z0.b
; CHECK-NEXT:    ptrue p0.s, vl8
; CHECK-NEXT:    sunpklo z0.s, z0.h
; CHECK-NEXT:    st1w { z0.s }, p0, [x0]
; CHECK-NEXT:    ret
  %b = sext <8 x i8> %a to <8 x i32>
  store <8 x i32>%b, ptr %out
  ret void
}

define void @sext_v16i8_v16i32(<16 x i8> %a, ptr %out) #0 {
; VBITS_GE_256-LABEL: sext_v16i8_v16i32:
; VBITS_GE_256:       // %bb.0:
; VBITS_GE_256-NEXT:    ext v1.16b, v0.16b, v0.16b, #8
; VBITS_GE_256-NEXT:    sunpklo z0.h, z0.b
; VBITS_GE_256-NEXT:    mov x8, #8 // =0x8
; VBITS_GE_256-NEXT:    ptrue p0.s, vl8
; VBITS_GE_256-NEXT:    sunpklo z1.h, z1.b
; VBITS_GE_256-NEXT:    sunpklo z0.s, z0.h
; VBITS_GE_256-NEXT:    sunpklo z1.s, z1.h
; VBITS_GE_256-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_256-NEXT:    st1w { z1.s }, p0, [x0, x8, lsl #2]
; VBITS_GE_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: sext_v16i8_v16i32:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    sunpklo z0.h, z0.b
; VBITS_GE_512-NEXT:    ptrue p0.s, vl16
; VBITS_GE_512-NEXT:    sunpklo z0.s, z0.h
; VBITS_GE_512-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_512-NEXT:    ret
  %b = sext <16 x i8> %a to <16 x i32>
  store <16 x i32> %b, ptr %out
  ret void
}

define void @sext_v32i8_v32i32(ptr %in, ptr %out) vscale_range(8,0) #0 {
; CHECK-LABEL: sext_v32i8_v32i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.b, vl32
; CHECK-NEXT:    ld1b { z0.b }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.s, vl32
; CHECK-NEXT:    add z0.b, z0.b, z0.b
; CHECK-NEXT:    sunpklo z0.h, z0.b
; CHECK-NEXT:    sunpklo z0.s, z0.h
; CHECK-NEXT:    st1w { z0.s }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <32 x i8>, ptr %in
  %b = add <32 x i8> %a, %a
  %c = sext <32 x i8> %b to <32 x i32>
  store <32 x i32> %c, ptr %out
  ret void
}

define void @sext_v64i8_v64i32(ptr %in, ptr %out) vscale_range(16,0) #0 {
; CHECK-LABEL: sext_v64i8_v64i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.b, vl64
; CHECK-NEXT:    ld1b { z0.b }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.s, vl64
; CHECK-NEXT:    add z0.b, z0.b, z0.b
; CHECK-NEXT:    sunpklo z0.h, z0.b
; CHECK-NEXT:    sunpklo z0.s, z0.h
; CHECK-NEXT:    st1w { z0.s }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <64 x i8>, ptr %in
  %b = add <64 x i8> %a, %a
  %c = sext <64 x i8> %b to <64 x i32>
  store <64 x i32> %c, ptr %out
  ret void
}

;
; sext i8 -> i64
;

; NOTE: v4i8 is an unpacked typed stored within a v4i16 container. The sign
; extend is a two step process where the container is any_extend'd with the
; result feeding an inreg sign extend.
define void @sext_v4i8_v4i64(<4 x i8> %a, ptr %out) vscale_range(2,0) #0 {
; CHECK-LABEL: sext_v4i8_v4i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    sxtb z0.d, p0/m, z0.d
; CHECK-NEXT:    st1d { z0.d }, p0, [x0]
; CHECK-NEXT:    ret
  %b = sext <4 x i8> %a to <4 x i64>
  store <4 x i64>%b, ptr %out
  ret void
}

define void @sext_v8i8_v8i64(<8 x i8> %a, ptr %out) #0 {
; VBITS_GE_256-LABEL: sext_v8i8_v8i64:
; VBITS_GE_256:       // %bb.0:
; VBITS_GE_256-NEXT:    sshll v0.8h, v0.8b, #0
; VBITS_GE_256-NEXT:    ptrue p0.d, vl4
; VBITS_GE_256-NEXT:    mov x8, #4 // =0x4
; VBITS_GE_256-NEXT:    ext v1.16b, v0.16b, v0.16b, #8
; VBITS_GE_256-NEXT:    sunpklo z0.s, z0.h
; VBITS_GE_256-NEXT:    sunpklo z1.s, z1.h
; VBITS_GE_256-NEXT:    sunpklo z0.d, z0.s
; VBITS_GE_256-NEXT:    sunpklo z1.d, z1.s
; VBITS_GE_256-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_256-NEXT:    st1d { z1.d }, p0, [x0, x8, lsl #3]
; VBITS_GE_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: sext_v8i8_v8i64:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    sunpklo z0.h, z0.b
; VBITS_GE_512-NEXT:    ptrue p0.d, vl8
; VBITS_GE_512-NEXT:    sunpklo z0.s, z0.h
; VBITS_GE_512-NEXT:    sunpklo z0.d, z0.s
; VBITS_GE_512-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_512-NEXT:    ret
  %b = sext <8 x i8> %a to <8 x i64>
  store <8 x i64>%b, ptr %out
  ret void
}

define void @sext_v16i8_v16i64(<16 x i8> %a, ptr %out) vscale_range(8,0) #0 {
; CHECK-LABEL: sext_v16i8_v16i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    sunpklo z0.h, z0.b
; CHECK-NEXT:    ptrue p0.d, vl16
; CHECK-NEXT:    sunpklo z0.s, z0.h
; CHECK-NEXT:    sunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x0]
; CHECK-NEXT:    ret
  %b = sext <16 x i8> %a to <16 x i64>
  store <16 x i64> %b, ptr %out
  ret void
}

define void @sext_v32i8_v32i64(ptr %in, ptr %out) vscale_range(16,0) #0 {
; CHECK-LABEL: sext_v32i8_v32i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.b, vl32
; CHECK-NEXT:    ld1b { z0.b }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.d, vl32
; CHECK-NEXT:    add z0.b, z0.b, z0.b
; CHECK-NEXT:    sunpklo z0.h, z0.b
; CHECK-NEXT:    sunpklo z0.s, z0.h
; CHECK-NEXT:    sunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <32 x i8>, ptr %in
  %b = add <32 x i8> %a, %a
  %c = sext <32 x i8> %b to <32 x i64>
  store <32 x i64> %c, ptr %out
  ret void
}

;
; sext i16 -> i32
;

define void @sext_v8i16_v8i32(<8 x i16> %a, ptr %out) vscale_range(2,0) #0 {
; CHECK-LABEL: sext_v8i16_v8i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    sunpklo z0.s, z0.h
; CHECK-NEXT:    ptrue p0.s, vl8
; CHECK-NEXT:    st1w { z0.s }, p0, [x0]
; CHECK-NEXT:    ret
  %b = sext <8 x i16> %a to <8 x i32>
  store <8 x i32>%b, ptr %out
  ret void
}

define void @sext_v16i16_v16i32(ptr %in, ptr %out) #0 {
; VBITS_GE_256-LABEL: sext_v16i16_v16i32:
; VBITS_GE_256:       // %bb.0:
; VBITS_GE_256-NEXT:    ptrue p0.h, vl16
; VBITS_GE_256-NEXT:    mov x8, #8 // =0x8
; VBITS_GE_256-NEXT:    ld1h { z0.h }, p0/z, [x0]
; VBITS_GE_256-NEXT:    ptrue p0.s, vl8
; VBITS_GE_256-NEXT:    add z0.h, z0.h, z0.h
; VBITS_GE_256-NEXT:    sunpklo z1.s, z0.h
; VBITS_GE_256-NEXT:    ext z0.b, z0.b, z0.b, #16
; VBITS_GE_256-NEXT:    sunpklo z0.s, z0.h
; VBITS_GE_256-NEXT:    st1w { z1.s }, p0, [x1]
; VBITS_GE_256-NEXT:    st1w { z0.s }, p0, [x1, x8, lsl #2]
; VBITS_GE_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: sext_v16i16_v16i32:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    ptrue p0.h, vl16
; VBITS_GE_512-NEXT:    ld1h { z0.h }, p0/z, [x0]
; VBITS_GE_512-NEXT:    ptrue p0.s, vl16
; VBITS_GE_512-NEXT:    add z0.h, z0.h, z0.h
; VBITS_GE_512-NEXT:    sunpklo z0.s, z0.h
; VBITS_GE_512-NEXT:    st1w { z0.s }, p0, [x1]
; VBITS_GE_512-NEXT:    ret
  %a = load <16 x i16>, ptr %in
  %b = add <16 x i16> %a, %a
  %c = sext <16 x i16> %b to <16 x i32>
  store <16 x i32> %c, ptr %out
  ret void
}

define void @sext_v32i16_v32i32(ptr %in, ptr %out) vscale_range(8,0) #0 {
; CHECK-LABEL: sext_v32i16_v32i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.h, vl32
; CHECK-NEXT:    ld1h { z0.h }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.s, vl32
; CHECK-NEXT:    add z0.h, z0.h, z0.h
; CHECK-NEXT:    sunpklo z0.s, z0.h
; CHECK-NEXT:    st1w { z0.s }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <32 x i16>, ptr %in
  %b = add <32 x i16> %a, %a
  %c = sext <32 x i16> %b to <32 x i32>
  store <32 x i32> %c, ptr %out
  ret void
}

define void @sext_v64i16_v64i32(ptr %in, ptr %out) vscale_range(16,0) #0 {
; CHECK-LABEL: sext_v64i16_v64i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.h, vl64
; CHECK-NEXT:    ld1h { z0.h }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.s, vl64
; CHECK-NEXT:    add z0.h, z0.h, z0.h
; CHECK-NEXT:    sunpklo z0.s, z0.h
; CHECK-NEXT:    st1w { z0.s }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <64 x i16>, ptr %in
  %b = add <64 x i16> %a, %a
  %c = sext <64 x i16> %b to <64 x i32>
  store <64 x i32> %c, ptr %out
  ret void
}

;
; sext i16 -> i64
;

define void @sext_v4i16_v4i64(<4 x i16> %a, ptr %out) vscale_range(2,0) #0 {
; CHECK-LABEL: sext_v4i16_v4i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    sunpklo z0.s, z0.h
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    sunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x0]
; CHECK-NEXT:    ret
  %b = sext <4 x i16> %a to <4 x i64>
  store <4 x i64>%b, ptr %out
  ret void
}

define void @sext_v8i16_v8i64(<8 x i16> %a, ptr %out) #0 {
; VBITS_GE_256-LABEL: sext_v8i16_v8i64:
; VBITS_GE_256:       // %bb.0:
; VBITS_GE_256-NEXT:    ext v1.16b, v0.16b, v0.16b, #8
; VBITS_GE_256-NEXT:    sunpklo z0.s, z0.h
; VBITS_GE_256-NEXT:    mov x8, #4 // =0x4
; VBITS_GE_256-NEXT:    ptrue p0.d, vl4
; VBITS_GE_256-NEXT:    sunpklo z1.s, z1.h
; VBITS_GE_256-NEXT:    sunpklo z0.d, z0.s
; VBITS_GE_256-NEXT:    sunpklo z1.d, z1.s
; VBITS_GE_256-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_256-NEXT:    st1d { z1.d }, p0, [x0, x8, lsl #3]
; VBITS_GE_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: sext_v8i16_v8i64:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    sunpklo z0.s, z0.h
; VBITS_GE_512-NEXT:    ptrue p0.d, vl8
; VBITS_GE_512-NEXT:    sunpklo z0.d, z0.s
; VBITS_GE_512-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_512-NEXT:    ret
  %b = sext <8 x i16> %a to <8 x i64>
  store <8 x i64>%b, ptr %out
  ret void
}

define void @sext_v16i16_v16i64(ptr %in, ptr %out) vscale_range(8,0) #0 {
; CHECK-LABEL: sext_v16i16_v16i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.h, vl16
; CHECK-NEXT:    ld1h { z0.h }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.d, vl16
; CHECK-NEXT:    add z0.h, z0.h, z0.h
; CHECK-NEXT:    sunpklo z0.s, z0.h
; CHECK-NEXT:    sunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <16 x i16>, ptr %in
  %b = add <16 x i16> %a, %a
  %c = sext <16 x i16> %b to <16 x i64>
  store <16 x i64> %c, ptr %out
  ret void
}

define void @sext_v32i16_v32i64(ptr %in, ptr %out) vscale_range(16,0) #0 {
; CHECK-LABEL: sext_v32i16_v32i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.h, vl32
; CHECK-NEXT:    ld1h { z0.h }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.d, vl32
; CHECK-NEXT:    add z0.h, z0.h, z0.h
; CHECK-NEXT:    sunpklo z0.s, z0.h
; CHECK-NEXT:    sunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <32 x i16>, ptr %in
  %b = add <32 x i16> %a, %a
  %c = sext <32 x i16> %b to <32 x i64>
  store <32 x i64> %c, ptr %out
  ret void
}

;
; sext i32 -> i64
;

define void @sext_v4i32_v4i64(<4 x i32> %a, ptr %out) vscale_range(2,0) #0 {
; CHECK-LABEL: sext_v4i32_v4i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    sunpklo z0.d, z0.s
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    st1d { z0.d }, p0, [x0]
; CHECK-NEXT:    ret
  %b = sext <4 x i32> %a to <4 x i64>
  store <4 x i64>%b, ptr %out
  ret void
}

define void @sext_v8i32_v8i64(ptr %in, ptr %out) #0 {
; VBITS_GE_256-LABEL: sext_v8i32_v8i64:
; VBITS_GE_256:       // %bb.0:
; VBITS_GE_256-NEXT:    ptrue p0.s, vl8
; VBITS_GE_256-NEXT:    mov x8, #4 // =0x4
; VBITS_GE_256-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_256-NEXT:    ptrue p0.d, vl4
; VBITS_GE_256-NEXT:    add z0.s, z0.s, z0.s
; VBITS_GE_256-NEXT:    sunpklo z1.d, z0.s
; VBITS_GE_256-NEXT:    ext z0.b, z0.b, z0.b, #16
; VBITS_GE_256-NEXT:    sunpklo z0.d, z0.s
; VBITS_GE_256-NEXT:    st1d { z1.d }, p0, [x1]
; VBITS_GE_256-NEXT:    st1d { z0.d }, p0, [x1, x8, lsl #3]
; VBITS_GE_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: sext_v8i32_v8i64:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    ptrue p0.s, vl8
; VBITS_GE_512-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_512-NEXT:    ptrue p0.d, vl8
; VBITS_GE_512-NEXT:    add z0.s, z0.s, z0.s
; VBITS_GE_512-NEXT:    sunpklo z0.d, z0.s
; VBITS_GE_512-NEXT:    st1d { z0.d }, p0, [x1]
; VBITS_GE_512-NEXT:    ret
  %a = load <8 x i32>, ptr %in
  %b = add <8 x i32> %a, %a
  %c = sext <8 x i32> %b to <8 x i64>
  store <8 x i64> %c, ptr %out
  ret void
}

define void @sext_v16i32_v16i64(ptr %in, ptr %out) vscale_range(8,0) #0 {
; CHECK-LABEL: sext_v16i32_v16i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.s, vl16
; CHECK-NEXT:    ld1w { z0.s }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.d, vl16
; CHECK-NEXT:    add z0.s, z0.s, z0.s
; CHECK-NEXT:    sunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <16 x i32>, ptr %in
  %b = add <16 x i32> %a, %a
  %c = sext <16 x i32> %b to <16 x i64>
  store <16 x i64> %c, ptr %out
  ret void
}

define void @sext_v32i32_v32i64(ptr %in, ptr %out) vscale_range(16,0) #0 {
; CHECK-LABEL: sext_v32i32_v32i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.s, vl32
; CHECK-NEXT:    ld1w { z0.s }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.d, vl32
; CHECK-NEXT:    add z0.s, z0.s, z0.s
; CHECK-NEXT:    sunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <32 x i32>, ptr %in
  %b = add <32 x i32> %a, %a
  %c = sext <32 x i32> %b to <32 x i64>
  store <32 x i64> %c, ptr %out
  ret void
}

;
; zext i8 -> i16
;

define void @zext_v16i8_v16i16(<16 x i8> %a, ptr %out) vscale_range(2,0) #0 {
; CHECK-LABEL: zext_v16i8_v16i16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    uunpklo z0.h, z0.b
; CHECK-NEXT:    ptrue p0.h, vl16
; CHECK-NEXT:    st1h { z0.h }, p0, [x0]
; CHECK-NEXT:    ret
  %b = zext <16 x i8> %a to <16 x i16>
  store <16 x i16>%b, ptr %out
  ret void
}

; NOTE: Extra 'add' is to prevent the extend being combined with the load.
define void @zext_v32i8_v32i16(ptr %in, ptr %out) #0 {
; VBITS_GE_256-LABEL: zext_v32i8_v32i16:
; VBITS_GE_256:       // %bb.0:
; VBITS_GE_256-NEXT:    ptrue p0.b, vl32
; VBITS_GE_256-NEXT:    mov x8, #16 // =0x10
; VBITS_GE_256-NEXT:    ld1b { z0.b }, p0/z, [x0]
; VBITS_GE_256-NEXT:    ptrue p0.h, vl16
; VBITS_GE_256-NEXT:    add z0.b, z0.b, z0.b
; VBITS_GE_256-NEXT:    uunpklo z1.h, z0.b
; VBITS_GE_256-NEXT:    ext z0.b, z0.b, z0.b, #16
; VBITS_GE_256-NEXT:    uunpklo z0.h, z0.b
; VBITS_GE_256-NEXT:    st1h { z1.h }, p0, [x1]
; VBITS_GE_256-NEXT:    st1h { z0.h }, p0, [x1, x8, lsl #1]
; VBITS_GE_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: zext_v32i8_v32i16:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    ptrue p0.b, vl32
; VBITS_GE_512-NEXT:    ld1b { z0.b }, p0/z, [x0]
; VBITS_GE_512-NEXT:    ptrue p0.h, vl32
; VBITS_GE_512-NEXT:    add z0.b, z0.b, z0.b
; VBITS_GE_512-NEXT:    uunpklo z0.h, z0.b
; VBITS_GE_512-NEXT:    st1h { z0.h }, p0, [x1]
; VBITS_GE_512-NEXT:    ret
  %a = load <32 x i8>, ptr %in
  %b = add <32 x i8> %a, %a
  %c = zext <32 x i8> %b to <32 x i16>
  store <32 x i16> %c, ptr %out
  ret void
}

define void @zext_v64i8_v64i16(ptr %in, ptr %out) vscale_range(8,0) #0 {
; CHECK-LABEL: zext_v64i8_v64i16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.b, vl64
; CHECK-NEXT:    ld1b { z0.b }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.h, vl64
; CHECK-NEXT:    add z0.b, z0.b, z0.b
; CHECK-NEXT:    uunpklo z0.h, z0.b
; CHECK-NEXT:    st1h { z0.h }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <64 x i8>, ptr %in
  %b = add <64 x i8> %a, %a
  %c = zext <64 x i8> %b to <64 x i16>
  store <64 x i16> %c, ptr %out
  ret void
}

define void @zext_v128i8_v128i16(ptr %in, ptr %out) vscale_range(16,0) #0 {
; CHECK-LABEL: zext_v128i8_v128i16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.b, vl128
; CHECK-NEXT:    ld1b { z0.b }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.h, vl128
; CHECK-NEXT:    add z0.b, z0.b, z0.b
; CHECK-NEXT:    uunpklo z0.h, z0.b
; CHECK-NEXT:    st1h { z0.h }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <128 x i8>, ptr %in
  %b = add <128 x i8> %a, %a
  %c = zext <128 x i8> %b to <128 x i16>
  store <128 x i16> %c, ptr %out
  ret void
}

;
; zext i8 -> i32
;

define void @zext_v8i8_v8i32(<8 x i8> %a, ptr %out) vscale_range(2,0) #0 {
; CHECK-LABEL: zext_v8i8_v8i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    uunpklo z0.h, z0.b
; CHECK-NEXT:    ptrue p0.s, vl8
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    st1w { z0.s }, p0, [x0]
; CHECK-NEXT:    ret
  %b = zext <8 x i8> %a to <8 x i32>
  store <8 x i32>%b, ptr %out
  ret void
}

define void @zext_v16i8_v16i32(<16 x i8> %a, ptr %out) #0 {
; VBITS_GE_256-LABEL: zext_v16i8_v16i32:
; VBITS_GE_256:       // %bb.0:
; VBITS_GE_256-NEXT:    ext v1.16b, v0.16b, v0.16b, #8
; VBITS_GE_256-NEXT:    uunpklo z0.h, z0.b
; VBITS_GE_256-NEXT:    mov x8, #8 // =0x8
; VBITS_GE_256-NEXT:    ptrue p0.s, vl8
; VBITS_GE_256-NEXT:    uunpklo z1.h, z1.b
; VBITS_GE_256-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_256-NEXT:    uunpklo z1.s, z1.h
; VBITS_GE_256-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_256-NEXT:    st1w { z1.s }, p0, [x0, x8, lsl #2]
; VBITS_GE_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: zext_v16i8_v16i32:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    uunpklo z0.h, z0.b
; VBITS_GE_512-NEXT:    ptrue p0.s, vl16
; VBITS_GE_512-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_512-NEXT:    st1w { z0.s }, p0, [x0]
; VBITS_GE_512-NEXT:    ret
  %b = zext <16 x i8> %a to <16 x i32>
  store <16 x i32> %b, ptr %out
  ret void
}

define void @zext_v32i8_v32i32(ptr %in, ptr %out) vscale_range(8,0) #0 {
; CHECK-LABEL: zext_v32i8_v32i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.b, vl32
; CHECK-NEXT:    ld1b { z0.b }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.s, vl32
; CHECK-NEXT:    add z0.b, z0.b, z0.b
; CHECK-NEXT:    uunpklo z0.h, z0.b
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    st1w { z0.s }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <32 x i8>, ptr %in
  %b = add <32 x i8> %a, %a
  %c = zext <32 x i8> %b to <32 x i32>
  store <32 x i32> %c, ptr %out
  ret void
}

define void @zext_v64i8_v64i32(ptr %in, ptr %out) vscale_range(16,0) #0 {
; CHECK-LABEL: zext_v64i8_v64i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.b, vl64
; CHECK-NEXT:    ld1b { z0.b }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.s, vl64
; CHECK-NEXT:    add z0.b, z0.b, z0.b
; CHECK-NEXT:    uunpklo z0.h, z0.b
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    st1w { z0.s }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <64 x i8>, ptr %in
  %b = add <64 x i8> %a, %a
  %c = zext <64 x i8> %b to <64 x i32>
  store <64 x i32> %c, ptr %out
  ret void
}

;
; zext i8 -> i64
;

; NOTE: v4i8 is an unpacked typed stored within a v4i16 container. The zero
; extend is a two step process where the container is zero_extend_inreg'd with
; the result feeding a normal zero extend from halfs to doublewords.
define void @zext_v4i8_v4i64(<4 x i8> %a, ptr %out) vscale_range(2,0) #0 {
; CHECK-LABEL: zext_v4i8_v4i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    bic v0.4h, #255, lsl #8
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x0]
; CHECK-NEXT:    ret
  %b = zext <4 x i8> %a to <4 x i64>
  store <4 x i64>%b, ptr %out
  ret void
}

define void @zext_v8i8_v8i64(<8 x i8> %a, ptr %out) #0 {
; VBITS_GE_256-LABEL: zext_v8i8_v8i64:
; VBITS_GE_256:       // %bb.0:
; VBITS_GE_256-NEXT:    ushll v0.8h, v0.8b, #0
; VBITS_GE_256-NEXT:    ptrue p0.d, vl4
; VBITS_GE_256-NEXT:    mov x8, #4 // =0x4
; VBITS_GE_256-NEXT:    ext v1.16b, v0.16b, v0.16b, #8
; VBITS_GE_256-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_256-NEXT:    uunpklo z1.s, z1.h
; VBITS_GE_256-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_256-NEXT:    uunpklo z1.d, z1.s
; VBITS_GE_256-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_256-NEXT:    st1d { z1.d }, p0, [x0, x8, lsl #3]
; VBITS_GE_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: zext_v8i8_v8i64:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    uunpklo z0.h, z0.b
; VBITS_GE_512-NEXT:    ptrue p0.d, vl8
; VBITS_GE_512-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_512-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_512-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_512-NEXT:    ret
  %b = zext <8 x i8> %a to <8 x i64>
  store <8 x i64>%b, ptr %out
  ret void
}

define void @zext_v16i8_v16i64(<16 x i8> %a, ptr %out) vscale_range(8,0) #0 {
; CHECK-LABEL: zext_v16i8_v16i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    uunpklo z0.h, z0.b
; CHECK-NEXT:    ptrue p0.d, vl16
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x0]
; CHECK-NEXT:    ret
  %b = zext <16 x i8> %a to <16 x i64>
  store <16 x i64> %b, ptr %out
  ret void
}

define void @zext_v32i8_v32i64(ptr %in, ptr %out) vscale_range(16,0) #0 {
; CHECK-LABEL: zext_v32i8_v32i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.b, vl32
; CHECK-NEXT:    ld1b { z0.b }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.d, vl32
; CHECK-NEXT:    add z0.b, z0.b, z0.b
; CHECK-NEXT:    uunpklo z0.h, z0.b
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <32 x i8>, ptr %in
  %b = add <32 x i8> %a, %a
  %c = zext <32 x i8> %b to <32 x i64>
  store <32 x i64> %c, ptr %out
  ret void
}

;
; zext i16 -> i32
;

define void @zext_v8i16_v8i32(<8 x i16> %a, ptr %out) vscale_range(2,0) #0 {
; CHECK-LABEL: zext_v8i16_v8i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    ptrue p0.s, vl8
; CHECK-NEXT:    st1w { z0.s }, p0, [x0]
; CHECK-NEXT:    ret
  %b = zext <8 x i16> %a to <8 x i32>
  store <8 x i32>%b, ptr %out
  ret void
}

define void @zext_v16i16_v16i32(ptr %in, ptr %out) #0 {
; VBITS_GE_256-LABEL: zext_v16i16_v16i32:
; VBITS_GE_256:       // %bb.0:
; VBITS_GE_256-NEXT:    ptrue p0.h, vl16
; VBITS_GE_256-NEXT:    mov x8, #8 // =0x8
; VBITS_GE_256-NEXT:    ld1h { z0.h }, p0/z, [x0]
; VBITS_GE_256-NEXT:    ptrue p0.s, vl8
; VBITS_GE_256-NEXT:    add z0.h, z0.h, z0.h
; VBITS_GE_256-NEXT:    uunpklo z1.s, z0.h
; VBITS_GE_256-NEXT:    ext z0.b, z0.b, z0.b, #16
; VBITS_GE_256-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_256-NEXT:    st1w { z1.s }, p0, [x1]
; VBITS_GE_256-NEXT:    st1w { z0.s }, p0, [x1, x8, lsl #2]
; VBITS_GE_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: zext_v16i16_v16i32:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    ptrue p0.h, vl16
; VBITS_GE_512-NEXT:    ld1h { z0.h }, p0/z, [x0]
; VBITS_GE_512-NEXT:    ptrue p0.s, vl16
; VBITS_GE_512-NEXT:    add z0.h, z0.h, z0.h
; VBITS_GE_512-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_512-NEXT:    st1w { z0.s }, p0, [x1]
; VBITS_GE_512-NEXT:    ret
  %a = load <16 x i16>, ptr %in
  %b = add <16 x i16> %a, %a
  %c = zext <16 x i16> %b to <16 x i32>
  store <16 x i32> %c, ptr %out
  ret void
}

define void @zext_v32i16_v32i32(ptr %in, ptr %out) vscale_range(8,0) #0 {
; CHECK-LABEL: zext_v32i16_v32i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.h, vl32
; CHECK-NEXT:    ld1h { z0.h }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.s, vl32
; CHECK-NEXT:    add z0.h, z0.h, z0.h
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    st1w { z0.s }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <32 x i16>, ptr %in
  %b = add <32 x i16> %a, %a
  %c = zext <32 x i16> %b to <32 x i32>
  store <32 x i32> %c, ptr %out
  ret void
}

define void @zext_v64i16_v64i32(ptr %in, ptr %out) vscale_range(16,0) #0 {
; CHECK-LABEL: zext_v64i16_v64i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.h, vl64
; CHECK-NEXT:    ld1h { z0.h }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.s, vl64
; CHECK-NEXT:    add z0.h, z0.h, z0.h
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    st1w { z0.s }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <64 x i16>, ptr %in
  %b = add <64 x i16> %a, %a
  %c = zext <64 x i16> %b to <64 x i32>
  store <64 x i32> %c, ptr %out
  ret void
}

;
; zext i16 -> i64
;

define void @zext_v4i16_v4i64(<4 x i16> %a, ptr %out) vscale_range(2,0) #0 {
; CHECK-LABEL: zext_v4i16_v4i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x0]
; CHECK-NEXT:    ret
  %b = zext <4 x i16> %a to <4 x i64>
  store <4 x i64>%b, ptr %out
  ret void
}

define void @zext_v8i16_v8i64(<8 x i16> %a, ptr %out) #0 {
; VBITS_GE_256-LABEL: zext_v8i16_v8i64:
; VBITS_GE_256:       // %bb.0:
; VBITS_GE_256-NEXT:    ext v1.16b, v0.16b, v0.16b, #8
; VBITS_GE_256-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_256-NEXT:    mov x8, #4 // =0x4
; VBITS_GE_256-NEXT:    ptrue p0.d, vl4
; VBITS_GE_256-NEXT:    uunpklo z1.s, z1.h
; VBITS_GE_256-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_256-NEXT:    uunpklo z1.d, z1.s
; VBITS_GE_256-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_256-NEXT:    st1d { z1.d }, p0, [x0, x8, lsl #3]
; VBITS_GE_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: zext_v8i16_v8i64:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    uunpklo z0.s, z0.h
; VBITS_GE_512-NEXT:    ptrue p0.d, vl8
; VBITS_GE_512-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_512-NEXT:    st1d { z0.d }, p0, [x0]
; VBITS_GE_512-NEXT:    ret
  %b = zext <8 x i16> %a to <8 x i64>
  store <8 x i64>%b, ptr %out
  ret void
}

define void @zext_v16i16_v16i64(ptr %in, ptr %out) vscale_range(8,0) #0 {
; CHECK-LABEL: zext_v16i16_v16i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.h, vl16
; CHECK-NEXT:    ld1h { z0.h }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.d, vl16
; CHECK-NEXT:    add z0.h, z0.h, z0.h
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <16 x i16>, ptr %in
  %b = add <16 x i16> %a, %a
  %c = zext <16 x i16> %b to <16 x i64>
  store <16 x i64> %c, ptr %out
  ret void
}

define void @zext_v32i16_v32i64(ptr %in, ptr %out) vscale_range(16,0) #0 {
; CHECK-LABEL: zext_v32i16_v32i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.h, vl32
; CHECK-NEXT:    ld1h { z0.h }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.d, vl32
; CHECK-NEXT:    add z0.h, z0.h, z0.h
; CHECK-NEXT:    uunpklo z0.s, z0.h
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <32 x i16>, ptr %in
  %b = add <32 x i16> %a, %a
  %c = zext <32 x i16> %b to <32 x i64>
  store <32 x i64> %c, ptr %out
  ret void
}

;
; zext i32 -> i64
;

define void @zext_v4i32_v4i64(<4 x i32> %a, ptr %out) vscale_range(2,0) #0 {
; CHECK-LABEL: zext_v4i32_v4i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    ptrue p0.d, vl4
; CHECK-NEXT:    st1d { z0.d }, p0, [x0]
; CHECK-NEXT:    ret
  %b = zext <4 x i32> %a to <4 x i64>
  store <4 x i64>%b, ptr %out
  ret void
}

define void @zext_v8i32_v8i64(ptr %in, ptr %out) #0 {
; VBITS_GE_256-LABEL: zext_v8i32_v8i64:
; VBITS_GE_256:       // %bb.0:
; VBITS_GE_256-NEXT:    ptrue p0.s, vl8
; VBITS_GE_256-NEXT:    mov x8, #4 // =0x4
; VBITS_GE_256-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_256-NEXT:    ptrue p0.d, vl4
; VBITS_GE_256-NEXT:    add z0.s, z0.s, z0.s
; VBITS_GE_256-NEXT:    uunpklo z1.d, z0.s
; VBITS_GE_256-NEXT:    ext z0.b, z0.b, z0.b, #16
; VBITS_GE_256-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_256-NEXT:    st1d { z1.d }, p0, [x1]
; VBITS_GE_256-NEXT:    st1d { z0.d }, p0, [x1, x8, lsl #3]
; VBITS_GE_256-NEXT:    ret
;
; VBITS_GE_512-LABEL: zext_v8i32_v8i64:
; VBITS_GE_512:       // %bb.0:
; VBITS_GE_512-NEXT:    ptrue p0.s, vl8
; VBITS_GE_512-NEXT:    ld1w { z0.s }, p0/z, [x0]
; VBITS_GE_512-NEXT:    ptrue p0.d, vl8
; VBITS_GE_512-NEXT:    add z0.s, z0.s, z0.s
; VBITS_GE_512-NEXT:    uunpklo z0.d, z0.s
; VBITS_GE_512-NEXT:    st1d { z0.d }, p0, [x1]
; VBITS_GE_512-NEXT:    ret
  %a = load <8 x i32>, ptr %in
  %b = add <8 x i32> %a, %a
  %c = zext <8 x i32> %b to <8 x i64>
  store <8 x i64> %c, ptr %out
  ret void
}

define void @zext_v16i32_v16i64(ptr %in, ptr %out) vscale_range(8,0) #0 {
; CHECK-LABEL: zext_v16i32_v16i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.s, vl16
; CHECK-NEXT:    ld1w { z0.s }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.d, vl16
; CHECK-NEXT:    add z0.s, z0.s, z0.s
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <16 x i32>, ptr %in
  %b = add <16 x i32> %a, %a
  %c = zext <16 x i32> %b to <16 x i64>
  store <16 x i64> %c, ptr %out
  ret void
}

define void @zext_v32i32_v32i64(ptr %in, ptr %out) vscale_range(16,0) #0 {
; CHECK-LABEL: zext_v32i32_v32i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.s, vl32
; CHECK-NEXT:    ld1w { z0.s }, p0/z, [x0]
; CHECK-NEXT:    ptrue p0.d, vl32
; CHECK-NEXT:    add z0.s, z0.s, z0.s
; CHECK-NEXT:    uunpklo z0.d, z0.s
; CHECK-NEXT:    st1d { z0.d }, p0, [x1]
; CHECK-NEXT:    ret
  %a = load <32 x i32>, ptr %in
  %b = add <32 x i32> %a, %a
  %c = zext <32 x i32> %b to <32 x i64>
  store <32 x i64> %c, ptr %out
  ret void
}

attributes #0 = { nounwind "target-features"="+sve" }
