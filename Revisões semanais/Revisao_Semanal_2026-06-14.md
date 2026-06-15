# Revisão Semanal (2026-06-14)

## Resumo das Alterações (Última Semana)
- **b7a2fcf** build(msix): adiciona empacotamento MSIX para a Microsoft Store (2026-06-13 21:11:06 -0300)
- **aebf2f8** fix(about): corrige botão Sobre que não abria e enriquece o painel (2026-06-13 17:11:54 -0300)
- **651a36d** fix(windows): corrige build no MSVC 14.51 (STL1011) e sobe versão 1.10.1 (2026-06-13 15:55:19 -0300)
- **777722f** fix(ci): silencia erro STL1011 do MSVC 14.51 no build Windows (2026-06-13 15:33:24 -0300)
- **c24f305** fix: corrige item "Sair" cortado no menu flutuante e sobe versao 1.9.2 (2026-06-11 15:16:57 -0300)
- **bac1cef** chore: add untracked og assets (2026-06-11 12:58:26 +0000)
- **98bd126** feat(release): v1.9.1 — widget persiste sobre apps em tela cheia (2026-06-11 08:42:53 -0300)
- **edaa9e9** docs(readme): substitui as capturas estáticas pelo vídeo de demonstração (GIF inline + MP4) (2026-06-10 13:12:05 -0300)
- **7cdd3ae** docs(readme): demo animado do app (GIF/MP4) gerado de HTML simulando o app (2026-06-10 01:28:34 -0300)
- **68a7940** chore: release v1.8.10 (2026-06-10 00:06:08 -0300)
- **d5e34eb** feat(site): adiciona landing page estática (site/) (2026-06-09 20:03:59 -0300)
- **6a404bc** feat: add github link and about dialog to floating menu (v1.8.9) (2026-06-09 19:22:01 -0300)
- **cfbd66e** feat: modern 3D minimalist design and progress ring border for version 1.8.8 (2026-06-09 19:17:41 -0300)
- **96974a7** chore: bump version to 1.8.7 to fix release artifact synchronization (2026-06-09 18:59:00 -0300)
- **d9445c4** chore: rename app to Dry Eye Widget and bump version to 1.8.6 (2026-06-09 18:50:39 -0300)
- **0379d70** feat: add dynamic orb effect (2026-06-09 18:31:35 -0300)
- **204d03c** chore: bump version to 1.8.4 for new release (2026-06-09 18:29:07 -0300)
- **3c8b26d** docs: conformidade com os termos do SignPath Foundation (2026-06-09 17:23:40 -0300)
- **c532e6d** feat(landing): add dry-eye widget landing pages, SDD artifacts and code-signing policy (2026-06-09 17:21:06 -0300)
- **003b8c7** chore: bump version to 1.8.3 and sync AppInfo version (2026-06-09 15:00:20 -0300)

## Revisão de Código e Melhorias Sugeridas
Esta semana tivemos muito trabalho concentrado em:
1. Empacotamento MSIX para Microsoft Store (b7a2fcf)
2. Correções de interface no widget e About Panel (aebf2f8, c24f305)
3. Correções no build do Windows CI (MSVC) (651a36d, 777722f)
4. Persistência de tela em Fullscreen (98bd126)
5. Adição de Landing Page, Site Estático e novos assets de documentação (d5e34eb, edaa9e9, 7cdd3ae, c532e6d)
6. Novos visuais: design 3D, orb dynamics, progress ring (cfbd66e, 0379d70)
7. Conformidade com SignPath para Windows CI Code Signing (3c8b26d)

### Falhas e Pontos de Atenção Encontrados
- **Falhas de CI/Build**: Vimos problemas em versões específicas do MSVC (14.51) que precisaram de hotfixes rápidos. O uso de `if:` com `secrets` no CI quebrou pipelines, o que nos lembra de sempre testar changes em branches antes de push na main.
- **Polimento da Interface**: O menu flutuante precisou de correções de layout (item 'Sair' sendo cortado) em versões recentes, mostrando que mais testes visuais poderiam prevenir esses deslizes.
- **Linter e Análise de Código**: A presença de linting fatal (`prefer_initializing_formals`) quebrando o CI evidencia a necessidade de rodar `dart analyze` localmente antes de commits.

### Melhorias Sugeridas
- Adicionar testes unitários/widget tests mais robustos para os novos componentes visuais e estados do menu flutuante.
- Incluir um passo no CI para checar os logs de warning de compilação, para agir antes que se tornem erros (como aconteceu no caso MSVC).
- Para as landing pages introduzidas (site/), garantir que passem por testes de acessibilidade e que o Lighthouse seja rodado automaticamente via GitHub Actions no CI.

## Próxima Ação
1. **Estabilização da Branch Main**: Dedicar a próxima sprint para escrever *widget tests* focados no botão flutuante e sobreposições, evitando que os bugs visuais relatados reapareçam.
2. **Monitoramento do MSIX**: Acompanhar de perto a primeira submissão real para a Microsoft Store e avaliar feedbacks no painel do Partner Center.
3. **Integração do Lighthouse**: Implementar CI para validar a landing page com Lighthouse para evitar regressões nas métricas vitais da Web.
