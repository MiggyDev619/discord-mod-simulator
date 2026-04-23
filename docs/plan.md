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

**Day:** 5
**Phase:** 1 — Core Game Loop

**Done (Days 1–4)**
- Project structure + Rojo setup (Workspace kept out of Rojo tree — see `state.md`)
- Map: `EnemyStart`, `ServerZone` (manual in Studio)
- Core scripts: `Config`, `GameManager`, `EnemySpawner`, `RoundManager`, `ClientMain`, `BanHammerScript`, `CurrencyManager`
- Server health system + game over (`SERVER DEAD`)
- Two enemy types: `Troll` (slow/tank) and `Spammer` (fast/weak)
- Wave system with difficulty scaling (+3 enemies, ×1.15 speed per wave)
- Ban Hammer tool with server-side validation, works on all `IsEnemy` parts
- Currency awarded on ban, player attributes replicate coin/upgrade state
- First upgrade: Faster Ban Hammer (3 levels, 50/100/150 coins, −0.1s cooldown each)
- UI: health label (top-center), coin counter (top-left), upgrade button (top-right)

**Next up (Day 5)**
- Visible wave counter + between-wave countdown (`Wave X / Y`, `Wave 3 in 5s`)
- Win condition — survive `WAVES_TO_WIN` waves and the game declares victory
- `GameWon` broadcast + VICTORY end state (parallel to existing SERVER DEAD path)

**Milestone target:** closing Phase 1 — the "wave survived → next wave → finish line" loop.

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
| 23–24 | Better map, lighting, UI cleanup |
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
- [ ] Enemy spawning
- [ ] Enemy movement
- [ ] Server health
- [ ] Game over

**Gameplay**
- [ ] Multiple enemy types
- [ ] Weapons/tools (Ban Hammer, Mute Gun, Timeout, Kick)
- [ ] Round system
- [ ] Difficulty scaling

**Progression**
- [ ] Currency
- [ ] Shop
- [ ] Upgrades
- [ ] XP / levels

**UI**
- [ ] Health display
- [ ] Round UI
- [ ] Currency UI
- [ ] Game over screen

**Polish**
- [ ] Hit effects
- [ ] Sounds
- [ ] Visual improvements

**Monetization**
- [ ] Gamepasses
- [ ] Dev products

**Launch**
- [ ] Icon
- [ ] Thumbnail
- [ ] Description
- [ ] First players

---

## 9. Reality Check

- Days 1–5 are the hardest. You're in it now.
- Days 6–12 are where it gets fun.
- Days 13–20 are where it gets addictive.
- Day 20+ is where it can actually earn.

**Most devs quit before Day 5. Reach Day 12 and you're ahead of 90% of them.**

The win isn't better tools. The win is:
> Better prompts + faster testing than everyone else.