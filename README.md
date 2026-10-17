# DevTools

Canivete suíço para desenvolvedores, em Flutter: ferramentas pequenas para o dia a dia que rodam
inteiramente no dispositivo. Nada do que você digita é enviado a um servidor.

| Ferramenta              | O que faz                                                                                   |
| ----------------------- | ------------------------------------------------------------------------------------------- |
| **JSON Formatter**      | Formata (2 espaços, 4 espaços ou tab), minifica e valida. Erros mostram linha, coluna e dica. |
| **UUID Generator**      | Gera UUID v4, um ou até 1000 de uma vez. Copia um a um ou todos.                            |
| **Base64**              | Texto ⇄ Base64 com Unicode (acentos, emoji) e opção base64url.                              |
| **URL Encoder/Decoder** | Encode/decode com opção de URL completa e de "+ como espaço".                               |
| **Timestamp Converter** | Unix timestamp (segundos ou ms, com detecção automática) ⇄ data em UTC, local e ISO 8601.   |
| **JWT Decoder**         | Mostra header, payload e datas do token. Só decodifica: a assinatura não é verificada.     |

Em telas largas as ferramentas ficam numa barra lateral; no celular, num menu lateral (drawer).
A busca (ícone de lupa ou <kbd>Ctrl</kbd> <kbd>K</kbd>) abre qualquer ferramenta, e o tema claro/escuro
segue o sistema, com botão para trocar.

## Como executar

```bash
flutter pub get
flutter run -d chrome     # web
flutter run               # celular ou emulador conectado
```

## Testes e análise

```bash
flutter test      # testes da lógica de cada ferramenta e da navegação
flutter analyze   # análise estática (regras do flutter_lints)
```

## Estrutura

```
lib/
├── main.dart                 # runApp
├── app.dart                  # MaterialApp, tema, barra lateral/drawer, busca
├── theme.dart                # cores (Material 3) e fonte monoespaçada
├── core/                     # Result, Base64 com UTF-8, tamanho em bytes
├── widgets/                  # componentes compartilhados (campo de código, copiar, mensagens)
└── tools/
    ├── tool_catalog.dart     # lista das ferramentas e busca
    ├── json/                 # json_formatter.dart (lógica) + json_page.dart (tela)
    ├── uuid/  base64/  url/  timestamp/  jwt/
test/                         # um arquivo de teste por ferramenta + app_test.dart
```

Cada ferramenta separa a **lógica** (funções Dart puras, sem Flutter, testadas diretamente) da
**tela**. Para adicionar uma ferramenta: crie a pasta em `lib/tools/` e adicione uma entrada em
`tool_catalog.dart`.
