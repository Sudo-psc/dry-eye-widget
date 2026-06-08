# 03 — Notas de plataforma (Windows) e validação

Este é o documento mais importante. O código é compartilhado com o macOS; aqui
estão as diferenças reais do Windows, como **observar** o comportamento e como
**corrigir** sem quebrar o macOS. Toda correção de divergência deve ser
condicional (`Platform.isWindows` / `Platform.isMacOS`).

---

## 1. Transparência da janela (maior risco visual)

**Como é hoje** (`lib/main.dart`): após `waitUntilReadyToShow`, o app faz
`setAsFrameless`, `setBackgroundColor(Colors.transparent)` e, fora do macOS:

```dart
await Window.setEffect(effect: WindowEffect.transparent);
```

**O que pode dar errado no Windows:**

- O fundo da bolinha renderiza **opaco/preto** em vez de transparente.
- Aparece um **retângulo** ao redor da bolinha.
- A transparência funciona em release mas não em debug (ou vice-versa).

**Como validar:** rode a build **Release**, coloque a bolinha sobre uma janela
colorida (ex.: navegador) e confirme que só o círculo aparece — sem moldura.

**Como corrigir (em ordem de preferência):**

1. Garantir `WindowEffect.transparent` (já presente). Em algumas versões do
   `flutter_acrylic`, no Windows, `WindowEffect.transparent` exige que o
   `backgroundColor` da janela seja `Colors.transparent` **antes** do show — já é
   o caso.
2. Se ainda houver fundo opaco, testar `Window.setEffect(effect:
   WindowEffect.transparent, color: Colors.transparent)`.
3. Em Windows 11, alternativas de efeito (`WindowEffect.acrylic` / `mica`) dão um
   vidro borrado — **não** é o visual desejado aqui (queremos transparência
   total para a bolinha "flutuar"). Use só se a transparência pura falhar e
   documente a decisão.
4. Confirme que `MaterialApp`/`Scaffold` usam `backgroundColor: Colors.transparent`
   (já configurado em `DryEyeApp` e nas páginas).

**Não** altere o ramo do macOS (`Window.makeWindowFullyTransparent()`).

---

## 2. Always-on-top, frameless e arrastar a bolinha

`window_manager` suporta tudo isso no Windows. Comportamento esperado:

- `setAlwaysOnTop(true)` — a bolinha fica acima das demais janelas.
- `setAsFrameless` + `titleBarStyle: hidden` — sem barra de título.
- `windowManager.startDragging()` (em `_onBallDragStart`) — arrastar a janela
  pela bolinha.

**Validar:** arraste a bolinha pelos quatro cantos; feche e reabra o app e
confirme que a posição foi **restaurada** (persistida via `shared_preferences`,
chaves `ball_x`/`ball_y`).

**Atenção a múltiplos monitores e DPI:** `screen_retriever` retorna coordenadas
em pixels físicos/lógicos dependendo do scaling. Teste com **escala do Windows a
125%/150%** (Configurações → Tela) e em **dois monitores**. Se a bolinha nascer
fora da tela, o ajuste fica em `_cornerOffset` / `_nudgeIntoScreen` em
`lib/main.dart` — corrija apenas se reproduzir o problema.

---

## 3. Ícone da bandeja (system tray)

`lib/services/tray_service.dart` desenha um olho cuja barra inferior se preenche
com o progresso, gerando um **PNG dinâmico** (`lib/utils/eye_icon.dart`) e
chamando `trayManager.setIcon(path, isTemplate: ...)`. No Windows, `_isTemplate`
é `false` e a cor é branca.

**Validar:**

- O ícone aparece na bandeja (perto do relógio; pode estar no "overflow" — peça
  para o usuário fixá-lo).
- O ícone **atualiza** o preenchimento conforme o tempo passa.
- **Clique** abre o menu de contexto; **clique direito** também
  (`onTrayIconMouseDown` / `onTrayIconRightMouseDown` chamam `popUpContextMenu`).
- Os itens do menu (habilitar/desabilitar widget, iniciar pausa, configurações,
  sair) funcionam.

**Possíveis ajustes:**

- O Windows tradicionalmente espera `.ico` na bandeja, mas o `tray_manager`
  aceita PNG. Se o ícone sair **borrado ou cortado**, gere-o em tamanho adequado
  (16/24/32 px conforme DPI) em `eye_icon.dart`. Só mexa se houver defeito visual.
- Se o ícone **não aparecer**, verifique se `tray.init` foi chamado (só não é
  chamado quando `hideMenuBarItem` está ligado) e se o PNG temporário foi gerado.

---

## 4. Notificações toast

`lib/services/notification_service.dart` usa `local_notifier` com
`ShortcutPolicy.requireCreate`. No Windows, as **notificações toast exigem um
atalho no Menu Iniciar** com um `AppUserModelID` — o `local_notifier` cria esse
atalho automaticamente com `requireCreate`.

**Validar:** com notificações habilitadas, espere/force uma pausa e confirme que
a toast aparece (e na Central de Ações do Windows).

**Armadilhas:**

- Em **debug/portátil** (rodando o `.exe` solto), a toast pode não aparecer porque
  o atalho/identidade não está registrado de forma persistente. O comportamento
  **confiável** vem da versão **instalada** (instalador cria o atalho no Menu
  Iniciar). Teste a notificação **após instalar** (ver `04-empacotamento.md`).
- Se o app for instalado e ainda assim não notificar, confirme que o
  `appName` (`'Dry Eye Widget'`) bate com o nome do atalho criado.

---

## 5. Iniciar com o login (launch at startup)

`lib/services/startup_service.dart` usa `launch_at_startup`, que no Windows grava
uma entrada em `HKCU\...\Run` apontando para `Platform.resolvedExecutable`.

**Implicação crítica:** o caminho do `.exe` precisa ser **estável**. Se o usuário
roda a versão portátil de uma pasta temporária e depois a move, a entrada de
inicialização quebra. **Recomende instalar** para usar "iniciar com o login".

**Validar:** ligue a opção nas Configurações → reinicie o Windows → o app deve
abrir. Desligue e confirme que para de abrir. Cheque a entrada em
`HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.

---

## 6. Tempo ocioso / pausa por inatividade (já implementado)

O canal nativo `dry_eye_widget/idle` já está implementado em
`windows/runner/flutter_window.cpp` via `GetLastInputInfo` + `GetTickCount`, e
consumido por `lib/services/idle_service.dart`. O `timer_provider` pausa o ciclo
após `inactivitySeconds` (padrão 120 s) quando `pauseOnInactivity` está ligado.

**Validar:** com a opção ligada, fique sem mexer no mouse/teclado por ~2 min e
confirme que o ciclo **pausa**; volte a usar e confirme que **retoma**.

> Não há nada a implementar aqui — apenas confirmar que funciona na build.

---

## 7. Som de alerta

`audioplayers` reproduz o som de `assets/sounds/`. **Validar:** com som ligado, a
transição de pausa toca o áudio. Em alguns Windows sem codecs, formatos exóticos
falham — se não tocar, confirme o formato do asset (WAV/MP3 são seguros).

---

## 8. Fechar / sair

`_quit()` chama `windowManager.close()`. **Validar:** "Sair" pelo menu da bandeja
encerra o processo de fato (confira no Gerenciador de Tarefas que
`dry_eye_widget.exe` sumiu — não deve ficar processo órfão).

---

## Resumo de "olhe aqui se quebrar"

| Sintoma no Windows | Arquivo |
|--------------------|---------|
| Fundo opaco/retângulo | `lib/main.dart` (ramo `else` do `setEffect`) |
| Bolinha não fica no topo / não arrasta | `lib/main.dart` (window_manager) |
| Ícone da bandeja borrado/ausente | `lib/utils/eye_icon.dart`, `lib/services/tray_service.dart` |
| Toast não aparece | `lib/services/notification_service.dart` + instalar o app |
| Não inicia com o login | `lib/services/startup_service.dart` + instalar o app |
| Pausa por ociosidade não funciona | `windows/runner/flutter_window.cpp`, `lib/services/idle_service.dart` |
| Metadados do `.exe` | `windows/runner/Runner.rc` |
