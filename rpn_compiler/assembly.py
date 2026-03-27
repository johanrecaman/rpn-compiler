from rpn_compiler.lexer import TokenType

def gerarAssembly(all_tokens, codigo_assembly):
    mem_addresses = {}
    val_labels = {}
    pow_counter = [0]
    header = ['.global _start', '_start:']
    footer = ['SVC #0']
    instructions = []
    num_lines = len(all_tokens)
    data_section = [
        '.data',
        f'history: .space {num_lines * 8}',
        'val_1_0: .double 1.0',
    ]

    def get_mem_label(name):
        if name not in mem_addresses:
            mem_addresses[name] = f'mem_{name}'
            data_section.append(f'mem_{name}: .double 0.0')
        return mem_addresses[name]

    def get_val_label(value):
        label = f'val_{value.replace(".", "_")}'
        if label not in val_labels:
            val_labels[label] = True
            data_section.append(f'{label}: .double {value}')
        return label

    def get_pow_instructions():
        idx = pow_counter[0]
        pow_counter[0] += 1
        return [
            'VPOP {d1}',
            'VPOP {d0}',
            'VCVT.S32.F64 s0, d1',
            'VMOV r2, s0',
            'LDR r3, =val_1_0',
            'VLDR d1, [r3]',
            f'pow_loop_{idx}:',
            'CMP r2, #0',
            f'BEQ pow_end_{idx}',
            'VMUL.F64 d1, d1, d0',
            'SUB r2, r2, #1',
            f'B pow_loop_{idx}',
            f'pow_end_{idx}:',
            'VPUSH {d1}',
        ]

    ASSEMBLY_OPERATORS = {
        '+': ['VPOP {d1}', 'VPOP {d0}', 'VADD.F64 d0, d0, d1', 'VPUSH {d0}'],
        '-': ['VPOP {d1}', 'VPOP {d0}', 'VSUB.F64 d0, d0, d1', 'VPUSH {d0}'],
        '*': ['VPOP {d1}', 'VPOP {d0}', 'VMUL.F64 d0, d0, d1', 'VPUSH {d0}'],
        '/': ['VPOP {d1}', 'VPOP {d0}', 'VDIV.F64 d0, d0, d1', 'VPUSH {d0}'],
        '//': [
            'VPOP {d1}', 'VPOP {d0}',
            'VCVT.S32.F64 s0, d0', 'VCVT.S32.F64 s1, d1',
            'VMOV r0, s0', 'VMOV r1, s1',
            'SDIV r0, r0, r1',
            'VMOV s0, r0', 'VCVT.F64.S32 d0, s0',
            'VPUSH {d0}'
        ],
        '%': [
            'VPOP {d1}', 'VPOP {d0}',
            'VCVT.S32.F64 s0, d0', 'VCVT.S32.F64 s1, d1',
            'VMOV r0, s0', 'VMOV r1, s1',
            'SDIV r2, r0, r1',
            'MLS r0, r2, r1, r0',
            'VMOV s0, r0', 'VCVT.F64.S32 d0, s0',
            'VPUSH {d0}'
        ],
    }

    for line_idx, tokens in enumerate(all_tokens):
        prev_token = None
        instructions.append(f'@ linha {line_idx + 1}')
        for token in tokens:
            match token.token_type:
                case TokenType.INT | TokenType.FLOAT:
                    label = get_val_label(token.value)
                    instructions.extend([f'LDR r0, ={label}', 'VLDR d0, [r0]', 'VPUSH {d0}'])
                case TokenType.OPERATOR:
                    if token.value == '^':
                        instructions.extend(get_pow_instructions())
                    else:
                        instructions.extend(
                            ASSEMBLY_OPERATORS.get(token.value, ['@ operador nao suportado'])
                        )
                case TokenType.MEM:
                    label = get_mem_label(token.value)
                    if prev_token and prev_token.token_type in (TokenType.INT, TokenType.FLOAT, TokenType.OPERATOR):
                        instructions.extend([f'LDR r0, ={label}', 'VPOP {d0}', 'VSTR d0, [r0]'])
                    else:
                        instructions.extend([f'LDR r0, ={label}', 'VLDR d0, [r0]', 'VPUSH {d0}'])
                case TokenType.KEYWORD:
                    instructions.extend([
                        'VPOP {d0}',
                        'VCVT.S32.F64 s0, d0',
                        'VMOV r0, s0',
                        'LDR r1, =history',
                        f'MOV r2, #{line_idx}',
                        'SUB r2, r2, r0',
                        'LSL r2, r2, #3',
                        'ADD r1, r1, r2',
                        'VLDR d0, [r1]',
                        'VPUSH {d0}'
                    ])
                case TokenType.ERROR:
                    instructions.append('@ token invalido ignorado')
            prev_token = token

        instructions.extend([
            'VPOP {d0}',
            'LDR r0, =history',
            f'MOV r1, #{line_idx * 8}',
            'ADD r0, r0, r1',
            'VSTR d0, [r0]',
            'VPUSH {d0}'
        ])

    lines = data_section + ['', '.text'] + header + instructions + footer
    codigo_assembly.extend(lines)
