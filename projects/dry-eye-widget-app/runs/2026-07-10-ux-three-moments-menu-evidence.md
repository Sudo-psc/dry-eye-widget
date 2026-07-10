# UX em três momentos — painel rápido

Data: 2026-07-10
Branch: `codex/ux-three-moments`
Worktree: `/Users/philipecruz/app_dry_eye_widget-ux-three-moments`

## Entrega

- Design aprovado e Decision Log registrados em
  `docs/superpowers/specs/2026-07-10-ux-three-moments-design.md`.
- Painel rápido dividido em página principal e página Sistema.
- Página principal preserva pausa, controle do ciclo, modo reunião, Hub de
  Saúde e Orientações.
- DVRS e Relatórios deixam de duplicar o primeiro nível e continuam acessíveis
  pelo Hub.
- Meus dados, atualização, configurações, Sobre e Sair ficam em Sistema, com
  ação Voltar explícita.
- Altura nominal do painel reduzida de 560 para 350 px.
- Referências de base quebradas a `WindowLayout` e `AppColors` corrigidas no
  worktree para recuperar a validação do commit de origem.
- Hub preserva a aba selecionada ao abrir fluxos adjacentes.
- Hub → DVRS → Relatório retorna ao DVRS e depois ao Hub.
- Hub → Relatório retorna diretamente ao Hub.
- DVRS aberto fora do Hub continua retornando ao contexto compacto.
- Hub reorganizado em Hoje, Evolução, DVRS e Relatórios.
- Evolução alterna internamente entre Hábitos e Indicadores.
- DVRS e Relatórios reutilizam seus widgets em modo incorporado, sem duplicar
  cálculo, persistência ou geração de PDF.
- Estados vazio, indisponível, erro e sucesso usam um componente comum com
  semântica, ícone, título e mensagem.
- Progresso, Tela e histórico DVRS usam vazios consistentes; coleta de tela
  desligada aparece como indisponível; Relatórios mostra erro e sucesso inline.
- A navegação superior é rolável e permanece utilizável em janela estreita com
  escala de texto de 160%.

## Verificação

- `flutter test test/floating_menu_test.dart test/window_layout_test.dart`:
  aprovado, 4 testes.
- `flutter analyze`: aprovado, zero issues.
- `flutter build macos --debug -t lib/main.dart`: aprovado; artefato em
  `build/macos/Build/Products/Debug/Dry Eye Widget.app`.
- `flutter test test/health_hub_screen_test.dart test/floating_menu_test.dart
  test/window_layout_test.dart`: aprovado, 5 testes.
- `flutter analyze` após a navegação contextual: aprovado, zero issues.
- Novo build macOS debug após a navegação contextual: aprovado.
- Testes focados após a incorporação do Hub: 20 aprovados, incluindo fluxo DVRS,
  relatório, painel rápido, layout e restauração de aba.
- `flutter analyze` após a incorporação: aprovado, zero issues.
- Build macOS debug após a incorporação: aprovado.
- QA automatizado do Hub em janela de 560 px e escala de texto de 160%: aprovado,
  sem overflow ou exceções.
- Asserção textual de `narrative_summary_test.dart` corrigida com radical estável
  antes do caractere acentuado.
- `flutter test`: 215 de 215 testes aprovados.
- `flutter analyze`: aprovado, zero issues.
- `flutter build macos --release -t lib/main.dart`: aprovado; app de release com
  59,2 MB em `build/macos/Build/Products/Release/Dry Eye Widget.app`.

## Próximos passos

1. Inspeção visual manual no macOS e Windows antes de uma release pública.
2. Avaliar golden tests quando houver ambiente gráfico estável entre plataformas.
