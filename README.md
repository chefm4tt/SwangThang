# SwangThang Hunter Shot Timer

**SwangThang** is a specialized Auto Shot timer for Hunters in **World of Warcraft: TBC Classic**. It is built to accurately visualize the unique swing timer mechanics of the expansion, including the hidden cast window and movement penalties.

## Features

*   **Dynamic Swing Calculation**: Real-time updates based on your current ranged weapon speed, accounting for procs like *Quick Shots*, *Rapid Fire*, or *Dragonspine Trophy*.
*   **The 0.5s Cast Window**: The bar turns **Red** during the final 0.5 seconds of the swing. This represents the hidden cast time where standing still is required.
*   **Movement Logic**:
    *   **Green Bar**: Safe to move (Cooldown phase).
    *   **Red Bar**: Moving here clips the shot. The timer will "pause" or reset to the start of the cast window to reflect the TBC retry mechanic.
*   **Latency Compensation**: Automatically adjusts the start time of the swing based on your current World Latency (`GetNetStats`).
*   **Draggable Interface**: Hold **Left Click** to drag the bar to your preferred position. The location is saved automatically.

## Installation

1.  Download the `SwangThang` folder.
2.  Place it in your AddOns directory:
    `\World of Warcraft\_anniversary_\Interface\AddOns\`
3.  (Optional) Ensure `SwangThang.toc` and `SwangThang.lua` are inside the folder.
4.  Log in and start shooting!

## Usage

The bar is hidden by default until you fire an Auto Shot.

*   **Visuals**:
    *   **Green**: Auto Shot Cooldown.
    *   **Red**: Auto Shot Cast (Don't move!).
    *   **Spark**: Indicates current progress.
*   **Reset**: The timer resets if you cast a hard-cast ability (like Aimed Shot) or if you stop attacking.

## Configuration

There are no slash commands. The frame is unlocked by default for dragging.

*   **Position**: Saved in `HunterTimerDB`.

## Technical Info

*   **API**: Uses `UnitRangedDamage` for precise haste calculations.
*   **Events**: Listens to `COMBAT_LOG_EVENT_UNFILTERED` for Spell ID 75 (Auto Shot).