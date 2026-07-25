# Evidência — quick win de legibilidade UI/UX

Data: 2026-07-25
Escopo: menu flutuante e Resumo do dia

## Objetivo

Eliminar microtextos inferiores a 11 px nas duas superfícies mais frequentes e
reforçar o contraste dos textos auxiliares sem ampliar a largura do menu ou
alterar a hierarquia de ações.

## Implementação

- Criado `AppTypography` com mínimos reutilizáveis de 11 px para microtextos e
  12 px para textos auxiliares.
- Menu: ações rápidas passaram de 9,5 para 11 px; cabeçalhos de seção, de 10,5
  para 11 px; ação auxiliar do cabeçalho, de 11 para 12 px.
- Resumo: rótulos estatísticos e aviso educativo passaram para 12 px; dicas
  passaram de 10 para 11 px; opacidades auxiliares subiram de 62–72% para
  74–82%.
- Testes passaram a impedir regressão dos mínimos tipográficos e das opacidades.

## Verificação

- Testes focados de menu e Resumo: 12 aprovados.
- Menu com escala de texto a 200%: aprovado pelo teste existente.
- `flutter analyze`: aprovado, sem ocorrências.
- Suíte completa `flutter test`: aprovada.
- `git diff --check`: aprovado.

## Limites

A validação confirma estrutura, escala, contraste codificado e ausência de
regressões automatizadas. Percepção visual em hardware e leitura assistida ainda
dependem das sessões humanas e do QA Windows já registrados no projeto.
