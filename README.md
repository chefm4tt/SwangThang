# ⚔️ SwangThang

Melee and ranged swing timer for World of Warcraft: TBC Classic.

**SwangThang** tracks your white-hit swing timers across all attack slots — main hand, off hand, and ranged — giving every physical DPS class the precise timing feedback needed to maximize damage. It handles all the quirks of TBC melee: NMA abilities, dual-wield desync, parry haste, extra attack suppression, haste rescaling, and Druid form shifts.

---

## ✨ Key Features

- ⚔️ **All Melee Classes** — Warrior, Rogue, Paladin, Shaman, Druid, and Hunter all get accurate swing bars tuned to their class mechanics
- 🏹 **Hunter Auto Shot** — Preserved from v1.x: 0.5s cast window visualization, movement penalty retry logic, and latency compensation
- 🔄 **Dual-Wield Tracking** — Independent MH and OH timers with correct isOffHand routing; OH bar anchors below MH automatically
- 🎯 **NMA Detection** — Heroic Strike, Cleave, Maul, and Raptor Strike reset the MH timer on cast via both CLEU and `UNIT_SPELLCAST_SUCCEEDED`
- ⚡ **Haste Rescaling** — Remaining time rescales proportionally when weapon speed changes mid-swing (Slice and Dice, Rapid Fire, haste procs)
- 🛡️ **Parry Haste** — Incoming parries reduce your MH remaining time by 40% of weapon speed (floored at 20%)
- 🔀 **Extra Attack Suppression** — Sword Spec and Windfury Weapon extra attacks are absorbed cleanly without desyncing the timer
- 🐾 **Druid Forms** — Form shifts reset the MH timer; bar label shows current form (*Cat*, *Bear*, *DireBear*, *Caster*)
- 🔑 **Seal Twist Zone** — Ret Paladins get a gold overlay marking the 0.4s window before each MH swing for seal-twisting timing

---

## ⚙️ Installation

1. Download `SwangThang.zip` from the [latest release](https://github.com/chefm4tt/SwangThang/releases/latest)
2. Extract and place the `SwangThang` folder in your AddOns directory:
   ```
   World of Warcraft\_anniversary_\Interface\AddOns\SwangThang\
   ```
3. Log in and start swinging

---

## 🖥️ Usage

Bars appear automatically when you enter combat. The ranged bar (Hunter) also appears when auto-shot mode starts.

| Bar | Color | Meaning |
|-----|-------|---------|
| Ranged | 🟢 Green | Auto Shot cooldown — safe to move |
| Ranged | 🔴 Red | Cast window — **do not move** |
| Main Hand | 🟡 Gold | MH swing cooldown |
| Off Hand | 🟢 Green | OH swing cooldown |

A spark indicator shows current progress. **Left-click drag** to reposition any bar. Positions persist across sessions.

---

## 🎮 Class Support

| Class | Bars | Special |
|-------|------|---------|
| Hunter | Ranged + MH | 0.5s cast window, movement clipping, latency compensation |
| Warrior | MH + OH | HS/Cleave/Slam NMA detection |
| Rogue | MH + OH | Full dual-wield |
| Paladin | MH | Gold seal-twist zone overlay |
| Enhancement Shaman | MH + OH | Full dual-wield |
| Feral Druid | MH | Form-label bar, reset on shift |
| Mage / Priest / Warlock | — | No bars (no auto-attack rotation) |

---

## 🔧 Configuration

No slash commands. All settings save automatically.

| Setting | Storage |
|---------|---------|
| Bar positions | `SwangThangDB.positions` |
| MH / OH visibility | `SwangThangDB.showMH` / `showOH` |

---

## 💬 Feedback

Found a bug? Have an idea? Open an issue on [GitHub Issues](https://github.com/chefm4tt/SwangThang/issues) — bug reports and feature requests are welcome. v2.0 is the first release with full melee support, so feedback from all class players is especially appreciated.

---

## 📋 Changelog

### 2.0 *(Latest)*

- 🆕 Full melee swing timer for all physical DPS classes
- 🆕 Dual-wield MH + OH independent tracking
- 🆕 NMA ability detection (Heroic Strike, Cleave, Maul, Raptor Strike, Slam)
- 🆕 Extra attack suppression (Sword Spec, Windfury Weapon)
- 🆕 Parry haste support
- 🆕 Haste rescaling for all melee bars
- 🆕 Druid form-shift reset with form label
- 🆕 Ret Paladin seal-twist zone overlay
- 🆕 5-module architecture (Constants / State / UI / ClassMods / Bootstrap)
- ✨ SavedVariables migrated to `SwangThangDB` (nested positions)

### 1.1.1

- ✨ Updated README with standard formatting and installation path
- 🆕 Added CI release workflow (GitHub + CurseForge)
- 🆕 Added issue templates and PR template

### 1.1

- 🆕 Initial public release — Hunter Auto Shot timer
- 🆕 Dynamic swing timer with haste proc support
- 🆕 0.5s cast window visualization
- 🆕 Movement penalty and TBC retry mechanic simulation
- 🆕 Latency compensation via `GetNetStats`
- 🆕 Draggable frame with persistent position storage
