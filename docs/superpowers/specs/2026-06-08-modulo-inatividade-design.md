# Módulo de Inatividade — Design / Especificação

**Data:** 2026-06-08
**Branch:** `inatividade`
**Status:** Aprovado para planejamento de implementação

---

## 1. Objetivo

Pausar automaticamente o ciclo da regra 20-20-20 quando o usuário está
*ausente* (longe do teclado, mouse e tela) e retomá-lo assim que a atividade
é reestabelecida. O limiar que separa "pausa natural" de "ausência real" é
**aprendido continuamente** a partir do comportamento do próprio usuário, em
vez de um valor fixo. Uma câmera **opcional** (desligada por padrão) pode
confirmar presença visual quando o sinal de input é ambíguo.

### Por que isso importa

O timer atual conta o tempo mesmo quando o usuário saiu da mesa, disparando
pausas inúteis quando ele volta. Um limiar fixo de 2 min é tosco: alguém lendo
um texto longo na tela fica "inativo" no input mas está presente. O módulo
distingue os dois casos.

### Não-objetivos (YAGNI)

- Microfone / análise de som — **fora de escopo**.
- Streaming contínuo de vídeo — **fora de escopo** (só snapshot pontual).
- Histórico de atividade, telemetria, sincronização em nuvem — **proibidos**.
- Modelo de ML pesado (tflite/redes) — desnecessário para este sinal.

---

## 2. Escopo dos sensores

| Sensor | Estado | Custo | Permissão |
|---|---|---|---|
| Teclado + mouse + tela (ociosidade do SO) | **Núcleo, sempre ativo** | Zero | Nenhuma |
| Câmera (detecção de rosto on-device) | **Opcional, OFF por padrão** | Snapshot pontual | Câmera (opt-in) |
| Microfone | Fora de escopo | — | — |

O núcleo reutiliza o `IdleService` já existente
(`CGEventSourceSecondsSinceLastEventType` no macOS, `GetLastInputInfo` no
Windows), que reporta a ociosidade de todo o sistema mesmo sem foco.

---

## 3. Arquitetura

```
TimerProvider ── consulta ──▶ PresenceController
                                  │  (decide presente / ausente)
                  ┌───────────────┼────────────────┐
                  ▼               ▼                ▼
        InputIdleSensor   AdaptiveThreshold   CameraPresenceSensor
        (núcleo, SO)        Model (ML)          (opcional, off)
                                  │
                                  ▼
                            PresenceStore
                       (estado agregado, cifrado)
```

### 3.1 Componentes e responsabilidades

| Unidade | O que faz | Depende de | Testável isolado |
|---|---|---|---|
| `PresenceSensor` (interface) | Contrato `Future<Presence> sample()` → `present \| absent \| unknown` | — | — |
| `InputIdleSensor` | Lê ociosidade do SO; `present` se `idle < limiar`, senão `unknown` (deixa o controller decidir) | `IdleService`, `AdaptiveThresholdModel` | Sim (fake IdleService) |
| `CameraPresenceSensor` | Captura 1 frame, detecta rosto on-device, descarta a imagem | Canal nativo de visão | Sim (fake atrás da interface) |
| `AdaptiveThresholdModel` | Aprende o limiar de inatividade por faixa horária | `PresenceStore` | Sim (puro Dart) |
| `PresenceController` | Máquina de estados que combina sinais; expõe `isPresent` / `shouldPauseTimer`; alimenta o modelo nos eventos de retomada | sensores, modelo | Sim (sensores fake) |
| `PresenceStore` | Persiste o estado agregado do modelo, cifrado | Keychain/DPAPI via canal nativo | Sim (fake keystore) |

**Critério de fronteira:** cada unidade é compreensível sem ler as internas das
outras; trocar a estatística do modelo ou a API de visão não afeta o
`TimerProvider`.

---

## 4. Fluxo de decisão (avaliado a cada tick de 1 s)

1. `idle < limiar` → **presente**; o timer corre normalmente.
2. `idle` cruza o **limiar adaptativo**:
   - Câmera **OFF** → declara **ausência** → pausa o ciclo (`_inactivityPaused = true`).
   - Câmera **ON** → 1 snapshot:
     - rosto detectado → **presente** (usuário lendo/assistindo): **não pausa**;
       registra como "presença parada" e adia a próxima reavaliação.
     - sem rosto → **ausência** → pausa.
3. **Qualquer input** (idle volta a ~0) enquanto pausado → **retoma
   automaticamente**. A câmera nunca é necessária para retomar — só para
   *evitar pausar* quando o usuário está parado mas presente.
4. Cada gap encerrado alimenta o `AdaptiveThresholdModel`:
   - retomada rápida após o gap → era "presença parada" → tende a **subir** o limiar;
   - gap longo encerrado por lock de tela / novo login → ausência real → mantém/baixa.

### Estados expostos ao `TimerProvider`

- `isPresent: bool`
- `shouldPauseTimer: bool` (true quando ausência confirmada e módulo ligado)
- `currentThresholdSeconds: int` (para diagnóstico/UI futura)

---

## 5. O "ML" — `AdaptiveThresholdModel`

Estatística **online leve**, sem dependências externas.

- **Buckets horários:** 4 faixas (00–06, 06–12, 12–18, 18–24). Padrões de pausa
  diferem entre madrugada e horário de trabalho.
- **Estimador:** **histograma compacto de contagens** (bins de 30 s até 600 s +
  overflow) para o **percentil-alvo P85** das durações de "presença parada"
  observadas, por bucket. Atualização O(1) por evento, sem armazenar a amostra.
  (Decisão de implementação: substitui o P² originalmente cogitado por ser
  **determinístico e testável**, com as mesmas garantias de agregação/privacidade.)
- **Suavização:** EWMA leve sobre o P85 estimado para estabilidade entre sessões.
- **Limiar efetivo:** `clamp(P85_bucket, 60 s … 600 s)`.
- **Cold start:** 120 s enquanto o bucket tiver menos de N observações (ex.: N=5).
- **Estado total persistido:** ~10 floats (marcadores P² + contadores por bucket).
  Nunca durações brutas, nunca timestamps de uso.

**Interpretabilidade:** o limiar atual é sempre um número legível e há reset a
um clique nas configurações.

---

## 6. Câmera (opcional) — `CameraPresenceSensor`

- **Gatilho:** captura **apenas no limiar** (snapshot pontual), nunca em fluxo.
- **Processamento:** detecção de rosto on-device; resultado é só um booleano
  "há rosto enquadrado". A imagem vive em memória pelo tempo da inferência e é
  descartada — **nunca** vai a disco nem à rede.
- **Plataforma:**
  - **macOS (fase 1):** framework **Vision** (`VNDetectFaceRectanglesRequest`),
    nativo e on-device.
  - **Windows (fase posterior):** toggle aparece **desabilitado** com aviso
    "em breve"; implementação via `Windows.Media.FaceAnalysis` depois.
- **LED da webcam:** acende só por instantes em cada avaliação no limiar —
  comportamento esperado e documentado ao usuário.

---

## 7. Privacidade e segurança

Requisitos do usuário: processamento local, criptografado, sem histórico, sem
acesso remoto.

- **`PresenceStore` cifrado:** o estado agregado do modelo é serializado em
  JSON e cifrado **em repouso pelo próprio SO** — **Keychain (macOS)** /
  **DPAPI (Windows)** via canal nativo `dry_eye_widget/secure_store`. (Decisão
  de implementação: usar a cifra nativa do SO em vez de AES-GCM manual em Dart
  elimina cripto custom e dependências, reduzindo a superfície de erro, com a
  mesma garantia de confidencialidade em repouso.) Nada de eventos brutos,
  timeline ou imagens é persistido.
- **Sem rede:** o módulo não abre sockets nem chama serviços. (Verificável em
  revisão de código — nenhuma dependência de rede é adicionada.)
- **Consentimento da câmera:** ao ativar o toggle, um diálogo explica
  exatamente o que a câmera faz (snapshot pontual, sem gravação) **antes** de o
  app solicitar a permissão de câmera do SO. Recusar mantém o módulo no núcleo.
- **Kill switches independentes:** `pauseOnInactivity` e `cameraPresence`.
  Desligar qualquer um faz o componente correspondente virar no-op imediato;
  desligar o módulo inteiro zera o estado de pausa.
- **Reset de aprendizado:** botão nas configurações apaga o `PresenceStore`.

---

## 8. UX

- **Sinalização de pausa (discreta):** a bolinha fica levemente **esmaecida**
  com ícone de pausa; o tooltip diz **"Pausado por inatividade"**. Sem som, sem
  overlay — coerente com não incomodar quem saiu. Reaproveita os campos
  `_inactivityPaused` / `_inactivityAlert` já existentes no `TimerProvider`.
- **Configurações novas (em `settings_dialog`):**
  - Toggle "Pausar por inatividade" (já existe `pauseOnInactivity`; passa a
    usar o limiar adaptativo em vez de fixo).
  - Toggle "Confirmar presença pela câmera" (novo, OFF; desabilitado no Windows).
  - Botão "Resetar aprendizado de inatividade".
- **i18n:** novas strings em `app_strings.dart` (PT-BR + English), seguindo o
  padrão existente.

---

## 9. Integração com o código existente

- **`TimerProvider`**: remove o `_checkInactivity()` **chamado em
  `timer_provider.dart:90` mas não definido** (bug atual — pausa por inatividade
  do último commit está quebrada) e passa a consultar o `PresenceController` no
  `_onTick`. Mantém a leitura dinâmica das settings.
- **`WidgetSettings`**: adiciona `cameraPresence` (bool, default false). Segue o
  padrão imutável + `copyWith`/`toMap`/`fromMap` com fallback robusto.
- **`IdleService`**: reutilizado sem mudanças.
- **Canais nativos novos**: `dry_eye_widget/vision` (detecção de rosto, macOS) e
  `dry_eye_widget/secure_store` (cifra via Keychain/DPAPI).

---

## 10. Estratégia de testes

- **Unit (puro Dart):**
  - `AdaptiveThresholdModel`: sequências determinísticas de gaps → limiar
    esperado; comportamento de cold start; isolamento entre buckets.
  - `PresenceController`: máquina de estados com `PresenceSensor` fakes
    (presente/ausente/unknown) e modelo fake → transições pausar/retomar.
  - `PresenceStore`: round-trip cifrar→decifrar com keystore fake; robustez a
    estado corrompido (cai para defaults).
- **Não testado em unit:** APIs nativas de Vision/Keychain (isoladas atrás de
  interfaces; cobertas por fakes). Verificação manual por plataforma.
- **Regressão:** os testes existentes (`app_state_test`, `timer` etc.) devem
  continuar passando após a refatoração do `_onTick`.

---

## 11. Fases de entrega

1. **Núcleo:** `PresenceSensor` + `InputIdleSensor` + `AdaptiveThresholdModel` +
   `PresenceController` + integração no `TimerProvider`; corrige o bug do
   `_checkInactivity`. UX discreta. Tudo em memória.
2. **Persistência cifrada:** `PresenceStore` + canal `secure_store` + reset.
3. **Câmera (macOS):** `CameraPresenceSensor` + canal `vision` + consentimento +
   toggle.
4. **Câmera (Windows):** paridade via `Windows.Media.FaceAnalysis`.

---

## 12. Riscos e mitigações

| Risco | Mitigação |
|---|---|
| Falsos positivos de ausência (pausa enquanto presente) | Limiar adaptativo + câmera opcional como desempate; clamp mínimo de 60 s |
| Falsos negativos (não pausa quando ausente) | Limiar máximo de 600 s; gap longo + lock encerra o aprendizado como ausência |
| Permissão de câmera negada | Módulo segue no núcleo; sem degradação do timer |
| Estado cifrado corrompido | `fromMap`/decifra com fallback para defaults |
| LED da webcam assustando o usuário | Documentado; snapshot pontual minimiza; OFF por padrão |
