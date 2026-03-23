import sys
import os
import json
from rpn_compiler.executor import executarExpressao
from rpn_compiler.lexer import parseExpressao


def lerArquivo(file_path, lines):
    try:
        with open(file_path, "r") as file:
            lines.extend(file.readlines())
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        sys.exit(1)


def exportTokens(tokens, file_path):
    os.makedirs("output", exist_ok=True)
    base_name = os.path.splitext(os.path.basename(file_path))[0]
    with open(f"output/{base_name}_tokens.txt", "w") as f:
        json.dump(
            [{"type": t.token_type.value, "value": t.value} for t in tokens],
            f,
            indent=2,
        )


def main():
    if len(sys.argv) < 2:
        print("Error: Missing input file.")
        print("Usage: python main.py <input_file>")
        sys.exit(1)
    file_path = sys.argv[1]
    lines = []
    lerArquivo(file_path, lines)
    file_tokens = []
    history = []
    memory = {}
    for line in lines:
        line = line.strip()
        if line:
            tokens = []
            parseExpressao(line, tokens)
            file_tokens.extend(tokens)
            print(executarExpressao(tokens, history, memory))
    exportTokens(file_tokens, file_path)


if __name__ == "__main__":
    main()