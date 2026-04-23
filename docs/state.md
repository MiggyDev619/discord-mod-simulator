# Project State — Day 2 Recovery

_Snapshot: 2026-04-21._

## TL;DR

Nothing is actually broken. Day 1 work isn't lost, scripts are fine, Rojo is connected. You're just working in a new Studio place that doesn't yet have the handful of runtime objects the Day 2 scripts expect. This doc explains the shape of the situation. `day2-studio-setup.md` is the step-by-step to finish the job.

---

## 1. What exists right now

### On disk (repo, under version control)

All Day 2 scripts are written and have content:

| File | Studio destination | Class |
|---|---|---|
| `src/ReplicatedStorage/Shared/Config.lua` | `ReplicatedStorage.Shared.Config` | ModuleScript |
| `src/ServerScriptService/Systems/GameManager.lua` | `ServerScriptService.Systems.GameManager` | ModuleScript |
| `src/ServerScriptService/Enemies/EnemySpawner.server.lua` | `ServerScriptService.Enemies.EnemySpawner` | Script |
| `src/ServerScriptService/Rounds/RoundManager.server.lua` | `ServerScriptService.Rounds.RoundManager` | Script (stub) |
| `src/StarterPlayer/StarterPlayerScripts/ClientMain.client.lua` | `StarterPlayer.StarterPlayerScripts.ClientMain` | LocalScript |
| `src/StarterPack/BanHammer/init.meta.json` + `BanHammerScript.client.lua` | `StarterPack.BanHammer` (Tool) > `BanHammerScript` (LocalScript) | Tool / LocalScript |

New this session (Rojo helpers to auto-create runtime objects):

| File | Produces in Studio |
|---|---|
| `src/ReplicatedStorage/Shared/Remotes.model.json` | `Remotes` Folder with 3 `RemoteEvent`s (`HealthChanged`, `GameOver`, `BanEnemy`) |
| `src/StarterGui/MainUI/init.meta.json` | Marks `MainUI` as a `ScreenGui` (not a plain Folder) |
| `src/StarterGui/MainUI/HealthLabel.model.json` | `TextLabel` named `HealthLabel` inside `MainUI` |

### In Roblox Studio

- `discord-mod-simulator.rbxlx` — the open working file. Baseplate + default services + whatever Rojo has synced. Map is empty.
- Rojo plugin is already connected (visible in screenshot).
- Script folders under `ServerScriptService`, `StarterPack`, `StarterPlayer` are populated by Rojo sync. Good.

### On disk (outside the repo)

- `E:\Roblox Development\DiscordModSimulator.rbxl` (66 KB) — Day 1 file. Has a `.lock` alongside it, so Studio had it open at some point. Day 1 content lives here. Small, mostly map placement.

---

## 2. What went wrong (and what didn't)

**What didn't happen:** Day 1 work was not destroyed. It's safe in `DiscordModSimulator.rbxl`.

**What did happen:** You opened a _different_ place file (`discord-mod-simulator.rbxlx`) for the Rojo workflow. That new place doesn't have the Day 1 map because the map was only ever in `DiscordModSimulator.rbxl`. On top of that, four runtime objects that the scripts call `WaitForChild` on had never been created in this new file:

- `ReplicatedStorage.Shared.Remotes` folder + 3 RemoteEvents
- `Workspace.Map.EnemyStart`
- `Workspace.Map.ServerZone`
- `StarterGui.MainUI.HealthLabel`

Scripts were fine. The scripts just can't make progress past their `WaitForChild` calls until those objects exist.

**Secondary risk we removed:** The original `default.project.json` had this entry:

```json
"Workspace": {
  "Map": { "$path": "src/Workspace/Map" }
}
```

That told Rojo "the `Workspace.Map` subtree in Studio mirrors `src/Workspace/Map` on disk." On every connect, Rojo would have enforced that match — and since `src/Workspace/Map/` is empty, any Parts you placed under `Workspace.Map` in Studio would be wiped the next time Rojo reconnected. This didn't destroy Day 1 work (because Day 1 lived in a different file), but it _would_ have eaten any new Map parts you built in the Rojo-connected place. That entry has now been removed from `default.project.json`.

---

## 3. Changes landed this session

1. **Edited** `default.project.json` — removed the `Workspace` subtree. Rojo no longer owns `Workspace.Map`. Map geometry is now Studio-side only (not version-controlled — acceptable for this project).
2. **Added** `src/ReplicatedStorage/Shared/Remotes.model.json` — Remotes folder + 3 RemoteEvents will be auto-created by Rojo.
3. **Added** `src/StarterGui/MainUI/init.meta.json` — MainUI syncs as a `ScreenGui` (`ResetOnSpawn = false` so the label survives respawns).
4. **Added** `src/StarterGui/MainUI/HealthLabel.model.json` — TextLabel auto-created. Only the `Text` property is Rojo-owned; size/position/color can be tweaked in Studio without getting stomped on reconnect.

Files untouched: all Lua scripts, Config values, BanHammer Tool config.

---

## 4. What you still have to do

Detailed in `docs/day2-studio-setup.md`. Short list:

1. Disconnect and reconnect the Rojo plugin so the new `.model.json` / `.meta.json` files take effect.
2. Create `Workspace.Map` Folder and the two Parts (`EnemyStart`, `ServerZone`) manually.
3. Save the place file.
4. Playtest.

---

## 5. Ongoing hygiene rules

- **Never put `Workspace.<folder>` back into `default.project.json`** unless you also commit its contents to `src/`. The empty-source-wipes-Studio bug is how map work gets lost.
- **Runtime objects that aren't visual geometry** (Remotes, UI, Tools) should be Rojo-managed via `.model.json` / `.meta.json`. Physical/visual things (Map parts, environment models) live in Studio only.
- **Two place files is fine**, but be clear which one you're editing. The Rojo-connected one should be your active workfile; the Day 1 `.rbxl` is now archival.

---

## 6. Optional cleanup (defer)

- `src/Workspace/` directory is now orphaned (no project.json reference). Safe to delete. Low priority.
- `build.rbxl` in the repo is a build artifact. Consider adding `build.rbxl` to `.gitignore` or deleting it.
- `DiscordModSimulator.rbxl` in the parent folder can stay where it is — it's an archive of Day 1.
