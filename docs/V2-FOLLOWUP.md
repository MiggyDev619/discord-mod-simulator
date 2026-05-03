# V2-FOLLOWUP.md — Manual Steps After v2 Autonomous Batch

The 8-week v2 plan was just executed in a single push (~10 commits, code + schema migrations + new modules + UI). All Lua / Rojo work is done and pushed to `origin/main`. This doc covers everything you need to do **outside the codebase** to actually see the v2 changes live.

> Companion to the v1 runbook (`docs/USER-ACTIONS.md`) and the v2 plan (`docs/V2-PLAN.md`). Read those for context.

## Status snapshot (v2 batch end)

| Item | Status |
|---|---|
| Week 1: 10 waves + ServerCrasher + new modifiers + map polish v3 | ✓ shipped |
| Week 2: cosmetic system (trails / pets / skins) + schema v7 | ✓ shipped |
| Week 3: sprint + double jump movement perks | ✓ shipped |
| Week 4: leaderboard + Donator gamepasses (id placeholders) | ✓ shipped |
| Week 5: lobby with mode picker + Hard Mode toggle | ✓ shipped |
| Week 6: maze generator script + spawn markers | ✓ shipped (geometry only — see ⚠ below) |
| Week 7: Hard Mode (opt-in player damage) | ✓ shipped |
| Week 8: achievements (9 starter achievements) + schema v8 | ✓ shipped |
| Run map polish v3 in Studio | ⏳ you do |
| Run maze generator in Studio | ⏳ you do |
| Create 2 Donator gamepasses on Creator Hub + paste IDs | ⏳ you do |
| Test each system in Studio Local Server | ⏳ you do |
| Publish update to Roblox | ⏳ you do |

⚠ **Maze Mode caveat:** the maze GEOMETRY generator ships in this batch, but the enemy AI for navigating the maze (PathfindingService waypoint navigation) does NOT. Picking "Maze Mode" in the lobby currently loads Lane Mode behavior on the maze geometry. The proper Maze Mode AI is scoped as a focused future sprint (needs real Studio testing on the generated geometry).

⚠ **Daily challenges deferred:** date/UTC-midnight reset logic + per-day DataStore round-trip is its own sprint. Achievements ship in this batch; daily challenges land in a focused future sprint.

⚠ **Word Filter weapon deferred:** Originally planned for Week 3, but adding new enemy state attribute + heartbeat changes risked regressing Week 1's ServerCrasher + modifier work in this same batch. Shipping as a focused future commit.

---

## §A — Create the 2 Donator gamepasses (5 min, browser)

**When:** anytime, but before testing Donator perks in Studio.

**Why:** The v2 Week 4 commit added `Donator` (99 R$) and `Donator+` (299 R$) entries to `Config.GAMEPASSES` with `id = 0` placeholders. Real Roblox gamepass IDs need to be created on Creator Hub and pasted into Config.

**Steps (mirror v1 §B pattern):**

1. Browser: [create.roblox.com](https://create.roblox.com) → Creations → **Server Mod Simulator** → Monetization → Passes → Create a Pass.

2. Create both passes:

| Pass | Name | Description | Price |
|---|---|---|---|
| 1 | `Donator` | "Show your support! Exclusive rainbow trail + chat badge + 5% coin bonus on every kill. Cosmetic + minor stat — no pay-to-win." | 99 R$ |
| 2 | `Donator+` | "All Donator perks + exclusive Golden Wumpus pet + Gold Donator skin + 10% coin bonus. Cosmetic + minor stat — no pay-to-win." | 299 R$ |

3. Click into each created pass → copy the ID from the URL or page header (numeric).

4. Open `src/ReplicatedStorage/Shared/Config.lua`, find the `Donator` and `DonatorPlus` entries in `Config.GAMEPASSES`, replace `id = 0` with the real IDs.

5. Commit + push:
   ```bash
   git add src/ReplicatedStorage/Shared/Config.lua
   git commit -m "config: paste Donator + Donator+ gamepass IDs"
   git push origin main
   ```

**Verify:** in Studio command bar after `rojo serve`:
```lua
local M = game:GetService("MarketplaceService")
local Config = require(game.ReplicatedStorage.Shared.Config)
for _, gp in ipairs(Config.GAMEPASSES) do
    if gp.key == "Donator" or gp.key == "DonatorPlus" then
        print(gp.label, "→", M:GetProductInfo(gp.id, Enum.InfoType.GamePass).Name)
    end
end
```
Should print both with matching names. If "Asset not found," the ID is wrong.

---

## §B — Run map polish v3 in Studio (30 sec, Studio command bar)

**When:** before publishing the v2 update.

**Why:** Week 1 extended `MapPolish.lua` with mid-lane decorative arches + lane-side themed signs ("RULES", "BANS/MIN: 99", etc). The script is on disk; you have to run it once in Studio to materialize the new parts.

**Steps:**

1. Open the place in Studio (`rojo serve` connected, or fresh `rojo build` and reopen).
2. View → Command Bar.
3. Paste:
   ```lua
   require(game.ServerScriptService.MapPolish).Apply()
   ```
4. Output should print: `[MapPolish] Applied — polish parts + decor (...) + recolors around lane (length: NN.N studs)`.
5. **File → Save** to persist the polish parts in the place file.

**Verify:** walk through the lane in Test → Play. Should see 3 arches at 20%/50%/80% along the lane, each with a horizontal beam + 2 pillars + yellow LED top. 5 lane-side signs alternating walls.

---

## §C — Run maze generator in Studio (30 sec, Studio command bar)

**When:** when you want to set up the Maze Mode geometry. Optional until Maze Mode AI ships in a future sprint.

**Why:** Week 6 added `MazeGenerator.lua` — a 10×10 procedural maze script. Generates walls + 4 entrances + center base + 4 spawn markers, anchored 200 studs perpendicular to the existing lane.

**Steps:**

1. Studio command bar:
   ```lua
   require(game.ServerScriptService.MazeGenerator).Apply()
   ```
2. Output: `[MazeGenerator] Generated 10x10 maze at ... — 100 cells, 4 spawn markers, center base.`
3. Walk over to the maze area (200 studs to the side of `EnemyStart`) to inspect.
4. **File → Save**.

**Iterate:** each call regenerates a fresh random maze (different layout each run). To get a layout you like, run a few times until it looks right. The script clears prior `MazeGen_`-prefixed parts before recreating, so re-runs are safe.

**To wipe the maze entirely** (no recreation):
```lua
for _, c in ipairs(workspace.Map:GetChildren()) do
    if c.Name:sub(1, 8) == "MazeGen_" then c:Destroy() end
end
```

---

## §D — Test each v2 system in Studio (Test → Play, ~15 min)

After running §B + §C and (optionally) §A.

**Test 1 — Lobby + mode picker (Week 5).**
- Play → LobbyPanel appears center-screen with title "CHOOSE MODE" + LANE MODE / MAZE MODE buttons + Hard Mode toggle.
- Click LANE MODE → panel hides, 5-second countdown → wave 1 starts as before.
- Output: `[RoundManager] Mode chosen by Miggs_619: Lane (hardMode=false)`.

**Test 2 — 10 waves + ServerCrasher (Week 1).**
- Push to wave 8+ to see ServerCrasher (slow black tank with "CRASHING THIS SERVER" speech).
- Ban one → 50 coins + 2 SplitterChild adds spawn at the kill site.
- Hit wave 10 → VICTORY (was wave 5 in v1 — confirms WAVES_TO_WIN bumped).

**Test 3 — Cosmetics (Week 2).**
- Open Cosmetics button (purple, top-right) → CosmeticsPanel with TRAIL / PET / SKIN headers.
- Default trail (white) + Mod Cube pet should be equipped from the start.
- Click "Equip" on Brand Yellow trail → trail color changes on the character.
- Equip Mod Cube pet → small yellow cube hovers above your character + bobs.
- Skin defaults work; Dark Ops requires Lv 5.

**Test 4 — Movement perks (Week 3).**
- Hold Shift → walk speed jumps from 16 to 24 (1.5×). Release → back to 16.
- Reach Lv 5 (or temporarily set `Config.PERKS.DoubleJump.level = 1` for testing) → double jump works.

**Test 5 — Achievements (Week 8).**
- Ban your first enemy → Output: `[AchievementManager] Miggs_619 unlocked first_ban — First Ban`.
- Reach Lv 5 → Output: `[AchievementManager] ... unlocked level_5`.
- Ban 100 → "Centurion" unlocks and grants `trail_red` cosmetic. Equip via Cosmetics panel.

**Test 6 — Hard Mode (Week 7).**
- Stop play. Re-play.
- In lobby: click "Hard Mode" toggle → button turns red, label says "Hard Mode: ON".
- Click LANE MODE.
- During play: walk INTO an enemy → character takes 8 HP damage. 1.5s i-frames before next damage tick.
- Earn coins → 2× normal (e.g., Troll = 20 coins instead of 10).
- Die → standard Roblox respawn flow handles you.

**Test 7 — Donator gamepasses (Week 4) — only after §A is done.**
- Buy Donator in Studio (simulated R$). Output: `[GamepassManager] ... purchased Donator mid-session`.
- Cosmetics panel: rainbow trail unlocks. Equip it.
- Earn coins → +5% bonus (10-coin Troll → 11 coins after rounding).

**Test 8 — Leaderboard (Week 4).**
- Click "Top Players" button (cyan, top-right).
- Loading... → list of top 10 players by Coins. (May be empty if first-ever play; populate by stopping play to write final stats.)

---

## §E — Publish update to Roblox (~30 sec, Studio)

When all tests pass:

1. **File → Publish to Roblox** in Studio.
2. Wait for "Published successfully."
3. The live game (https://www.roblox.com/share?code=6b575d753764f741a2a25711acdc3a7b) now serves the v2 build.

**If §B + §C ran in your Studio session:** the polish + maze parts are in the place file you're publishing. They'll ship with the update.

**If you opened a fresh `rojo build` and skipped §B+§C:** publish will ship a place WITHOUT the maze + extended map polish. Re-run them in a session before publishing, or accept that the v2 published version has only the v1 map.

---

## §F — Push to origin (whenever)

Code commits from the v2 batch are already pushed (last commit pushed in Week 8). After §A's Donator-id paste commit, also push:

```bash
git push origin main
```

---

## Architectural notes

**Schema migrations across v1 + v2:** v1 → v5. v2 added v6 (Week 1 placeholder) → v7 (cosmetics) → v8 (achievements). Full migration chain in `PersistenceManager.migrate()`. Existing v1 players grandfather forward with sensible defaults.

**`_G.DMSAchievementManager`** — pragmatic global. CurrencyManager + AchievementManager have a circular relationship (CurrencyManager calls achievement triggers; AchievementManager grants cosmetics via CurrencyManager). Putting AchievementManager on `_G` avoids module-level require cycle. Lua's `_G` is fine for this single-author project; if the codebase grows multi-team, refactor to a service-locator module.

**Workspace attributes for cross-system signaling:**
- `CurrentMode` — Lane / Maze
- `CurrentHardMode` — bool
- `CurrentWaveCoinMult` — number (set by CoinFrenzy modifier)
- `CurrentWaveSilenced` — bool (set by SilentWave modifier)

These are read by CurrencyManager / EnemySpawner / HardModeManager without needing a require chain. Pattern works as long as it stays small (~5 attributes); for more, refactor to a GameState ModuleScript.

**Cosmetic system uses CSV strings for OwnedCosmetics + OwnedAchievements:** Roblox attributes don't natively support tables, and JSON encode/decode every save is wasteful. CSV is cheap to grow + check (`string.find` on `,id,`) and human-readable in Studio's attribute editor.

---

## What's intentionally not in v2 batch (future sprints)

- **Maze Mode enemy AI** (PathfindingService waypoint navigation, multi-spawner integration). Geometry script ships now; AI lands in its own focused sprint after you've designed the maze layout you like.
- **Daily challenges** (UTC-midnight refresh + DataStore daily-key + UI panel).
- **Word Filter weapon** (deferred from Week 3 to avoid regression risk in this batch).
- **Wave-cleared achievement triggers** — RoundManager doesn't yet fire per-player wave-clear callbacks. Wave 5/10 achievements only retroactively trigger via `checkAllOnLoad`. Add the trigger in a future sprint.
- **Achievement notification toast UI** — currently unlocks just print to Output. A short top-center toast on unlock would be a nice polish.
- **Cosmetic system for purchased (not just earned) cosmetics** — current Config has level / pass gates only; no coin-purchase tier. Future sprint could add `coinCost` to Config.COSMETICS entries.
- **Mode-specific themes** — Maze Mode could have its own visual theme (different LED colors, different ambient lighting, neon corridor walls).

---

## Quick-fire summary

You can resume normal flow with these manual steps (in order):

1. **5 min:** §A — create Donator + Donator+ gamepasses on Creator Hub, paste IDs.
2. **30 sec:** §B — run map polish v3 in Studio.
3. **30 sec:** §C — run maze generator in Studio (optional, for future Maze Mode).
4. **15 min:** §D — Studio Test → Play through the test list.
5. **30 sec:** §E — File → Publish to Roblox.
6. **10 sec:** §F — `git push origin main`.

Total: ~25 min of focused work to bring v2 fully live.
