<p align="center">
  <img src="banner.png" alt="Dry Eye Widget — a regra 20-20-20 em um lembrete gentil na sua tela" width="820">
</p>

<h1 align="center">Dry Eye Widget 👁️💧</h1>

<p align="center"><em>Prevenção da Fadiga Visual Digital através de Micro-Pausas Oculares.</em></p>

<p align="center"><b>🇧🇷 Português</b> · <a href="README.en.md">🇺🇸 English</a></p>

<p align="center">
  <a href="https://github.com/Sudo-psc/dry-eye-widget/releases/latest/download/DryEyeWidget.dmg"><img src="https://img.shields.io/badge/Baixar-macOS%20.dmg-0A84FF?style=flat-square&logo=apple&logoColor=white" alt="Baixar para macOS"></a>
  <a href="https://github.com/Sudo-psc/dry-eye-widget/releases/latest/download/DryEyeWidget-Setup-x64.exe"><img src="https://img.shields.io/badge/Baixar-Windows%20.exe-0078D6?style=flat-square&logo=windows&logoColor=white" alt="Baixar para Windows"></a>
  <img src="https://img.shields.io/badge/Plataforma-macOS%20%7C%20Windows-555?style=flat-square" alt="Plataformas">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter">
  <a href="#-licença"><img src="https://img.shields.io/badge/Licença-MIT-22c55e?style=flat-square" alt="Licença MIT"></a>
</p>

<p align="center">
Uma ferramenta de intervenção profilática que implementa a regra oftalmológica 20-20-20, visando mitigar a Síndrome da Visão de Computador (CVS) e a Doença do Olho Seco (DED) associada ao uso prolongado de telas.
</p>

---

## Fisiopatologia e Justificativa

O uso contínuo e prolongado de Terminais de Vídeo (VDTs) induz alterações fisiológicas significativas na superfície ocular e na musculatura intrínseca do olho. Durante atividades cognitivamente exigentes em telas, a **taxa de pestanejo espontâneo é reduzida em até 60%**, enquanto a amplitude do piscar frequentemente se torna incompleta. Esta disfunção na dinâmica do pestanejo leva a uma instabilidade mecânica do filme lacrimal, aumento da taxa de evaporação e hiperosmolaridade, resultando no ressecamento da superfície ocular (Doença do Olho Seco evaporativa). Simultaneamente, a focalização ininterrupta a curtas distâncias resulta em espasmo acomodativo do músculo ciliar e estresse convergente, manifestando-se clinicamente como astenopia (fadiga visual) e visão turva transitória.

O conjunto dessas manifestações clínicas é definido como **Síndrome da Visão de Computador (CVS)** ou **Fadiga Visual Digital (DES)**. Do ponto de vista ocupacional, a DED sintomática e a fadiga visual têm um impacto substancial no desempenho laboral, resultando em quedas significativas de produtividade (presenteísmo) que podem atingir cerca de 30% [²], além de induzir um declínio na velocidade e na fluência de leitura prolongada em até 14% [³ ⁴].

### 📊 Evidências Científicas

| | |
|---:|:---|
| **~50%** | Prevalência global de Doença do Olho Seco (DED) entre trabalhadores usuários de terminais de vídeo, segundo meta-análises [¹] |
| **~30%** | Redução documentada no desempenho e produtividade (*presenteísmo*) em indivíduos com olho seco sintomático [²] |
| **até 14%** | Comprometimento da fluência e velocidade de leitura prolongada induzido por alterações da superfície ocular [³ ⁴] |

A intervenção profilática de primeira linha, preconizada pelas sociedades internacionais de oftalmologia e ergonomia, é a adesão a intervalos visuais regulares e padronizados:

## A Regra 20-20-20 ⏱️

> **A cada 20 minutos de uso de tela, o indivíduo deve desviar o foco visual para um objeto situado a pelo menos 20 pés (aproximadamente 6 metros) de distância, durante um período mínimo de 20 segundos.**

**Mecanismo de ação:**
1. **Relaxamento Acomodativo:** O desvio do olhar para o infinito óptico (≥ 6 metros) interrompe a contração sustentada do músculo ciliar e a convergência dos músculos extraoculares, aliviando o estresse biomecânico e a astenopia.
2. **Restauração do Filme Lacrimal:** A pausa de 20 segundos encoraja ativamente o restabelecimento da frequência normal e completa de pestanejo, promovendo a ação mecânica de expressão das glândulas de Meibomius e a consequente redistribuição lipídica e aquosa sobre a córnea.

A principal barreira clínica a essa intervenção é a baixa adesão comportamental, motivada pelo engajamento cognitivo profundo (imersão digital). O *Dry Eye Widget* atua diretamente sobre essa limitação, servindo como um mecanismo de *biofeedback* contínuo que automatiza e sinaliza essas micro-pausas terapêuticas.

---

## 👨‍⚕️ Desenvolvimento Especializado

A aplicação foi concebida e desenvolvida pelo **Dr. Philipe Saraiva Cruz**, médico oftalmologista, em resposta à crescente incidência de DES na prática clínica diária. O software tem como objetivo transpor as recomendações preventivas baseadas em evidências do ambiente clínico para uma solução digital integrada e ininterrupta, perfeitamente alinhada ao fluxo de trabalho (*workflow*) do usuário moderno.

---

## 📥 Implantação e Execução

### 🍎 macOS

**➡️ [Baixar pacote DMG (DryEyeWidget.dmg)](https://github.com/Sudo-psc/dry-eye-widget/releases/latest/download/DryEyeWidget.dmg)** — Binário universal (Apple Silicon + Intel)

1. Monte o arquivo `.dmg` e **mova** a aplicação para o diretório de **Aplicativos** (`/Applications`).
2. Na primeira execução, contorne as restrições de quarentena do Gatekeeper selecionando o arquivo e utilizando a função **botão direito → Abrir** (a aplicação é distribuída livremente e não possui certificação digital paga da Apple).
3. Após a inicialização, um *widget* não intrusivo será renderizado em uma camada de janela persistente (always-on-top), operando de forma autônoma.

### 🪟 Windows

**➡️ [Baixar instalador executável (DryEyeWidget-Setup-x64.exe)](https://github.com/Sudo-psc/dry-eye-widget/releases/latest/download/DryEyeWidget-Setup-x64.exe)** &nbsp;·&nbsp; ou o **[arquivo compactado portátil (.zip)](https://github.com/Sudo-psc/dry-eye-widget/releases/latest/download/DryEyeWidget-windows-x64.zip)** (Arquitetura 64 bits)

1. Execute o instalador. Caso o filtro **Windows SmartScreen** intercepte a execução devido à ausência de assinatura de código, selecione **Mais informações → Executar assim mesmo**.
2. Inicialize o aplicativo via atalho no **Menu Iniciar**. O *widget* se acoplará à tela e registrará um processo em segundo plano na **bandeja do sistema** (*system tray*).

> **Aviso sobre a versão portátil:** extraia o conteúdo do `.zip` e inicie via `dry_eye_widget.exe`. Certifique-se de preservar a integridade estrutural do diretório, mantendo os arquivos `.dll` e a subpasta `data\` no mesmo diretório do executável raiz.

> Todos os binários de *release* encontram-se arquivados em **[Releases](https://github.com/Sudo-psc/dry-eye-widget/releases)**.

---

## ✨ Dinâmica Operacional

- 🔵 **Interface Persistente:** O *widget* opera em modo *overlay* com fundo transparente, garantindo visibilidade contínua de status sem bloquear eventos subjacentes do sistema operacional.
- ⏰ **Ciclos de Alerta:** A cada **20 minutos** (parâmetro customizável), a sinalização visual do *widget* transita para um estado de alerta e sugere ativamente a micro-pausa visual e a realização de piscadas voluntárias.
- 🧘 **Temporizador Integrado:** Um cronômetro decrescente orienta o processo fisiológico de repouso por 20 segundos. Concluída a pausa, os ciclos subjacentes são automaticamente rearmados.
- 👁️ **Controle via Bandeja:** Um nó integrado na barra de menus/bandeja do sistema provê monitoramento em tempo real do progresso metabólico e opções globais de sobreposição de controle (pausar, resetar, etc).

### Parâmetros Configuráveis ⚙️

O motor do *widget* oferece uma arquitetura flexível de configuração: modulação do ciclo de tempo, ajuste do raio do *overlay*, matriz de cores de estado (idle/alerta), configurações de renderização (modo *glass* translúcido vs fundo escurecido), inicialização acoplada ao boot do sistema operacional, e controle de inatividade, garantindo aderência ótima a fluxos de trabalho variados.

---

## 💚 Consideração Clínica

Esta aplicação é rigorosamente uma **ferramenta de suporte profilático**, atuando na modulação de hábitos laborais e não consistindo em dispositivo médico com fins diagnósticos ou curativos. Em casos de astenopia crônica, hiperemia sustentada ou instabilidade sintomática do filme lacrimal, é imprescindível **buscar avaliação oftalmológica especializada**.

---

## 🛠️ Especificações Técnicas (Desenvolvedores)

A infraestrutura baseia-se em **Flutter** (*desktop-first*), suportando macOS e Windows nativamente.

```bash
flutter pub get
flutter run -d macos      # ou -d windows
```

Processo de compilação (*Build Pipeline*):

```bash
flutter build macos --release         # Compila binário universal (arm64 + x86_64)
./scripts/make_dmg.sh                  # Transcreve o pacote estrutural dist/DryEyeWidget.dmg
flutter build windows --release        # Produz binário standalone x64
```

Arquitetura e Dependências: O projeto não apresenta avisos sob `flutter analyze`. Utiliza injeção de dependência reativa via `provider`. O controle avançado da janela do sistema operacional utiliza `window_manager` interligado ao `flutter_acrylic` (para efeitos de transparência *liquid glass*). A comunicação da bandeja é feita por `tray_manager`, eventos sonoros por `audioplayers`, *bus* de notificação pelo pacote `local_notifier` e observabilidade de inatividade por interações via canais nativos multiplataforma.

> **Pré-requisitos:** Compilar para Windows exige **Visual Studio 2022** com o pacote "Desktop development with C++" operando sob SO Windows. Compilar para macOS demanda **Xcode** via infraestrutura de host Apple.

---

## 📚 Referências Bibliográficas

1. Courtin R, et al. **Prevalence of dry eye disease in visual display terminal
   workers: a systematic review and meta-analysis.** *BMJ Open.* 2016;6(1):e009675.
   [doi:10.1136/bmjopen-2015-009675](https://doi.org/10.1136/bmjopen-2015-009675)
2. Nichols KK, et al. **Impact of Dry Eye Disease on Work Productivity, and
   Patients' Satisfaction With Over-the-Counter Dry Eye Treatments.** *Invest
   Ophthalmol Vis Sci.* 2016;57(7):2975-82.
   [doi:10.1167/iovs.16-19419](https://doi.org/10.1167/iovs.16-19419)
3. Mathews PM, et al. **Functional impairment of reading in patients with dry
   eye.** *Br J Ophthalmol.* 2016;101(4):481-6.
   [doi:10.1136/bjophthalmol-2015-308237](https://doi.org/10.1136/bjophthalmol-2015-308237)
4. Karakus S, et al. **Impact of Dry Eye on Prolonged Reading.** *Optom Vis Sci.*
   2018;95(12):1105-13.
   [doi:10.1097/OPX.0000000000001303](https://doi.org/10.1097/OPX.0000000000001303)

<sub>Arquivo de metadados de referência no formato RIS disponível em:
[`docs/referencias.ris`](docs/referencias.ris).</sub>

## ⚖️ Aspectos Legais

- [Termos de Uso](docs/TERMOS.md)
- [Política de Privacidade](docs/PRIVACIDADE.md)

## 🆓 Licenciamento

**Código de Distribuição Livre.** Arquitetura open-source governada sob a Licença **MIT** — garantindo prerrogativas irrestritas de uso, replicação, auditoria de código e derivação comercial ou não-comercial. O objetivo fundamental desta ferramenta é universalizar o cuidado ergonômico. 💙

## 👨‍⚕️ Autoria Científica

Concebido e documentado clinicamente pelo **Dr. Philipe Saraiva Cruz** — Médico Oftalmologista · CRM-MG 82.521 · RQE 71.903
