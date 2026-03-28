# Integrantes (ordem alfabética):
#   Johan Recaman - johanrecaman
#   Nicole Guarnieri - nick11nic
# Grupo: ra1-55

import sys
import os
import json

from rpn_compiler.assembly  import gerarAssembly
from rpn_compiler.lexer     import parseExpressao
from rpn_compiler.executor  import executarExpressao


def lerArquivo(file_path, lines):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines.extend(f.readlines())
    except FileNotFoundError:
        print(f"Erro: arquivo '{file_path}' nao encontrado.")
        sys.exit(1)
    except IOError as e:
        print(f"Erro ao ler '{file_path}': {e}")
        sys.exit(1)


def exportTokens(all_tokens_flat, file_path):
    """Salva o vetor de tokens da última execução em JSON."""
    os.makedirs('output', exist_ok=True)
    base = os.path.splitext(os.path.basename(file_path))[0]
    out_path = os.path.join('output', f'{base}_tokens.txt')
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(
            [{'type': t.token_type.value, 'value': t.value}
             for t in all_tokens_flat],
            f,
            indent=2,
            ensure_ascii=False,
        )
    print(f"Tokens salvos em: {out_path}")


def exportAssembly(codigo_assembly, file_path):
    os.makedirs('output', exist_ok=True)
    base = os.path.splitext(os.path.basename(file_path))[0]
    out_path = os.path.join('output', f'{base}_assembly.asm')
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(codigo_assembly))
    print(f"Assembly salvo em: {out_path}")


def exibirResultados(resultados):
    print('\n=== Resultados (referencia local — calculo real no CPUlator) ===')
    for i, r in enumerate(resultados, start=1):
        if isinstance(r, float):
            print(f'  Linha {i:>3}: {r:.10g}')
        else:
            print(f'  Linha {i:>3}: {r}')


def main():
    if len(sys.argv) < 2:
        print('Uso: python main.py <arquivo_de_entrada>')
        sys.exit(1)

    file_path = sys.argv[1]
    lines = []
    lerArquivo(file_path, lines)

    all_tokens_flat = []   # todos os tokens (para exportação)
    all_tokens      = []   # tokens agrupados por linha (para Assembly)

    for line in lines:
        line = line.strip()
        if not line:
            continue
        tokens = []
        parseExpressao(line, tokens)
        all_tokens_flat.extend(tokens)
        all_tokens.append(tokens)

    exportTokens(all_tokens_flat, file_path)

    history  = []
    memory   = {}
    resultados = []

    for tokens in all_tokens:
        resultado = executarExpressao(tokens, history, memory)
        resultados.append(resultado)

    exibirResultados(resultados)

    codigo_assembly = []
    gerarAssembly(all_tokens, codigo_assembly)
    exportAssembly(codigo_assembly, file_path)


if __name__ == '__main__':
    main()
