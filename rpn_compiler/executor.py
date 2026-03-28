# Integrantes (ordem alfabética):
#   Johan Recaman - johanrecaman
#   Nicole Guarnieri - nick11nic
# Grupo: ra1-55

# ATENÇÃO: este módulo serve APENAS para validação/testes do analisador léxico
# e verificação de semântica das expressões. Ele NÃO faz parte da solução
# principal do compilador. Os cálculos reais ocorrem no código Assembly gerado,
# executado no CPUlator ARMv7 DEC1-SOC(v16.1).

import operator as _op
from rpn_compiler.lexer import TokenType

_OPERATORS = {
    "+":  _op.add,
    "-":  _op.sub,
    "*":  _op.mul,
    "/":  _op.truediv,
    "%":  _op.mod,
    "^":  _op.pow,
    "//": _op.floordiv,
}


def executarExpressao(tokens, history, memory):
    stack = []

    for token in tokens:
        match token.token_type:

            case TokenType.ERROR:
                history.append("error")
                return "error"

            case TokenType.PARENTHESIS:
                pass

            case TokenType.INT:
                stack.append(float(int(token.value)))

            case TokenType.FLOAT:
                stack.append(float(token.value))

            case TokenType.OPERATOR:
                if len(stack) < 2:
                    history.append("error")
                    return "error"
                b = stack.pop()
                a = stack.pop()

                if token.value in ('/', '//', '%') and b == 0.0:
                    history.append("error")
                    return "error"

                if token.value == '^':
                    if b != int(b) or b < 0:
                        history.append("error")
                        return "error"
                    b = int(b)

                if token.value in ('//', '%'):
                    a, b = int(a), int(b)

                stack.append(float(_OPERATORS[token.value](a, b)))

            case TokenType.MEM_WRITE:
                # (V MEM): armazena topo da pilha
                if not stack:
                    history.append("error")
                    return "error"
                val = stack.pop()
                memory[token.value] = val
                stack.append(val)

            case TokenType.MEM_READ:
                val = memory.get(token.value, 0.0)
                stack.append(val)

            case TokenType.MEM:
                val = memory.get(token.value, 0.0)
                stack.append(val)

            case TokenType.KEYWORD:
                if not stack:
                    history.append("error")
                    return "error"
                n = int(stack.pop())
                if n <= 0 or n > len(history):
                    history.append("error")
                    return "error"
                stack.append(history[-n])

    if len(stack) != 1:
        history.append("error")
        return "error"

    result = stack[0]
    history.append(result)
    return result
