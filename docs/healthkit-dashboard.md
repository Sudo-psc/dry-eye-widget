# Dry Eye Health Dashboard

## Objetivo

Construir um dashboard longitudinal que cruze dados do Dry Eye Widget com dados autorizados do HealthKit para apoiar acompanhamento clinico da sindrome do olho seco, com foco em habitos de tela, sintomas e fatores sistemicos correlacionaveis.

O dashboard nao deve diagnosticar, prescrever ou inferir causalidade. Ele deve organizar series temporais e indicar correlacoes exploratorias entre uso de tela, pausas, sintomas e dados de saude disponiveis.

## Escopo HealthKit do MVP

Dados importaveis do HealthKit no MVP:

- Sono: `HKCategoryTypeIdentifierSleepAnalysis`.
- Frequencia cardiaca media: `HKQuantityTypeIdentifierHeartRate`, agregada por dia.

Fora do HealthKit no MVP:

- Tempo de tela: vem do proprio Dry Eye Widget, porque a coleta atual ja mede tempo ativo de tela e descarta inatividade. O modelo nao trata tempo de tela como tipo HealthKit.
- OSDI: vem do historico local do app.
- Colirios, pausas e piscadas sugeridas: vem do app quando houver eventos persistidos.
- Medicacoes e sintomas livres: inicialmente user-reported, ate existir uma fonte autorizada e bem definida.
- Cliques e teclas: metricas futuras, apenas agregadas e opt-in; nunca devem registrar conteudo, coordenadas, sequencia de teclas ou trajetoria do cursor.

Referencias de API usadas para o desenho:

- https://developer.apple.com/documentation/healthkit
- https://developer.apple.com/documentation/healthkit/hkhealthstore
- https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/sleepanalysis
- https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/heartrate

## Modelo temporal

Grao padrao: dia local.

Janelas de visualizacao:

- Diario: correlacao de tela, pausas, OSDI, sono e frequencia cardiaca media por data.
- Semanal: tendencia de exposicao, aderencia e sintomas.
- Mensal: acompanhamento clinico longitudinal.

Toda metrica deve carregar:

- periodo inicial e final;
- fonte;
- unidade;
- estado de disponibilidade;
- valor numerico ou textual;
- motivo explicito de ausencia quando sem dado.

Estados de disponibilidade:

- `available`: dado disponivel e exibivel.
- `unavailable`: fonte nao tem dado no periodo.
- `notCollected`: o app ainda nao coleta ou coleta desligada.
- `permissionDenied`: HealthKit ou permissao local recusada.

## Campos, fontes e unidades

| Metrica | Fonte primaria | Fonte alternativa | Unidade | Grao | Observacao |
| --- | --- | --- | --- | --- | --- |
| Tempo de tela | App | nenhuma no MVP | segundos | dia | Tempo ativo local, sem inatividade. |
| OSDI | App | nenhuma | escore 0-100 | data de preenchimento | Historico local do questionario. |
| Uso de colirios | App | user-reported | contagem | dia | Futuro: persistir confirmacoes de uso. |
| Medicacoes | user-reported | nenhuma no MVP | texto | dia | Nao importar do HealthKit no MVP. |
| Sono | HealthKit | nenhuma | segundos | dia | Somar amostras autorizadas de sono. |
| Frequencia cardiaca media | HealthKit | nenhuma | bpm | dia | Media ponderada/aritmetica conforme amostras disponiveis. |
| Sintomas | user-reported | App/OSDI | categorico/texto | dia | Sintomas livres ou resumo OSDI. |
| Frequencia de pausas | App/derivada | nenhuma | contagem | dia | Pausas sugeridas ou realizadas. |
| Aderencia 20-20-20 | Derivada | nenhuma | percentual | dia | pausas realizadas / pausas esperadas. |
| Numero de cliques | App futuro | nenhuma | contagem | dia | Apenas agregado, opt-in, sem coordenadas. |
| Numero de teclas digitadas | App futuro | nenhuma | contagem | dia | Apenas agregado, opt-in, sem conteudo. |
| Numero de pausas | App | nenhuma | contagem | dia | Eventos de pausa. |
| Numero de piscadas sugeridas | App | nenhuma | contagem | dia | Microlembretes visuais/sonoros. |

## Relacoes clinicas de exibicao

O dashboard deve permitir comparar:

- tempo de tela versus OSDI;
- tempo de tela versus sintomas;
- pausas esperadas versus pausas realizadas;
- aderencia 20-20-20 versus OSDI;
- sono versus sintomas e OSDI;
- frequencia cardiaca media versus dias de maior desconforto, apenas como contexto geral;
- colirios e medicacoes versus variacao de sintomas.

As relacoes devem ser apresentadas como associacoes temporais, nao como causalidade.

## Permissoes e privacidade

HealthKit:

- solicitar permissao de leitura somente para os tipos usados;
- explicar que a autorizacao e opcional;
- permitir dashboard parcial quando HealthKit estiver indisponivel;
- nao exportar dados de saude sem consentimento explicito.

App:

- manter dados locais por padrao;
- preservar ausencia explicita em vez de esconder lacunas;
- manter cliques e teclas fora do MVP ate existir consentimento granular e modelo agregado.

## Implementacao nativa macOS

Estado em 2026-06-19:

- `HealthKitDashboardBridge.swift` registra o canal `dry_eye_widget/healthkit_dashboard`.
- `isAvailable` verifica disponibilidade real via `HKHealthStore.isHealthDataAvailable()` quando o framework HealthKit esta presente.
- `requestAuthorization` solicita somente leitura de sono e frequencia cardiaca.
- `fetchDailySummaries` normaliza sono em segundos por dia e frequencia cardiaca media em bpm por dia.
- `HealthKitDashboardService` converte as linhas nativas para `DryEyeDashboardPeriod` e marca ausencia como indisponivel de forma explicita.
- `NSHealthShareUsageDescription` foi adicionado ao `Info.plist`.
- A entitlement `com.apple.developer.healthkit` foi adicionada aos perfis DebugProfile e Release.

Comportamento quando HealthKit nao estiver disponivel:

- A ponte retorna `available: false` ou erro `healthkit_unavailable`.
- O servico Dart preserva os campos do dashboard como indisponiveis, sem comprometer a visualizacao geral.

Verificacao executada em 2026-06-19:

- `flutter analyze`: aprovado.
- `flutter test test/dry_eye_health_dashboard_test.dart test/healthkit_dashboard_service_test.dart`: aprovado.
- `xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Release CODE_SIGNING_ALLOWED=NO`: aprovado.
- `flutter build macos --release`: bloqueado por assinatura local, porque a entitlement HealthKit exige certificado de desenvolvimento.

## Proxima implementacao

1. Conectar a UI do dashboard ao `HealthKitDashboardService`.
2. Criar fluxo visivel para permissao opcional do HealthKit.
3. Persistir eventos locais de pausas, colirios e piscadas sugeridas.
4. Criar visualizacao longitudinal usando `DryEyeDashboardPeriod`.
5. Testar em Mac assinado com conta Apple que tenha HealthKit habilitado.
6. Adicionar exportacao clinica somente com consentimento explicito.
