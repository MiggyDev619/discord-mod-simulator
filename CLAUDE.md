# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Roblox game "Discord Mod Simulator" — a wave-based survival game where players defend a server from enemies (trolls/spam) using moderation tools (ban, mute, kick). Managed with Rojo 7.6.x.

`docs/plan.md` is the source of truth for phase/day, the 30-day roadmap, and the master checklist — read §2 before proposing feature work. Consolidated devlog notes (one section per session, newest first) live at `DEVLOG-NOTES.md` at the project root — that's what the devlog-post generator consumes. `docs/state.md` captures past incidents/postmortems worth remembering.

## Build / Serve

```bash
rojo build -o "discord-mod-simulator.rbxlx"   # build place file from src/
rojo serve                                      # sync src/ ↔ Roblox Studio
```

No lint/test toolchain yet — Selene/Wally/TestEZ are planned for later phases per `docs/plan.md` §4.

## Rojo mapping (from `default.project.json`)

- `src/ReplicatedStorage` → `ReplicatedStorage` (so `Shared/` becomes `ReplicatedStorage.Shared`)
- `src/ServerScriptService` → `ServerScriptService` (preserves `Systems/`, `Enemies/`, `Rounds/` folders — do not flatten)
- `src/StarterPlayer/StarterPlayerScripts` → `StarterPlayer.StarterPlayerScripts`
- `src/StarterGui` → `StarterGui`
- `src/StarterPack` → `StarterPack`

**`Workspace` is intentionally NOT in the Rojo tree.** It used to be (`src/Workspace/Map → Workspace.Map`) but that caused Rojo to wipe manually-placed Map parts on every reconnect because the source directory was empty. Map geometry (`EnemyStart`, `ServerZone`, any future map models) lives in Studio only and is not version-controlled. Do not re-add `Workspace` to the project tree without also committing actual map contents to `src/`. See `docs/state.md` §2 for the full postmortem.

Script type is chosen by filename suffix: `.server.lua` → Script, `.client.lua` → LocalScript, plain `.lua` → ModuleScript. `GameManager`, `CurrencyManager`, and `Effects` must stay ModuleScripts (plain `.lua`) because other scripts `require()` them.

## Non-code runtime objects — who owns what

Rojo produces almost every non-script runtime object via `.model.json` / `.meta.json` files:

| Object | Source | Notes |
|---|---|---|
| `ReplicatedStorage.Shared.Remotes` + all `RemoteEvent`s | `src/ReplicatedStorage/Shared/Remotes.model.json` | Single file owns the whole subtree. Current events: `HealthChanged`, `GameOver`, `GameWon`, `BanEnemy`, `MuteEnemy`, `PurchaseUpgrade`, `WaveStarted`, `WaveBreak` |
| `StarterGui.MainUI` as `ScreenGui` | `src/StarterGui/MainUI/init.meta.json` | `ResetOnSpawn = false` |
| `MainUI` children (`HealthLabel`, `CurrencyLabel`, `WaveLabel`, `UpgradeButton`) | `src/StarterGui/MainUI/*.model.json` | **Fully Rojo-owned** including Size/Position/AnchorPoint/colors/Font/TextSize plus nested `UIPadding`/`UICorner` children. Don't style in Studio — edit the `.model.json`. |
| `StarterPack.BanHammer` as `Tool` | `src/StarterPack/BanHammer/init.meta.json` | `RequiresHandle = true`. The Tool's `TextureId` (hotbar icon) is set in Studio only — Rojo doesn't own it |
| `BanHammer.Handle` + `BanHammer.Head` parts | `src/StarterPack/BanHammer/{Handle,Head}.model.json` | Wooden shaft + red metal head. `BanHammerSetup.server.lua` welds them on join/respawn. |

The **only** runtime objects that must be created manually in Studio are the Map parts: `Workspace.Map` Folder containing Anchored Parts `EnemyStart` and `ServerZone`. If these don't exist, `EnemySpawner` hangs forever on `WaitForChild`.

When adding a new RemoteEvent, Tool, or GUI element, prefer adding it via `.model.json` / `.meta.json` rather than asking the user to create it in Studio — that's what stops state loss when a place file is lost.

**Rojo gotchas:**
- `.model.json` creates GUI elements with zero Size and default position — they're invisible until sized. For MainUI children, set Size/Position/AnchorPoint + styling in the `.model.json` itself (see existing files for the property-array format). Studio-side styling does NOT survive a place-file rebuild.
- Part color properties: use `Color` with a Color3 array (`[0.78, 0.12, 0.12]`, 0–1 floats). Avoid `BrickColor` strings in `.model.json` — Rojo rejects them ("Expected BrickColor, got a string").

## Architecture rules (do not break)

- **Config is the only place for tunable numbers.** `ReplicatedStorage/Shared/Config.lua` owns all magic values (speeds, damages, intervals, cooldowns, rewards, upgrade curves, effect asset IDs). Logic scripts read from it — never hardcode.
- **GameManager owns run state.** All damage flows through `GameManager.TakeDamage()`. Victory flows through `GameManager.Win()`. `IsGameOver()` returns true for both loss and win so downstream checks halt cleanly in either case. `GameManager` fires `HealthChanged` / `GameOver` / `GameWon` to clients.
- **CurrencyManager owns per-player economy state** via Player attributes (`Coins`, `CooldownLevel`, `BanCooldown`). Attributes replicate server→client automatically, so clients listen with `GetAttributeChangedSignal(...)` — do NOT wire a RemoteEvent for state the client just needs to render.
- **Effects module owns all visual/audio feedback.** `ReplicatedStorage/Shared/Effects.lua`. One public call per event (currently `Effects.BanEffect(position, reward)`). All effects are short-lived instances parented to `workspace` and self-clean via `Debris:AddItem`. Add new effect types as new functions here; don't scatter `Instance.new("ParticleEmitter")` across systems.
- **One system per script, kept in its folder** (`Systems/`, `Enemies/`, `Rounds/`). Don't merge systems or add monoliths.
- **Server-authoritative for destructive actions.** Ban Hammer LocalScript picks a target and fires `BanEnemy:FireServer(enemyPart)`. Server validates (part has `IsEnemy == true`, is a descendant of workspace, player is within `BAN_RANGE * 1.5`, server-side cooldown from `player:GetAttribute("BanCooldown")`) before destroying and rewarding. Keep this pattern for new tools — never let the client delete or damage enemies directly.
- **Enemies are identified by the `IsEnemy` attribute, not by Name.** Each enemy also carries a `Reward` attribute so coin award is data-driven. If you add a new enemy type, set both attributes when spawning — every matcher in the codebase keys off them.
- **Temporary enemy state lives on attributes.** The Mute Gun sets `MutedUntil` (number) and `OriginalColor` (Color3) on the target. `EnemySpawner`'s heartbeat reads `MutedUntil` each frame, applies `MUTE_SLOW_FACTOR` while active, and restores the color + clears the attributes when it expires. Future status effects (Timeout, Stun, DoT) should follow the same "attribute-as-timer" pattern — one writer, one reader.

## Design constraints for new work

`docs/plan.md` §1 sets the product bar: simple, fast, funny, highly replayable, never overengineered, ship > perfect. When generating systems, prefer the smallest working version — the plan explicitly calls out testing every 5–10 minutes and avoiding premature abstraction.

Phase 1 (core loop) closed at Day 5. Phase 2 (Days 6–12, "game feel") is in progress — this is polish work, not new systems. When the user asks for a "feature" during Phase 2, default to the smallest feel-improving change (effect, tween, sound) before reaching for new mechanics.
