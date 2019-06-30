; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=aarch64-- | FileCheck %s

; CodeGenPrepare is expected to form overflow intrinsics to improve DAG/isel.

define i1 @usubo_ult_i64(i64 %x, i64 %y, i64* %p) nounwind {
; CHECK-LABEL: usubo_ult_i64:
; CHECK:       // %bb.0:
; CHECK-NEXT:    subs x8, x0, x1
; CHECK-NEXT:    cset w0, lo
; CHECK-NEXT:    str x8, [x2]
; CHECK-NEXT:    ret
  %s = sub i64 %x, %y
  store i64 %s, i64* %p
  %ov = icmp ult i64 %x, %y
  ret i1 %ov
}

; Verify insertion point for single-BB. Toggle predicate.

define i1 @usubo_ugt_i32(i32 %x, i32 %y, i32* %p) nounwind {
; CHECK-LABEL: usubo_ugt_i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    cmp w1, w0
; CHECK-NEXT:    cset w8, hi
; CHECK-NEXT:    sub w9, w0, w1
; CHECK-NEXT:    mov w0, w8
; CHECK-NEXT:    str w9, [x2]
; CHECK-NEXT:    ret
  %ov = icmp ugt i32 %y, %x
  %s = sub i32 %x, %y
  store i32 %s, i32* %p
  ret i1 %ov
}

; Constant operand should match.

define i1 @usubo_ugt_constant_op0_i8(i8 %x, i8* %p) nounwind {
; CHECK-LABEL: usubo_ugt_constant_op0_i8:
; CHECK:       // %bb.0:
; CHECK-NEXT:    and w8, w0, #0xff
; CHECK-NEXT:    mov w9, #42
; CHECK-NEXT:    cmp w8, #42 // =42
; CHECK-NEXT:    sub w9, w9, w0
; CHECK-NEXT:    cset w0, hi
; CHECK-NEXT:    strb w9, [x1]
; CHECK-NEXT:    ret
  %s = sub i8 42, %x
  %ov = icmp ugt i8 %x, 42
  store i8 %s, i8* %p
  ret i1 %ov
}

; Compare with constant operand 0 is canonicalized by commuting, but verify match for non-canonical form.

define i1 @usubo_ult_constant_op0_i16(i16 %x, i16* %p) nounwind {
; CHECK-LABEL: usubo_ult_constant_op0_i16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    and w8, w0, #0xffff
; CHECK-NEXT:    mov w9, #43
; CHECK-NEXT:    cmp w8, #43 // =43
; CHECK-NEXT:    sub w9, w9, w0
; CHECK-NEXT:    cset w0, hi
; CHECK-NEXT:    strh w9, [x1]
; CHECK-NEXT:    ret
  %s = sub i16 43, %x
  %ov = icmp ult i16 43, %x
  store i16 %s, i16* %p
  ret i1 %ov
}

; Subtract with constant operand 1 is canonicalized to add.

define i1 @usubo_ult_constant_op1_i16(i16 %x, i16* %p) nounwind {
; CHECK-LABEL: usubo_ult_constant_op1_i16:
; CHECK:       // %bb.0:
; CHECK-NEXT:    and w8, w0, #0xffff
; CHECK-NEXT:    cmp w8, #44 // =44
; CHECK-NEXT:    sub w9, w0, #44 // =44
; CHECK-NEXT:    cset w0, lo
; CHECK-NEXT:    strh w9, [x1]
; CHECK-NEXT:    ret
  %s = add i16 %x, -44
  %ov = icmp ult i16 %x, 44
  store i16 %s, i16* %p
  ret i1 %ov
}

define i1 @usubo_ugt_constant_op1_i8(i8 %x, i8* %p) nounwind {
; CHECK-LABEL: usubo_ugt_constant_op1_i8:
; CHECK:       // %bb.0:
; CHECK-NEXT:    and w8, w0, #0xff
; CHECK-NEXT:    cmp w8, #45 // =45
; CHECK-NEXT:    cset w8, lo
; CHECK-NEXT:    sub w9, w0, #45 // =45
; CHECK-NEXT:    mov w0, w8
; CHECK-NEXT:    strb w9, [x1]
; CHECK-NEXT:    ret
  %ov = icmp ugt i8 45, %x
  %s = add i8 %x, -45
  store i8 %s, i8* %p
  ret i1 %ov
}

; Special-case: subtract 1 changes the compare predicate and constant.

define i1 @usubo_eq_constant1_op1_i32(i32 %x, i32* %p) nounwind {
; CHECK-LABEL: usubo_eq_constant1_op1_i32:
; CHECK:       // %bb.0:
; CHECK-NEXT:    cmp w0, #0 // =0
; CHECK-NEXT:    sub w8, w0, #1 // =1
; CHECK-NEXT:    cset w0, eq
; CHECK-NEXT:    str w8, [x1]
; CHECK-NEXT:    ret
  %s = add i32 %x, -1
  %ov = icmp eq i32 %x, 0
  store i32 %s, i32* %p
  ret i1 %ov
}

; Verify insertion point for multi-BB.

declare void @call(i1)

define i1 @usubo_ult_sub_dominates_i64(i64 %x, i64 %y, i64* %p, i1 %cond) nounwind {
; CHECK-LABEL: usubo_ult_sub_dominates_i64:
; CHECK:       // %bb.0: // %entry
; CHECK-NEXT:    tbz w3, #0, .LBB7_2
; CHECK-NEXT:  // %bb.1: // %t
; CHECK-NEXT:    subs x8, x0, x1
; CHECK-NEXT:    cset w0, lo
; CHECK-NEXT:    str x8, [x2]
; CHECK-NEXT:    ret
; CHECK-NEXT:  .LBB7_2: // %f
; CHECK-NEXT:    and w0, w3, #0x1
; CHECK-NEXT:    ret
entry:
  br i1 %cond, label %t, label %f

t:
  %s = sub i64 %x, %y
  store i64 %s, i64* %p
  br i1 %cond, label %end, label %f

f:
  ret i1 %cond

end:
  %ov = icmp ult i64 %x, %y
  ret i1 %ov
}

define i1 @usubo_ult_cmp_dominates_i64(i64 %x, i64 %y, i64* %p, i1 %cond) nounwind {
; CHECK-LABEL: usubo_ult_cmp_dominates_i64:
; CHECK:       // %bb.0: // %entry
; CHECK-NEXT:    str x22, [sp, #-48]! // 8-byte Folded Spill
; CHECK-NEXT:    stp x21, x20, [sp, #16] // 16-byte Folded Spill
; CHECK-NEXT:    mov w20, w3
; CHECK-NEXT:    stp x19, x30, [sp, #32] // 16-byte Folded Spill
; CHECK-NEXT:    tbz w3, #0, .LBB8_3
; CHECK-NEXT:  // %bb.1: // %t
; CHECK-NEXT:    cmp x0, x1
; CHECK-NEXT:    mov x22, x0
; CHECK-NEXT:    cset w0, lo
; CHECK-NEXT:    mov x19, x2
; CHECK-NEXT:    mov x21, x1
; CHECK-NEXT:    bl call
; CHECK-NEXT:    subs x8, x22, x21
; CHECK-NEXT:    b.hs .LBB8_3
; CHECK-NEXT:  // %bb.2: // %end
; CHECK-NEXT:    cset w0, lo
; CHECK-NEXT:    str x8, [x19]
; CHECK-NEXT:    b .LBB8_4
; CHECK-NEXT:  .LBB8_3: // %f
; CHECK-NEXT:    and w0, w20, #0x1
; CHECK-NEXT:  .LBB8_4: // %f
; CHECK-NEXT:    ldp x19, x30, [sp, #32] // 16-byte Folded Reload
; CHECK-NEXT:    ldp x21, x20, [sp, #16] // 16-byte Folded Reload
; CHECK-NEXT:    ldr x22, [sp], #48 // 8-byte Folded Reload
; CHECK-NEXT:    ret
entry:
  br i1 %cond, label %t, label %f

t:
  %ov = icmp ult i64 %x, %y
  call void @call(i1 %ov)
  br i1 %ov, label %end, label %f

f:
  ret i1 %cond

end:
  %s = sub i64 %x, %y
  store i64 %s, i64* %p
  ret i1 %ov
}

