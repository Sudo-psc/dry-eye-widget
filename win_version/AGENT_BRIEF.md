# AGENT_BRIEF — Missão: gerar a versão Windows do Dry Eye Widget

> **Você é um agente Claude rodando em uma máquina Windows** (ou em CI
> `windows-latest`). Sua tarefa é transformar este projeto Flutter, já
> multiplataforma, em uma **build Windows funcional, empacotada e publicável**.

## Contexto do produto

O **Dry Eye Widget** é um widget flutuante (always-on-top) que lembra o usuário
de seguir a regra **20-20-20** (a cada 20 min, olhar 20 segundos para ~6 m de
distância), com lembrete opcional de colírio, ícone na bandeja, notificações e
pausa automática quando o sistema fica ocioso. É um produto de saúde ocular
feito por um médico oftalmologista — **tom cuidadoso, sem promessas médicas**.

## Escopo (faça)

1. Preparar o ambiente Windows (Flutter + Visual Studio 2022 C++).
2. Resolver dependências (`flutter pub get`) e gerar ícones (`flutter_launcher_icons`).
3. Compilar em Release (`flutter build windows --release`).
4. **Validar manualmente** o comportamento específico de Windows (lista em
   `03-notas-plataforma.md`): transparência da janela, always-on-top, arrastar a
   bolinha, bandeja, notificações toast, início com o login, pausa por ociosidade.
5. Corrigir apenas o que for necessário para o Windows, com mudanças cirúrgicas e
   **protegidas por `Platform.isWindows`** quando o comportamento divergir do macOS.
6. Empacotar: instalador Inno Setup e/ou ZIP portátil (`04-empacotamento.md`).
7. Adicionar o workflow de CI (`05-ci-github-actions.md`).
8. Atualizar `README.md` e `README.en.md` com download para Windows.
9. Rodar o checklist final (`06-checklist-verificacao.md`).

## Fora de escopo (não faça)

- **Não reescreva** a lógica do app nem a UI. Ela é compartilhada e já funciona.
- **Não quebre o macOS.** Qualquer ajuste de plataforma deve ser condicional.
- **Não suba binários grandes** ao repositório (o `.gitignore` já ignora `dist/`
  e `/build/`). Artefatos vão para o GitHub Releases, não para o git.
- **Não bump de versão** sem instrução explícita. Se for publicar uma release,
  alinhe `pubspec.yaml` (`version:`) e `AppInfo.version` em `lib/utils/constants.dart`.
- **Não toque** em chaves/segredos. O `GITHUB_TOKEN` do Actions é suficiente.

## Princípios de execução

- **Evidência > suposição.** Compile e rode de fato; não declare "pronto" sem ter
  visto a janela transparente, a bandeja e uma notificação reais.
- **Mudanças mínimas e reversíveis.** Prefira condicionar por plataforma a alterar
  o caminho comum.
- **Cada correção precisa de justificativa** ligada a um sintoma observado no Windows.
- **Mantenha o português** nos comentários de código e mensagens, seguindo o
  estilo já presente no projeto.

## Pontos de atenção já mapeados (resumo — detalhes em `03-notas-plataforma.md`)

| Área | Risco no Windows | Onde olhar |
|------|------------------|-----------|
| Transparência da janela | Fundo pode renderizar opaco/preto | `lib/main.dart` (`Window.setEffect(WindowEffect.transparent)`) |
| Ícone da bandeja | Windows prefere `.ico`; o app gera PNG dinâmico | `lib/services/tray_service.dart`, `lib/utils/eye_icon.dart` |
| Notificações toast | Exigem atalho no Menu Iniciar com AppUserModelID | `lib/services/notification_service.dart` (`ShortcutPolicy.requireCreate`) |
| Início com o login | Caminho do `.exe` deve ser estável (instalado) | `lib/services/startup_service.dart` |
| Tempo ocioso | Já implementado via `GetLastInputInfo` | `windows/runner/flutter_window.cpp` (canal `dry_eye_widget/idle`) |
| Metadados do `.exe` | Nome/empresa/versão do binário | `windows/runner/Runner.rc` |

## Critério de "pronto"

`06-checklist-verificacao.md` 100% verde, com:
- executável Release que abre sem console, janela transparente e funcional;
- instalador e/ou ZIP gerados e testados em um Windows limpo (ou VM);
- workflow de CI passando;
- READMEs atualizados.

Ao terminar, entregue um resumo com: o que foi compilado, quais ajustes de
plataforma foram necessários (com o porquê), artefatos gerados e como publicá-los.
