# Política de Assinatura de Código (Code Signing Policy)

> Free code signing provided by [SignPath.io](https://about.signpath.io), certificate by [SignPath Foundation](https://signpath.org)

Este documento descreve como as versões do **Dry Eye Widget** são construídas,
revisadas, aprovadas e assinadas — em conformidade com os
[termos do SignPath Foundation](https://signpath.org/terms).

## Projeto

- **Nome:** Dry Eye Widget
- **Repositório:** <https://github.com/Sudo-psc/dry-eye-widget> (público)
- **Licença:** [MIT](../../LICENSE) — licença aprovada pela OSI, **sem**
  duplo-licenciamento comercial.
- **Propósito:** ferramenta gratuita de saúde ocular (regra 20-20-20). Não
  contém malware, programas potencialmente indesejados nem ferramentas de
  exploração de vulnerabilidades.

## Papéis da equipe (Team roles)

Projeto mantido por um único responsável, com revisão assistida e portões de CI:

| Papel | Responsável |
|---|---|
| **Autor / Mantenedor (Author)** | Dr. Philipe Saraiva Cruz — GitHub [@Sudo-psc](https://github.com/Sudo-psc) |
| **Revisor (Reviewer)** | [@Sudo-psc](https://github.com/Sudo-psc), com revisão automatizada (GitHub Copilot, Gemini Code Assist) e portões de CI (`flutter analyze`, testes, build macOS + Windows) |
| **Aprovador (Approver)** | [@Sudo-psc](https://github.com/Sudo-psc) — única pessoa autorizada a criar tags de release e aprovar a assinatura |

## Processo de aprovação de releases

1. Toda mudança entra por **Pull Request** e precisa passar nos CIs
   (`flutter analyze`, `flutter test`, build macOS e Windows).
2. Uma versão é publicada criando a tag `vX.Y.Z` no branch `main`.
3. O GitHub Actions compila os artefatos e **submete o instalador Windows ao
   SignPath** para assinatura (trusted build, vinculado a este repositório).
4. **Apenas** binários compilados a partir do código-fonte **deste repositório
   público** são assinados. Não assinamos software de terceiros nem upstream
   modificado.

## Metadados dos binários

Todos os binários publicados carregam metadados obrigatórios de **nome do
produto e versão** (configurados no Inno Setup e em `windows/runner/Runner.rc`).
Detalhes técnicos em [`win_version/CODE_SIGNING.md`](../../win_version/CODE_SIGNING.md).

## Privacidade

- O aplicativo processa **tudo localmente**. O modelo de aprendizado de
  inatividade é guardado **cifrado em repouso** (Keychain no macOS, DPAPI no
  Windows), sem histórico e sem acesso remoto. A confirmação opcional de
  presença pela câmera roda **on-device** e descarta a imagem imediatamente.
- O **único** acesso à rede é uma **verificação de atualização opcional** que
  consulta a API de releases do GitHub para checar se há uma versão mais nova —
  nenhum dado pessoal ou de atividade é transmitido.
- Política completa: [Política de Privacidade](politica-de-privacidade.md).

## Isenção de responsabilidade

Conforme os termos do SignPath Foundation, **o SignPath Foundation não se
responsabiliza por danos decorrentes de software assinado com seus
certificados**. O software é fornecido "como está" (*as is*) sob a Licença MIT,
sem garantias. A responsabilidade pelo conteúdo e comportamento dos binários é
do mantenedor do projeto.

---

🇺🇸 English version: [code-signing-policy.en.md](code-signing-policy.en.md)
