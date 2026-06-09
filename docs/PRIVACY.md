# Dry Eye Widget — Privacy Policy

Last updated: June 9, 2026

This Privacy Policy explains how Dry Eye Widget handles information while you use
the app. The core principle is simple: the app is designed to run **locally** and
**not** send user activity data off the machine.

## 1. Summary

Dry Eye Widget has no activity telemetry, usage analytics, remote monitoring, or
behavior-history upload.

| Topic | How Dry Eye Widget handles it |
| --- | --- |
| Activity data | Not collected, not logged, not sent off the machine. |
| Inactivity detection | Reads only the seconds since the last user input, locally. |
| Keys, clicks, cursor | Does not record keystrokes, clicks, coordinates, paths, or cursor history. |
| Windows and apps | Does not identify open apps, window titles, or visited sites. |
| Screenshots | Does not take screenshots or analyze the screen. |
| Camera (presence) | **Optional and off by default.** When enabled, takes a **single local photo**, checks for a face, and **discards the image immediately** — nothing is stored or sent. |
| Inactivity learning | Aggregated state stored **encrypted** on the device (Keychain/DPAPI), with no event history and no remote access. |
| Settings | Stored locally to keep your preferences. |
| Updates | The optional update check queries GitHub Releases and includes no activity data. |

## 2. Data the app does not collect

Dry Eye Widget does not collect, store, share, sell, or send user activity data
off the machine. This includes, without limitation: browsing history, visited
sites, open applications, window names/titles, typed text, passwords, clipboard
contents, keystrokes, clicks, mouse coordinates, cursor paths, screenshots,
microphone audio, local file contents, and productivity/presence/attention or
behavioral scores.

Webcam images are **not** collected **except** when you explicitly enable camera
presence confirmation (see section 3.1), which processes **a single frame
locally and discards it**, without recording or transmitting it.

The app does not use any such data for advertising, profiling, surveillance,
productivity scoring, or behavioral analysis.

## 3. How inactivity detection works

Inactivity detection uses a local operating-system feature to read the time
elapsed since the last global user input (mouse movement, click, or key). That
query returns only a time value, in seconds, used to pause the timer when you
appear to be away, show a small inactivity-pause notice, resume automatically on
new activity, and allow manual resume.

It does not reveal which key was pressed, where you clicked, which window was
open, which site was being accessed, or what was on screen. The local counter is
never turned into an activity history and is never sent to external servers.

The threshold separating "pause" from "away" is **learned locally** from your own
patterns. This learning is kept only as an **aggregated state** (a handful of
numbers, no raw events, no timeline), **encrypted at rest** by the operating
system (Keychain on macOS, DPAPI on Windows), with no remote access. A settings
button lets you erase this learning.

### 3.1 Optional camera presence confirmation

As of version 1.8, Dry Eye Widget offers an **optional, off-by-default** feature:
confirming your presence with the camera when the system goes idle. When — and
only when — you enable it and grant the OS camera permission:

- when inactivity reaches the threshold, the app captures **a single frame**;
- processing is **100% local** (on macOS, via the system Vision framework): it
  only checks **whether a face is in view**;
- the image is **discarded immediately** after that check — it is **not** saved
  to disk, **not** sent over the network, and **not** turned into any history;
- the only signal the app uses is "present / away".

The feature asks for **explicit consent** before the OS camera prompt, can be
**turned off at any time**, and when off the camera is **never** accessed. On
Windows, camera confirmation is not available yet.

## 4. Data stored locally

To work conveniently, the app may store simple preferences and state on your own
computer: break intervals and reminder durations; notification, audio, and
gentle-mode settings; language, theme, scale, and visual preferences; widget
position; timer progress for resuming after a restart; the "launch at startup"
preference; and the encrypted inactivity-learning state described above.

These are used only to keep your configuration and experience continuity. They
are not sent to our servers, analytics services, or third parties.

## 5. External communications

Dry Eye Widget does not send user activity data off the machine.

The only external communication the app makes is the **optional update check**
against GitHub Releases, when that feature is triggered. It compares the
installed version with the latest published version and includes no activity
history, inactivity data, keystrokes, clicks, cursor, open windows, screenshots,
or medical preferences.

As with any access to an external address, GitHub, the operating system, your
ISP, or a corporate network may process technical connection metadata (IP
address, request time, user-agent, network logs). This metadata is not activity
data collected by Dry Eye Widget and is not controlled by the app.

## 6. Local notifications

When enabled, notifications are shown locally by the operating system to signal
breaks, resumes, eye rest, or configured reminders. They do not require sending
activity data off the machine.

## 7. Launch at startup

If you enable "launch at startup," the app may register that preference with the
local Windows/macOS startup mechanism. This only opens the app automatically; it
collects no activity data and creates no remote monitoring.

## 8. User control

You can control the app via its own settings and the operating system: disable
notifications, disable sounds, disable launch-at-startup, adjust times and
breaks, disable or reset camera presence, erase the inactivity learning, close
the app, uninstall it, and clear local app data through OS mechanisms.

If you sync, copy, or back up local folders using external tools, those tools may
handle the files per their own policies, which is outside the app's control.

## 9. Security

The app reduces privacy risk by avoiding activity-data collection and keeping
preferences (and the encrypted learning state) on your own computer. Environment
security also depends on the operating system, permissions, antivirus, corporate
policies, backups, and sync tools installed by the user.

## 10. Children and adolescents

Dry Eye Widget is not directed at collecting data from children or adolescents.
Because it collects no activity data and sends none off the machine, it creates
no registration, profile, or remote monitoring of minors. Guardians should guide
computer use, breaks, and eye care according to age and professional advice.

## 11. Changes to this policy

This Privacy Policy may be updated to reflect changes in the app, documentation,
or legal requirements. The "last updated" date is revised whenever a relevant
change is made.

## 12. Contact

Questions, suggestions, bug reports, or privacy-related requests can be sent
through the official channels of the Dry Eye Widget repository, such as GitHub
issues or discussions when available.

---

🇧🇷 Versão em português: [politica-de-privacidade.md](legal/politica-de-privacidade.md)
