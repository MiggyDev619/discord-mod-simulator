# Server Mod Simulator — v2 Plan

> Successor to the closed 30-day v1 plan (`docs/plan.md`). v1 launched 2026-05-03 at https://www.roblox.com/share?code=6b575d753764f741a2a25711acdc3a7b. This doc plans the **rolling-cadence v2 upgrade** built on top of the live game — same place, schema-migrated saves, no breaking changes for existing players.

## 1. Vision

Server Mod Simulator v1 has a working core loop (5 waves, 4 tools, single straight lane, monetization, multiplayer, touch). Players engage but the loop runs out — **v2's job is depth and replayability** so players come back for hour-long sessions over weeks, not a single 10-minute play.

Three dimensions of depth, in priority order:

1. **Map / level design** — current single-lane reads as a "first prototype." v2 adds visual richness, more decorative variety, eventually a **maze mode** as a second game mode (Pac-Man-style: enemies converge on a center base from 4 spawn points).
2. **Player cosmetics** — skins, trails, pets. Most free (earned through level / achievement gates), a small **Donator** tier (R$ gamepass) that's cosmetic + minor stat boost, no pay-to-win.
3. **More levels / rounds** — current 5-wave cap leaves the game feeling short. Expand to 10 waves with new enemy types and modifiers; add post-victory endless mode for long sessions.

## 2. What's IN scope vs OUT

**IN scope for v2:**
- Same place update (existing players keep all v1 progression via DataStore migration).
- Maze Mode added as second game mode (lobby with mode picker — Lane vs Maze).
- Touch damage as **opt-in Hard Mode** difficulty toggle.
- Rolling weekly cadence — 1-2 features shipped per week, no big batch runs.
- Mostly-free cosmetic economy with a single Donator gamepass tier for a small paid layer.
- Public leaderboard via `OrderedDataStore`.
- Schema migrations forward (v5 → v6 → v7 → ... as features land).

**OUT of scope for v2:**
- Replacing the existing Lane Mode (it stays — Maze is additive).
- Aggressive monetization (no pay-to-win mechanics).
- Real-money mobile App Store flow (Roblox handles all R$).
- Custom character animations from scratch (we use Roblox's official animation library).
- 3D modeling work (we use procedural generation for maps + curated free models for pets/cosmetics).

## 3. Cadence — rolling weekly

Different from the v1 30-day batch model. v2 ships **1-2 features per week**, watched against real player metrics, iterated based on what players actually engage with. No multi-day autonomous batches — each weekly sprint is small enough to design + ship + observe in one cycle.

**Target rhythm:**
- Monday: pick this week's 1-2 features from the roadmap below
- Tue-Thu: design + implement + commit per feature
- Fri: publish to Roblox + monitor first-weekend metrics
- Following Mon: review what landed, adjust priorities for next week

Soak window: don't ship breaking changes Friday night before metrics surface (avoid weekend bug-firefighting).

## 4. Decisions locked in (Q&A 2026-05-03)

| Decision | Choice |
|---|---|
| Same place or new place? | **Same place** — keeps players + progression. Schema v6 migration. |
| Maze: replace lane or add as 2nd mode? | **Mode picker** — lobby UI lets players choose Lane Mode or Maze Mode. v1 lane stays intact. |
| Touch damage: yes / no / opt-in? | **Opt-in** — "Hard Mode" toggle in mode picker. Default off. |
| Cadence | **Rolling weekly** — small ships, fast feedback, no batch runs. |
| Top 3 priorities | **Map/level design, player cosmetics, more levels/rounds** |
| Cosmetic gating | **Mostly free** (level-gated, achievement-gated). Small **Donator** R$ tier for cosmetic-only perks + minor stat bonus. |

## 5. Weekly sprint roadmap

Sprints sized for 1 calendar week (5-8 hours of focused dev). Order is opinionated based on the Q5 priorities (map → cosmetics → rounds first). After ~6 weeks, larger features (maze, hard mode) fit in.

### Week 1 — More rounds + Lane Mode polish
- **`Config.WAVES_TO_WIN` 5 → 10** (with rebalanced enemy counts + speed scaling so 10 waves doesn't take 30+ min).
- New wave-9 / wave-10 boss-flavor enemy types (e.g., "Server Crasher" with high HP + chance to spawn additional enemies on damage).
- 2 new wave modifiers (`Coin Frenzy` 2× coins this wave, `Silent Wave` enemies don't speak on spawn).
- Map polish v3: extend `MapPolish.lua` with mid-lane decorative arches, more particle systems, lane-side themed signage ("RULES", "BANS PER MIN", etc).
- Schema v5 → v6 (no new persisted fields yet — placeholder migration).

### Week 2 — Cosmetic system foundation
- **Schema v6 → v7:** add `EquippedSkin`, `EquippedTrail`, `EquippedPet` (string IDs) + `OwnedCosmetics` (table of unlocked IDs).
- New `Config.COSMETICS` table: 4-5 free trails (one per color from Theme), 3 free pet variants (small block pets that follow the player), 2-3 player skin variants (shirt/pants color overrides).
- New `Cosmetics` button in HUD next to Upgrades/Shop. Opens panel with 3 tabs (Trails / Pets / Skins). Owned items show "Equipped" / "Equip"; locked items show level / achievement requirement.
- Server-side `CosmeticManager.lua` applies equipped trail + pet + skin on `CharacterAdded`.

### Week 3 — Movement perks + 1 new weapon
- **Sprint perk:** Shift to sprint (PC) / on-screen sprint button (touch). Configurable speed multiplier.
- **Double jump:** 1 extra mid-air jump. Free perk after Lv 5.
- **Trail when running:** automatic Roblox `Trail` instance on character feet, color from equipped trail cosmetic. Active only while moving.
- **1 new weapon — "Word Filter":** mid-range AOE that silences enemy chat bubbles for the wave + reduces their move speed 20%. Non-destructive utility, fits between Mute Gun (precision destroy) and Kick Boot (AOE knockback).

### Week 4 — Public leaderboard + Donator gamepass
- **`OrderedDataStore`-backed top-N leaderboard:** Top 10 by Coins, Top 10 by Level. Auto-updates on every coin/level mutation. New `LeaderboardPanel` UI accessible from a button.
- **Donator gamepass (99 R$):** "Donator" exclusive cosmetic trail color (rainbow gradient), donator chat badge, +5% coin bonus. Cosmetic + minor stat — no gameplay advantage.
- Optional **Donator+ gamepass (299 R$):** all of above + exclusive pet (golden version) + exclusive skin + +10% coin bonus.

### Week 5 — Mode picker lobby + lobby UI
- Currently game starts immediately on character spawn. Replace with **lobby phase**: new UI panel that asks player "Lane Mode" or "Maze Mode" or "Hard Mode toggle". Player selects, taps Ready, game starts.
- For multiplayer: all players in the server vote on mode, majority wins (or first player picks).
- Refactor `RoundManager.startRun()` to take a mode parameter.

### Week 6 — Maze Mode foundation
- **`MazeGenerator.lua`** — procedural maze script (similar pattern to `MapPolish.lua`), generates a NxN grid of corridors + dead-ends with 4 spawn points (one per wall midpoint) converging on a center base. Idempotent, command-bar runnable for design iteration.
- **`PathfindingService` integration** in EnemySpawner — when in Maze Mode, enemies use `PathfindingService:CreatePath()` to navigate around walls toward the center base. New `EnemyPathState` tracks each enemy's current path waypoints.
- Multi-spawner: 2 active spawn points at wave 1, scaling to 4 by wave 5.
- Center "Server Base" (renamed from ServerZone for maze context) — same damage logic, new visual.

### Week 7 — Maze Mode polish + Hard Mode
- Maze Mode-specific enemy types (faster, smaller — "data leaks" that squeeze through corridors).
- Maze visual theme (different from lane mode — neon corridor walls, glowing floor markers).
- **Hard Mode opt-in toggle** in lobby:
  - Add `Config.HARD_MODE_TOUCH_DAMAGE = 5` (HP per touch tick).
  - Player gets `Health` attribute (currently only server has health). Character takes damage on enemy contact (with cooldown to prevent shred-on-touch).
  - Character respawn loop on death (server health continues; player respawns at lobby).
  - 2× coins from kills in Hard Mode (compensation).

### Week 8 — Achievements + daily challenges
- **`Achievements.lua`** — config-driven achievement list ("Ban 100 trolls", "Reach Level 10", "Survive Maze Mode", etc.). Each grants a cosmetic on completion.
- **Daily challenge** — random objective from a pool, refreshes daily, grants extra coins. New `DailyChallenge.lua` server module + UI panel.
- Schema bump as needed.

### Beyond Week 8 (rolling backlog)
- Tier-2 weapons (Bronze → Silver → Gold ban hammer with visual upgrades + stat boosts).
- Trail variants (4 more colors + animated patterns).
- Pet variants (10+ pet models from Roblox official library + procedural).
- Seasonal events (Halloween moderator skin, Winter ice-themed maze).
- Co-op revival mechanic (one player downs, ally can revive).
- Custom character animations.
- Mobile-optimized HUD adjustments based on real player feedback.

## 6. Persistence migration plan

Continuing the v1 schema-versioning pattern. Each weekly sprint that adds persisted state bumps the schema version + ships a forward-only migration in `PersistenceManager.migrate()`.

| Schema | Adds | When |
|---|---|---|
| v6 | placeholder bump (no new fields) | Week 1 |
| v7 | `EquippedSkin`, `EquippedTrail`, `EquippedPet`, `OwnedCosmetics` | Week 2 |
| v8 | `MovementPerksOwned`, `WordFilterUnlocked` | Week 3 |
| v9 | `DonatorTier` (string), `LeaderboardOptOut` (bool) | Week 4 |
| v10 | `PreferredMode` (string — "Lane"/"Maze"), `HardModeUnlocked` (bool) | Week 5 |
| v11 | `MazeStats` (waves cleared, best time) | Week 6 |
| v12+ | per-feature additions | Week 7+ |

**Rule:** every migration grandfathers existing players to a sensible default. Never wipe a player's data.

## 7. Asset strategy

User flagged level design + animations as their weak spots. Strategy per asset type:

| Asset type | Strategy |
|---|---|
| Map geometry / decoration | **Procedural via `MapPolish.lua` pattern.** Already proven for v1 — extend with more decorative variety. Idempotent + version-controlled. Maze = `MazeGenerator.lua`. |
| Animations (player walk/run/sprint/attack) | **Roblox official animation library.** Search Toolbox → filter "by Roblox" — verified safe. Free. |
| Pet models | **Roblox official model library** (filter "by Roblox") + small primitive builds (cube/ball pets). Avoid random Toolbox uploads (malicious script risk). |
| Player skins | **Procedural color overrides** on default character (Shirt + Pants color via `SetAttribute`). Optional: upload custom shirts/pants via Roblox Avatar Editor when we have a specific design. |
| Sound effects | **Roblox sound library** filter "by Roblox" + reuse v1's existing sound asset IDs in `Config.lua`. |
| Trail textures | **Procedural** — Roblox `Trail` Instance with `Color` and `Texture` properties. ColorSequence for gradients. No external assets needed. |

**Hard rule:** every Roblox Toolbox import gets every Script + ModuleScript inspected before parenting. Common red flags: `require()` with a numeric asset ID, anything calling `HttpService:GetAsync`, anything with names like "Antivirus" / "Anti-Lag" / "Boost." When in doubt, build from primitives.

## 8. Donator monetization concept

Single-tier paid layer designed to NOT be pay-to-win. All gameplay-essential content stays free (earned via level / achievement / coin grinds).

**Donator tier (99 R$):**
- Exclusive trail color: animated rainbow gradient (visually distinct, not better)
- Donator chat badge (yellow [DONATOR] tag in chat)
- +5% coin bonus (small, doesn't break the economy)
- Donator-only emote (cosmetic taunt — no gameplay effect)

**Donator+ tier (299 R$, optional addon):**
- All Donator tier perks
- Exclusive Wumpus pet (mini Wumpus follows player)
- Exclusive moderator skin (gold accent on hood)
- +10% coin bonus (cumulative)
- Two custom emotes

Both are pure cosmetic + minor coin acceleration. No exclusive weapons, no exclusive maps, no exclusive game modes. Free players can complete everything in the game without paying.

## 9. Risks + open questions

**Architectural risks:**
- **PathfindingService performance** in Maze Mode with 10+ active enemies recomputing paths every few seconds. Mitigation: cache paths, recompute only every N seconds per enemy, set `MaxIterations` low.
- **Multiplayer mode picker** — what happens if Player 1 picks Lane Mode, Player 2 joins mid-game and wants Maze? Likely answer: mode is locked once round starts; new joiners spectate or join the next round.
- **Hard Mode + multiplayer** — does one player toggling Hard Mode affect everyone? Likely answer: server-wide toggle decided in lobby, can't change mid-run.

**Design risks:**
- **Cosmetic depth vs progression depth** — too many cosmetics with no game-mechanic depth = vanity treadmill that bores players. Balance by tying each cosmetic unlock to a meaningful achievement (not just XP grind).
- **Donator tier perception** — some players may resent any paid advantage even at +5% coins. Watch reviews carefully; consider dropping the coin boost if it generates negative sentiment.
- **Maze Mode fragmenting playerbase** — if half the players play Lane, half play Maze, we have to balance + content-update both. Early data should tell us if one mode dominates and we should focus there.

**Open questions to resolve before each relevant sprint starts:**
- Week 2: visual style for the 4-5 free trail variants — neon colors? Pastels? Brand-only (yellow/blurple/red/green)?
- Week 3: should sprint cost stamina (regenerates) or be free-unlimited?
- Week 4: should leaderboard sort by coins, level, or both? Reset weekly?
- Week 6: maze size — 10×10? 15×15? 20×20? Affects difficulty + pathfinding cost.
- Week 7: Hard Mode reward — 2× coins? Exclusive cosmetic? XP multiplier?
- Beyond: tier-2 weapons — same tools with stats, or new weapon classes entirely?

## 10. Success metrics for v2

How we know v2 is working (not just shipped):

- **Engagement:** average session length grows from v1 baseline.
- **Retention:** Day 7 return rate (% of players who return within a week).
- **Cosmetic adoption:** % of active players who have equipped at least one cosmetic.
- **Maze Mode adoption:** % of plays that pick Maze vs Lane (target: 30%+ Maze adoption signals it's worth continued investment).
- **Donator conversion:** % of returning players who buy Donator (target: 1-3% — typical for Roblox cosmetic gamepasses).
- **No drop in v1 metrics:** existing players' coin/level economy isn't disrupted by v2 additions.

Track via Roblox built-in analytics + custom DataStore queries.

## 11. References

- Original 30-day plan: `docs/plan.md` (now closed at Phase 6).
- Manual operations runbook: `docs/USER-ACTIONS.md`.
- Map polish script (extends in v2): `src/ServerScriptService/MapPolish.lua`.
- Persistence migration site: `src/ServerScriptService/Systems/PersistenceManager.server.lua` — `migrate()` function.
- Cosmetic / gamepass / dev product Config patterns established in v1: `src/ReplicatedStorage/Shared/Config.lua`.
- Live game: https://www.roblox.com/share?code=6b575d753764f741a2a25711acdc3a7b

---

**Next action:** when ready to start Week 1, say "start v2 week 1" and I'll write the design Q&A doc for that sprint (smaller-scope version of the Phase 4-5 questionnaires), then implement after sign-off.
