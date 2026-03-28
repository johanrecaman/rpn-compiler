# Integrantes (ordem alfabética):
#   Johan Recaman - johanrecaman
#   Nicole Guarnieri - nick11nic
# Grupo: (alterar para o nome do grupo no Canvas)

from rpn_compiler.lexer import TokenType

_ADDR_LEDS  = '0xFF200000'   # 10 LEDs vermelhos
_ADDR_HEX10 = '0xFF200020'   # Displays HEX3 HEX2 HEX1 HEX0
_ADDR_HEX54 = '0xFF200030'   # Displays HEX5 HEX4
_ADDR_KEY   = '0xFF200050'   # Pushbuttons KEY3-KEY0 (bit 0 = KEY0, ativo-baixo)
_STACK_SIZE = 4096

# ---------------------------------------------------------------------------
# Tabela de codificação 7-segmentos para dígitos 0-9
# Segmentos: .gfedcba  (bit 6=g … bit 0=a)
#  0=0x3F  1=0x06  2=0x5B  3=0x4F  4=0x66
#  5=0x6D  6=0x7D  7=0x07  8=0x7F  9=0x6F
#  '-'=0x40   apagado=0x00
# ---------------------------------------------------------------------------
_SEG_DIGITS = [0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F]
_SEG_MINUS  = 0x40
_SEG_OFF    = 0x00

def _divmod10_inline(label, r_in, r_quot, r_rem):
    """
    Inline: divide r_in por 10.
    Saída: r_quot = r_in / 10, r_rem = r_in % 10
    Destrói apenas r_quot e r_rem.
    """
    return [
        f'MOV {r_quot}, #0',
        f'{label}_loop:',
        f'  CMP {r_in}, #10',
        f'  BLT {label}_done',
        f'  SUB {r_in}, {r_in}, #10',
        f'  ADD {r_quot}, {r_quot}, #1',
        f'  B {label}_loop',
        f'{label}_done:',
        f'MOV {r_rem}, {r_in}',   # resto = o que sobrou em r_in
    ]


def _display_instructions(line_idx, div_seq_counter):

    L = f'dsp{line_idx}'          # prefixo de labels único por linha
    C = div_seq_counter           # contador para labels de divisão (lista mutável)

    def next_div_label(digit):
        lbl = f'dv{line_idx}_{digit}'
        return lbl

    instr = [
        f'@ === exibir resultado linha {line_idx + 1} nos displays ===',
        '@ peek: VPOP para usar, VPUSH para restaurar ao final',
        'VPOP {d0}',

        '@ converte float64 -> inteiro com sinal em r6',
        'VCVT.S32.F64 s0, d0',
        'VMOV r6, s0',

        '@ LEDs: exibe os 10 bits inferiores do valor inteiro',
        '@ AND com 0xFF (bits 7-0) e depois isola bit 9 e 8 separadamente',
        '@ para evitar constante 0x3FF que nao e encodavel como imediato ARM',
        f'LDR r4, ={_ADDR_LEDS}',
        'AND r5, r6, #0xFF',         '@ bits 7-0',
        'MOV r3, r6, LSR #8',        '@ desloca 8 para direita',
        'AND r3, r3, #0x3',          '@ isola bits 9-8 (so 2 bits)',
        'ORR r5, r5, r3, LSL #8',    '@ reconstroi os 10 bits em r5',
        'STR r5, [r4]',

        '@ trata sinal: r7=0 positivo, r7=1 negativo; r6 = abs(valor)',
        'MOV r7, #0',
        'CMP r6, #0',
        f'BGE {L}_pos',
        'RSB r6, r6, #0',
        'MOV r7, #1',
        f'{L}_pos:',
    ]

    # Extrai 6 dígitos por divisão successiva
    # Cada dígito usa r6 (que vai sendo dividido) e coloca o resto no reg destino
    # Registradores de resultado: r0..r3 para dígitos 0-3, r11 e r12 para 4-5
    digit_regs = ['r0', 'r1', 'r2', 'r3', 'r11', 'r12']

    for d, dreg in enumerate(digit_regs):
        dlabel = f'dv{line_idx}d{d}'
        instr += [
            f'@ digito {d}',
        ]
        instr += _divmod10_inline(dlabel, 'r6', 'r8', 'r10')
        instr += [
            f'MOV r6, r8',               # r6 = quociente (para próxima iteração)
            f'LDR r4, =seg_table',
            f'LDRB {dreg}, [r4, r10]',   # dreg = seg_table[resto]
        ]

    # Trata sinal: se negativo, substitui dígito 5 (mais à esquerda) por '-'
    instr += [
        f'CMP r7, #1',
        f'BNE {L}_nosign',
        f'MOV r12, #0x40',   '@ codigo 7-seg do traco "-"',
        f'{L}_nosign:',

        '@ monta palavra para HEX3_HEX0: byte3=r3 byte2=r2 byte1=r1 byte0=r0',
        'MOV r4, r0',
        'ORR r4, r4, r1, LSL #8',
        'ORR r4, r4, r2, LSL #16',
        'ORR r4, r4, r3, LSL #24',
        f'LDR r5, ={_ADDR_HEX10}',
        'STR r4, [r5]',

        '@ monta palavra para HEX5_HEX4: byte1=r12 byte0=r11',
        'MOV r4, r11',
        'ORR r4, r4, r12, LSL #8',
        f'LDR r5, ={_ADDR_HEX54}',
        'STR r4, [r5]',

        '@ restaura d0 na pilha VFP',
        'VPUSH {d0}',
    ]

    return instr


def _wait_key0(line_idx):
    return [
        f'@ aguarda KEY0 para avancar para a linha {line_idx + 2}',
        f'LDR r4, ={_ADDR_KEY}',
        f'wpress{line_idx}:',
        f'  LDR r5, [r4]',
        f'  TST r5, #1',
        f'  BNE wpress{line_idx}',      '@ KEY0 solto (bit=1): continua aguardando',
        f'wrelease{line_idx}:',
        f'  LDR r5, [r4]',
        f'  TST r5, #1',
        f'  BEQ wrelease{line_idx}',    '@ KEY0 pressionado (bit=0): aguarda soltar',
    ]


def _save_history(line_idx):
    offset = line_idx * 8
    instr = [
        f'@ salva resultado da linha {line_idx + 1} em history[{line_idx}]',
        'VPOP {d0}',
        'LDR r1, =history',
    ]
    if offset == 0:
        instr.append('VSTR d0, [r1]')
    elif offset <= 255:
        instr.append(f'ADD r1, r1, #{offset}')
        instr.append('VSTR d0, [r1]')
    else:
        instr.append(f'LDR r2, ={offset}')
        instr.append('ADD r1, r1, r2')
        instr.append('VSTR d0, [r1]')
    instr.append('VPUSH {d0}')
    return instr


def gerarAssembly(all_tokens, codigo_assembly):
    mem_addresses = {}
    val_labels    = {}
    pow_counter   = [0]
    num_lines     = len(all_tokens)
    div_seq       = [0]   # contador para labels de divisão únicos

    SEG_BYTES = ', '.join(f'0x{v:02X}' for v in _SEG_DIGITS)

    data_lines = [
        '',
        '@ ===== secao de dados =====',
        '.data',
        '.align 3',
        f'history: .space {num_lines * 8}',
        '.align 3',
        'val_1_0: .double 1.0',
        '.align 3',
        'val_0_0: .double 0.0',
        '@ tabela de codigos 7-segmentos: digitos 0-9',
        f'seg_table: .byte {SEG_BYTES}',
        '.align 2',
        f'vfp_stack: .space {_STACK_SIZE}',
        'vfp_stack_top:',
    ]
    val_labels['val_1_0'] = True
    val_labels['val_0_0'] = True

    def get_mem_label(name):
        if name not in mem_addresses:
            mem_addresses[name] = f'mem_{name}'
            data_lines.append('.align 3')
            data_lines.append(f'mem_{name}: .double 0.0')
        return mem_addresses[name]

    def get_val_label(value):
        safe  = value.replace('.', 'p').replace('-', 'neg')
        label = f'val_{safe}'
        if label not in val_labels:
            val_labels[label] = True
            asm_value = value if '.' in value else value + '.0'
            data_lines.append('.align 3')
            data_lines.append(f'{label}: .double {asm_value}')
        return label

    def get_pow_instructions():
        idx = pow_counter[0]
        pow_counter[0] += 1
        return [
            '@ potenciacao: base=d0 expoente=d1 (inteiro >= 0)',
            'VPOP {d1}', 'VPOP {d0}',
            'VCVT.S32.F64 s2, d1',
            'VMOV r2, s2',          '@ r2 = expoente inteiro',
            'CMP r2, #0',
            f'BGE pow_ok_{idx}',
            'MOV r2, #0',           '@ expoente negativo tratado como 0',
            f'pow_ok_{idx}:',
            'LDR r3, =val_1_0',
            'VLDR d1, [r3]',        '@ d1 = acumulador = 1.0',
            f'pow_loop_{idx}:',
            'CMP r2, #0',
            f'BLE pow_end_{idx}',
            'VMUL.F64 d1, d1, d0',
            'SUB r2, r2, #1',
            f'B pow_loop_{idx}',
            f'pow_end_{idx}:',
            'VPUSH {d1}',
        ]

    def get_floordiv_instructions():
        idx = div_seq[0]
        div_seq[0] += 1
        return [
            '@ divisao inteira: sem UDIV, por subtracao',
            'VPOP {d1}', 'VPOP {d0}',
            'VCVT.S32.F64 s0, d0', 'VCVT.S32.F64 s1, d1',
            'VMOV r0, s0',          '@ r0 = dividendo',
            'VMOV r1, s1',          '@ r1 = divisor',
            '@ trata sinais: r3 = flag de resultado negativo',
            'MOV r3, #0',
            'CMP r0, #0',
            f'BGE fdiv_pa_{idx}',
            'RSB r0, r0, #0',
            'MOV r3, #1',
            f'fdiv_pa_{idx}:',
            'CMP r1, #0',
            f'BGE fdiv_pb_{idx}',
            'RSB r1, r1, #0',
            'EOR r3, r3, #1',
            f'fdiv_pb_{idx}:',
            '@ divisao por subtracao',
            'MOV r2, #0',
            f'fdiv_loop_{idx}:',
            'CMP r0, r1',
            f'BLT fdiv_end_{idx}',
            'SUB r0, r0, r1',
            'ADD r2, r2, #1',
            f'B fdiv_loop_{idx}',
            f'fdiv_end_{idx}:',
            'CMP r3, #1',
            f'BNE fdiv_store_{idx}',
            'RSB r2, r2, #0',
            f'fdiv_store_{idx}:',
            'VMOV s0, r2',
            'VCVT.F64.S32 d0, s0',
            'VPUSH {d0}',
        ]

    def get_mod_instructions():
        idx = div_seq[0]
        div_seq[0] += 1
        return [
            '@ modulo: sem UDIV, por subtracao',
            'VPOP {d1}', 'VPOP {d0}',
            'VCVT.S32.F64 s0, d0', 'VCVT.S32.F64 s1, d1',
            'VMOV r0, s0',
            'VMOV r1, s1',
            'MOV r3, #0',
            'CMP r0, #0',
            f'BGE mod_pos_{idx}',
            'RSB r0, r0, #0',
            'MOV r3, #1',
            f'mod_pos_{idx}:',
            'CMP r1, #0',
            f'BGE mod_loop_{idx}',
            'RSB r1, r1, #0',
            f'mod_loop_{idx}:',
            'CMP r0, r1',
            f'BLT mod_end_{idx}',
            'SUB r0, r0, r1',
            f'B mod_loop_{idx}',
            f'mod_end_{idx}:',
            'CMP r3, #1',
            f'BNE mod_store_{idx}',
            'RSB r0, r0, #0',
            f'mod_store_{idx}:',
            'VMOV s0, r0',
            'VCVT.F64.S32 d0, s0',
            'VPUSH {d0}',
        ]

    ASSEMBLY_OPERATORS = {
        '+': ['VPOP {d1}', 'VPOP {d0}', 'VADD.F64 d0, d0, d1', 'VPUSH {d0}'],
        '-': ['VPOP {d1}', 'VPOP {d0}', 'VSUB.F64 d0, d0, d1', 'VPUSH {d0}'],
        '*': ['VPOP {d1}', 'VPOP {d0}', 'VMUL.F64 d0, d0, d1', 'VPUSH {d0}'],
        '/': ['VPOP {d1}', 'VPOP {d0}', 'VDIV.F64 d0, d0, d1', 'VPUSH {d0}'],
    }

    header = [
        '@ Assembly ARMv7 gerado pelo compilador RPN',
        '@ Target: CPUlator DE1-SoC v16.1  (ARMv7-A, Cortex-A9)',
        '@ Para ver cada resultado pressione KEY0 no CPUlator',
        '.syntax unified',
        '.arch armv7-a',
        '.fpu vfpv3-d16',
        '.global _start',
        '.text',
        '',
        '_start:',
        '@ aponta SP para area de stack VFP dedicada',
        'LDR SP, =vfp_stack_top',
        '',
        '@ limpa displays e LEDs na inicializacao',
        f'LDR r0, ={_ADDR_HEX10}',
        'MOV r1, #0',
        'STR r1, [r0]',
        f'LDR r0, ={_ADDR_HEX54}',
        'STR r1, [r0]',
        f'LDR r0, ={_ADDR_LEDS}',
        'STR r1, [r0]',
        '',
    ]

    footer = [
        '',
        'end:',
        'B end',
        '',
        '.ltorg',
    ]

    instructions = []

    for line_idx, tokens in enumerate(all_tokens):
        instructions.append(f'@ ---- linha {line_idx + 1} ----')

        for token in tokens:
            match token.token_type:

                case TokenType.PARENTHESIS:
                    pass

                case TokenType.INT | TokenType.FLOAT:
                    label = get_val_label(token.value)
                    instructions.extend([
                        f'LDR r0, ={label}',
                        'VLDR d0, [r0]',
                        'VPUSH {d0}',
                    ])

                case TokenType.OPERATOR:
                    if token.value == '^':
                        instructions.extend(get_pow_instructions())
                    elif token.value == '//':
                        instructions.extend(get_floordiv_instructions())
                    elif token.value == '%':
                        instructions.extend(get_mod_instructions())
                    else:
                        instructions.extend(
                            ASSEMBLY_OPERATORS.get(token.value,
                                                   ['@ operador nao suportado'])
                        )

                case TokenType.MEM_WRITE:
                    label = get_mem_label(token.value)
                    instructions.extend([
                        f'@ MEM_WRITE -> {token.value}',
                        f'LDR r0, ={label}',
                        'VPOP {d0}',
                        'VSTR d0, [r0]',
                        'VLDR d0, [r0]',
                        'VPUSH {d0}',
                    ])

                case TokenType.MEM_READ:
                    label = get_mem_label(token.value)
                    instructions.extend([
                        f'@ MEM_READ <- {token.value}',
                        f'LDR r0, ={label}',
                        'VLDR d0, [r0]',
                        'VPUSH {d0}',
                    ])

                case TokenType.KEYWORD:
                    # RES: endereço = history + (line_idx - N) * 8
                    # Calculado com base absoluta para evitar off-by-one
                    instructions.extend([
                        '@ RES: recupera resultado de N linhas anteriores',
                        'VPOP {d0}',
                        'VCVT.S32.F64 s0, d0',
                        'VMOV r0, s0',              '@ r0 = N',
                        'LDR r1, =history',         '@ r1 = base do historico',
                        f'MOV r2, #{line_idx}',     '@ r2 = indice da linha atual',
                        'SUB r2, r2, r0',           '@ r2 = line_idx - N',
                        'LSL r2, r2, #3',           '@ r2 = (line_idx - N) * 8',
                        'ADD r1, r1, r2',           '@ r1 = &history[line_idx - N]',
                        'VLDR d0, [r1]',
                        'VPUSH {d0}',
                    ])

                case TokenType.MEM:
                    instructions.append('@ MEM sem contexto semantico — ignorado')

                case TokenType.ERROR:
                    instructions.append(f'@ token invalido: {token.value}')

        # Salva resultado no histórico
        instructions.extend(_save_history(line_idx))

        # Exibe nos displays 7-segmentos e LEDs
        instructions.extend(_display_instructions(line_idx, div_seq))

        # Aguarda KEY0 entre linhas (exceto após a última)
        if line_idx < num_lines - 1:
            instructions.extend(_wait_key0(line_idx))

        # Pool de literais por linha para evitar "out of range"
        instructions.extend([
            f'B _ap{line_idx}',
            '.ltorg',
            f'_ap{line_idx}:',
            '',
        ])

    lines = header + instructions + footer + data_lines
    codigo_assembly.extend(lines)
