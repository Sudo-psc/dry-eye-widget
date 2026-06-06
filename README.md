# Dry Eye Widget 👁️💧

### Seus olhos também merecem uma pausa.

Um pequeno companheiro que vive no canto da sua tela e, de tempos em tempos, te
convida a respirar, olhar para longe e cuidar da sua visão — para que você
trabalhe o dia inteiro com mais conforto e menos cansaço nos olhos.

---

## Por que isso importa

Passamos horas e horas diante de telas. E acontece algo curioso: quando estamos
muito concentrados no computador ou no celular, **piscamos bem menos** — em
alguns casos, até cerca de dois terços menos do que o normal. Piscar é o que
espalha a lágrima que mantém os olhos lubrificados e protegidos. Piscando pouco,
a lágrima evapora rápido e surgem aqueles sintomas tão conhecidos de quem
trabalha no digital: **ardência, olhos cansados, vermelhidão, visão embaçada no
fim do dia e aquela sensação de areia nos olhos**.

Esse conjunto de incômodos tem nome: **Síndrome da Visão de Computador** (ou
fadiga visual digital), e caminha lado a lado com o **olho seco**. Não é "frescura"
nem cansaço passageiro — é um problema real, cada vez mais comum, que vai além do
desconforto: olhos secos e fatigados **atrapalham a concentração e reduzem a
produtividade** de quem vive de tela. Quando os olhos não estão bem, o trabalho
rende menos.

A boa notícia é que existe um hábito simples, recomendado por oftalmologistas no
mundo todo, que ajuda muito:

## A regra 20-20-20 ⏱️

> **A cada 20 minutos, olhe para algo a cerca de 6 metros de distância (20 pés)
> por 20 segundos** — e aproveite para piscar algumas vezes, devagar e completo.

Esses 20 segundos relaxam o músculo que mantém o foco de perto e dão à lágrima a
chance de renovar a superfície dos olhos. Parece pouco, mas, repetido ao longo do
dia, faz diferença real no conforto visual.

O problema? **No meio do trabalho, a gente esquece.** É exatamente aí que este
app entra: ele lembra por você, sem atrapalhar.

---

## Feito por um médico, para quem trabalha no digital 👨‍⚕️

Este aplicativo foi criado pelo **Dr. Philipe Saraiva Cruz**, oftalmologista, com
um objetivo simples e sincero: **ajudar seus pacientes — e todos os trabalhadores
digitais — a conviverem melhor com o olho seco e a fadiga visual**. Ele nasceu da
prática do consultório, da vontade de levar um cuidado que normalmente fica
restrito à consulta para dentro da rotina de quem passa o dia diante de uma tela.

É a regra 20-20-20 transformada em um gesto gentil que aparece na sua tela na hora
certa.

---

## 📥 Baixe e use (macOS)

**➡️ [Baixar DryEyeWidget.dmg](https://github.com/Sudo-psc/dry-eye-widget/releases/latest/download/DryEyeWidget.dmg)** — universal (Apple Silicon + Intel)

1. Abra o `.dmg` e **arraste** o app para a pasta **Aplicativos**.
2. Na primeira vez, clique com o **botão direito → Abrir** (o app é gratuito e
   ainda não tem assinatura paga da Apple, então o macOS pede essa confirmação).
3. Pronto! Uma bolinha azul aparece num canto da tela e um ícone de olho na barra
   de menu. Pode continuar trabalhando — ele cuida do resto.

> Todas as versões ficam em **[Releases](https://github.com/Sudo-psc/dry-eye-widget/releases)**.

---

## ✨ Como funciona

- 🔵 **Uma bolinha discreta** fica sempre visível, no canto que você preferir.
  Arraste para onde quiser.
- ⏰ A cada **20 minutos** (ajustável), ela fica vermelha, pisca suavemente e abre
  um lembrete delicado: **olhe para longe e pisque por 20 segundos**.
- 🧘 Um cronômetro guia a pausa. Ao terminar, um "Parabéns!" e a bolinha volta ao
  normal — ciclo reiniciado.
- 👁️ Um **ícone de olho na barra de menu** mostra o progresso até a próxima pausa
  e permite controlar o app a qualquer momento.
- 📖 Um item **Orientações** traz, em poucas palavras, o porquê de tudo isso.

### Você no controle ⚙️

Tudo é ajustável para caber na sua rotina: tempo entre as pausas e duração delas,
tamanho e cor da bolinha, som e notificações, um anel de progresso ao redor da
bolinha, iniciar junto com o computador, ocultar do Dock e muito mais. Quer
discrição total? Esconda a bolinha e use só o ícone da barra de menu — ou o
contrário. Do seu jeito.

---

## 💚 Uma nota de cuidado

Este app é um **lembrete de bons hábitos**, não um tratamento. Ele não diagnostica
nem cura nada. Se você sente desconforto nos olhos com frequência, **procure um
oftalmologista** — seus olhos merecem uma avaliação de verdade.

---

## 🛠️ Para desenvolvedores

Projeto **Flutter** (macOS e Windows). Rápido de rodar:

```bash
flutter pub get
flutter run -d macos      # ou: -d windows
```

Compilar e empacotar:

```bash
flutter build macos --release         # gera o app universal (arm64 + x86_64)
./scripts/make_dmg.sh                  # empacota em dist/DryEyeWidget.dmg
flutter build windows --release        # .exe (em uma máquina Windows)
```

Qualidade: `flutter analyze` (sem avisos) e `flutter test`. A arquitetura usa
`provider` para estado, `window_manager` + `flutter_acrylic` para a janela
flutuante transparente, `tray_manager` para a barra de menu, além de
`audioplayers`, `local_notifier`, `launch_at_startup` e `shared_preferences`.

> Windows precisa de **Visual Studio 2022** ("Desktop development with C++") e só
> pode ser compilado em uma máquina Windows. macOS precisa do **Xcode**.

---

## 🆓 Licença

**Uso livre.** Distribuído sob a licença **MIT** — você pode usar, compartilhar,
estudar e modificar livremente. Que ele ajude o máximo de olhos possível. 💙

## 👨‍⚕️ Autor

Criado com cuidado por **Dr. Philipe Saraiva Cruz** — Oftalmologista · RQE 71.903
