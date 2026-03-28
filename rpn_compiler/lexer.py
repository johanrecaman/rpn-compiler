# Integrantes (ordem alfabética):
#   Johan Recaman - johanrecaman
#   Nicole Guarnieri - nick11nic
# Grupo: ra1-55

from dataclasses import dataclass
from enum import Enum

class TokenType(Enum):
    FLOAT = "float"
    INT = "int"
    OPERATOR = "operator"
    PARENTHESIS = "parenthesis"
    KEYWORD = "keyword"
    MEM = "mem"
    MEM_READ = "mem_read"   # (MEM) — leitura sem valor anterior
    MEM_WRITE = "mem_write" # (V MEM) — escrita com valor anterior
    ERROR = "error"

@dataclass
class Token:
    token_type: TokenType
    value: str

def save_token(token_type, value, tokens):
    tokens.append(Token(token_type, value))

def initial_state(char, buffer, tokens):
    match char:
        case "(" | ")":
            buffer.append(char)
            return parenthesis_state
        case "+" | "-" | "*" | "%" | "^":
            buffer.append(char)
            return operator_state
        case "/":
            buffer.append(char)
            return slash_state
        case " " | "\t":
            return initial_state
        case _:
            if char.isdigit():
                buffer.append(char)
                return integer_state
            if char.isupper():
                buffer.append(char)
                return letter_state
            buffer.append(char)
            return error_state


def operator_state(char, buffer, tokens):
    save_token(TokenType.OPERATOR, buffer[0], tokens)
    buffer.clear()
    return initial_state(char, buffer, tokens)


def parenthesis_state(char, buffer, tokens):
    save_token(TokenType.PARENTHESIS, buffer[0], tokens)
    buffer.clear()
    return initial_state(char, buffer, tokens)


def slash_state(char, buffer, tokens):
    if char == "/":
        buffer.append(char)
        save_token(TokenType.OPERATOR, "".join(buffer), tokens)
        buffer.clear()
        return initial_state  # próximo char ainda não chegou — aguarda
    save_token(TokenType.OPERATOR, buffer[0], tokens)
    buffer.clear()
    return initial_state(char, buffer, tokens)


def integer_state(char, buffer, tokens):
    if char.isdigit():
        buffer.append(char)
        return integer_state
    if char == ".":
        buffer.append(char)
        return dot_state
    save_token(TokenType.INT, "".join(buffer), tokens)
    buffer.clear()
    return initial_state(char, buffer, tokens)


def dot_state(char, buffer, tokens):
    if char.isdigit():
        buffer.append(char)
        return float_state
    save_token(TokenType.ERROR, "".join(buffer), tokens)
    buffer.clear()
    return initial_state(char, buffer, tokens)


def float_state(char, buffer, tokens):
    if char.isdigit():
        buffer.append(char)
        return float_state
    if char == ".":
        # Segundo ponto: número malformado (ex: 3.14.5)
        buffer.append(char)
        return error_float_state
    save_token(TokenType.FLOAT, "".join(buffer), tokens)
    buffer.clear()
    return initial_state(char, buffer, tokens)


def error_float_state(char, buffer, tokens):
    if char.isdigit() or char == ".":
        buffer.append(char)
        return error_float_state
    save_token(TokenType.ERROR, "".join(buffer), tokens)
    buffer.clear()
    return initial_state(char, buffer, tokens)


def letter_state(char, buffer, tokens):
    if char.isupper():
        buffer.append(char)
        return letter_state
    if char.islower() or char.isdigit():
        buffer.append(char)
        return error_identifier_state
    word = "".join(buffer)
    if word == "RES":
        save_token(TokenType.KEYWORD, word, tokens)
    else:
        save_token(TokenType.MEM, word, tokens)
    buffer.clear()
    return initial_state(char, buffer, tokens)


def error_identifier_state(char, buffer, tokens):
    if char.isalnum():
        buffer.append(char)
        return error_identifier_state
    save_token(TokenType.ERROR, "".join(buffer), tokens)
    buffer.clear()
    return initial_state(char, buffer, tokens)


def error_state(char, buffer, tokens):
    save_token(TokenType.ERROR, "".join(buffer), tokens)
    buffer.clear()
    return initial_state(char, buffer, tokens)

def _resolve_mem_semantics(tokens):
    result = []
    for i, tok in enumerate(tokens):
        if tok.token_type != TokenType.MEM:
            result.append(tok)
            continue

        prev_relevant = None
        for j in range(i - 1, -1, -1):
            if tokens[j].token_type != TokenType.PARENTHESIS:
                prev_relevant = tokens[j]
                break

        if prev_relevant and prev_relevant.token_type in (
            TokenType.INT, TokenType.FLOAT,
            TokenType.OPERATOR, TokenType.MEM_READ,
        ):
            result.append(Token(TokenType.MEM_WRITE, tok.value))
        else:
            result.append(Token(TokenType.MEM_READ, tok.value))

    return result


def parseExpressao(linha, tokens):
    buffer = []
    state = initial_state

    for char in linha + " ":
        state = state(char, buffer, tokens)

    balance = 0
    paren_error = False
    for t in tokens:
        if t.token_type == TokenType.PARENTHESIS:
            if t.value == "(":
                balance += 1
            else:
                balance -= 1
                if balance < 0:
                    paren_error = True
                    break
    if paren_error or balance != 0:
        save_token(TokenType.ERROR, "unbalanced_parenthesis", tokens)

    resolved = _resolve_mem_semantics(tokens)
    tokens.clear()
    tokens.extend(resolved)
