# QA — interação líquida da bolinha

Data: 2026-07-11
Versão: 1.24.0+70

## Resultado

- 231 testes Flutter: passaram.
- Análise estática Flutter: sem problemas.
- Testes focados de bolinha, movimento, docking e layout: 27 passaram.
- Golden determinístico: passou e gerou `../artifacts/liquid-orb-preview.png`.
- Build macOS release: passou; bundle gerado com 59,3 MB.

## Cobertura relevante

- Limite e direção da velocidade de soltura.
- Inércia curta dentro da área útil.
- Trajetória monotônica sem overshoot.
- Docking magnético à direita.
- Pressão imediata e separação entre clique e arraste.
- Semântica percentual e preferência de reduzir movimento.

## Limites do ambiente

O teste interativo do app instalado esbarrou na solicitação do Keychain durante
o acesso a recursos protegidos. Nenhuma senha foi solicitada ou utilizada. A
renderização foi validada por harness determinístico; assinatura e teste manual
multiplataforma continuam dependentes dos ambientes de distribuição.
