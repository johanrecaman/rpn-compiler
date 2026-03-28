# Compilador RPN → Assembly ARMv7

> **Instituição:** Pontifícia Universidade Católica do Paraná
> **Disciplina:** Construção de Interpretadores
> **Professor:** Frank Alcantara
> **Grupo:** ra1-55

## Integrantes (ordem alfabética)

| Nome | GitHub |
|------|--------|
| Johan Recaman | [@johanrecaman](https://github.com/johanrecaman) |
| Nicole Guarnieri | [@nick11nic](https://github.com/nick11nic) |

---

## Descrição

Este projeto implementa a **Fase 1** de um compilador para uma linguagem de expressões aritméticas em **Notação Polonesa Reversa (RPN)**. O programa:

1. Lê um arquivo de texto com expressões RPN (uma por linha)
2. Realiza a **análise léxica** usando um Autômato Finito Determinístico (AFD) implementado com funções de estado
3. Gera **código Assembly ARMv7** funcional para o simulador [CPUlator DE1-SoC v16.1](https://cpulator.01xz.net/?sys=arm-de1soc)

> ⚠️ **Nenhum cálculo da linguagem é realizado em Python.** O executor Python (`executor.py`) existe exclusivamente para validação do analisador léxico durante o desenvolvimento. Todos os cálculos reais ocorrem no código Assembly gerado, executado no CPUlator ARMv7 DE1-SoC(v16.1).

---

## Estrutura do Projeto

```
ra1-55/
├── rpn_compiler/
│   ├── __init__.py
│   ├── lexer.py          # parseExpressao + AFD (Aluno 1)
│   ├── executor.py       # executarExpressao — só para validação (Aluno 2)
│   ├── assembly.py       # gerarAssembly (Aluno 3)
│   └── main.py           # lerArquivo + exibirResultados + main (Aluno 4)
├── tests/
│   ├── teste1.txt        # ≥ 10 linhas, todas as operações e comandos especiais
│   ├── teste2.txt
│   └── teste3.txt
├── output/               # gerado automaticamente na execução
│   ├── <base>_tokens.txt
│   └── <base>_assembly.asm
├── pyproject.toml
├── poetry.lock
└── README.md
```

---

## Linguagem Suportada

### Operadores

| Operador | Sintaxe | Descrição |
|----------|---------|-----------|
| `+` | `(A B +)` | Adição |
| `-` | `(A B -)` | Subtração |
| `*` | `(A B *)` | Multiplicação |
| `/` | `(A B /)` | Divisão real |
| `//` | `(A B //)` | Divisão inteira |
| `%` | `(A B %)` | Resto da divisão inteira |
| `^` | `(A B ^)` | Potenciação (B inteiro ≥ 0) |

### Comandos Especiais

| Comando | Descrição |
|---------|-----------|
| `(N RES)` | Retorna o resultado da expressão N linhas anteriores |
| `(V MEM)` | Armazena o valor V na memória chamada MEM |
| `(MEM)` | Retorna o valor armazenado em MEM |

> `MEM` pode ser qualquer sequência de letras maiúsculas (ex.: `X`, `VAR`, `TOTAL`). `RES` é a única keyword da linguagem.

### Exemplos de expressões válidas

```
(3.14 2.0 +)
((1.5 2.0 *) (3.0 4.0 *) /)
(10.5 CONTADOR)
(2 RES)
((A B +) (C D *) /)
```

---

## Pré-requisitos

- Python 3.10 ou superior
- [Poetry](https://python-poetry.org/docs/#installation)

---

## Instalação

```bash
# Clone o repositório
git clone https://github.com/<seu-usuario>/ra1-55.git
cd ra1-55

# Instale as dependências com Poetry
poetry install
```

---

## Execução

```bash
poetry run python main.py <arquivo_de_entrada>
```

**Exemplos:**

```bash
poetry run python main.py tests/teste1.txt
poetry run python main.py tests/teste2.txt
poetry run python main.py tests/teste3.txt
```

Após a execução, os arquivos gerados estarão em `output/`:

- `output/<base>_tokens.txt` — vetor de tokens em formato JSON
- `output/<base>_assembly.asm` — código Assembly ARMv7 gerado

---

## Executando os Testes do Analisador Léxico

```bash
poetry run pytest tests/
```

Os testes cobrem:

- Entradas válidas: números reais, inteiros, operadores, comandos especiais, parênteses
- Entradas inválidas: números malformados (`3.14.5`, `3,45`), tokens desconhecidos, parênteses desbalanceados

---

## Usando o Assembly no CPUlator

1. Acesse [cpulator.01xz.net/?sys=arm-de1soc](https://cpulator.01xz.net/?sys=arm-de1soc)
2. Selecione **ARMv7 DE1-SoC v16.1**
3. Cole o conteúdo do arquivo `.asm` gerado em `output/`
4. Compile e execute
5. Pressione **KEY0** para avançar entre os resultados de cada linha
6. Os resultados são exibidos nos **displays de 7 segmentos (HEX5–HEX0)** e nos **10 LEDs vermelhos**

### Interface de saída no CPUlator

| Periférico | Uso |
|------------|-----|
| HEX3–HEX0 (`0xFF200020`) | 4 dígitos menos significativos |
| HEX5–HEX4 (`0xFF200030`) | 2 dígitos mais significativos (inclui sinal `−`) |
| LEDs vermelhos (`0xFF200000`) | 10 bits inferiores do valor inteiro |
| KEY0 (`0xFF200050`) | Avança para o resultado da próxima linha |

---

## Analisador Léxico — AFD

O AFD é implementado em `rpn_compiler/lexer.py` com as seguintes funções de estado:

| Função de estado | Descrição |
|-----------------|-----------|
| `initial_state` | Estado inicial — despacha para o estado correto |
| `integer_state` | Lendo dígitos de um número inteiro |
| `dot_state` | Leu ponto decimal — aguarda dígito |
| `float_state` | Lendo parte fracionária |
| `error_float_state` | Número malformado (ex.: `3.14.5`) |
| `operator_state` | Operador simples (`+`, `-`, `*`, `%`, `^`) |
| `slash_state` | Pode ser `/` ou `//` |
| `parenthesis_state` | Parênteses `(` ou `)` |
| `letter_state` | Identificador em maiúsculas (`RES`, `MEM`, etc.) |
| `error_identifier_state` | Identificador com minúsculas/dígitos (inválido) |
| `error_state` | Caractere inválido |

Após a análise, `_resolve_mem_semantics` distingue `MEM_READ` de `MEM_WRITE` com base no contexto (token precedente).

---

## Tokens Gerados

O arquivo `output/<base>_tokens.txt` é salvo em JSON. Exemplo:

```json
[
  { "type": "parenthesis", "value": "(" },
  { "type": "float",       "value": "3.14" },
  { "type": "float",       "value": "2.0" },
  { "type": "operator",    "value": "+" },
  { "type": "parenthesis", "value": ")" }
]
```

Tipos possíveis: `int`, `float`, `operator`, `parenthesis`, `keyword`, `mem`, `mem_read`, `mem_write`, `error`.

---

## Observações sobre o Código Assembly Gerado

- Todos os números são armazenados em **double (IEEE 754, 64 bits)** usando registradores VFP (`d0`–`d15`)
- A pilha VFP usa uma área dedicada (`vfp_stack` em `.data`) apontada pelo `SP`
- Divisão inteira (`//`) e resto (`%`) são implementados por **subtração sucessiva** (sem `UDIV`)
- Potenciação (`^`) é implementada por **multiplicação repetida** em loop
- O histórico de resultados (`RES`) é salvo em `history` na seção `.data`
- Literais de ponto flutuante são carregados via `VLDR` a partir de labels na seção `.data`
- Pools de literais (`.ltorg`) são inseridos a cada linha para evitar erros de alcance

---

## Licença

Trabalho acadêmico — uso restrito conforme regras da disciplina.