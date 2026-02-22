# 🏹 SwangThang

Hunter Auto Shot timer for World of Warcraft: TBC Classic.

**SwangThang** is a specialized swing timer addon built to accurately visualize the unique Auto Shot mechanics of TBC Classic — including the hidden cast window and movement penalty retry behavior. It gives Hunters the precise timing feedback needed to maximize ranged DPS without clipping shots.

---

## ✨ Key Features

- ⏱️ **Dynamic Swing Calculation** — Real-time updates based on your current ranged weapon speed, accounting for haste procs like *Quick Shots*, *Rapid Fire*, and *Dragonspine Trophy*
- 🔴 **0.5s Cast Window** — The bar turns red during the final 0.5 seconds of the swing, signaling the hidden cast time where movement will clip the shot
- 🟢 **Movement Logic** — Green bar means safe to move (cooldown phase); red bar means standing still is required. Moving during red triggers the TBC retry mechanic — the timer resets to the start of the cast window
- 📡 **Latency Compensation** — Automatically adjusts swing start time based on your current World Latency (`GetNetStats`)
- 🖱️ **Draggable Interface** — Hold Left Click to drag the bar anywhere on screen. Position is saved automatically between sessions

---

## ⚙️ Installation

1. Download `SwangThang.zip` from the [latest release](https://github.com/chefm4tt/SwangThang/releases/latest)
2. Extract and place the `SwangThang` folder in your AddOns directory:
   ```
   World of Warcraft\_anniversary_\Interface\AddOns\SwangThang\
   ```
3. Log in and start shooting

---

## 🖥️ Usage

The bar is hidden until you fire your first Auto Shot.

| Color | Meaning |
|-------|---------|
| 🟢 Green | Auto Shot cooldown — safe to move |
| 🔴 Red | Auto Shot cast window — **do not move** |

A spark indicator shows current progress along the bar. The timer resets if you cast a hard-cast ability (like Aimed Shot) or stop attacking.

---

## 🔧 Configuration

No slash commands. The frame is unlocked by default for dragging.

| Setting | Storage |
|---------|---------|
| Bar position | Saved in `HunterTimerDB` (persists across sessions) |

---

## 📋 Changelog

### 1.1 *(Latest)*

- 🆕 Initial public release
- 🆕 Dynamic swing timer with haste proc support (*Quick Shots*, *Rapid Fire*, *Dragonspine Trophy*)
- 🆕 0.5s cast window visualization with color-coded red/green bar
- 🆕 Movement penalty and TBC retry mechanic simulation
- 🆕 Latency compensation via `GetNetStats`
- 🆕 Draggable frame with persistent position storage
