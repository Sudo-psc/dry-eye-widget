# Evidência — auditoria crítica em três ciclos

Data: 2026-07-11

## Ciclo 1 — exclusão LGPD

Falha: apagar o histórico removia a atividade do armazenamento, mas preservava
o snapshot em memória. Um flush posterior podia recriar os dados apagados.

Correção: `HealthDataService.clearHealthHistory` usa
`ActivityStatsService.clear`, zerando memória e persistência.

Regressão: o teste limpa os dados, força novo flush e confirma que memória e
armazenamento continuam vazios.

## Ciclo 2 — exclusão DVRS

Falha: tocar no ícone de exclusão removia imediatamente uma avaliação, sem
confirmação e sem possibilidade de recuperação.

Correção: diálogo localizado de confirmação antes da exclusão definitiva.

Regressão: o teste confirma que cancelar preserva o resultado e que confirmar
o remove.

## Ciclo 3 — exportação completa

Falha: a exportação JSON lia atividade apenas do armazenamento e podia omitir
amostras recentes ainda em memória.

Correção: exportação baseada no snapshot vivo de `ActivityStatsService`.

Regressão: o teste adiciona uma amostra sem flush e confirma sua presença no
mapa exportado.

## Verificação final

- `flutter test`: 224 testes aprovados.
- `flutter analyze`: nenhum problema encontrado.
- `flutter build macos --release -t lib/main.dart`: aprovado.
- Artefato: `build/macos/Build/Products/Release/Dry Eye Widget.app` (57 MB).
- `git diff --check`: aprovado.
