# Decisions

## 2026-07-25 - O ciclo usa uma linguagem visual calma e tokenizada

Decision:

- Manter a paleta de baixa luminância e usar apenas azul como acento funcional.
- Reservar cores adicionais para estados semânticos acompanhados por texto.
- Remover loops decorativos do orbe, overlay e contador.
- Usar feedback finito no início/fim do ciclo, hover, pressão e lembrete.
- Manter a paleta escura na janela transparente para preservar contraste
  previsível; respeitar alto contraste e reduzir movimento do sistema.

Rationale:

- Um app de pausa ocular não deve criar uma nova fonte de competição visual.
- Progresso contínuo e estático é legível pela visão periférica sem exigir
  vigilância.
- Tokens e gates automáticos tornam contraste, motion e tipografia verificáveis.

## 2026-06-15 - Blink reminders use widget-level micronotification

Decision:

- Implement blink reminders as a small animated cue inside the floating widget window instead of system notifications.
- Show the cue every 7.5 seconds, equivalent to 8 reminders per minute.
- Keep the feature enabled by default, with a settings toggle for users who prefer to disable it.

Rationale:

- The request asked for a delicate visual reminder rather than a robust notification.
- System notifications would be too disruptive at 8 times per minute.
- The cue stays within the existing always-on-top widget surface and avoids new notification permissions or OS-specific notification behavior.

## 2026-06-15 - Blink sounds are opt-in and separate from visual cues

Decision:

- Add a separate opt-in sound reminder for blink cues.
- Keep visual blink reminders enabled by default, but keep blink sound reminders disabled by default.
- Offer 4 built-in gentle tones and a volume slider.
- Keep the existing global sound setting as a master mute for the blink sound.

Rationale:

- A sound every 7.5 seconds can be helpful for some users but intrusive for others.
- Separate visual and sound controls let the user choose visual-only, sound-only, both, or neither.
- The sound layer should not rely on OS notifications because the desired behavior is frequent and delicate.

## 2026-07-06 - Docking uses partial off-screen window anchoring

Decision:

- Treat lateral docking as a window-positioning behavior, not only as an internal clipping effect.
- Keep about 62% of the compact window visible while docked.
- Increase the snap threshold to make docking easier to trigger intentionally.
- Recalculate docked position after startup and compact size changes.
- Undock automatically when the user disables edge snapping.

Rationale:

- A fully visible window with an internally clipped ball felt less like a side attachment.
- Partial off-screen anchoring makes the widget visually calmer while still clickable.
- Redocking after size changes prevents stale saved positions from making the widget drift.

## 2026-07-06 - Modern visual defaults are enabled conservatively

Decision:

- Increase the default ball size from 24 px to 32 px.
- Lower idle opacity from 100% to 82%.
- Enable the dynamic orb effect by default, but reduce default intensity from 85% to 72%.
- Allow a wider size range, 18-96 px, and opacity down to 20%.

Rationale:

- The old 24 px default was too small for a primary always-on-top control.
- Lower idle opacity and the docked opacity multiplier make the widget less intrusive during work.
- The modern effect should be visible out of the box, but not so intense that it becomes a distraction.
