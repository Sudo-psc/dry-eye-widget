# Run — QA Windows docking + micronotificação

Date: 2026-07-10  
Scope: ROADMAP Now #2  
Executor: agent (análise + testes automatizados; GUI Windows pendente de máquina)

## Automated evidence

```
flutter test test/edge_snap_test.dart test/floating_ball_test.dart test/gentle_break_card_test.dart
→ All tests passed (14+ cases including Windows-like geometry)
```

## Code review (Windows-relevant)

| Área | Comportamento | Status |
|------|---------------|--------|
| Meia-lua | `dockEdgeFor` + `dockedWindowPosition` puros; threshold `max(56, width*0.72)` | Coberto por unit tests |
| Persistência | `StorageKeys.dockEdge` + posição X/Y | Código revisado |
| Clique encaixado | 1º clique = undock; 2º = menu | Código revisado |
| Piscada encaixada | Sem expandir janela; só brilho; sem pill de texto | Test widget + main.dart |
| Piscada solta | Layout `blinkReminder` + `_nudgeIntoScreen` **sem** gravar `_ballPosition` | Código revisado (fix histórico) |
| Modo suave pausa | `GentleBreakCard` canto superior direito | Test widget |
| Multi-monitor | Só primary display em vários paths | Risco documentado no checklist |

## Manual GUI Windows

Protocolo: `docs/QA-WINDOWS.md`  
Status: **pendente** — ambiente do agente é macOS; preencher checkboxes A–D em máquina Windows com build de release.

## Conclusion

- Gate automatizado do item 2: **pass**.  
- Aceite final de produto: requer uma passagem humana com o checklist em Win10/11.
