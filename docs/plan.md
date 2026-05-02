# Discord Mod Simulator — Project Bible

> One document. Everything you need. Update it daily.

---

## 1. The Vision

**Game:** Discord Mod Simulator
**Genre:** Wave-based survival · Multiplayer · Casual / funny / chaotic

**Core Loop:**
1. Enemies (trolls, spam) spawn
2. They move toward the "server"
3. You use moderation tools (ban, mute, kick) to stop them
4. Server health drops if they get through
5. Survive waves → earn currency → upgrade → repeat

**Design rules (do not break these):**
- Simple, fast, funny
- Highly replayable
- Meme / stream potential
- Never overengineered
- Ship > perfect

---

## 2. Where You Are Right Now

**Day:** 18 (Phase 3 closed)
**Phase:** 3 — Retention · CLOSED
**Next phase:** 4 — Monetization (Days 19–22)

> See `DEVLOG-NOTES.md` for per-session details. This is the at-a-glance state.

**Done — Phase 1 (Days 1–5): Core Loop**
- Core scripts: `Config`, `GameManager`, `EnemySpawner`, `RoundManager`, `ClientMain`, `BanHammerScript`, `CurrencyManager`
- Map (Studio-only, not in Rojo tree — see `state.md`): `EnemyStart`, `ServerZone`
- Server health, game over (`SERVER DEAD`), win condition (`WAVES_TO_WIN = 5`, `VICTORY`), `IsGameOver()` covers both
- Wave system + scaling (+3 enemies, ×1.15 speed per wave, 8s break, `Config.PRE_WAVE_DELAY = 2` for wave-1 race)
- Two enemy types (Troll, Spammer), `IsEnemy` + `Reward` attribute pattern
- Ban Hammer with server-side validation
- Currency via Player attributes, first upgrade: Faster Ban Hammer (L1–3)
- UI scaffolding (health label, coin counter, wave label, upgrade button)

**Done — Phase 2 (Days 6–12): Game Feel**
- **Day 6:** `Effects.lua` module — ban particles, `+N` coin popup, ban sound, `Debris:AddItem` cleanup
- **Day 7:** `HitFlash`, `Humanoid.CameraOffset` camera shake, swing animation, visible 3D hammer (Handle + Head + weld)
- **Day 8:** full moderation toolkit — Mute Gun (slow), Timeout Card (freeze), Kick Boot (AOE forward-cone knockback). Status priority ladder `Kick > Timeout > Mute > seek` in `EnemySpawner` heartbeat. Hotbar PNG icons (`Tool.TextureId`, Studio-only)
- **Day 9:** Teleporter enemy (warps every 2s; Mute slips through, Timeout blocks); Kick aim fix (client-camera vector with server validation — documented exception to server-authoritative)
- **Day 10:** Splitter enemy + distinct `SplitterChild` type (no recursion by construction); `Effects.SplitEffect`
- **Day 11:** UI polish v1 — health bar (Frame with `Fill`/`Label`, color thresholds 60/30%), live wave count + "N left" via single `EnemyCountChanged` event, cooldown panel reading `<Tool>ReadyAt` attributes per-frame
- **Day 12 close (Apr 25 → May 1):** `FlashOverlay` full-screen red/green flash on `gameOver`/`gameWon`; brand rebrand (`Theme.lua`, yellow/black HUD + Watermark); recording-session polish — `Effects` shockwave + `PointLight` on Ban/Kick/Mute/Timeout, `BanHammer` shake bumped to 0.30s / 0.75 magnitude, `HitFlash` cut 0.15s → 0.08s

**Done — Phase 3 (Days 13–18): Retention**
- **Day 13:** `PersistenceManager` (DataStore) — coins + cooldown level. Schema-versioned (`v1`), Studio mock fallback for unpublished places. Place published mid-session.
- **Day 14:** Upgrade tree expansion — `Config.COOLDOWN_UPGRADES` table drives 4 cooldown upgrades + UI. New `UpgradePanel` modal toggled by existing UpgradeButton. Schema v2 (per-tool levels). Tool client scripts standardized on `<Tool>Cooldown` attribute reads.
- **Day 14.5 (combat depth detour):** Mute Gun reworked from slow → hitscan freeze gun (mouse raycast, gun-shaped model with Barrel/Sight, two-hit destroy with combo bonus). New `MuteFrozenUntil` attribute joins `FrozenUntil` in the heartbeat. `EnemySpawner.DestroyEnemy` BindableFunction is the shared destroy path (Splitter children + reward + effects in one place). `COMBO_MULTIPLIER = 2` doubles coin reward when destroying frozen enemies (via `CurrencyManager.RewardForKill`). Kick now awards `COIN_KICK_PER_HIT = 5` per cone-hit. Tool unlock system: Mute/Timeout/Kick moved to `ReplicatedStorage/Tools`, granted by new `ToolGranter` based on `<Tool>Unlocked` attributes. Schema v3 (unlocks, with v2→v3 grandfathering).
- **Day 15:** Random wave modifiers — `Config.WAVE_MODIFIERS` table (Spam Storm, Toxic Wave, Splitter Surge), 30% chance from wave 3+. `WaveStarted` extended with optional modifier label.
- **Day 16–17:** XP + player levels — `CurrencyManager.AddXp` from `RewardForKill` (XP = base reward, NOT combo'd), per-level requirement `level * 100`, cap 25. Schema v4. CurrencyLabel renders `Lv N · Coins: M`.
- **Day 18:** Restart flow — `GameManager.Reset`, `EnemySpawner.ClearAll`, RoundManager re-runnable via `startRun()`, new `RetryRun` RemoteEvent, `GameOverPanel` modal with stats (waves survived, run coins, level) + Retry button. `RunCoinsEarned` per-run tracker (NOT persisted).

**Next up — Phase 4 (Days 19–22): Monetization**
- **Day 19:** Gamepasses (Double Coins, Faster Cooldown, etc.). Real-money decisions — design pricing before coding.
- **Day 20:** Dev Products (Instant Revive, Coin Boosts).
- **Day 21–22:** Balance pass (catch any economy exploits, tune costs against actual play data).

**Milestone target:** game can earn money. Publishing workflow already proven (Day 13).

---

## 3. Project Architecture

Keep this structure. It stops Claude from generating messy code.

```
Workspace/
├── Map/
│   ├── EnemyStart
│   └── ServerZone

ReplicatedStorage/
└── Shared/
    └── Config

ServerScriptService/
├── GameManager
├── EnemySpawner
└── RoundManager

StarterPack/
└── BanHammer
```

**Rules:**
- Server logic → `ServerScriptService`
- Shared config → `ReplicatedStorage`
- Modular scripts only — no monoliths
- One system per script

---

## 4. Tool Stack

### Use daily (install now)
| Tool | Role |
|---|---|
| Roblox Studio | Runtime, editor, testing |
| Roblox Assistant | In-editor AI with game context |
| Claude (Pro) | Main brain — generates systems in one shot |
| ChatGPT (Pro) | Second brain — debugging, sanity checks |
| Git + GitHub | Version control, checkpoints |

### Add around Day 5–7
| Tool | Role |
|---|---|
| VS Code | Main code editor |
| Luau Language Server | Lua autocomplete/errors |
| Rojo | Syncs VS Code ↔ Roblox Studio |

### Add later (when codebase grows)
| Tool | Role |
|---|---|
| Selene | Linting |
| Wally | Package manager |
| TestEZ | Unit tests |

---

## 5. The Vibe-Coding Loop

This is the whole workflow. Repeat all day.

```
1. DEFINE       → Tell Claude exactly what feature you want
2. GENERATE     → Claude gives you the full script + where it goes
3. PASTE        → Drop it into Roblox Studio
4. TEST         → Hit Play. Watch it break.
5. FIX FAST     → Roblox Assistant for in-context fixes
                → ChatGPT for stubborn errors
6. ITERATE      → Tweak values, improve feel, go again
```

**Golden rules:**
1. Never code from scratch unless it's tiny
2. Always specify "Roblox Lua" in prompts
3. Keep systems small — one feature per prompt
4. Test every 5–10 minutes, not every 500 lines
5. Studio is for *feel*, AI is for *code*

---

## 6. The Master Prompt

Paste this at the start of every new Claude chat, then fill in section 2 ("Where You Are Right Now") below it.

```
You are my senior game developer helping me build a Roblox game
called "Discord Mod Simulator".

Context:
- Wave-based survival game
- Players defend a server from enemies
- Enemies represent trolls/spam
- Player uses moderation tools (ban, mute, kick)

Your role:
- Help design systems
- Generate Roblox Lua scripts
- Keep architecture clean and modular
- Avoid overengineering
- Prioritize fast iteration and testing

Constraints:
- Code must be Roblox Lua
- Use proper Roblox services (Workspace, ServerScriptService, ReplicatedStorage)
- Keep systems simple and extendable
- Always explain where scripts should go

Current progress:
[PASTE SECTION 2 HERE]

Task:
Help me implement the next step with clean, modular code.
```

---

## 7. The 30-Day Roadmap

### Phase 1 — Core Loop (Days 1–5)
Goal: **Game works, even if ugly.**

| Day | Focus | Milestone |
|---|---|---|
| 1 ✅ | Setup, map, first test | Project runs |
| 2 🟡 | Enemy spawn/movement, server health, ban hammer | Playable loop exists |
| 3 | 2 enemy types, scaling, health UI | You can *lose* |
| 4 | Currency, shop, first upgrade | Reason to keep playing |
| 5 | Round system, break between rounds, win condition | "Wave survived" loop |

### Phase 2 — Game Feel (Days 6–12)
Goal: **Make it fun, not just functional.**

| Day | Focus |
|---|---|
| 6–7 | Hit effects, enemy feedback, simple animations |
| 8 | Mute Gun (slow), Timeout (freeze), Kick (pushback) |
| 9–10 | Path variation, annoying enemies (teleporters, splitters) |
| 11–12 | Health bar, enemy count, round number, currency UI |

**Milestone:** Looks like a real game.

### Phase 3 — Retention (Days 13–18)
Goal: **Make players stay.**

| Day | Focus |
|---|---|
| 13–14 | Upgrade tree, persistent upgrades, tool upgrades |
| 15 | Random waves + modifiers ("Spam Storm", "Toxic Wave") |
| 16–17 | XP, player levels, unlock new tools |
| 18 | Restart flow, retry button, game over screen |

**Milestone:** Addictive enough to replay.

### Phase 4 — Monetization (Days 19–22)
Goal: **Capable of earning.**

| Day | Focus |
|---|---|
| 19 | Gamepasses (Double Coins, Faster Cooldown) |
| 20 | Dev Products (Instant Revive, Boosts) |
| 21–22 | Balance economy, fix exploits |

**Milestone:** Game can make money.

### Phase 5 — Polish + Viral (Days 23–27)
Goal: **Make it shareable.**

| Day | Focus |
|---|---|
| 23–24 | Better map, lighting, UI cleanup, **touch controls + tablet/phone playtest pass** |
| 25 | Meme enemies, chat bubbles, "You got banned lol", SFX |
| 26–27 | Multiplayer polish, shared server health, coop feel |

**Milestone:** Fun with friends. Clippable.

### Phase 6 — Launch (Days 28–30)
Goal: **Ship it.**

| Day | Focus |
|---|---|
| 28 | Icon, thumbnail, description, tags |
| 29 | Soft launch to friends, bug fixes |
| 30 | Public release + post to TikTok / Discord / Reddit |

**Milestone:** Shipped.

---

## 8. Master Checklist

**Core Systems**
- [x] Project setup
- [x] Map
- [x] Enemy spawning
- [x] Enemy movement
- [x] Server health
- [x] Game over (loss + win both flow through `IsGameOver()`)

**Gameplay**
- [x] Multiple enemy types (Troll, Spammer, Teleporter, Splitter + SplitterChild)
- [x] Weapons/tools (Ban Hammer, Mute Gun, Timeout Card, Kick Boot)
- [x] Round system
- [x] Difficulty scaling

**Progression**
- [x] Currency (coins via Player attributes, data-driven `Reward` per enemy; `RunCoinsEarned` per-run tracker for game-over screen)
- [x] Shop (Upgrades panel — 4 cooldown upgrades + 3 tool unlocks via `Config.COOLDOWN_UPGRADES` + `Config.TOOL_UNLOCKS`)
- [x] Upgrades (per-tool cooldown reductions Lv 1–3; persisted via DataStore schema v4)
- [x] XP / levels (per-level `level * 100` XP from `RewardForKill`, cap 25; `Lv N · Coins: M` in HUD)
- [x] Persistence (DataStore — coins, XP, level, all cooldown levels, all tool unlocks; schema migrations v1→v2→v3→v4)

**UI**
- [x] Health display (Frame + `Fill`/`Label` bar, 60/30% color thresholds)
- [x] Round UI (`WaveLabel` — "Wave X / Y", "in Ns", VICTORY, Run ended; modifier label inline for chaos waves)
- [x] Currency UI (top-left `Lv N · Coins: M` + `+N` popups via `Effects.BanEffect`)
- [x] Game over screen (`GameOverPanel` — headline + waves survived + run coins + level + Retry button)

**Polish**
- [x] Hit effects (`HitFlash`, `BanEffect`/`MuteEffect`/`TimeoutEffect`/`KickEffect`/`SplitEffect`/`TeleportEffect`, shockwaves + lights)
- [x] Sounds (ban, mute, timeout, kick, split, teleport — all Config-driven asset IDs)
- [x] Visual improvements (camera shake, swing anim, visible 3D hammer, hotbar icons, `FlashOverlay`, brand rebrand)

**Monetization** — Phase 4 (Days 19–22)
- [ ] Gamepasses
- [ ] Dev products

**Launch** — Phase 6 (Days 28–30)
- [ ] Icon
- [ ] Thumbnail
- [ ] Description
- [ ] First players

---

## 9. Deferred polish / backlog

Known improvements we've explicitly chosen not to build yet. Revisit in Phase 2 polish or Phase 5 if they're still relevant.

- **Mute Gun → real aim-and-shoot targeting.** Currently picks the closest `IsEnemy` part in a 20-stud sphere, same pattern as the Ban Hammer. Feels like a long-range Ban Hammer, not a gun. Three upgrade paths, in order of effort: (1) mouse-raycast — `Mouse.Hit` + closest enemy to the ray, ≈15 lines, enables range bump to 40–60 studs; (2) forward cone — reject enemies not in front of `HumanoidRootPart.CFrame.LookVector` via dot product, ≈5 lines; (3) visible projectile with travel time. Option 1 is the right default when we pick this up.
- **Map polish.** Default Roblox `SpawnLocation` sits mid-lane and enemies sometimes collide with it. Scheduled Phase 5 (Days 23–24). Can do a 30-sec spawn reposition earlier if it becomes annoying.
- **Touch controls (tablet + phone).** At publish (Day 13), Devices is set to **Computer only**. Tools rely on mouse click for targeting and `Camera.CFrame.LookVector` for Kick aim — touch needs tap-to-target for Ban / Mute / Timeout and a touch-drag camera or virtual joystick for Kick aim. HUD + cooldown panel also need responsive sizing for narrow phone screens. **Until this is built and tested, leave Devices = Computer only — shipping touch against PC-built code surfaces as 1-star reviews from kids who can't aim.** Scoped to Phase 5 Days 23–24 alongside UI cleanup. Verification flow: build → Studio device emulator (Test → Device) for tablet + phone aspect ratios → real-device playtest before checking Tablet/Phone in Game Settings → Devices.

---

## 10. Reality Check

- Days 1–5 are the hardest. You're in it now.
- Days 6–12 are where it gets fun.
- Days 13–20 are where it gets addictive.
- Day 20+ is where it can actually earn.

**Most devs quit before Day 5. Reach Day 12 and you're ahead of 90% of them.**

The win isn't better tools. The win is:
> Better prompts + faster testing than everyone else.