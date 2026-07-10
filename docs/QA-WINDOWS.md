# QA manual Windows — docking meia-lua + micronotificação

Atualizado: 2026-07-10 · ROADMAP Now #2

Protocolo para validar no **Windows 10/11** (instalador ou ZIP portátil) o
comportamento que mais falhou em revisões anteriores e que o CI não cobre em
GUI: encaixe na borda e aviso visual de piscada.

## Pré-requisitos

| Item | Como obter |
|------|------------|
| Build | Release `v*` → `DryEyeWidget-Setup-x64.exe` ou ZIP, ou `flutter build windows --release` |
| Máquina | Windows 10 1809+ ou 11; preferir escala 100% e repetir em 125%/150% |
| Config inicial | Widget flutuante **visível**; “Encostar nas bordas” **ligado**; lembretes visuais de piscada **ligados** |

## Ambiente recomendado

1. **Primário 1920×1080**, taskbar inferior.
2. **Escala 150%** (Configurações → Sistema → Tela).
3. **Dois monitores** (se disponível): arrastar a bolinha entre telas.
4. App em **tela cheia** (browser F11 ou vídeo) para o caminho de notificação forçada.

---

## A. Docking meia-lua (encaixe na borda)

Configuração: Configurações → **Encostar nas bordas (meia-lua discreta)** = ON.

| # | Passo | Resultado esperado | OK? |
|---|-------|--------------------|-----|
| A1 | Arrastar a bolinha até ~1 cm da **borda esquerda** e soltar | Encaixa: ~62% da bola ainda visível, resto “dentro” da borda; opacidade um pouco menor | ☐ |
| A2 | Clicar uma vez na meia-lua | **Solta** (não abre menu); afasta ~18 px para dentro | ☐ |
| A3 | Clicar de novo (já solta) | Abre o **menu** flutuante | ☐ |
| A4 | Encaixar na **borda direita** e soltar | Simétrico a A1 | ☐ |
| A5 | Encaixar, **fechar o app** e reabrir | Continua encaixada na mesma borda e Y aproximado | ☐ |
| A6 | Desligar “Encostar nas bordas”, arrastar à borda | **Não** encaixa; se estava encaixada, solta | ☐ |
| A7 | Com meia-lua ativa, disparar ciclo de **piscada** | **Só brilho** na bola (sem pílula de texto expandida); janela **não** cresce e some | ☐ |
| A8 | Arrastar bem para o **canto inferior** (acima da taskbar) e encaixar | Y clampado: não fica sob a taskbar; ainda clicável | ☐ |
| A9 | (Opcional) 2 monitores: encaixar na borda externa do secundário | Encaixa relativo à tela atual; não “teleporta” ao primário | ☐ |
| A10 | Escala 150%: repetir A1–A4 | Mesmo comportamento; hit-test clicável | ☐ |

### Falhas históricas (já corrigidas no código — revalidar)

- Bolinha sumia ao encaixar e não voltava (1.21.1).
- Lembrete de piscada empurrava a posição canônica da bolinha a cada ciclo (`_nudgeIntoScreen` não grava `_ballPosition`).

---

## B. Micronotificação de piscada

Configuração: lembretes visuais de piscada ON; frequência “Normal” (ou “Frequente” para QA rápido).

| # | Passo | Resultado esperado | OK? |
|---|-------|--------------------|-----|
| B1 | Bolinha **solta** (não encaixada); aguardar ciclo | Pílula/texto de piscada aparece junto da bola; brilho/burst; some após ~1–2 s | ☐ |
| B2 | Clicar na bola **durante** o aviso | Clique ainda funciona (menu / ação) | ☐ |
| B3 | Frequência “Discreto” vs “Frequente” | Intervalo muda de forma perceptível | ☐ |
| B4 | Desligar lembrete visual; manter som se quiser | Sem expansão visual; som opcional | ☐ |
| B5 | Meia-lua + piscada (igual A7) | Só feedback na bola, sem layout expandido | ☐ |

---

## C. Notificação suave de pausa 20-20-20 (relacionado)

Não é a micronotificação de piscada, mas falha no mesmo eixo “overlay vs notificação” no Windows.

| # | Passo | Resultado esperado | OK? |
|---|-------|--------------------|-----|
| C1 | Modo suave OFF; “Iniciar pausa agora” | Overlay/fullscreen de pausa ou cartão conforme config | ☐ |
| C2 | **Notificações suaves** ON; iniciar pausa | Cartão ~430×164 no canto **superior direito**; não cobre a tela toda | ☐ |
| C3 | Notificações do Windows ON; pausa com app em fullscreen | Toast do sistema “Hora da pausa” (ou force se overlay falhar) | ☐ |
| C4 | Always-on-top: abrir File Explorer maximizado | Bolinha/cartão permanece **acima** | ☐ |

---

## D. Smoke de bandeja e instalação

| # | Passo | Resultado esperado | OK? |
|---|-------|--------------------|-----|
| D1 | Ícone na bandeja (system tray) | Visível, menu abre | ☐ |
| D2 | SmartScreen no instalador | Documentado (unsigned até SignPath) | ☐ |
| D3 | Reinício com “iniciar com o sistema” se testado | Sobe sem crash | ☐ |

---

## Cobertura automatizada (sem GUI Windows)

```bash
flutter test test/edge_snap_test.dart test/floating_ball_test.dart test/gentle_break_card_test.dart
```

- `edge_snap_test` — geometria pura + cenários taskbar / monitor com origem negativa / bola grande  
- `floating_ball_test` — micronotificação com texto; modo docked **sem** pill  
- `gentle_break_card_test` — cartão de pausa suave  

Rodar no CI em todo PR (`ci.yml`).

---

## Registro de execução

Preencher e anexar em issue ou `projects/dry-eye-widget-app/runs/`:

```
Data:
Build/tag:
Windows:
Escala DPI:
Monitores:
Executor:

A1-A10: 
B1-B5:
C1-C4:
D1-D3:

Bugs encontrados:
```

## Riscos conhecidos (código, 2026-07-10)

1. **Só `getPrimaryDisplay()`** no encaixe — multi-monitor extremo pode usar geometria do primário se o plugin reportar mal o display ativo.  
2. **Janela parcialmente fora da tela** (meia-lua) depende do DWM aceitar bounds negativos; se o Windows “empurrar” de volta, a meia-lua vira bola colada por dentro (ainda usável, menos “half-moon”).  
3. **Assinatura** — fora do escopo deste QA (ROADMAP #1).

Referência de implementação: `lib/utils/edge_snap.dart`, `lib/main.dart` (`_onBallDragEnd`, `_triggerBlinkReminder`), `lib/widgets/floating_ball.dart`.
