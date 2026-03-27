import operator
from rpn_compiler.lexer import TokenType

OPERATORS = {
    "+": operator.add,
    "-": operator.sub,
    "*": operator.mul,
    "/": operator.truediv,
    "%": operator.mod,
    "^": operator.pow,
    "//": operator.floordiv,
}


def executarExpressao(tokens, history, memory):
    stack = []
    for token in tokens:
        match token.token_type:
            case TokenType.ERROR:
                history.append("error")
                return "error"
            case TokenType.INT | TokenType.FLOAT:
                stack.append(float(token.value))
            case TokenType.OPERATOR:
                b, a = stack.pop(), stack.pop()
                if token.value in ('/', '//', '%') and b == 0:
                    history.append('error')
                    return 'error'
                if token.value in ("//", "%"):
                    a, b = int(a), int(b) if b != 0 else 1
                stack.append(OPERATORS[token.value](a, b))
            case TokenType.MEM:
                if not stack:
                    stack.append(memory.get(token.value, "error"))
                    continue
                memory[token.value] = stack.pop()
            case TokenType.KEYWORD:
                n = int(stack.pop())
                stack.append(history[-n] if n <= len(history) else "error")
    if len(stack) > 1:
        history.append('error')
        return 'error'

    result = stack.pop() if stack else None
    history.append(result)

    return result
