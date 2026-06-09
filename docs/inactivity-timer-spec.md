# Especificacao Tecnica - Modulo de Deteccao de Inatividade do Timer

## 1. Objetivo

Implementar e documentar o modulo que detecta quando o usuario se afastou do teclado, mouse e tela, pausa automaticamente o timer do Dry Eye Widget e retoma o ciclo quando o usuario volta a interagir com o computador. Durante a pausa por inatividade, o app deve exibir um aviso pequeno, discreto e minimalista, com um botao para retomada manual.

> **Atualizacao v1.7.x:** o limiar de pausa deixou de ser fixo (120 s) e passou
> a ser **adaptativo** (aprendido por faixa horaria; 120 s vira apenas o cold
> start, com clamp em `[60 s, 600 s]`), via `PresenceController` +
> `AdaptiveThresholdModel`. Foram adicionados (a) **presenca opcional pela
> camera** (snapshot pontual + Vision on-device no macOS; opt-in, off por
> padrao; `VisionService` + `CameraPresenceSensor`) e (b) **persistencia cifrada**
> do aprendizado (Keychain/DPAPI via `SecurePresenceStore`, sem historico nem
> acesso remoto). Onde esta secao cita o limiar fixo `inactivitySeconds`, leia-se
> "cold start adaptativo". O cartao de aviso, a histerese (`inactivityResumeSeconds`)
> e a retomada manual permanecem validos.

## 2. Problema

O timer da regra 20-20-20 deve medir tempo real de exposicao ativa a tela. Se o usuario se afasta do computador, continuar contando esse tempo gera alertas incorretos: o app pode pedir uma pausa quando a pessoa ja estava longe da tela. O modulo de inatividade deve impedir esse falso positivo, sem exigir configuracao complexa e sem bloquear a experiencia.

## 3. Escopo

### Incluido

- Detectar inatividade global do sistema operacional, mesmo quando o app nao esta em foco.
- Pausar o progresso do ciclo de trabalho enquanto o usuario estiver inativo.
- Exibir aviso compacto informando que o timer foi pausado por inatividade.
- Retomar automaticamente quando houver movimento de mouse, clique ou tecla.
- Permitir retomada manual por um botao pequeno no aviso.
- Manter a preferencia `pauseOnInactivity` habilitavel/desabilitavel nas configuracoes.
- Persistir o tempo de ciclo ja acumulado antes da inatividade.

### Fora do Escopo

- Rastrear camera, rosto, olhar ou presenca fisica por webcam.
- Diferenciar tipos de atividade, como leitura sem teclado/mouse.
- Bloquear a tela ou impedir uso do computador.
- Sincronizar inatividade entre varios dispositivos.
- Alterar a regra principal de pausa 20-20-20.

## 4. Definicoes

- **Atividade do usuario:** qualquer entrada de mouse, clique, scroll, teclado, touchpad ou evento equivalente reconhecido pelo sistema operacional.
- **Inatividade:** tempo desde a ultima entrada global do usuario no sistema operacional.
- **Pausa por inatividade:** estado ortogonal ao timer principal em que o ciclo de trabalho para de acumular segundos porque o usuario provavelmente nao esta olhando para a tela.
- **Retomada automatica:** retorno do timer ao estado normal quando a inatividade medida volta a ficar abaixo do limite de retomada.
- **Retomada manual:** acao explicita no botao do aviso para limpar o estado de pausa e voltar a contar.

## 5. Estado Atual do Codigo

O projeto ja possui uma base parcial:

- `windows/runner/flutter_window.cpp` expoe o canal nativo `dry_eye_widget/idle`.
- `GetLastInputInfo` calcula o tempo desde a ultima entrada do usuario no Windows.
- `lib/services/idle_service.dart` encapsula `idleSeconds()`.
- `lib/providers/timer_provider.dart` consulta a inatividade e pausa o ciclo quando `pauseOnInactivity` esta ativo.
- `AppDefaults.inactivitySeconds` define o limite padrao em 120 segundos.
- `AppStrings` ja contem textos para inatividade.

Lacunas atuais a resolver:

- O estado `inactivityAlert` ainda nao e exibido na UI principal.
- Nao ha botao dedicado de retomada manual no aviso de inatividade.
- A retomada automatica precisa ser formalizada com criterio claro de histerese.
- Nao ha widget especifico para o aviso pequeno de inatividade.
- Nao ha testes dedicados para transicoes de pausa/retomada por inatividade.

## 6. Requisitos Funcionais

### RF-01 - Detectar Inatividade Global

O sistema deve consultar o tempo de inatividade global do sistema operacional por meio de `IdleService.idleSeconds()`.

No Windows, a fonte deve ser `GetLastInputInfo`, pois ela captura entrada do usuario fora do foco do app.

### RF-02 - Pausar o Timer em Inatividade

Quando `pauseOnInactivity == true` e `idleSeconds >= inactivitySeconds`, o timer deve:

- Definir `inactivityPaused = true`.
- Definir `inactivityAlert = true`.
- Parar de incrementar `cycleElapsed`.
- Preservar o valor atual de `cycleElapsed`.
- Manter o app responsivo.

### RF-03 - Nao Resetar Progresso

Entrar em pausa por inatividade nao deve resetar o ciclo. Ao retomar, o timer deve continuar do mesmo `cycleElapsed` que existia antes da pausa.

### RF-04 - Retomar Automaticamente

Quando o sistema detectar nova atividade do usuario, o timer deve retomar automaticamente.

Criterio recomendado:

- Entrar em pausa quando `idleSeconds >= 120`.
- Sair da pausa quando `idleSeconds <= 5`.

Essa diferenca evita oscilacao caso a leitura de inatividade varie perto do limite.

### RF-05 - Retomar Manualmente

O aviso de inatividade deve conter um botao pequeno e minimalista com texto curto:

- PT-BR: `Retomar`
- EN: `Resume`

Ao clicar, o app deve:

- Limpar `inactivityPaused`.
- Limpar `inactivityAlert`.
- Retomar o incremento do ciclo no proximo tick.

### RF-06 - Mostrar Aviso Compacto

Quando `inactivityAlert == true`, o app deve mostrar um aviso pequeno, nao bloqueante, preferencialmente no canto superior direito.

O aviso deve:

- Usar a linguagem visual do modo suave (`LiquidGlass` ou componente equivalente).
- Ter largura compacta, entre 260 e 340 px.
- Nao ocupar tela cheia.
- Nao usar overlay escuro.
- Nao impedir o usuario de interagir com outros apps.
- Ter texto curto e legivel.

Conteudo sugerido:

- Titulo: `Timer pausado`
- Corpo: `Inatividade detectada. O ciclo sera retomado quando voce voltar.`
- Botao: `Retomar`

### RF-07 - Nao Emitir Alerta Sonoro

A pausa por inatividade nao deve tocar som de alerta, sucesso ou tick. O evento deve ser silencioso por padrao.

### RF-08 - Nao Gerar Toast Nativa por Padrao

O aviso de inatividade deve ser visual dentro do widget. Notificacao toast nativa nao deve ser emitida por padrao para evitar ruido.

### RF-09 - Respeitar Configuracao do Usuario

Se `pauseOnInactivity == false`, o modulo deve:

- Nao consultar inatividade desnecessariamente.
- Limpar estados pendentes de inatividade.
- Continuar o timer normalmente.

### RF-10 - Estado Durante Pausa 20-20-20

A pausa por inatividade deve afetar apenas o acumulo do ciclo de trabalho em `AppState.idle`.

Se o app ja estiver em `alerta`, `fase1` ou `conclusao`, a deteccao pode continuar sendo consultada, mas nao deve substituir a UI de pausa 20-20-20. A pausa ocular tem prioridade visual sobre o aviso de inatividade.

### RF-11 - Tray e Progresso

Enquanto o timer estiver pausado por inatividade, o progresso exibido no icone da bandeja deve permanecer congelado no ultimo valor valido.

### RF-12 - Persistencia

O app deve persistir `cycleElapsed` periodicamente como ja faz hoje. Ao entrar em inatividade, o app deve preservar o ultimo valor salvo ou salvar o valor atual para evitar perda em caso de encerramento.

## 7. Requisitos Nao Funcionais

### RNF-01 - Baixo Custo de CPU

A leitura de inatividade deve ser leve. A consulta deve ocorrer no maximo a cada 5 segundos enquanto o app estiver rodando.

### RNF-02 - Sem Consultas Concorrentes

O provider deve impedir chamadas simultaneas a `IdleService.idleSeconds()`. O flag `_idleBusy` ou mecanismo equivalente deve continuar existindo.

### RNF-03 - Tolerancia a Falha

Se o canal nativo falhar, `IdleService.idleSeconds()` deve retornar `0` e o timer deve seguir funcionando normalmente.

### RNF-04 - Privacidade

O modulo nao deve coletar conteudo de teclado, posicao do cursor, nome de janela ativa, screenshot, camera ou historico de uso. Deve medir apenas o tempo desde a ultima entrada do sistema.

### RNF-05 - Multiplataforma

O Windows deve ser a plataforma principal validada. Em outras plataformas, o comportamento deve ser:

- Usar implementacao nativa equivalente quando disponivel.
- Fazer fallback seguro para `0` segundos de inatividade quando nao houver suporte.
- Nunca quebrar o timer principal.

### RNF-06 - UI Discreta

O aviso deve ser visualmente discreto e adequado a uma ferramenta de produtividade:

- Tipografia pequena.
- Um unico botao.
- Sem animacoes chamativas.
- Sem hero, modal central ou tela cheia.

## 8. Requisitos Tecnicos

### RT-01 - API do Servico

`IdleService` deve manter a API:

```dart
Future<double> idleSeconds();
```

O retorno deve representar segundos desde a ultima entrada global do usuario.

### RT-02 - Canal Nativo Windows

O canal deve permanecer:

```text
dry_eye_widget/idle
```

Metodo:

```text
idleSeconds
```

Implementacao Windows:

- Usar `GetLastInputInfo`.
- Usar contador monotonicamente seguro para diferenca de tempo.
- Retornar `double`.

Observacao tecnica: a implementacao atual usa `GetTickCount()`. Para maior robustez em execucoes muito longas, recomenda-se migrar para `GetTickCount64()`.

### RT-03 - Estado no TimerProvider

O `TimerProvider` deve expor:

```dart
bool get inactivityAlert;
bool get isPaused;
```

E deve conter ou expor acao manual:

```dart
void resumeFromInactivity();
```

`resumeFromInactivity()` deve limpar somente a pausa causada por inatividade. Ela nao deve interferir em pausa manual feita pelo usuario via menu.

### RT-04 - Separacao entre Pausa Manual e Inatividade

O estado `_paused` representa pausa manual. O estado `_inactivityPaused` representa pausa automatica por inatividade.

O timer deve incrementar somente quando:

```dart
!_paused && !_inactivityPaused
```

### RT-05 - Histerese de Retomada

Adicionar constante:

```dart
static const int inactivityResumeSeconds = 5;
```

Local recomendado: `AppDefaults`.

Transicoes:

```text
Ativo -> Pausado por inatividade:
idleSeconds >= inactivitySeconds

Pausado por inatividade -> Ativo:
idleSeconds <= inactivityResumeSeconds
```

### RT-06 - Widget de Aviso

Criar widget dedicado:

```text
lib/widgets/inactivity_pause_card.dart
```

Responsabilidade:

- Renderizar o aviso compacto.
- Receber strings localizadas.
- Receber callback `onResume`.

Assinatura sugerida:

```dart
class InactivityPauseCard extends StatelessWidget {
  const InactivityPauseCard({
    super.key,
    required this.strings,
    required this.onResume,
  });

  final AppStrings strings;
  final VoidCallback onResume;
}
```

### RT-07 - Integracao na HomePage

Em `HomePage.build`, a prioridade visual deve ser:

1. Dialogo de atualizacao.
2. Configuracoes.
3. Orientacoes.
4. Lembrete de colirio.
5. Pausa 20-20-20 ativa.
6. Aviso de inatividade.
7. Bolinha/menu compacto.

Ou seja, `timer.inactivityAlert` deve ser avaliado depois de `timer.state.isActive` e antes da UI compacta.

### RT-08 - Layout de Janela

Quando o aviso de inatividade abrir:

- Se a bolinha estiver visivel, a janela deve expandir para um pequeno cartao.
- Tamanho recomendado: `Size(320, 120)`.
- Posicao recomendada: canto superior direito da tela primaria, margem 16 px.
- Deve manter `alwaysOnTop`.

Sugestao de enum:

```dart
enum _WindowLayout {
  ball,
  menu,
  settings,
  breakOverlay,
  gentleBreak,
  inactivity,
}
```

### RT-09 - Localizacao

Atualizar `AppStrings` com textos especificos:

PT-BR:

- `inactivityTitle`: `Timer pausado`
- `inactivityBody`: `Inatividade detectada. O ciclo sera retomado quando voce voltar.`
- `inactivityContinue`: `Retomar`

EN:

- `inactivityTitle`: `Timer paused`
- `inactivityBody`: `Inactivity detected. The cycle will resume when you return.`
- `inactivityContinue`: `Resume`

### RT-10 - Configuracao

Manter a opcao:

```dart
pauseOnInactivity
```

Texto PT-BR:

```text
Pausar por inatividade (2 min)
```

Texto EN:

```text
Pause when inactive (2 min)
```

## 9. Maquina de Estados

Estados ortogonais:

```text
Timer principal:
idle -> alerta -> fase1 -> conclusao -> idle

Inatividade:
active -> inactivePaused -> active
```

Regras:

- `inactivePaused` so congela o progresso de `idle`.
- `inactivePaused` nao altera `AppState`.
- `inactivePaused` nao zera `cycleElapsed`.
- Retomada automatica limpa `inactivePaused` e `inactivityAlert`.
- Retomada manual limpa `inactivePaused` e `inactivityAlert`.
- Pausa manual e pausa por inatividade podem coexistir; nesse caso, a retomada por inatividade nao deve limpar `_paused`.

## 10. Criterios de Aceite

- Com `pauseOnInactivity` ligado, ficar 120 segundos sem entrada pausa o timer.
- Durante a pausa por inatividade, `cycleElapsed` nao aumenta.
- O aviso pequeno aparece sem bloquear a tela.
- O aviso mostra titulo, corpo curto e botao `Retomar`.
- Mover o mouse, clicar ou pressionar tecla retoma automaticamente o timer em ate 5 segundos.
- Clicar em `Retomar` retoma manualmente o timer.
- Se a pausa manual tambem estiver ativa, clicar em `Retomar` remove apenas a pausa por inatividade.
- Se `pauseOnInactivity` estiver desligado, o timer nunca pausa por inatividade.
- O build Windows release continua funcionando.

## 11. Testes Recomendados

### Unitarios

- `TimerProvider` entra em `inactivityPaused` quando `idleSeconds >= inactivitySeconds`.
- `TimerProvider` nao incrementa `cycleElapsed` enquanto `_inactivityPaused == true`.
- `TimerProvider` retoma automaticamente quando `idleSeconds <= inactivityResumeSeconds`.
- `resumeFromInactivity()` limpa apenas a pausa por inatividade.
- Desabilitar `pauseOnInactivity` limpa estados de inatividade.

### Widget Tests

- `InactivityPauseCard` renderiza titulo, corpo e botao.
- Tocar no botao chama `onResume`.
- `HomePage` prioriza pausa 20-20-20 sobre aviso de inatividade.

### Testes Manuais Windows

1. Abrir build release.
2. Garantir que `Pausar por inatividade (2 min)` esteja ligado.
3. Observar o progresso da bolinha/tray.
4. Ficar sem mexer no mouse/teclado por 2 minutos.
5. Confirmar que o aviso pequeno aparece.
6. Confirmar que o progresso congela.
7. Mover o mouse.
8. Confirmar que o aviso desaparece e o progresso volta a contar.
9. Repetir e testar o botao `Retomar`.

## 12. Riscos e Mitigacoes

| Risco | Impacto | Mitigacao |
|---|---|---|
| Usuario lendo sem mexer no mouse/teclado | Pausa indevida | Limite padrao de 120 s e opcao para desligar |
| Oscilacao perto do limite | Aviso aparece/desaparece | Histerese com `inactivityResumeSeconds` |
| Canal nativo falha | Timer poderia travar | Fallback para `0` no `IdleService` |
| UI intrusiva | Irrita o usuario | Aviso compacto, sem som e sem toast |
| App sem foco | Evento nao detectado se usar eventos Flutter | Usar API global do sistema operacional |

## 13. Checklist de Implementacao

- [ ] Adicionar `AppDefaults.inactivityResumeSeconds`.
- [ ] Adicionar `TimerProvider.resumeFromInactivity()`.
- [ ] Atualizar `_checkInactivity()` com histerese.
- [ ] Salvar `cycleElapsed` ao entrar em pausa por inatividade.
- [ ] Criar `InactivityPauseCard`.
- [ ] Integrar `timer.inactivityAlert` no `HomePage.build`.
- [ ] Adicionar layout `_WindowLayout.inactivity`.
- [ ] Atualizar strings PT-BR/EN.
- [ ] Adicionar testes unitarios do provider.
- [ ] Adicionar widget test do card.
- [ ] Rodar `flutter analyze`.
- [ ] Rodar `flutter test`.
- [ ] Rodar `flutter build windows --release`.
