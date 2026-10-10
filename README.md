TrinketSwitcher
===============

What it does
- Auto switch: Out of combat, equips the highest-priority ready trinket for each slot.
- Preemptive return: When your top priority becomes switch-ready, it preempts lower priority trinkets.
- Cross-slot coordination: If both slots want the same trinket, slot 13 gets it; slot 14 takes the next ready item.
- Passive trinkets: Passive items do not block swaps; usable trinkets only block if they will be ready in 30 seconds or less.
- Mount handling: Auto switching is paused while mounted and restored after dismount.
- Glow hint: In combat, a slot glows if a queued trinket will be ready in 35 seconds or less.
- Ready glow: An equipped on-use trinket can glow when it is ready.
- Manual badge: An "M" appears on a slot when manual mode is active.

In-game usage
- Minimap button:
  - Left-Click: Show/Hide Trinkets window
  - Right-Click: Open/Close Options window
  - Shift + Right-Click: Lock/Unlock buttons
  - Ctrl + Right-Click: Toggle auto switching
  - Drag to reposition using the bundled minimap libraries.
- Trinket buttons:
  - Hover: Show the trinket menu and tooltip.
  - Left-Click: Use the equipped trinket.
- Trinket menu:
  - Shift + Left/Right-Click: Add/remove a trinket from slot 13/14 queue.
  - Ctrl + Left/Right-Click: Equip in slot 13/14 and toggle that slot's manual mode.

Priority rules
- Each slot has its own queue; position 1 is highest priority.
- The first ready trinket with 30 seconds or less cooldown remaining is chosen.
- If both slots want the same item, slot 13 wins; slot 14 tries its next choice.
- While a slot's top priority is not ready, the currently equipped queued item for that slot is reserved so the other slot will not steal it.
- Usable items near ready will not be swapped off unless the incoming trinket is higher priority for that slot.

Slash commands
- `/ts`: Show quick help.
- `/ts clear 13`: Clear slot 13 queue.
- `/ts clear 14`: Clear slot 14 queue.
- `/ts clear both`: Clear both queues.
- `/trinketswitcher`: Same as `/ts`.

Notes
- All required libraries are bundled: LibStub, CallbackHandler-1.0, LibDataBroker-1.1, and LibDBIcon-1.0. No separate library installation is needed.
- Auto switching only happens out of combat.
- On WoW Forever clients that do not read addon SavedVariables back, settings are mirrored per character through the Blizzard addon-list table and addon CVars.
- If the client protects item cooldown values in a restricted encounter, cooldown-based switching waits until those values are readable again.
- The trinket menu can be configured to appear only out of combat.
- Tiny tooltips, ALT full tooltips, and clean isolated tooltips can be configured in Options.
- Riding trinket, riding enchant, and special trinket handling from the TBC version are intentionally not included.

Talent-based queues
- TrinketSwitcher tracks separate queue sets per talent build.
- When talents change, TrinketSwitcher automatically switches to that build's dedicated queues.
- On first run, current queues are migrated to the current build.
- Settings are saved per character.

### Trinket ready alerts

In Options, scroll to **Trinket ready alerts**. Both new features are off by default.
- Enable macro glows for action-bar macros containing `/use 13`, `/use 14`, or both. Conditional slot-use lines are supported. A macro glows when any referenced equipped on-use trinket is ready; macro conditions are not evaluated. Choose its color beside the toggle and adjust its border width from 1–10 px (default 2 px).
- Enable the ready sound, choose Chime, Bell, or Pulse, and use Preview to listen. Alert volume adjusts only these bundled sounds, in 10% steps; WoW master volume still applies.
- Alerts fire once when an equipped trinket cooldown finishes, including shared or equip cooldowns. Login, newly equipped ready items, and the GCD do not trigger alerts. Simultaneous readiness produces one sound.

Macro glow discovery supports Blizzard, Bartender4, and Dominos action buttons. New buttons are discovered within two seconds.
