<p align="center">
  <img src="banner.png" alt="Dry Eye Widget — the 20-20-20 rule as a gentle reminder on your screen" width="820">
</p>

<h1 align="center">Dry Eye Widget 👁️💧</h1>

<p align="center"><em>Your eyes deserve a break too.</em></p>

<p align="center"><a href="README.md">🇧🇷 Português</a> · <b>🇺🇸 English</b></p>

<p align="center">
  <a href="https://github.com/Sudo-psc/dry-eye-widget/releases/download/v1.6.0/DryEyeWidget.dmg"><img src="https://img.shields.io/badge/Download-macOS%20.dmg-0A84FF?style=flat-square&logo=apple&logoColor=white" alt="Download for macOS"></a>
  <a href="https://github.com/Sudo-psc/dry-eye-widget/releases/latest/download/DryEyeWidget-Setup-x64.exe"><img src="https://img.shields.io/badge/Download-Windows%20.exe-0078D6?style=flat-square&logo=windows&logoColor=white" alt="Download for Windows"></a>
  <img src="https://img.shields.io/badge/Platform-macOS%20%7C%20Windows-555?style=flat-square" alt="Platforms">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter">
  <a href="#-license"><img src="https://img.shields.io/badge/License-MIT-22c55e?style=flat-square" alt="MIT License"></a>
</p>

<p align="center">
A little companion that lives in the corner of your screen and, every so often,
invites you to breathe, look into the distance and take care of your vision — so
you can work all day with more comfort and less eye strain.
</p>

---

## Why it matters

We spend hours upon hours in front of screens. And something curious happens: when
we are deeply focused on a computer or phone, we **blink much less** — in some
cases up to about two-thirds less than usual. Blinking spreads the tears that keep
the eyes lubricated and protected. Blinking less, tears evaporate quickly and the
familiar symptoms of digital work appear: **burning, tired eyes, redness, blurry
vision at the end of the day and that gritty feeling**.

This set of complaints has a name: **Computer Vision Syndrome** (or digital eye
strain), and it goes hand in hand with **dry eye**. It is a real, increasingly
common problem that goes beyond discomfort: dry, fatigued eyes **hurt focus and
reduce the productivity** of people who live on screens. When your eyes aren't
well, work suffers.

### 📊 What studies show

| | |
|---:|:---|
| **~50%** | of screen workers have dry eye — in some studies, close to 60% [¹] |
| **~30%** | drop in work performance (*presenteeism*) among those with symptomatic dry eye [²] |
| **up to 14%** | slower prolonged reading because of dry eye [³ ⁴] |

<sub>Full sources in the [References](#-references) section. The numbers were
checked against the literature: exact prevalence varies by diagnostic criteria
(meta-analysis: 49.5%), and the productivity impact is measured as reduced
performance, not as fixed minutes per day.</sub>

The good news is that there is a simple habit, recommended by eye doctors
worldwide, that helps a lot:

## The 20-20-20 rule ⏱️

> **Every 20 minutes, look at something about 6 meters (20 feet) away for 20
> seconds** — and take the chance to blink a few times, slowly and fully.

Those 20 seconds relax the muscle that holds your near focus and give your tears a
chance to refresh the eye surface. It seems like little, but repeated throughout
the day it makes a real difference in visual comfort.

The catch? **In the middle of work, we forget.** That is exactly where this app
comes in: it remembers for you, without getting in the way.

---

## Made by a doctor, for people who work on screens 👨‍⚕️

This app was created by **Dr. Philipe Saraiva Cruz**, ophthalmologist, with a
simple and sincere goal: **to help his patients — and all digital workers — cope
better with dry eye and visual fatigue**. It was born out of clinical practice,
out of the wish to bring care that usually stays inside the consulting room into
the daily routine of people who spend their day in front of a screen.

It is the 20-20-20 rule turned into a gentle nudge that appears on your screen at
just the right time.

---

## 📥 Download & use

### 🍎 macOS

**➡️ [Download DryEyeWidget.dmg](https://github.com/Sudo-psc/dry-eye-widget/releases/download/v1.6.0/DryEyeWidget.dmg)** — universal (Apple Silicon + Intel)

1. Open the `.dmg` and **drag** the app into your **Applications** folder.
2. On first launch, **right-click → Open** (the app is free and not yet signed
   with a paid Apple certificate, so macOS asks for this confirmation).
3. Done! A blue ball appears in a corner of your screen and an eye icon in the
   menu bar. Keep working — it takes care of the rest.

### 🪟 Windows

**➡️ [Download installer (DryEyeWidget-Setup-x64.exe)](https://github.com/Sudo-psc/dry-eye-widget/releases/latest/download/DryEyeWidget-Setup-x64.exe)** &nbsp;·&nbsp; or the **[portable version (.zip)](https://github.com/Sudo-psc/dry-eye-widget/releases/latest/download/DryEyeWidget-windows-x64.zip)** (64-bit)

1. Run the installer. Since the app isn't code-signed yet, **Windows SmartScreen**
   may show "Unknown publisher" — click **More info → Run anyway**.
2. Open it from the **Start Menu** shortcut. A blue ball appears in a corner and
   an eye icon in the **system tray**.

> **Portable version:** extract the `.zip` and run `dry_eye_widget.exe` — keep the
> `.exe` next to the DLLs and the `data\` folder (don't separate the files).

> All versions live in **[Releases](https://github.com/Sudo-psc/dry-eye-widget/releases)**.

---

## ✨ How it works

- 🔵 **A discreet ball** stays always visible, in the corner you prefer. Drag it
  anywhere.
- ⏰ Every **20 minutes** (adjustable), it turns red, blinks gently and shows a
  delicate reminder: **look into the distance and blink for 20 seconds**.
- 🧘 A timer guides the break. When it ends, a "Well done!" and the ball goes back
  to normal — cycle restarted.
- 👁️ An **eye icon in the menu bar** shows the progress to the next break and lets
  you control the app anytime.
- 📖 An **Eye care guide** item explains, in a few words, the why behind it all.

### You're in control ⚙️

Everything is adjustable to fit your routine: time between breaks and their length,
ball size and color, sound and notifications, a progress ring around the ball,
launch at startup, hide from the Dock and more. Want full discretion? Hide the ball
and use only the menu bar icon — or the other way around. Your call.

---

## 💚 A note of care

This app is a **good-habits reminder**, not a treatment. It does not diagnose or
cure anything. If you often feel eye discomfort, **see an ophthalmologist** — your
eyes deserve a real evaluation.

---

## 🛠️ For developers

A **Flutter** project (macOS and Windows). Quick to run:

```bash
flutter pub get
flutter run -d macos      # or: -d windows
```

Build and package:

```bash
flutter build macos --release         # builds the universal app (arm64 + x86_64)
./scripts/make_dmg.sh                  # packages into dist/DryEyeWidget.dmg
flutter build windows --release        # .exe (on a Windows machine)
```

Quality: `flutter analyze` (no warnings) and `flutter test`. The architecture uses
`provider` for state, `window_manager` + `flutter_acrylic` for the transparent
floating window, `tray_manager` for the menu bar, plus `audioplayers`,
`local_notifier`, `launch_at_startup` and `shared_preferences`.

> Windows needs **Visual Studio 2022** ("Desktop development with C++") and can
> only be compiled on a Windows machine. macOS needs **Xcode**.

---

## 📚 References

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

## 🆓 License

**Free to use.** Distributed under the **MIT** license — you may use, share, study
and modify it freely. May it help as many eyes as possible. 💙

## 👨‍⚕️ Author

Crafted with care by **Dr. Philipe Saraiva Cruz** — Ophthalmologist · RQE 71.903
