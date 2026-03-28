@ Assembly ARMv7 gerado pelo compilador RPN
@ Target: CPUlator DE1-SoC v16.1  (ARMv7-A, Cortex-A9)
@ Para ver cada resultado pressione KEY0 no CPUlator
.syntax unified
.arch armv7-a
.fpu vfpv3-d16
.global _start
.text

_start:
@ aponta SP para area de stack VFP dedicada
LDR SP, =vfp_stack_top

@ limpa displays e LEDs na inicializacao
LDR r0, =0xFF200020
MOV r1, #0
STR r1, [r0]
LDR r0, =0xFF200030
STR r1, [r0]
LDR r0, =0xFF200000
STR r1, [r0]

@ ---- linha 1 ----
LDR r0, =val_3p0
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_2p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VADD.F64 d0, d0, d1
VPUSH {d0}
LDR r0, =val_4p0
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_5p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VMUL.F64 d0, d0, d1
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VADD.F64 d0, d0, d1
VPUSH {d0}
@ salva resultado da linha 1 em history[0]
VPOP {d0}
LDR r1, =history
VSTR d0, [r1]
VPUSH {d0}
@ === exibir resultado linha 1 nos displays ===
@ peek: VPOP para usar, VPUSH para restaurar ao final
VPOP {d0}
@ converte float64 -> inteiro com sinal em r6
VCVT.S32.F64 s0, d0
VMOV r6, s0
@ LEDs: exibe os 10 bits inferiores do valor inteiro
@ AND com 0xFF (bits 7-0) e depois isola bit 9 e 8 separadamente
@ para evitar constante 0x3FF que nao e encodavel como imediato ARM
LDR r4, =0xFF200000
AND r5, r6, #0xFF
@ bits 7-0
MOV r3, r6, LSR #8
@ desloca 8 para direita
AND r3, r3, #0x3
@ isola bits 9-8 (so 2 bits)
ORR r5, r5, r3, LSL #8
@ reconstroi os 10 bits em r5
STR r5, [r4]
@ trata sinal: r7=0 positivo, r7=1 negativo; r6 = abs(valor)
MOV r7, #0
CMP r6, #0
BGE dsp0_pos
RSB r6, r6, #0
MOV r7, #1
dsp0_pos:
@ digito 0
MOV r8, #0
dv0d0_loop:
  CMP r6, #10
  BLT dv0d0_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv0d0_loop
dv0d0_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r0, [r4, r10]
@ digito 1
MOV r8, #0
dv0d1_loop:
  CMP r6, #10
  BLT dv0d1_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv0d1_loop
dv0d1_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r1, [r4, r10]
@ digito 2
MOV r8, #0
dv0d2_loop:
  CMP r6, #10
  BLT dv0d2_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv0d2_loop
dv0d2_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r2, [r4, r10]
@ digito 3
MOV r8, #0
dv0d3_loop:
  CMP r6, #10
  BLT dv0d3_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv0d3_loop
dv0d3_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r3, [r4, r10]
@ digito 4
MOV r8, #0
dv0d4_loop:
  CMP r6, #10
  BLT dv0d4_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv0d4_loop
dv0d4_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r11, [r4, r10]
@ digito 5
MOV r8, #0
dv0d5_loop:
  CMP r6, #10
  BLT dv0d5_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv0d5_loop
dv0d5_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r12, [r4, r10]
CMP r7, #1
BNE dsp0_nosign
MOV r12, #0x40
@ codigo 7-seg do traco "-"
dsp0_nosign:
@ monta palavra para HEX3_HEX0: byte3=r3 byte2=r2 byte1=r1 byte0=r0
MOV r4, r0
ORR r4, r4, r1, LSL #8
ORR r4, r4, r2, LSL #16
ORR r4, r4, r3, LSL #24
LDR r5, =0xFF200020
STR r4, [r5]
@ monta palavra para HEX5_HEX4: byte1=r12 byte0=r11
MOV r4, r11
ORR r4, r4, r12, LSL #8
LDR r5, =0xFF200030
STR r4, [r5]
@ restaura d0 na pilha VFP
VPUSH {d0}
@ aguarda KEY0 para avancar para a linha 2
LDR r4, =0xFF200050
wpress0:
  LDR r5, [r4]
  TST r5, #1
  BNE wpress0
@ KEY0 solto (bit=1): continua aguardando
wrelease0:
  LDR r5, [r4]
  TST r5, #1
  BEQ wrelease0
@ KEY0 pressionado (bit=0): aguarda soltar
B _ap0
.ltorg
_ap0:

@ ---- linha 2 ----
LDR r0, =val_2p0
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_3p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VMUL.F64 d0, d0, d1
VPUSH {d0}
LDR r0, =val_4p0
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_5p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VMUL.F64 d0, d0, d1
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VDIV.F64 d0, d0, d1
VPUSH {d0}
@ salva resultado da linha 2 em history[1]
VPOP {d0}
LDR r1, =history
ADD r1, r1, #8
VSTR d0, [r1]
VPUSH {d0}
@ === exibir resultado linha 2 nos displays ===
@ peek: VPOP para usar, VPUSH para restaurar ao final
VPOP {d0}
@ converte float64 -> inteiro com sinal em r6
VCVT.S32.F64 s0, d0
VMOV r6, s0
@ LEDs: exibe os 10 bits inferiores do valor inteiro
@ AND com 0xFF (bits 7-0) e depois isola bit 9 e 8 separadamente
@ para evitar constante 0x3FF que nao e encodavel como imediato ARM
LDR r4, =0xFF200000
AND r5, r6, #0xFF
@ bits 7-0
MOV r3, r6, LSR #8
@ desloca 8 para direita
AND r3, r3, #0x3
@ isola bits 9-8 (so 2 bits)
ORR r5, r5, r3, LSL #8
@ reconstroi os 10 bits em r5
STR r5, [r4]
@ trata sinal: r7=0 positivo, r7=1 negativo; r6 = abs(valor)
MOV r7, #0
CMP r6, #0
BGE dsp1_pos
RSB r6, r6, #0
MOV r7, #1
dsp1_pos:
@ digito 0
MOV r8, #0
dv1d0_loop:
  CMP r6, #10
  BLT dv1d0_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv1d0_loop
dv1d0_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r0, [r4, r10]
@ digito 1
MOV r8, #0
dv1d1_loop:
  CMP r6, #10
  BLT dv1d1_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv1d1_loop
dv1d1_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r1, [r4, r10]
@ digito 2
MOV r8, #0
dv1d2_loop:
  CMP r6, #10
  BLT dv1d2_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv1d2_loop
dv1d2_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r2, [r4, r10]
@ digito 3
MOV r8, #0
dv1d3_loop:
  CMP r6, #10
  BLT dv1d3_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv1d3_loop
dv1d3_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r3, [r4, r10]
@ digito 4
MOV r8, #0
dv1d4_loop:
  CMP r6, #10
  BLT dv1d4_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv1d4_loop
dv1d4_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r11, [r4, r10]
@ digito 5
MOV r8, #0
dv1d5_loop:
  CMP r6, #10
  BLT dv1d5_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv1d5_loop
dv1d5_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r12, [r4, r10]
CMP r7, #1
BNE dsp1_nosign
MOV r12, #0x40
@ codigo 7-seg do traco "-"
dsp1_nosign:
@ monta palavra para HEX3_HEX0: byte3=r3 byte2=r2 byte1=r1 byte0=r0
MOV r4, r0
ORR r4, r4, r1, LSL #8
ORR r4, r4, r2, LSL #16
ORR r4, r4, r3, LSL #24
LDR r5, =0xFF200020
STR r4, [r5]
@ monta palavra para HEX5_HEX4: byte1=r12 byte0=r11
MOV r4, r11
ORR r4, r4, r12, LSL #8
LDR r5, =0xFF200030
STR r4, [r5]
@ restaura d0 na pilha VFP
VPUSH {d0}
@ aguarda KEY0 para avancar para a linha 3
LDR r4, =0xFF200050
wpress1:
  LDR r5, [r4]
  TST r5, #1
  BNE wpress1
@ KEY0 solto (bit=1): continua aguardando
wrelease1:
  LDR r5, [r4]
  TST r5, #1
  BEQ wrelease1
@ KEY0 pressionado (bit=0): aguarda soltar
B _ap1
.ltorg
_ap1:

@ ---- linha 3 ----
LDR r0, =val_10p0
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_2p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VDIV.F64 d0, d0, d1
VPUSH {d0}
LDR r0, =val_3p0
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_1p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VSUB.F64 d0, d0, d1
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VMUL.F64 d0, d0, d1
VPUSH {d0}
@ salva resultado da linha 3 em history[2]
VPOP {d0}
LDR r1, =history
ADD r1, r1, #16
VSTR d0, [r1]
VPUSH {d0}
@ === exibir resultado linha 3 nos displays ===
@ peek: VPOP para usar, VPUSH para restaurar ao final
VPOP {d0}
@ converte float64 -> inteiro com sinal em r6
VCVT.S32.F64 s0, d0
VMOV r6, s0
@ LEDs: exibe os 10 bits inferiores do valor inteiro
@ AND com 0xFF (bits 7-0) e depois isola bit 9 e 8 separadamente
@ para evitar constante 0x3FF que nao e encodavel como imediato ARM
LDR r4, =0xFF200000
AND r5, r6, #0xFF
@ bits 7-0
MOV r3, r6, LSR #8
@ desloca 8 para direita
AND r3, r3, #0x3
@ isola bits 9-8 (so 2 bits)
ORR r5, r5, r3, LSL #8
@ reconstroi os 10 bits em r5
STR r5, [r4]
@ trata sinal: r7=0 positivo, r7=1 negativo; r6 = abs(valor)
MOV r7, #0
CMP r6, #0
BGE dsp2_pos
RSB r6, r6, #0
MOV r7, #1
dsp2_pos:
@ digito 0
MOV r8, #0
dv2d0_loop:
  CMP r6, #10
  BLT dv2d0_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv2d0_loop
dv2d0_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r0, [r4, r10]
@ digito 1
MOV r8, #0
dv2d1_loop:
  CMP r6, #10
  BLT dv2d1_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv2d1_loop
dv2d1_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r1, [r4, r10]
@ digito 2
MOV r8, #0
dv2d2_loop:
  CMP r6, #10
  BLT dv2d2_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv2d2_loop
dv2d2_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r2, [r4, r10]
@ digito 3
MOV r8, #0
dv2d3_loop:
  CMP r6, #10
  BLT dv2d3_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv2d3_loop
dv2d3_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r3, [r4, r10]
@ digito 4
MOV r8, #0
dv2d4_loop:
  CMP r6, #10
  BLT dv2d4_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv2d4_loop
dv2d4_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r11, [r4, r10]
@ digito 5
MOV r8, #0
dv2d5_loop:
  CMP r6, #10
  BLT dv2d5_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv2d5_loop
dv2d5_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r12, [r4, r10]
CMP r7, #1
BNE dsp2_nosign
MOV r12, #0x40
@ codigo 7-seg do traco "-"
dsp2_nosign:
@ monta palavra para HEX3_HEX0: byte3=r3 byte2=r2 byte1=r1 byte0=r0
MOV r4, r0
ORR r4, r4, r1, LSL #8
ORR r4, r4, r2, LSL #16
ORR r4, r4, r3, LSL #24
LDR r5, =0xFF200020
STR r4, [r5]
@ monta palavra para HEX5_HEX4: byte1=r12 byte0=r11
MOV r4, r11
ORR r4, r4, r12, LSL #8
LDR r5, =0xFF200030
STR r4, [r5]
@ restaura d0 na pilha VFP
VPUSH {d0}
@ aguarda KEY0 para avancar para a linha 4
LDR r4, =0xFF200050
wpress2:
  LDR r5, [r4]
  TST r5, #1
  BNE wpress2
@ KEY0 solto (bit=1): continua aguardando
wrelease2:
  LDR r5, [r4]
  TST r5, #1
  BEQ wrelease2
@ KEY0 pressionado (bit=0): aguarda soltar
B _ap2
.ltorg
_ap2:

@ ---- linha 4 ----
LDR r0, =val_2p0
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_3p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VADD.F64 d0, d0, d1
VPUSH {d0}
LDR r0, =val_4p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VMUL.F64 d0, d0, d1
VPUSH {d0}
LDR r0, =val_5p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VADD.F64 d0, d0, d1
VPUSH {d0}
@ salva resultado da linha 4 em history[3]
VPOP {d0}
LDR r1, =history
ADD r1, r1, #24
VSTR d0, [r1]
VPUSH {d0}
@ === exibir resultado linha 4 nos displays ===
@ peek: VPOP para usar, VPUSH para restaurar ao final
VPOP {d0}
@ converte float64 -> inteiro com sinal em r6
VCVT.S32.F64 s0, d0
VMOV r6, s0
@ LEDs: exibe os 10 bits inferiores do valor inteiro
@ AND com 0xFF (bits 7-0) e depois isola bit 9 e 8 separadamente
@ para evitar constante 0x3FF que nao e encodavel como imediato ARM
LDR r4, =0xFF200000
AND r5, r6, #0xFF
@ bits 7-0
MOV r3, r6, LSR #8
@ desloca 8 para direita
AND r3, r3, #0x3
@ isola bits 9-8 (so 2 bits)
ORR r5, r5, r3, LSL #8
@ reconstroi os 10 bits em r5
STR r5, [r4]
@ trata sinal: r7=0 positivo, r7=1 negativo; r6 = abs(valor)
MOV r7, #0
CMP r6, #0
BGE dsp3_pos
RSB r6, r6, #0
MOV r7, #1
dsp3_pos:
@ digito 0
MOV r8, #0
dv3d0_loop:
  CMP r6, #10
  BLT dv3d0_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv3d0_loop
dv3d0_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r0, [r4, r10]
@ digito 1
MOV r8, #0
dv3d1_loop:
  CMP r6, #10
  BLT dv3d1_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv3d1_loop
dv3d1_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r1, [r4, r10]
@ digito 2
MOV r8, #0
dv3d2_loop:
  CMP r6, #10
  BLT dv3d2_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv3d2_loop
dv3d2_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r2, [r4, r10]
@ digito 3
MOV r8, #0
dv3d3_loop:
  CMP r6, #10
  BLT dv3d3_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv3d3_loop
dv3d3_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r3, [r4, r10]
@ digito 4
MOV r8, #0
dv3d4_loop:
  CMP r6, #10
  BLT dv3d4_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv3d4_loop
dv3d4_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r11, [r4, r10]
@ digito 5
MOV r8, #0
dv3d5_loop:
  CMP r6, #10
  BLT dv3d5_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv3d5_loop
dv3d5_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r12, [r4, r10]
CMP r7, #1
BNE dsp3_nosign
MOV r12, #0x40
@ codigo 7-seg do traco "-"
dsp3_nosign:
@ monta palavra para HEX3_HEX0: byte3=r3 byte2=r2 byte1=r1 byte0=r0
MOV r4, r0
ORR r4, r4, r1, LSL #8
ORR r4, r4, r2, LSL #16
ORR r4, r4, r3, LSL #24
LDR r5, =0xFF200020
STR r4, [r5]
@ monta palavra para HEX5_HEX4: byte1=r12 byte0=r11
MOV r4, r11
ORR r4, r4, r12, LSL #8
LDR r5, =0xFF200030
STR r4, [r5]
@ restaura d0 na pilha VFP
VPUSH {d0}
@ aguarda KEY0 para avancar para a linha 5
LDR r4, =0xFF200050
wpress3:
  LDR r5, [r4]
  TST r5, #1
  BNE wpress3
@ KEY0 solto (bit=1): continua aguardando
wrelease3:
  LDR r5, [r4]
  TST r5, #1
  BEQ wrelease3
@ KEY0 pressionado (bit=0): aguarda soltar
B _ap3
.ltorg
_ap3:

@ ---- linha 5 ----
LDR r0, =val_2
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_3
VLDR d0, [r0]
VPUSH {d0}
@ potenciacao: base=d0 expoente=d1 (inteiro >= 0)
VPOP {d1}
VPOP {d0}
VCVT.S32.F64 s2, d1
VMOV r2, s2
@ r2 = expoente inteiro
CMP r2, #0
BGE pow_ok_0
MOV r2, #0
@ expoente negativo tratado como 0
pow_ok_0:
LDR r3, =val_1_0
VLDR d1, [r3]
@ d1 = acumulador = 1.0
pow_loop_0:
CMP r2, #0
BLE pow_end_0
VMUL.F64 d1, d1, d0
SUB r2, r2, #1
B pow_loop_0
pow_end_0:
VPUSH {d1}
LDR r0, =val_4
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_2
VLDR d0, [r0]
VPUSH {d0}
@ potenciacao: base=d0 expoente=d1 (inteiro >= 0)
VPOP {d1}
VPOP {d0}
VCVT.S32.F64 s2, d1
VMOV r2, s2
@ r2 = expoente inteiro
CMP r2, #0
BGE pow_ok_1
MOV r2, #0
@ expoente negativo tratado como 0
pow_ok_1:
LDR r3, =val_1_0
VLDR d1, [r3]
@ d1 = acumulador = 1.0
pow_loop_1:
CMP r2, #0
BLE pow_end_1
VMUL.F64 d1, d1, d0
SUB r2, r2, #1
B pow_loop_1
pow_end_1:
VPUSH {d1}
VPOP {d1}
VPOP {d0}
VADD.F64 d0, d0, d1
VPUSH {d0}
@ salva resultado da linha 5 em history[4]
VPOP {d0}
LDR r1, =history
ADD r1, r1, #32
VSTR d0, [r1]
VPUSH {d0}
@ === exibir resultado linha 5 nos displays ===
@ peek: VPOP para usar, VPUSH para restaurar ao final
VPOP {d0}
@ converte float64 -> inteiro com sinal em r6
VCVT.S32.F64 s0, d0
VMOV r6, s0
@ LEDs: exibe os 10 bits inferiores do valor inteiro
@ AND com 0xFF (bits 7-0) e depois isola bit 9 e 8 separadamente
@ para evitar constante 0x3FF que nao e encodavel como imediato ARM
LDR r4, =0xFF200000
AND r5, r6, #0xFF
@ bits 7-0
MOV r3, r6, LSR #8
@ desloca 8 para direita
AND r3, r3, #0x3
@ isola bits 9-8 (so 2 bits)
ORR r5, r5, r3, LSL #8
@ reconstroi os 10 bits em r5
STR r5, [r4]
@ trata sinal: r7=0 positivo, r7=1 negativo; r6 = abs(valor)
MOV r7, #0
CMP r6, #0
BGE dsp4_pos
RSB r6, r6, #0
MOV r7, #1
dsp4_pos:
@ digito 0
MOV r8, #0
dv4d0_loop:
  CMP r6, #10
  BLT dv4d0_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv4d0_loop
dv4d0_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r0, [r4, r10]
@ digito 1
MOV r8, #0
dv4d1_loop:
  CMP r6, #10
  BLT dv4d1_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv4d1_loop
dv4d1_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r1, [r4, r10]
@ digito 2
MOV r8, #0
dv4d2_loop:
  CMP r6, #10
  BLT dv4d2_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv4d2_loop
dv4d2_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r2, [r4, r10]
@ digito 3
MOV r8, #0
dv4d3_loop:
  CMP r6, #10
  BLT dv4d3_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv4d3_loop
dv4d3_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r3, [r4, r10]
@ digito 4
MOV r8, #0
dv4d4_loop:
  CMP r6, #10
  BLT dv4d4_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv4d4_loop
dv4d4_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r11, [r4, r10]
@ digito 5
MOV r8, #0
dv4d5_loop:
  CMP r6, #10
  BLT dv4d5_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv4d5_loop
dv4d5_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r12, [r4, r10]
CMP r7, #1
BNE dsp4_nosign
MOV r12, #0x40
@ codigo 7-seg do traco "-"
dsp4_nosign:
@ monta palavra para HEX3_HEX0: byte3=r3 byte2=r2 byte1=r1 byte0=r0
MOV r4, r0
ORR r4, r4, r1, LSL #8
ORR r4, r4, r2, LSL #16
ORR r4, r4, r3, LSL #24
LDR r5, =0xFF200020
STR r4, [r5]
@ monta palavra para HEX5_HEX4: byte1=r12 byte0=r11
MOV r4, r11
ORR r4, r4, r12, LSL #8
LDR r5, =0xFF200030
STR r4, [r5]
@ restaura d0 na pilha VFP
VPUSH {d0}
@ aguarda KEY0 para avancar para a linha 6
LDR r4, =0xFF200050
wpress4:
  LDR r5, [r4]
  TST r5, #1
  BNE wpress4
@ KEY0 solto (bit=1): continua aguardando
wrelease4:
  LDR r5, [r4]
  TST r5, #1
  BEQ wrelease4
@ KEY0 pressionado (bit=0): aguarda soltar
B _ap4
.ltorg
_ap4:

@ ---- linha 6 ----
LDR r0, =val_9
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_4
VLDR d0, [r0]
VPUSH {d0}
@ divisao inteira: sem UDIV, por subtracao
VPOP {d1}
VPOP {d0}
VCVT.S32.F64 s0, d0
VCVT.S32.F64 s1, d1
VMOV r0, s0
@ r0 = dividendo
VMOV r1, s1
@ r1 = divisor
@ trata sinais: r3 = flag de resultado negativo
MOV r3, #0
CMP r0, #0
BGE fdiv_pa_0
RSB r0, r0, #0
MOV r3, #1
fdiv_pa_0:
CMP r1, #0
BGE fdiv_pb_0
RSB r1, r1, #0
EOR r3, r3, #1
fdiv_pb_0:
@ divisao por subtracao
MOV r2, #0
fdiv_loop_0:
CMP r0, r1
BLT fdiv_end_0
SUB r0, r0, r1
ADD r2, r2, #1
B fdiv_loop_0
fdiv_end_0:
CMP r3, #1
BNE fdiv_store_0
RSB r2, r2, #0
fdiv_store_0:
VMOV s0, r2
VCVT.F64.S32 d0, s0
VPUSH {d0}
LDR r0, =val_9
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_4
VLDR d0, [r0]
VPUSH {d0}
@ modulo: sem UDIV, por subtracao
VPOP {d1}
VPOP {d0}
VCVT.S32.F64 s0, d0
VCVT.S32.F64 s1, d1
VMOV r0, s0
VMOV r1, s1
MOV r3, #0
CMP r0, #0
BGE mod_pos_1
RSB r0, r0, #0
MOV r3, #1
mod_pos_1:
CMP r1, #0
BGE mod_loop_1
RSB r1, r1, #0
mod_loop_1:
CMP r0, r1
BLT mod_end_1
SUB r0, r0, r1
B mod_loop_1
mod_end_1:
CMP r3, #1
BNE mod_store_1
RSB r0, r0, #0
mod_store_1:
VMOV s0, r0
VCVT.F64.S32 d0, s0
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VADD.F64 d0, d0, d1
VPUSH {d0}
@ salva resultado da linha 6 em history[5]
VPOP {d0}
LDR r1, =history
ADD r1, r1, #40
VSTR d0, [r1]
VPUSH {d0}
@ === exibir resultado linha 6 nos displays ===
@ peek: VPOP para usar, VPUSH para restaurar ao final
VPOP {d0}
@ converte float64 -> inteiro com sinal em r6
VCVT.S32.F64 s0, d0
VMOV r6, s0
@ LEDs: exibe os 10 bits inferiores do valor inteiro
@ AND com 0xFF (bits 7-0) e depois isola bit 9 e 8 separadamente
@ para evitar constante 0x3FF que nao e encodavel como imediato ARM
LDR r4, =0xFF200000
AND r5, r6, #0xFF
@ bits 7-0
MOV r3, r6, LSR #8
@ desloca 8 para direita
AND r3, r3, #0x3
@ isola bits 9-8 (so 2 bits)
ORR r5, r5, r3, LSL #8
@ reconstroi os 10 bits em r5
STR r5, [r4]
@ trata sinal: r7=0 positivo, r7=1 negativo; r6 = abs(valor)
MOV r7, #0
CMP r6, #0
BGE dsp5_pos
RSB r6, r6, #0
MOV r7, #1
dsp5_pos:
@ digito 0
MOV r8, #0
dv5d0_loop:
  CMP r6, #10
  BLT dv5d0_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv5d0_loop
dv5d0_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r0, [r4, r10]
@ digito 1
MOV r8, #0
dv5d1_loop:
  CMP r6, #10
  BLT dv5d1_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv5d1_loop
dv5d1_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r1, [r4, r10]
@ digito 2
MOV r8, #0
dv5d2_loop:
  CMP r6, #10
  BLT dv5d2_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv5d2_loop
dv5d2_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r2, [r4, r10]
@ digito 3
MOV r8, #0
dv5d3_loop:
  CMP r6, #10
  BLT dv5d3_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv5d3_loop
dv5d3_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r3, [r4, r10]
@ digito 4
MOV r8, #0
dv5d4_loop:
  CMP r6, #10
  BLT dv5d4_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv5d4_loop
dv5d4_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r11, [r4, r10]
@ digito 5
MOV r8, #0
dv5d5_loop:
  CMP r6, #10
  BLT dv5d5_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv5d5_loop
dv5d5_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r12, [r4, r10]
CMP r7, #1
BNE dsp5_nosign
MOV r12, #0x40
@ codigo 7-seg do traco "-"
dsp5_nosign:
@ monta palavra para HEX3_HEX0: byte3=r3 byte2=r2 byte1=r1 byte0=r0
MOV r4, r0
ORR r4, r4, r1, LSL #8
ORR r4, r4, r2, LSL #16
ORR r4, r4, r3, LSL #24
LDR r5, =0xFF200020
STR r4, [r5]
@ monta palavra para HEX5_HEX4: byte1=r12 byte0=r11
MOV r4, r11
ORR r4, r4, r12, LSL #8
LDR r5, =0xFF200030
STR r4, [r5]
@ restaura d0 na pilha VFP
VPUSH {d0}
@ aguarda KEY0 para avancar para a linha 7
LDR r4, =0xFF200050
wpress5:
  LDR r5, [r4]
  TST r5, #1
  BNE wpress5
@ KEY0 solto (bit=1): continua aguardando
wrelease5:
  LDR r5, [r4]
  TST r5, #1
  BEQ wrelease5
@ KEY0 pressionado (bit=0): aguarda soltar
B _ap5
.ltorg
_ap5:

@ ---- linha 7 ----
LDR r0, =val_3p0
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_2p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VADD.F64 d0, d0, d1
VPUSH {d0}
LDR r0, =val_4p0
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_1p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VSUB.F64 d0, d0, d1
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VMUL.F64 d0, d0, d1
VPUSH {d0}
LDR r0, =val_2p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VDIV.F64 d0, d0, d1
VPUSH {d0}
@ salva resultado da linha 7 em history[6]
VPOP {d0}
LDR r1, =history
ADD r1, r1, #48
VSTR d0, [r1]
VPUSH {d0}
@ === exibir resultado linha 7 nos displays ===
@ peek: VPOP para usar, VPUSH para restaurar ao final
VPOP {d0}
@ converte float64 -> inteiro com sinal em r6
VCVT.S32.F64 s0, d0
VMOV r6, s0
@ LEDs: exibe os 10 bits inferiores do valor inteiro
@ AND com 0xFF (bits 7-0) e depois isola bit 9 e 8 separadamente
@ para evitar constante 0x3FF que nao e encodavel como imediato ARM
LDR r4, =0xFF200000
AND r5, r6, #0xFF
@ bits 7-0
MOV r3, r6, LSR #8
@ desloca 8 para direita
AND r3, r3, #0x3
@ isola bits 9-8 (so 2 bits)
ORR r5, r5, r3, LSL #8
@ reconstroi os 10 bits em r5
STR r5, [r4]
@ trata sinal: r7=0 positivo, r7=1 negativo; r6 = abs(valor)
MOV r7, #0
CMP r6, #0
BGE dsp6_pos
RSB r6, r6, #0
MOV r7, #1
dsp6_pos:
@ digito 0
MOV r8, #0
dv6d0_loop:
  CMP r6, #10
  BLT dv6d0_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv6d0_loop
dv6d0_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r0, [r4, r10]
@ digito 1
MOV r8, #0
dv6d1_loop:
  CMP r6, #10
  BLT dv6d1_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv6d1_loop
dv6d1_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r1, [r4, r10]
@ digito 2
MOV r8, #0
dv6d2_loop:
  CMP r6, #10
  BLT dv6d2_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv6d2_loop
dv6d2_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r2, [r4, r10]
@ digito 3
MOV r8, #0
dv6d3_loop:
  CMP r6, #10
  BLT dv6d3_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv6d3_loop
dv6d3_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r3, [r4, r10]
@ digito 4
MOV r8, #0
dv6d4_loop:
  CMP r6, #10
  BLT dv6d4_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv6d4_loop
dv6d4_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r11, [r4, r10]
@ digito 5
MOV r8, #0
dv6d5_loop:
  CMP r6, #10
  BLT dv6d5_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv6d5_loop
dv6d5_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r12, [r4, r10]
CMP r7, #1
BNE dsp6_nosign
MOV r12, #0x40
@ codigo 7-seg do traco "-"
dsp6_nosign:
@ monta palavra para HEX3_HEX0: byte3=r3 byte2=r2 byte1=r1 byte0=r0
MOV r4, r0
ORR r4, r4, r1, LSL #8
ORR r4, r4, r2, LSL #16
ORR r4, r4, r3, LSL #24
LDR r5, =0xFF200020
STR r4, [r5]
@ monta palavra para HEX5_HEX4: byte1=r12 byte0=r11
MOV r4, r11
ORR r4, r4, r12, LSL #8
LDR r5, =0xFF200030
STR r4, [r5]
@ restaura d0 na pilha VFP
VPUSH {d0}
@ aguarda KEY0 para avancar para a linha 8
LDR r4, =0xFF200050
wpress6:
  LDR r5, [r4]
  TST r5, #1
  BNE wpress6
@ KEY0 solto (bit=1): continua aguardando
wrelease6:
  LDR r5, [r4]
  TST r5, #1
  BEQ wrelease6
@ KEY0 pressionado (bit=0): aguarda soltar
B _ap6
.ltorg
_ap6:

@ ---- linha 8 ----
LDR r0, =val_5p0
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_2p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VMUL.F64 d0, d0, d1
VPUSH {d0}
LDR r0, =val_3p0
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_2p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VADD.F64 d0, d0, d1
VPUSH {d0}
LDR r0, =val_4p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VMUL.F64 d0, d0, d1
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VADD.F64 d0, d0, d1
VPUSH {d0}
@ salva resultado da linha 8 em history[7]
VPOP {d0}
LDR r1, =history
ADD r1, r1, #56
VSTR d0, [r1]
VPUSH {d0}
@ === exibir resultado linha 8 nos displays ===
@ peek: VPOP para usar, VPUSH para restaurar ao final
VPOP {d0}
@ converte float64 -> inteiro com sinal em r6
VCVT.S32.F64 s0, d0
VMOV r6, s0
@ LEDs: exibe os 10 bits inferiores do valor inteiro
@ AND com 0xFF (bits 7-0) e depois isola bit 9 e 8 separadamente
@ para evitar constante 0x3FF que nao e encodavel como imediato ARM
LDR r4, =0xFF200000
AND r5, r6, #0xFF
@ bits 7-0
MOV r3, r6, LSR #8
@ desloca 8 para direita
AND r3, r3, #0x3
@ isola bits 9-8 (so 2 bits)
ORR r5, r5, r3, LSL #8
@ reconstroi os 10 bits em r5
STR r5, [r4]
@ trata sinal: r7=0 positivo, r7=1 negativo; r6 = abs(valor)
MOV r7, #0
CMP r6, #0
BGE dsp7_pos
RSB r6, r6, #0
MOV r7, #1
dsp7_pos:
@ digito 0
MOV r8, #0
dv7d0_loop:
  CMP r6, #10
  BLT dv7d0_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv7d0_loop
dv7d0_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r0, [r4, r10]
@ digito 1
MOV r8, #0
dv7d1_loop:
  CMP r6, #10
  BLT dv7d1_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv7d1_loop
dv7d1_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r1, [r4, r10]
@ digito 2
MOV r8, #0
dv7d2_loop:
  CMP r6, #10
  BLT dv7d2_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv7d2_loop
dv7d2_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r2, [r4, r10]
@ digito 3
MOV r8, #0
dv7d3_loop:
  CMP r6, #10
  BLT dv7d3_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv7d3_loop
dv7d3_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r3, [r4, r10]
@ digito 4
MOV r8, #0
dv7d4_loop:
  CMP r6, #10
  BLT dv7d4_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv7d4_loop
dv7d4_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r11, [r4, r10]
@ digito 5
MOV r8, #0
dv7d5_loop:
  CMP r6, #10
  BLT dv7d5_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv7d5_loop
dv7d5_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r12, [r4, r10]
CMP r7, #1
BNE dsp7_nosign
MOV r12, #0x40
@ codigo 7-seg do traco "-"
dsp7_nosign:
@ monta palavra para HEX3_HEX0: byte3=r3 byte2=r2 byte1=r1 byte0=r0
MOV r4, r0
ORR r4, r4, r1, LSL #8
ORR r4, r4, r2, LSL #16
ORR r4, r4, r3, LSL #24
LDR r5, =0xFF200020
STR r4, [r5]
@ monta palavra para HEX5_HEX4: byte1=r12 byte0=r11
MOV r4, r11
ORR r4, r4, r12, LSL #8
LDR r5, =0xFF200030
STR r4, [r5]
@ restaura d0 na pilha VFP
VPUSH {d0}
@ aguarda KEY0 para avancar para a linha 9
LDR r4, =0xFF200050
wpress7:
  LDR r5, [r4]
  TST r5, #1
  BNE wpress7
@ KEY0 solto (bit=1): continua aguardando
wrelease7:
  LDR r5, [r4]
  TST r5, #1
  BEQ wrelease7
@ KEY0 pressionado (bit=0): aguarda soltar
B _ap7
.ltorg
_ap7:

@ ---- linha 9 ----
LDR r0, =val_8p0
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_2p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VDIV.F64 d0, d0, d1
VPUSH {d0}
LDR r0, =val_3p0
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_2p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VMUL.F64 d0, d0, d1
VPUSH {d0}
LDR r0, =val_5p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VADD.F64 d0, d0, d1
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VMUL.F64 d0, d0, d1
VPUSH {d0}
@ salva resultado da linha 9 em history[8]
VPOP {d0}
LDR r1, =history
ADD r1, r1, #64
VSTR d0, [r1]
VPUSH {d0}
@ === exibir resultado linha 9 nos displays ===
@ peek: VPOP para usar, VPUSH para restaurar ao final
VPOP {d0}
@ converte float64 -> inteiro com sinal em r6
VCVT.S32.F64 s0, d0
VMOV r6, s0
@ LEDs: exibe os 10 bits inferiores do valor inteiro
@ AND com 0xFF (bits 7-0) e depois isola bit 9 e 8 separadamente
@ para evitar constante 0x3FF que nao e encodavel como imediato ARM
LDR r4, =0xFF200000
AND r5, r6, #0xFF
@ bits 7-0
MOV r3, r6, LSR #8
@ desloca 8 para direita
AND r3, r3, #0x3
@ isola bits 9-8 (so 2 bits)
ORR r5, r5, r3, LSL #8
@ reconstroi os 10 bits em r5
STR r5, [r4]
@ trata sinal: r7=0 positivo, r7=1 negativo; r6 = abs(valor)
MOV r7, #0
CMP r6, #0
BGE dsp8_pos
RSB r6, r6, #0
MOV r7, #1
dsp8_pos:
@ digito 0
MOV r8, #0
dv8d0_loop:
  CMP r6, #10
  BLT dv8d0_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv8d0_loop
dv8d0_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r0, [r4, r10]
@ digito 1
MOV r8, #0
dv8d1_loop:
  CMP r6, #10
  BLT dv8d1_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv8d1_loop
dv8d1_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r1, [r4, r10]
@ digito 2
MOV r8, #0
dv8d2_loop:
  CMP r6, #10
  BLT dv8d2_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv8d2_loop
dv8d2_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r2, [r4, r10]
@ digito 3
MOV r8, #0
dv8d3_loop:
  CMP r6, #10
  BLT dv8d3_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv8d3_loop
dv8d3_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r3, [r4, r10]
@ digito 4
MOV r8, #0
dv8d4_loop:
  CMP r6, #10
  BLT dv8d4_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv8d4_loop
dv8d4_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r11, [r4, r10]
@ digito 5
MOV r8, #0
dv8d5_loop:
  CMP r6, #10
  BLT dv8d5_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv8d5_loop
dv8d5_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r12, [r4, r10]
CMP r7, #1
BNE dsp8_nosign
MOV r12, #0x40
@ codigo 7-seg do traco "-"
dsp8_nosign:
@ monta palavra para HEX3_HEX0: byte3=r3 byte2=r2 byte1=r1 byte0=r0
MOV r4, r0
ORR r4, r4, r1, LSL #8
ORR r4, r4, r2, LSL #16
ORR r4, r4, r3, LSL #24
LDR r5, =0xFF200020
STR r4, [r5]
@ monta palavra para HEX5_HEX4: byte1=r12 byte0=r11
MOV r4, r11
ORR r4, r4, r12, LSL #8
LDR r5, =0xFF200030
STR r4, [r5]
@ restaura d0 na pilha VFP
VPUSH {d0}
@ aguarda KEY0 para avancar para a linha 10
LDR r4, =0xFF200050
wpress8:
  LDR r5, [r4]
  TST r5, #1
  BNE wpress8
@ KEY0 solto (bit=1): continua aguardando
wrelease8:
  LDR r5, [r4]
  TST r5, #1
  BEQ wrelease8
@ KEY0 pressionado (bit=0): aguarda soltar
B _ap8
.ltorg
_ap8:

@ ---- linha 10 ----
LDR r0, =val_6p0
VLDR d0, [r0]
VPUSH {d0}
@ MEM_WRITE -> MEM
LDR r0, =mem_MEM
VPOP {d0}
VSTR d0, [r0]
VLDR d0, [r0]
VPUSH {d0}
@ salva resultado da linha 10 em history[9]
VPOP {d0}
LDR r1, =history
ADD r1, r1, #72
VSTR d0, [r1]
VPUSH {d0}
@ === exibir resultado linha 10 nos displays ===
@ peek: VPOP para usar, VPUSH para restaurar ao final
VPOP {d0}
@ converte float64 -> inteiro com sinal em r6
VCVT.S32.F64 s0, d0
VMOV r6, s0
@ LEDs: exibe os 10 bits inferiores do valor inteiro
@ AND com 0xFF (bits 7-0) e depois isola bit 9 e 8 separadamente
@ para evitar constante 0x3FF que nao e encodavel como imediato ARM
LDR r4, =0xFF200000
AND r5, r6, #0xFF
@ bits 7-0
MOV r3, r6, LSR #8
@ desloca 8 para direita
AND r3, r3, #0x3
@ isola bits 9-8 (so 2 bits)
ORR r5, r5, r3, LSL #8
@ reconstroi os 10 bits em r5
STR r5, [r4]
@ trata sinal: r7=0 positivo, r7=1 negativo; r6 = abs(valor)
MOV r7, #0
CMP r6, #0
BGE dsp9_pos
RSB r6, r6, #0
MOV r7, #1
dsp9_pos:
@ digito 0
MOV r8, #0
dv9d0_loop:
  CMP r6, #10
  BLT dv9d0_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv9d0_loop
dv9d0_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r0, [r4, r10]
@ digito 1
MOV r8, #0
dv9d1_loop:
  CMP r6, #10
  BLT dv9d1_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv9d1_loop
dv9d1_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r1, [r4, r10]
@ digito 2
MOV r8, #0
dv9d2_loop:
  CMP r6, #10
  BLT dv9d2_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv9d2_loop
dv9d2_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r2, [r4, r10]
@ digito 3
MOV r8, #0
dv9d3_loop:
  CMP r6, #10
  BLT dv9d3_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv9d3_loop
dv9d3_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r3, [r4, r10]
@ digito 4
MOV r8, #0
dv9d4_loop:
  CMP r6, #10
  BLT dv9d4_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv9d4_loop
dv9d4_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r11, [r4, r10]
@ digito 5
MOV r8, #0
dv9d5_loop:
  CMP r6, #10
  BLT dv9d5_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv9d5_loop
dv9d5_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r12, [r4, r10]
CMP r7, #1
BNE dsp9_nosign
MOV r12, #0x40
@ codigo 7-seg do traco "-"
dsp9_nosign:
@ monta palavra para HEX3_HEX0: byte3=r3 byte2=r2 byte1=r1 byte0=r0
MOV r4, r0
ORR r4, r4, r1, LSL #8
ORR r4, r4, r2, LSL #16
ORR r4, r4, r3, LSL #24
LDR r5, =0xFF200020
STR r4, [r5]
@ monta palavra para HEX5_HEX4: byte1=r12 byte0=r11
MOV r4, r11
ORR r4, r4, r12, LSL #8
LDR r5, =0xFF200030
STR r4, [r5]
@ restaura d0 na pilha VFP
VPUSH {d0}
@ aguarda KEY0 para avancar para a linha 11
LDR r4, =0xFF200050
wpress9:
  LDR r5, [r4]
  TST r5, #1
  BNE wpress9
@ KEY0 solto (bit=1): continua aguardando
wrelease9:
  LDR r5, [r4]
  TST r5, #1
  BEQ wrelease9
@ KEY0 pressionado (bit=0): aguarda soltar
B _ap9
.ltorg
_ap9:

@ ---- linha 11 ----
@ MEM_READ <- MEM
LDR r0, =mem_MEM
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_2p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VADD.F64 d0, d0, d1
VPUSH {d0}
@ MEM_WRITE -> MEM
LDR r0, =mem_MEM
VPOP {d0}
VSTR d0, [r0]
VLDR d0, [r0]
VPUSH {d0}
LDR r0, =val_3p0
VLDR d0, [r0]
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VMUL.F64 d0, d0, d1
VPUSH {d0}
VPOP {d1}
VPOP {d0}
VADD.F64 d0, d0, d1
VPUSH {d0}
@ salva resultado da linha 11 em history[10]
VPOP {d0}
LDR r1, =history
ADD r1, r1, #80
VSTR d0, [r1]
VPUSH {d0}
@ === exibir resultado linha 11 nos displays ===
@ peek: VPOP para usar, VPUSH para restaurar ao final
VPOP {d0}
@ converte float64 -> inteiro com sinal em r6
VCVT.S32.F64 s0, d0
VMOV r6, s0
@ LEDs: exibe os 10 bits inferiores do valor inteiro
@ AND com 0xFF (bits 7-0) e depois isola bit 9 e 8 separadamente
@ para evitar constante 0x3FF que nao e encodavel como imediato ARM
LDR r4, =0xFF200000
AND r5, r6, #0xFF
@ bits 7-0
MOV r3, r6, LSR #8
@ desloca 8 para direita
AND r3, r3, #0x3
@ isola bits 9-8 (so 2 bits)
ORR r5, r5, r3, LSL #8
@ reconstroi os 10 bits em r5
STR r5, [r4]
@ trata sinal: r7=0 positivo, r7=1 negativo; r6 = abs(valor)
MOV r7, #0
CMP r6, #0
BGE dsp10_pos
RSB r6, r6, #0
MOV r7, #1
dsp10_pos:
@ digito 0
MOV r8, #0
dv10d0_loop:
  CMP r6, #10
  BLT dv10d0_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv10d0_loop
dv10d0_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r0, [r4, r10]
@ digito 1
MOV r8, #0
dv10d1_loop:
  CMP r6, #10
  BLT dv10d1_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv10d1_loop
dv10d1_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r1, [r4, r10]
@ digito 2
MOV r8, #0
dv10d2_loop:
  CMP r6, #10
  BLT dv10d2_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv10d2_loop
dv10d2_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r2, [r4, r10]
@ digito 3
MOV r8, #0
dv10d3_loop:
  CMP r6, #10
  BLT dv10d3_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv10d3_loop
dv10d3_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r3, [r4, r10]
@ digito 4
MOV r8, #0
dv10d4_loop:
  CMP r6, #10
  BLT dv10d4_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv10d4_loop
dv10d4_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r11, [r4, r10]
@ digito 5
MOV r8, #0
dv10d5_loop:
  CMP r6, #10
  BLT dv10d5_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv10d5_loop
dv10d5_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r12, [r4, r10]
CMP r7, #1
BNE dsp10_nosign
MOV r12, #0x40
@ codigo 7-seg do traco "-"
dsp10_nosign:
@ monta palavra para HEX3_HEX0: byte3=r3 byte2=r2 byte1=r1 byte0=r0
MOV r4, r0
ORR r4, r4, r1, LSL #8
ORR r4, r4, r2, LSL #16
ORR r4, r4, r3, LSL #24
LDR r5, =0xFF200020
STR r4, [r5]
@ monta palavra para HEX5_HEX4: byte1=r12 byte0=r11
MOV r4, r11
ORR r4, r4, r12, LSL #8
LDR r5, =0xFF200030
STR r4, [r5]
@ restaura d0 na pilha VFP
VPUSH {d0}
@ aguarda KEY0 para avancar para a linha 12
LDR r4, =0xFF200050
wpress10:
  LDR r5, [r4]
  TST r5, #1
  BNE wpress10
@ KEY0 solto (bit=1): continua aguardando
wrelease10:
  LDR r5, [r4]
  TST r5, #1
  BEQ wrelease10
@ KEY0 pressionado (bit=0): aguarda soltar
B _ap10
.ltorg
_ap10:

@ ---- linha 12 ----
@ MEM_READ <- MEM
LDR r0, =mem_MEM
VLDR d0, [r0]
VPUSH {d0}
@ salva resultado da linha 12 em history[11]
VPOP {d0}
LDR r1, =history
ADD r1, r1, #88
VSTR d0, [r1]
VPUSH {d0}
@ === exibir resultado linha 12 nos displays ===
@ peek: VPOP para usar, VPUSH para restaurar ao final
VPOP {d0}
@ converte float64 -> inteiro com sinal em r6
VCVT.S32.F64 s0, d0
VMOV r6, s0
@ LEDs: exibe os 10 bits inferiores do valor inteiro
@ AND com 0xFF (bits 7-0) e depois isola bit 9 e 8 separadamente
@ para evitar constante 0x3FF que nao e encodavel como imediato ARM
LDR r4, =0xFF200000
AND r5, r6, #0xFF
@ bits 7-0
MOV r3, r6, LSR #8
@ desloca 8 para direita
AND r3, r3, #0x3
@ isola bits 9-8 (so 2 bits)
ORR r5, r5, r3, LSL #8
@ reconstroi os 10 bits em r5
STR r5, [r4]
@ trata sinal: r7=0 positivo, r7=1 negativo; r6 = abs(valor)
MOV r7, #0
CMP r6, #0
BGE dsp11_pos
RSB r6, r6, #0
MOV r7, #1
dsp11_pos:
@ digito 0
MOV r8, #0
dv11d0_loop:
  CMP r6, #10
  BLT dv11d0_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv11d0_loop
dv11d0_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r0, [r4, r10]
@ digito 1
MOV r8, #0
dv11d1_loop:
  CMP r6, #10
  BLT dv11d1_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv11d1_loop
dv11d1_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r1, [r4, r10]
@ digito 2
MOV r8, #0
dv11d2_loop:
  CMP r6, #10
  BLT dv11d2_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv11d2_loop
dv11d2_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r2, [r4, r10]
@ digito 3
MOV r8, #0
dv11d3_loop:
  CMP r6, #10
  BLT dv11d3_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv11d3_loop
dv11d3_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r3, [r4, r10]
@ digito 4
MOV r8, #0
dv11d4_loop:
  CMP r6, #10
  BLT dv11d4_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv11d4_loop
dv11d4_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r11, [r4, r10]
@ digito 5
MOV r8, #0
dv11d5_loop:
  CMP r6, #10
  BLT dv11d5_done
  SUB r6, r6, #10
  ADD r8, r8, #1
  B dv11d5_loop
dv11d5_done:
MOV r10, r6
MOV r6, r8
LDR r4, =seg_table
LDRB r12, [r4, r10]
CMP r7, #1
BNE dsp11_nosign
MOV r12, #0x40
@ codigo 7-seg do traco "-"
dsp11_nosign:
@ monta palavra para HEX3_HEX0: byte3=r3 byte2=r2 byte1=r1 byte0=r0
MOV r4, r0
ORR r4, r4, r1, LSL #8
ORR r4, r4, r2, LSL #16
ORR r4, r4, r3, LSL #24
LDR r5, =0xFF200020
STR r4, [r5]
@ monta palavra para HEX5_HEX4: byte1=r12 byte0=r11
MOV r4, r11
ORR r4, r4, r12, LSL #8
LDR r5, =0xFF200030
STR r4, [r5]
@ restaura d0 na pilha VFP
VPUSH {d0}
B _ap11
.ltorg
_ap11:


end:
B end

.ltorg

@ ===== secao de dados =====
.data
.align 3
history: .space 96
.align 3
val_1_0: .double 1.0
.align 3
val_0_0: .double 0.0
@ tabela de codigos 7-segmentos: digitos 0-9
seg_table: .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
.align 2
vfp_stack: .space 4096
vfp_stack_top:
.align 3
val_3p0: .double 3.0
.align 3
val_2p0: .double 2.0
.align 3
val_4p0: .double 4.0
.align 3
val_5p0: .double 5.0
.align 3
val_10p0: .double 10.0
.align 3
val_1p0: .double 1.0
.align 3
val_2: .double 2.0
.align 3
val_3: .double 3.0
.align 3
val_4: .double 4.0
.align 3
val_9: .double 9.0
.align 3
val_8p0: .double 8.0
.align 3
val_6p0: .double 6.0
.align 3
mem_MEM: .double 0.0