# 06 — Checklist de verificação final

Não declare "pronto" sem marcar **todos** os itens. Cada item exige observação
real (rodar/instalar), não suposição.

## Ambiente e build

- [ ] `flutter doctor -v` sem ❌ (Visual Studio com C++ verde).
- [ ] `dart run flutter_launcher_icons` regenerou `windows/runner/resources/app_icon.ico`.
- [ ] `flutter build windows --release` concluiu sem erros.
- [ ] `build\windows\x64\runner\Release\dry_eye_widget.exe` abre sem janela de console.

## Comportamento (rodando o Release)

- [ ] Bolinha com **fundo transparente** (sem retângulo/fundo opaco) sobre janela colorida.
- [ ] Bolinha **always-on-top** (fica acima de outras janelas).
- [ ] **Arrastar** a bolinha funciona; posição é **restaurada** após reabrir.
- [ ] Testado com **escala 125%/150%** e em **2 monitores** (bolinha nasce na tela).
- [ ] **Bandeja:** ícone aparece, atualiza o progresso, clique esquerdo e direito abrem o menu.
- [ ] Itens do menu (habilitar/desabilitar, iniciar pausa, configurações, sair) funcionam.
- [ ] **Ciclo 20-20-20:** a pausa dispara, overlay/cartão aparece, áudio toca (se ligado).
- [ ] **Lembrete de colírio** (se habilitado) aparece no intervalo configurado.
- [ ] **Pausa por ociosidade:** ~2 min sem input pausa o ciclo; voltar a usar retoma.
- [ ] **Configurações** salvam e persistem após reiniciar o app.
- [ ] **Sair** encerra o processo (sem `dry_eye_widget.exe` órfão no Gerenciador de Tarefas).

## Pós-instalação (instalador)

- [ ] Instalador gerado (`dist\DryEyeWidget-Setup-x64.exe`).
- [ ] Instala em Windows limpo/VM; atalho no Menu Iniciar criado.
- [ ] **Notificações toast** aparecem (válido sobretudo na versão instalada).
- [ ] **Iniciar com o login:** ligar → reiniciar → app abre; desligar → não abre.
- [ ] Desinstalação remove o app corretamente.

## Distribuição

- [ ] ZIP portátil gerado (`dist\DryEyeWidget-windows-x64.zip`) e testado.
- [ ] Nenhum binário comitado no git (`dist/` e `build/` continuam ignorados).
- [ ] Workflow `.github/workflows/windows-build.yml` presente e **passando**.
- [ ] `pubspec.yaml` (`version:`) e `AppInfo.version` em sincronia.

## Documentação

- [ ] `README.md` e `README.en.md` com badge/link de download para Windows.
- [ ] Se não houver assinatura de código, README menciona o aviso do SmartScreen.

## Regressão macOS

- [ ] Nenhuma mudança quebrou o macOS: ajustes de plataforma estão sob
      `Platform.isWindows`/`isMacOS`; o ramo macOS de transparência
      (`Window.makeWindowFullyTransparent`) permanece intacto.

## Entrega

- [ ] Resumo final com: ajustes de plataforma feitos (e porquê), artefatos
      gerados e instruções de publicação.
