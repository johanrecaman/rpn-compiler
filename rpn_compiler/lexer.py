from dataclasses import dataclass
from enum import Enum


class TokenType(Enum):
    FLOAT = "float"
    INT = "int"
    OPERATOR = "operator"
    PARENTHESIS = "parenthesis"
    KEYWORD = "keyword"
    MEM = "mem"
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
        case _:
            if char.isdigit():
                buffer.append(char)
                return integer_state
            if char.isupper():
                buffer.append(char)
                return letter_state
            if char != " ":
                buffer.append(char)
                return error_state
            return initial_state


def operator_state(char, buffer, tokens):
    save_token(TokenType.OPERATOR, buffer[0], tokens)
    buffer.clear()
    return initial_state(char, buffer, tokens)


def parenthesis_state(char, buffer, tokens):
    save_token(TokenType.PARENTHESIS, buffer[0], tokens)
    buffer.clear()
    return initial_state(char, buffer, tokens)


def slash_state(char, buffer, tokens):
    if char != buffer[0]:
        save_token(TokenType.OPERATOR, buffer[0], tokens)
        buffer.clear()
        return initial_state(char, buffer, tokens)
    buffer.append(char)
    save_token(TokenType.OPERATOR, "".join(buffer), tokens)
    buffer.clear()
    return initial_state


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


def float_state(char, buffer, tokens):
    if char == ".":
        buffer.append(char)
        return error_state
    if char.isdigit():
        buffer.append(char)
        return float_state
    save_token(TokenType.FLOAT, "".join(buffer), tokens)
    buffer.clear()
    return initial_state(char, buffer, tokens)


def dot_state(char, buffer, tokens):
    if not char.isdigit():
        buffer.append(char)
        return error_state
    buffer.append(char)
    return float_state


def letter_state(char, buffer, tokens):
    if char.isupper():
        buffer.append(char)
        return letter_state
    if char.islower():
        buffer.append(char)
        return error_state
    word = "".join(buffer)
    if word == "RES":
        save_token(TokenType.KEYWORD, word, tokens)
    else:
        save_token(TokenType.MEM, word, tokens)
    buffer.clear()
    return initial_state(char, buffer, tokens)


def error_state(char, buffer, tokens):
    save_token(TokenType.ERROR, "".join(buffer), tokens)
    buffer.clear()
    return error_state

def parseExpressao(line, tokens):
    buffer = []
    state = initial_state
    for char in line + " ":
        state = state(char, buffer, tokens)
    parens = sum(1 if t.value == '(' else -1 for t in tokens if t.token_type == TokenType.PARENTHESIS)
    if parens != 0:
        save_token(TokenType.ERROR, 'parenthesis', tokens)