# Handoff

## Current State

Em 2026-08-15, foi realizada a auditoria e reconciliação da fila do HealthKit dashboard (Issue #65).
A branch histórica `codex/healthkit-dashboard` definiu o primeiro contrato de dados e spike exploratório.
A `main` atual não contém serviço nativo ou entitlement do HealthKit; ela executa o Hub de Saúde Visual nativo de forma independente.

## Key References

- `projects/dry-eye-health-dashboard/`
- Issue #55: Ativar assinatura de código macOS + Windows (secrets)
- Issue #58: Validar HealthKit em build macOS assinado
- `projects/dry-eye-widget-landing/handoff.md`

## Next Actions (Backlog)

1. Quando as credenciais de assinatura estiverem ativas (#55), retomar a validação do entitlement HealthKit (#58).
2. Adicionar o adaptador de serviço e permissões na plataforma Apple.
3. Persistir eventos adicionais (colírio, piscada guiada) para sincronização opcional.
4. Integrar visualizações do HealthKit ao Hub de Saúde Visual existente.

## Blockers

- Dependência direta de assinatura de código e provisionamento na Apple (#55, #58).
- Screen Time permanece isolado dos dados de saúde.
