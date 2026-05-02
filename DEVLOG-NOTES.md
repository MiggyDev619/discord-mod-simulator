# discord-mod-simulator — devlog notes

Raw build notes for the Discord Mod Simulator Roblox project, structured for a devlog-generation session to consume.

## How to use this file

- Each dated section is one work session's deliverables, decisions, and hooks.
- The devlog session should pick one or two **narrative angles** from the "Hooks for the post" list per section — not try to cover everything.
- Voice: raw material, not a draft.
- Newest entries at the top.
- **BACKLOG** lives at the bottom — items deferred or filed for later reconception. Not dated.

---

## 2026-05-02 — Days 19–22 / Phase 4 close (Monetization)

> Same-day continuation after the Phase 3 close. Built end-to-end gamepass + dev product systems against placeholder Roblox asset IDs (user creates the actual passes/products on Creator Hub per `docs/USER-ACTIONS.md`). 4 commits: Day 19 (gamepasses) → Day 20 (dev products + Shop UI) → Day 21-22 (balance) → this close.

### What "Phase 4 closed" means against `plan.md` §7

| Phase 4 scope (Days 19–22) | Status |
|---|---|
| Gamepasses (Double Coins, Faster Cooldown) (Day 19) | ✓ — 3 passes shipped (added Starter Pack as the third). `GamepassManager` checks ownership + handles mid-session purchases. Effects wired into `CurrencyManager.AddCoins` and `effectiveCooldownForLevel`. |
| Dev Products (Instant Revive, Boosts) (Day 20) | ✓ — 4 products. `ProductHandler` owns `ProcessReceipt` with idempotent retry semantics. `GameManager.Heal` added for Revive. New Shop UI with mutex-toggled UpgradePanel coexistence. |
| Balance economy, fix exploits (Days 21-22) | ✓ tool unlock costs bumped 50% to make Starter Pack worthwhile. ✗ exploit hunting (server-side validation already covers destructive actions; non-destructive cooldown bypass is low-impact). No coin cap (run length self-limits). |

### Decisions made (and why)

- **Placeholder IDs (`id = 0`) instead of asking the user to pause for Creator Hub work mid-build.** Each `Config.GAMEPASSES` and `Config.DEV_PRODUCTS` entry has a TODO. Code guards on `id == 0` (purchase prompt prints to Output instead of erroring; ownership check returns false). User can hot-swap IDs later via `docs/USER-ACTIONS.md` §B/§C. Keeps the autonomous run unblocked.
- **Starter Pack as the 3rd gamepass.** Original §7 plan said "Double Coins, Faster Cooldown, etc." — I added Starter Pack as the third because it's the quintessential "skip the grind" pass, gives the Day 21-22 balance pass something concrete to balance against (bumping unlock costs gives the pass real ROI), AND tests the more complex one-time-grant path (`StarterPackClaimed` persistent attribute). The other two are pure passive multipliers.
- **Cooldown floor preserved past gamepass multiplier.** `effectiveCooldownForLevel` clamps to `upg.minValue` AFTER applying the FasterCooldowns ×0.7. Otherwise the pass + level 3 upgrade could push Ban cooldown to 0.07s (below the 0.1s balanced floor). Pass is "faster," not "instant."
- **Double Coins gamepass DOES double Coin Pack purchases.** A player who owns Double Coins and buys a Coin Pack Large gets 1000 coins instead of 500. Could be argued exploit-y (paying R$ to amplify R$). Going with intentional for v1 — "doubles every coin source" is a clean rule. If economy data shows this matters, gate later.
- **`ProcessReceipt` returns NotProcessedYet on any failure (no player, unknown product, handler error).** Roblox retries; receipt eventually grants or expires. No homegrown dedup table — Roblox handles R$ idempotency on their side.
- **XP Boost replaces existing duration, doesn't stack.** Buying two boosts in a row resets to 10 minutes from now. Stacking would let a whale skip half the leveling curve in one transaction; replacement caps the value-per-purchase.
- **Shop + Upgrades panels share the same screen slot (top-right, y=108).** Mutex toggle: opening one closes the other. Cleaner than two-tab UI for now; revisit if either panel grows past ~10 rows.
- **Schema v5 with v4→v5 migration.** Only `starterPackClaimed` persists from the gamepass system (ownership is queried fresh per join — Roblox is the source of truth, no cache divergence risk). XP Boost timestamp NOT persisted (mid-boost disconnect = lost boost; Phase 5 polish if it becomes a complaint).
- **No new `RewardForKill` or `effectiveCooldownForLevel` arguments — gamepass effects via Player attribute reads.** Same pattern as Day 14.5's combo check (`FrozenUntil` / `MuteFrozenUntil`). Adding a multiplier doesn't propagate through every callsite — just one helper does the lookup. Pays off again now.

### Phase 4 by the numbers

- 4 commits: `f227520` (Day 19) → `8541c73` (Day 20) → `ff5f514` (Day 21-22) → this close.
- New files: `GamepassManager.server.lua`, `ProductHandler.server.lua`, `ShopButton.model.json`, `ShopPanel.model.json`. Plus `docs/USER-ACTIONS.md` (the runbook for everything Claude can't do).
- New `Config` keys: `GAMEPASSES` (3 entries), `DOUBLE_COINS_MULT`, `FASTER_COOLDOWNS_MULT`, `STARTER_PACK_COIN_GRANT`, `DEV_PRODUCTS` (4 entries), `XP_BOOST_MULT`. Tool unlock costs updated.
- New player attributes: `DoubleCoinsOwned`, `FasterCooldownsOwned`, `StarterPackOwned`, `StarterPackClaimed` (persisted), `XpBoostUntil`.
- Schema v4 → v5. Migration grandfathers `starterPackClaimed = false` for any v4 player.
- Test cycles: 0 in-Studio (autonomous run; user verifies post-batch). Build verified clean across all commits.

### What's intentionally not built yet

- **Real Creator Hub IDs.** All 7 monetization items use `id = 0`. User MUST create them per `docs/USER-ACTIONS.md` §B + §C and paste the IDs into `Config.lua` before any R$ flow works. Code is purchase-ready; data is not.
- **Gamepass purchase confirmation modal.** The Roblox built-in "purchase succeeded" prompt is the only confirmation right now. A custom in-game modal ("You bought Double Coins! Effect active.") is queued for Day 23-24 UI cleanup.
- **Fancy gamepass icons.** No 512×512 icons uploaded — Roblox shows a placeholder grid icon in the purchase prompt. User can upload via Creator Hub when creating each pass (optional but improves conversion).
- **No anti-exploit beyond existing server-side validation.** Non-destructive tool spam isn't worth chasing. Mute Gun second-hit destroy IS server-validated (range + cooldown + IsEnemy check). Phase 6 launch can revisit if real players surface anything weird.

### Blockers for next session (Phase 5)

- **Phase 5 starts with map work that's Studio-only** (Workspace not in Rojo). Day 23 will produce `docs/MAP-LAYOUT.md` as a spec; user executes it manually in Studio per `USER-ACTIONS.md` §E.
- **Touch controls land in Day 23-24** but real-device verification is on the user (per §G). Tablet/Phone stay disabled in Game Settings until user confirms.
- **Working tree clean.** 21 commits ahead of `origin/main`, never pushed by intent.

### Hooks for the post

- **"Player attributes carried 4 features without one new RemoteEvent."** Combo (`FrozenUntil`/`MuteFrozenUntil`), tool unlocks (`<Tool>Unlocked`), gamepasses (`<Pass>Owned`), XP boost (`XpBoostUntil`) — all check player attributes, all replicate server→client automatically. The Day 4 lesson ("Player attributes replace half your RemoteEvents") just keeps paying.
- **"Code-ready, data-not-ready."** Phase 4 ships an entire monetization stack with `id = 0` placeholders that no-op gracefully. Code is correct, prompts won't fire until IDs land. Lets the build run autonomously and decouples the implementation from the Creator Hub UI work that has to happen in a browser tab.
- **"Don't double-dip-prevent until you have data."** Double Coins ×2 on Coin Pack purchases is a thing. Could be an exploit, could be the gamepass living up to its name. Easy to gate later (one `if dp.skipMultiplier` flag), expensive to add THEN remove if it turns out fine. Default to permissive, gate when proven.
- **"Effects via attributes scale linearly."** When the design called for a 4th passive multiplier (XP Boost on top of combo + Double Coins + Faster Cooldowns), it was 1 attribute, 1 helper edit. Compare to threading a new arg through `RewardForKill` callsites — would have been a multi-file refactor. Attributes are cheaper than function signatures when the dimension matters globally.

---

## 2026-05-02 — Days 13–18 / Phase 3 close (Retention)

> Single-day push through all of Phase 3 — Days 13 through 18 plus a Day 14.5 detour that wasn't on the original 30-day plan. Six commits ahead of the Phase 2 close, finishing on commit `ce79754`. Game now persists per-player progression across sessions, has 3 tool-unlock gates, 3 wave modifiers, an XP / level system, and a working restart loop with stats screen.

### What "Phase 3 closed" means against `plan.md` §7

| Phase 3 scope (Days 13–18) | Status |
|---|---|
| Upgrade tree, persistent upgrades, tool upgrades (Days 13–14) | ✓ DataStore + 4 cooldown upgrades + 3 tool unlocks. Schema v4 with full v1→v2→v3→v4 migration chain. Mock fallback for unpublished Studio runs. |
| Random waves + modifiers (Day 15) | ✓ 3 modifiers (Spam Storm, Toxic Wave, Splitter Surge), 30% chance from wave 3+. `Config.WAVE_MODIFIERS` is the source of truth — adding a new modifier is one entry. |
| XP, player levels, unlock new tools (Day 16–17) | ✓ XP from `RewardForKill` (base, not combo'd), per-level `level * 100`, cap 25. "Unlock new tools" interpreted as gating EXISTING tools behind an unlock cost (Day 14.5) since no new tools were designed. |
| Restart flow, retry button, game over screen (Day 18) | ✓ `GameOverPanel` modal + `RetryRun` RemoteEvent + `GameManager.Reset` + `EnemySpawner.ClearAll` + `RoundManager.startRun()` re-entrant. |

### The Day 14.5 detour (combat depth + tool unlocks)

Mid-Phase 3, a feature batch landed that wasn't in the original 30-day plan:
- **Mute Gun reworked** from a slow utility into a hitscan freeze gun: gun-shaped model (Handle + Barrel + Sight, Massless on top parts so grip physics is handle-driven), mouse-cursor raycast at 50 studs, cyan tracer + muzzle flash. **Two-hit destroy** — first hit sets `MuteFrozenUntil` + freezes blue; second hit on a still-frozen target invokes `EnemySpawner.DestroyEnemy` (the same shared destroy path Ban uses, so Splitter children still spawn).
- **Combo bonus** (`COMBO_MULTIPLIER = 2`) doubles coin reward when destroying an enemy that had `FrozenUntil` OR `MuteFrozenUntil` active. Wired through `CurrencyManager.RewardForKill`, applied at all destroy sites.
- **Kick rewards** — non-destructive AOE now awards `COIN_KICK_PER_HIT = 5` per cone-hit, doubled if the enemy was frozen. Was previously zero-reward.
- **Tool unlocks** — Mute / Timeout / Kick moved from `StarterPack` to `ReplicatedStorage/Tools/`; new `ToolGranter.server.lua` clones unlocked tools to Backpack on `CharacterAdded` AND on unlock attribute flip. Costs: MuteGun 100, KickBoot 150, TimeoutCard 200. Schema v3 with v2→v3 grandfathering for in-flight playtest saves.

This was a player request mid-session ("make Mute Gun an actual gun that shoots, give coins for kicks, give bonus for combos, lock the other tools behind purchases"). Roughly 2 hours of work spread across 17 files — comparable in scope to a full day.

### Decisions made (and why)

- **Schema-versioned datastore from Day 13.** `DMS_PlayerData_v1` (the `_v1` suffix) is a hard-reset hammer for breaking changes; the `version` field inside each save is the per-record migration path. Cheap to set up both, expensive to retrofit. By Phase 3 close we've already chained v1→v2→v3→v4 with no save loss — the pattern paid off.
- **Mock DataStore in Studio for unpublished runs.** Detected via `RunService:IsStudio() and game.PlaceId == 0`. Returns a table-backed shim. Persists across `PlayerRemoving` within a session but NOT across Stop→Play (Studio recreates the DataModel on Stop, destroying module state). Caught me off guard mid-session — wrote a misleading comment ("persists per Studio session") then corrected.
- **Place published mid-Day-13.** Switched from local-only `.rbxlx` workflow to a published place to enable real DataStore. Game Settings → Security → API Services flipped on. Local `rojo serve` workflow continues unchanged.
- **CurrencyManager and PersistenceManager are the project's first ModuleScript-with-Script pairing.** PersistenceManager is a `.server.lua` (no public API — side-effect installer). CurrencyManager is a `.lua` ModuleScript (other modules `require` it). PersistenceManager imports CurrencyManager one-way; dirty tracking via attribute change signals (no event plumbing).
- **Combo multiplier on coins, NOT XP.** XP always awards the base reward. Reasoning: combos are about chasing reward streaks (coins → upgrades → more combos), while XP is about steady progression (play more = level more). Doubling XP on combos would let combo-chaining players outlevel everyone else.
- **Mute Gun second hit shares Ban's destroy path via `EnemySpawner.DestroyEnemy` BindableFunction.** No duplicate Splitter logic, no duplicate combo logic, no duplicate effects. One source of truth for "an enemy died because a player did something." Adding a 4th destructive tool would just call into the same function.
- **Tool unlocks default to FALSE on init, get grandfathered=true on v2→v3 load.** Two paths through the same code — fresh players see the locked state and have to buy in; existing testers (just me) keep their full kit. No special-case migration code beyond the one line in `migrate()`.
- **`startRun()` doesn't use a runId / cancellation token.** The wave loop only halts when `IsGameOver()` is true; `Reset()` only fires from a player click on the GameOverPanel button, which only appears after `gameOver`/`gameWon`. By the time Retry happens, the old loop has fully exited. Not bulletproof for a multiplayer scenario where one player retries while another is mid-win, but solo-correct.
- **Wave modifiers gated by `minWave`.** Spam Storm and Toxic Wave from wave 3, Splitter Surge from wave 4 (matches Splitter's normal eligibility). Picks uniformly from eligible. 30% chance per wave. Tunable in `Config.MODIFIER_CHANCE`.
- **Mute Gun rename rejected by user** ("keep mute gun"). Name is now slightly inaccurate (the tool freezes, doesn't mute) but the player asked for it. Filing this as a teaching moment: clarifying questions surface user preferences that defaults wouldn't.

### Phase 3 by the numbers

- 6 commits: `a3244e2` (Day 13) → `0dd31d9` (plan tablet/phone) → `4cfabed` (Day 14 + 14.5) → `c0bc653` (Day 15) → `12a2f88` (Day 16-17) → `ce79754` (Day 18).
- 17 commits ahead of `origin/main` total since project start, never pushed.
- New files: `PersistenceManager`, `ToolGranter`, `MuteGunSetup`, `Barrel.model.json`, `Sight.model.json`, `UpgradePanel.model.json`, `GameOverPanel.model.json`. Plus the 3 tool directories renamed to `ReplicatedStorage/Tools/`.
- New `Config` keys: 4 cooldown upgrade defs, 3 tool unlock defs, 3 wave modifier defs, plus `COMBO_MULTIPLIER`, `COIN_KICK_PER_HIT`, `XP_PER_LEVEL_BASE`, `XP_MAX_LEVEL`, `MUTE_FREEZE_DURATION`, `MODIFIER_CHANCE`, `PERSISTENCE_AUTOSAVE_INTERVAL`. Removed: `MUTE_SLOW_FACTOR`, `MUTE_DURATION`, the old flat `UPGRADE_COOLDOWN_*` keys.
- Schema versions shipped: v1 → v2 → v3 → v4. Full migration chain in `PersistenceManager.migrate()`.
- Test cycles: ~5 mid-Phase-3 (mostly during Day 13 + 14.5).

### What's intentionally not built yet (Phase 4+ unblocked)

- **Phase 4 monetization (Days 19–22).** Gamepasses + Dev Products. Pricing decisions need the user — autonomous defaults are risky on real-money flow. Place is published, so Dev Products can be created in the Roblox Creator Hub.
- **Phase 5 polish + viral (Days 23–27).** Better map, lighting, UI cleanup, **touch controls + tablet/phone playtest** (per `plan.md` §9 — verification needs real devices), meme enemies, multiplayer polish.
- **Phase 6 launch (Days 28–30).** Icon, thumbnail, description, public release.
- **DataStore queue warning on disconnect.** Saw `DataStore request was added to queue` in Day 14.5 testing — autosave + PlayerRemoving + BindToClose all firing close together brushes Roblox's per-key rate limit. Benign so far (no dropped saves). Optimization: skip autosave-on-leave when PlayerRemoving will save anyway. Revisit if a save is ever actually dropped.
- **Combo + Kick interactions.** Kick on a frozen enemy gives 10 coins per hit (5 × 2 combo), but Kick doesn't destroy the enemy — so the combo timer remains, and a follow-up Ban or Mute-second-hit also gets the combo. Intentional: combos cascade across tools. Watch for any feel issues at high cooldown levels.
- **Studio retry race in multiplayer.** `startRun()` doesn't use a runId token. Solo-safe (loop has fully exited by Retry click). Multiplayer would need cancellation. Flag for Phase 5 multiplayer polish.

### Blockers for next session

- **Phase 4 needs human pricing decisions.** Don't autonomously default Gamepass costs / Dev Product prices — these affect real money once players show up. Pitch designs first, get sign-off, then code.
- **Working tree clean. Push to origin is the user's call** — 17 commits ahead, never pushed by intent.

### Hooks for the post

Pick one. Not all.

- **"Schema versioning paid for itself in 6 days."** — Day 13 set up v1 with the version field "just in case." By Phase 3 close we'd shipped v1→v2→v3→v4 across the full lifecycle (split a single field, added a new field, grandfathered legacy state). Each migration was 4–6 lines. The alternative — wiping saves on every shape change — would have lost the user's playtest progression three times.
- **"How a 'simple gun' became a 17-file refactor."** — the Mute Gun rework story. Started as "make it a real gun." Cascaded into: gun model (3 parts + setup script), hitscan with mouse raycast, two-hit state machine, combo system, Kick rewards, tool unlock system (3 new tool grants + new server module + schema migration), upgrade panel rewrite, persistence v3. Lesson: gameplay reworks rarely stay scoped to the gameplay file.
- **"`EnemySpawner.DestroyEnemy` is the kill API now."** — the BindableFunction extracted on Day 14.5 became the single point through which any tool destroys an enemy. Splitter children, combo reward, hit flash, ban effect — all in one place. When the player adds a fourth destructive tool (someday), it'll be a one-line `destroyEnemy:Invoke(player, enemyPart)`.
- **"Tool unlocks are a free retention loop."** — Day 14.5's incidental win. Locking the 3 non-Ban tools behind coin costs (100 / 150 / 200) gives a fresh player a multi-hour goal trail without any new mechanics. The tools always existed — the unlock gate IS the progression.
- **"Mute Gun freeze + Ban combo is the most satisfying loop in the game right now."** — the gameplay finding. Shoot (freeze blue) → run up → ban hammer → 2× coins + COMBO! tag in chat. Rewards both planning and execution. Probably accidentally became the core loop the game should lean into in Phase 5 polish.

---

## 2026-05-02 — Day 12 / Phase 2 close (bookkeeping)

> Not a code session. A deliberate checkpoint: Phase 2 ("Game Feel," Days 6–12) is closed before Phase 3 work begins. The brand rebrand (Apr 25–26) and the recording-session polish (May 1) were the de-facto closing beats — both real game-feel work even though neither was a planned dev day. This entry exists so Phase 3 starts from honest documentation, not stale `plan.md` §2 text claiming Day 5 / Phase 1.

### What "Phase 2 closed" means against `plan.md` §7

| Phase 2 scope (Days 6–12) | Status |
|---|---|
| Hit effects, enemy feedback, simple animations (Days 6–7) | ✓ — `Effects.lua`, `HitFlash`, camera shake, swing anim, visible hammer |
| Mute Gun, Timeout, Kick (Day 8) | ✓ — full status-effect toolkit, priority ladder `Kick > Timeout > Mute > seek` |
| Path variation, annoying enemies (Days 9–10) | ✓ Teleporter + Splitter; ✗ path variation (skipped — enemy variety carried the differentiation, single-lane geometry kept aim/positioning legible) |
| Health bar, enemy count, round number, currency UI (Days 11–12) | ✓ Day 11 UI polish v1 + `FlashOverlay` + brand rebrand layered on top |

The May 1 recording session functioned as the de-facto Day 12 closing beat — it forced a quality bar that surfaced two real game-feel gaps (`Effects` shockwave/light and `BanHammer` shake), both committed to main as `228b9fc` and `da556b7`. See the 2026-05-01 entry for the full recording writeup.

### Bookkeeping done this session

- **`plan.md` §2 rewritten**: Day 5 → Day 12, Phase 1 → Phase 2 closed, prior "Done (Days 1–4)" + "Next up (Day 5)" replaced with a per-day Phase 1 + Phase 2 ledger, "Next up" now pointing at Phase 3 (Days 13–18).
- **`plan.md` §8 master checklist** ticked: all of Core Systems, Gameplay, Polish; Currency / Shop / Upgrades from Progression; Health / Round / Currency UI. Three boxes deliberately left unchecked: XP / levels (Day 16–17), Game-over screen (`FlashOverlay` covers the visual flash but Day 18 builds the full screen + retry button), Monetization, Launch. Inline notes added to each ticked item naming the concrete artifact (e.g. "Faster Ban Hammer L1–3; tree expansion is Phase 3") so the checklist also serves as a "what exactly is built" reference.
- **This entry written.**

### Decisions made (and why)

- **Wrap entry exists at all.** Days 11 and 12 ran together with the brand rebrand and the May 1 recording session, neither of which produced a "Day 12: Phase 2 close" devlog naturally. The May 1 entry is recording-focused, not phase-focused. Without a deliberate close, Phase 3 work would start while §2 still claimed Day 5 / Phase 1 — `plan.md` is what someone reads top-down to onboard, and it shouldn't lie. Cost: ~30 min. Benefit: every future Phase 3 session starts from honest checkpoint state.
- **Path variation marked ✗ skipped, not ✗ deferred.** Original Day 9–10 scope mentioned it; enemy variety (Teleporter + Splitter) shipped instead. Single-lane geometry has held up across all four enemy types and four tools — adding a second lane now would dilute aim/positioning legibility for no clear gameplay gain. If Phase 3 modifiers ("Spam Storm") want spatial variety, they'll get it via spawn rate / direction, not via path geometry.
- **"Game over screen" intentionally left unchecked despite `FlashOverlay` shipping.** The flash is run-end visual feedback — it's a polish item, ticked under Polish. Day 18's "retry button + full game over screen" is a different deliverable (UI screen + flow restart). Conflating them now would re-mark the box on Day 18 anyway.
- **No code touched.** Considered piggybacking a small Phase 2 cleanup pass — there isn't one needed. Working tree was clean coming in; closing the phase doesn't require shipping more polish, it requires acknowledging the existing polish is enough.

### Phase 2 by the numbers

For the Clip 10 re-pitch (BACKLOG, currently filed as a "Phase 2 in N days" companion piece): re-tally `src/` LOC at next code session. Last count was 1,691 Lua LOC across 15 files on 2026-04-25; brand rebrand + Day 11 UI + recording polish has likely moved both numbers.

### What's intentionally not built yet (Phase 3 unblocked, in order)

- **Day 13 — DataStore design pass.** First persistence work in the project. Read/write model needs to exist before the upgrade tree gets built on top of it; otherwise the tree gets retrofitted to whatever the first save format happened to be. Specifics to decide on Day 13: per-player `DataStore` or single-key player table, autosave cadence, what happens on load failure (default vs hard-block), upgrade-spec versioning so future schema changes don't wipe saves.
- **Day 13–14 — Upgrade tree.** Currently one upgrade (Faster Ban Hammer). The shop button + `CurrencyManager.TryPurchaseCooldown` pattern generalizes — but only after persistence exists. Don't build the second upgrade against in-memory state and then refactor.
- **Phase 2 deferred polish still standing.** Cooldown sweep animation, custom hotbar replacement (Phase 5 per CLAUDE.md), Mute Gun real aim-and-shoot (`plan.md` §9), Kick whiff visual-without-audio, Kick Y-axis lift, Splitter children inheriting muted/frozen visuals, Teleport telegraph, real level decoration (Phase 5). Not blockers for Phase 3.

### Blockers for next session

- None. Working tree is clean. 11 commits ahead of `origin/main` (this entry + the two `plan.md` edits will make 12) — push is the user's call, never been pushed yet by intent.

### Hooks for the post

Pick one. Not all. (These are unusual — the work was bookkeeping, so the hooks are about the *practice* of phase closing, not about code.)

- **"Phase boundaries are documentation, not engineering."** — the argument for explicit phase-close commits even on a solo project. `plan.md` lying about your current state isn't a doc bug — it's a planning bug, because it's what you onboard yourself with at the start of every session. 30 minutes to fix; pays back the first time someone (you, future-you, an AI assistant) reads the project top-down.
- **"The recording session was the Phase 2 close, I just didn't know it."** — sometimes the closing beat of a phase isn't a planned dev day. May 1 forced a quality bar that surfaced two real polish gaps; once those shipped, Phase 2 was actually done. The bookkeeping entry just acknowledges what already happened.
- **"What `plan.md` §8 is for: a 30-second 'what's built' reference."** — the checklist isn't a TODO; it's a reverse index. Every ticked box names the concrete artifact ("Faster Ban Hammer L1–3", "Frame + `Fill`/`Label` bar"). Future-you reading "Upgrades ✓" without context would assume the tree is done; "Upgrades ✓ (Faster Ban Hammer L1–3; tree expansion is Phase 3)" tells the truth.

---

## 2026-05-01 — Recording session: 7 clips captured + game-feel polish

> Single overnight push (Thu Apr 30 evening → Fri May 1 early hours). Sunday Apr 26 recording slipped 5 days; pulled the trigger Friday instead. Captured 7 of 8 planned clips and shipped two real game-feel commits as a side-effect of recording surfacing visual gaps.

### What got captured

Raw files in `E:\Content\DMS\Raw\studio\` (gameplay) and `E:\Content\DMS\Raw\code\` (editor screencaps). VO folder empty (deferred).

| Clip | Status | Notes |
|---|---|---|
| 01 — The loadout | ✓ | 4 tool-firing takes (Ban: 3 takes, others 1-2 each) + final hotbar reveal |
| 02 — Three statuses | ✓ | Mute → Timeout → Kick chain on a single Spammer, ending on void launch |
| 03 LEFT — Bad shake | ✓ | ~30s of banning with deliberately broken `Camera.CFrame` shake on RenderStepped |
| 03 RIGHT — Good shake | ✓ | ~10s with the (now committed) bumped `CameraOffset` shake |
| 04 — SERVER DEAD | ✓ | Wave 3 chaos → HP 0 → red FlashOverlay fires |
| 05 OLD — Whiff bug | ✓ | 2 takes — Kick whiff plays sound + visual (gate temporarily removed) |
| 05 SILENT — Whiff fix | ✓ | 2 takes — Kick whiff produces nothing (gate restored) |
| 06 — Failed icons | ✗ skipped | User passed mid-session; not in rotation |
| 07 — VICTORY | ✓ | Full 5-wave clear → green FlashOverlay fires |
| 09 — Wave 3 transition | ✓ | Waves 1→2→3 with rapid tool-swapping ending on cleared zone |

VOs for Clips 05 + 07 deferred — to record before each clip's editing pass next week. Casual rewrite of the 05 VO was drafted during the session (in `content-engine/docs/recording-status.md` — "Decisions changed" section).

### What got built (real game-feel polish, both committed to main)

- **`Effects: shockwave + light on Ban/Kick/Mute/Timeout for game-feel`** (commit `228b9fc`). Original Ban/Kick particle bursts read as "poof" not "bang" — drowned by `HitFlash`'s 0.15s white-neon despawn. Added expanding Neon-material shockwave Parts + brief `PointLight` glows + bumped particle counts (Ban 25→50, Kick 40→70). `HitFlash` duration 0.15→0.08s so red Ban particles get visible airtime. Mute/Timeout got smaller-scale ports (sphere shockwave 1→5 studs) for visual hierarchy: **Ban (loudest, destructive) > Kick (loud, AOE) > Mute / Timeout (medium, status)**.
- **`BanHammer: bump shake duration + magnitude for visible feedback`** (commit `da556b7`). Original 0.18s / 0.35-magnitude was too subtle to register. Bumped to 0.30s / 0.75. Still uses `Humanoid.CameraOffset` (smooth, respects camera controller), just punchier. The bad-shake demo for Clip 03 LEFT was rewritten mid-session too — the `task.wait`-based loop in the staged `clip-recording-bad-shake` branch got smoothed out by the camera controller and looked like nothing. Rewrote to RenderStepped + bigger magnitude. The rewrite is preserved at `E:\Content\DMS\Raw\code\clip03-shake-comparison.lua` since it's not in any committed branch (`clip-recording-bad-shake` was deleted at EOD).

### Decisions made (and why)

- **Polish committed during recording, not after.** Effects.lua and BanHammer shake were dirty-fixed on the recording branch when their visual weakness blocked clean clip captures. Both are real Phase 2 game-feel improvements, not recording-only — committed to main rather than left in stash. The recording session forced a quality bar the dev sessions hadn't.
- **`HitFlash` duration cut, not removed.** Considered killing `HitFlash` entirely (it's what was washing out the red Ban particles), but the white-flash-then-poof has its own readability value (sells the "destroyed" beat). Cut to 0.08s — short enough to clear the frame for Ban particles, long enough to register as a hit confirm.
- **Bad-shake had to be rewritten, not just restored.** Original staged version (`task.wait(0.04)` loop with 0.5-stud max offset) didn't actually look broken on screen — camera controller smoothed it between writes. To demonstrate the failure mode in a clip, the bad shake had to *actually fight the controller* every frame. RenderStepped connection + 1.4-stud magnitude. Lesson: a "broken" example needs to look broken, not just *be* broken in the abstract.
- **Clip 06 (failed icons) dropped, not deferred.** User passed mid-session. Different from Clip 08 + Clip 10 in BACKLOG — those were deferred for reconception. 06 is just out of rotation. Saves the editing-week budget; collapses 8-clip rotation to 7-clip rotation, last post Mon May 18.
- **Level visual polish via runtime debug script, not committed assets.** Used a `LevelPolish.debug.server.lua` (gitignored, deleted post-session) to apply baseplate color, lighting tweaks, and EnemyStart/ServerZone glows at game start. Doesn't touch Workspace or Lighting in the Rojo tree (per CLAUDE.md, Workspace is intentionally out). Edit-mode look is back to defaults — clip captures had the polished look baked in via runtime application. Real level polish (decorations, walls, themed signage) is Phase 5 (Days 23-24) per plan §7.
- **Logo not uploaded.** `miggydev-mark-200.png` still local-only. `Watermark.model.json` still has `rbxassetid://0` placeholder. CapCut overlay watermark in editing handles brand visibility — in-game corner watermark is a "would be nice" not a blocker. Roblox cloud upload needs Studio's Asset Manager to "Save to Roblox" (a place link), which creates a drift hazard with the local `.rbxlx` workflow. Skipped to preserve clean local-only state.

### Quick state changes worth remembering

- **`SoloSpawn` got keybind triggers** (`Z`/`X`/`C`/`V` for Spammer/Troll/Teleporter/Splitter) in addition to the chat command, because `RecordMode` hides chat. Server creates a runtime `_DebugSpawn` RemoteEvent in `ReplicatedStorage`; paired client script (`SoloSpawnInput.debug.client.lua`) fires it on key press. All four debug scripts deleted at EOD; the pattern is in `content-engine/docs/recording-status.md` if useful next time.
- **`FlashOverlay` was tested for the first time** (had been committed Apr 25 untested). Both red and green flashes fire correctly via `GameManager.TakeDamage(99999)` / `GameManager.Win()`. Used a temp `FlashTest.debug.server.lua` with auto-fire mode constant (`MODE = "lose"` / `"win"`); deleted post-test.
- **`clip-recording-bad-shake` branch deleted** at EOD per runbook §4.5. The bad-shake change was never committed; only existed in stash, then in working tree, now in the comparison file at `E:\Content\DMS\Raw\code\clip03-shake-comparison.lua`.

### What's intentionally not built yet

- **Voiceovers (Clips 05 + 07).** ~10 min in Audacity, save WAVs to `E:\Content\DMS\Raw\vo\`. To be recorded before each clip's editing pass.
- **Logo upload to Roblox.** See decision rationale above. `INSERT-LOGO-ASSET-ID-HERE` searchable marker still in `Theme.lua` header.
- **Real level decoration.** Yellow boundary walls, server-rack props, Discord-themed billboards. Phase 5 work (Days 23-24).
- **Tool 3D models.** Still primitive Parts. Tight camera framing during clip captures hides this; full model pass is post-launch polish if at all.

### Blockers for next session

None. Working tree is clean (only untracked file is `docs/MiggyDev-DMS-Recording-Plan.md`, the user's planning doc). All recording-only debug state is gone. Two commits ready for a Phase 2 close devlog or roll into Phase 3 kickoff.

### Hooks for the post

Pick one. Not all.

- **"My recording session debugged my game."** — recording forced a quality bar that dev sessions hadn't. Ban particles too thin → shockwave + light. BanHammer shake too subtle → bumped duration + magnitude. Bad-shake demo wasn't actually visibly broken → had to rewrite it to fight the camera controller every frame. Three real polish commits came out of capturing footage. Lesson: shipping for an audience surfaces problems regular playtesting doesn't.
- **"A 'broken' example has to look broken."** — the bad-shake rewrite. The staged `task.wait(0.04)` loop wasn't fighting the camera controller because between writes, the controller smoothed it out. Visually identical to no shake. To demonstrate the failure mode, the bad version had to write `Camera.CFrame` on RenderStepped — same heartbeat as the controller — to produce visible snap-back. The intuition: in Roblox, a "wrong" approach doesn't necessarily *look* wrong; it competes with whatever framework code is running on the same loop, and the framework usually wins.
- **"Three particles never beat one shockwave."** — the Effects.lua buff. 25 small sparkles drowned by a 0.15s white-neon flash read as "poof". One expanding Neon Part (1→8 studs over 0.4s) + a PointLight reads as "bang" — for the same compute budget. Visual punch is geometry + light, not particle count.
- **"`HitFlash` is a feature, not a bug — but its duration was."** — the 0.15s → 0.08s cut. Originally added `HitFlash` so the player gets a "hit confirmed" beat before the enemy poofs. But it was *also* washing out the Ban particles for a third of their lifetime. Tuned, not removed: the white flash still does the hit-confirm job, just doesn't dominate the frame.

---

## 2026-04-25 — Sunday recording prep: cuts, decisions, polish

> Pre-production pass for the 10-clip Sunday recording session. Audit (commit `b68a82a`) flagged 4 hard blockers; this session resolves them via cuts and small code fixes. Same calendar day as the wave-1 race fix and Day 9–11 backfills — split out because this is content-prep, not gameplay code.

### Decisions made (and why)

- **Clip 02 caption rewritten + payoff dropped.** Original draft ("kick gets eaten by the slow") inverts the actual priority ladder (`Kick > Timeout > Mute > seek`). Kick *overrides* mute, doesn't get eaten. The "+20 coins" final frame was also impossible — `Kick` is non-destructive (`KickHandler.server.lua` doesn't call `CurrencyManager.AddCoins`); only Ban awards coins. New caption: **"Three statuses, one Spammer, one launch into the void."** Hashtags: `#robloxgame #robloxdev #gamefeel`. Demonstrates the visual without making a false mechanical claim.

- **Clip 08 OUT for Sunday → filed in BACKLOG.** Premise was "empty packet, server-derived geometry" — but `CLAUDE.md` documents the kick aim as the explicit *exception* to server-authoritative: client sends `Workspace.CurrentCamera.CFrame.LookVector` (flattened) as a Vector3 payload, server uses that vector. Was never not the case in committed history. Pitching it as a server-derived design lesson would be a lie. Reconception path: pivot to `BanEnemy` (truly server-validated — server checks `IsEnemy`, range, cooldown before destroying) or write a different "trust boundary" angle.

- **Clip 10 OUT for Sunday → reschedule to Phase 2 close.** Animated milestone-table is editor-heavy with no committed scaffold-only state to film for "Day 1." Recap clips work better with an audience to recap *for*. Better as a "Phase 2 in N days" companion when Phase 2 closes (Day 12).

- **Source line count tally**: **1,691 Lua LOC across 15 `.lua` files** in `src/`. Recorded for future Clip 10 caption use.

### What got built (same session, content-driven)

- **`KickBoot/init.meta.json` ToolTip "Kick" → "Kick Boot"** (commit `4b2956b`). Hotbar consistency for Clip 01 — every other tool's ToolTip uses the full name.
- **`MainUI/FlashOverlay` full-screen flash on gameOver / gameWon** (commit `ac6e0d2`). New `Frame` model.json (full-screen, `BackgroundTransparency=1` default, `ZIndex=100`, `Active=false`); `ClientMain` tweens it red on `gameOver` / green on `gameWon` with shape `0.15s fade-in → 0.3s hold → 0.4s fade-out`. Real game improvement, not just a clip prop — the previous run-end "flash" was just a label color change. Used by Clip 04 (SERVER DEAD) and Clip 07 (VICTORY). NOT yet tested in Studio at time of commit — verify Sunday morning.

### Decisions made (and why) — second batch

- **`Active = false` on FlashOverlay**, not `Visible` toggling. Frame stays mounted the whole game, just transparent. Avoids the "first flash has a one-frame mount delay" failure mode. `Active = false` ensures the overlay doesn't sink input clicks (UpgradeButton stays clickable through it).

- **`ZIndex = 100`**, not `ZIndex = 1`. Standard ScreenGui ZIndexBehavior is `Sibling`; the flash needs to render *over* the labels, not under them. 100 is arbitrary — picked high to leave room for future overlays (pause screen, settings) at 50.

- **Color picks: red `(255, 70, 70)` and green `(80, 255, 140)`.** Match the existing run-end label text colors so the flash and the "SERVER DEAD" / "VICTORY" text feel like one event. Slightly brighter than `HEALTH_RED` so the flash reads as a panic-state, not a "low health" warning that the player might already be desensitized to.

### Pre-production blockers cleared

| # | Blocker | Resolution |
|---|---------|------------|
| 1 | Clip 02 caption inverted | Rewritten — see above |
| 2 | Clip 02 +20 coin payoff impossible | Dropped from caption |
| 3 | Clip 08 server-derived premise false | Cut from Sunday, filed in BACKLOG |
| 4 | Clip 03 bad "before" version not in git history | Pre-write on `clip-recording-bad-shake` branch (next, this same session) |

### Hooks for the post

Pick one. Not all.

- **"Pre-production audit found my own clip captions were lying about my own code."** — the meta-lesson. Three of ten captions had factual errors (Clip 02 inverted priority, Clip 08 false premise, Clip 02 impossible coin payoff). Lesson: audit captions against committed code, not against your mental model of how the system *should* work.
- **"The flash overlay was a clip prop that turned into a real fix."** — flashOverlay was added because Clip 04/07 needed visual punch, but the previous run-end was genuinely too subtle (just a text color change). Sometimes the recording requirement is what surfaces the real polish gap.
- **"Cutting clips before recording is cheaper than recutting after."** — three of ten clips deferred at audit time. Doing 7 right beats doing 10 wrong.

---

## 2026-04-25 — Wave 1 "N left" race fix

> Bugfix follow-up to Day 11 UI polish (`6e50c6c`). Same calendar session as the content-planning sprint that lives in `content-engine/DEVLOG-NOTES.md` (clips work moved there); split out because this is code, not planning.

### What got built

- **`Config.PRE_WAVE_DELAY = 2`** — new tunable, seconds the server waits after the first player joins before starting wave 1.
- **`RoundManager.server.lua` waits before wave 1**: `if #Players:GetPlayers() == 0 then Players.PlayerAdded:Wait() end` followed by `task.wait(Config.PRE_WAVE_DELAY)` at the top of the wave-loop `task.spawn`. Imports `Players` service.
- **`WaveLabel.model.json`** — width 240 → 280px, added `TextTruncate: "AtEnd"`. Cheap layout headroom.
- **`SetWaveRemaining` BindableFunction in `EnemySpawner`** also broadcasts `EnemyCountChanged` immediately on invoke (in addition to the heartbeat dedup) — defensive, kept even though it wasn't the root cause.

### What was NOT the cause (false leads, documented for next time)

- **Em-dash (`—`) glyph rendering.** Reverted. Wave 5 screenshot showed `Wave 5 / 5  —  1 left` rendering cleanly in Gotham — em-dash works fine. Hyphen swap was treating a symptom that didn't exist.
- **Label width.** 240px was probably enough. 280px stays as headroom but didn't fix anything.
- **Heartbeat broadcast timing.** The "1-frame gap" theory was wrong. Even immediate broadcast doesn't help if the client hasn't connected its `OnClientEvent` handler yet.

### Decisions made (and why)

- **Root cause was a startup race, not a render bug.** Server scripts (`ServerScriptService`) boot before `StarterPlayerScripts` finish their `WaitForChild` chain and connect `OnClientEvent` handlers. RoundManager's `task.spawn` fires `WaveStarted` and `EnemyCountChanged` for wave 1 before the client's listeners exist. Roblox does NOT queue RemoteEvents fired before a connection is made — they're dropped silently. The label kept its `model.json` default text (`"Wave 1 / 5"`) because `renderWaveLabel` never ran. By wave 2+ the client was fully booted, so subsequent waves worked. The diagnostic was the wave-5 screenshot showing the suffix render perfectly: if rendering worked at all, the bug had to be at game-start specifically.

- **Fix on the server, not the client.** Two options were available: (a) delay wave 1 server-side, (b) implement a "client ready" signal that the server waits on. Picked (a) because it's two lines and zero new state machinery. (b) is correct for late-joining multiplayer players, but multiplayer is Phase 4+; not paying that cost now.

- **`Players.PlayerAdded:Wait()` guard despite Studio always having a player.** Defensive. In Studio Playtest the player exists at script start, so the guard is a no-op. In a future server-with-no-players startup (closed test, dedicated server) it prevents the loop from racing past `PlayerAdded`. Free correctness.

- **2 seconds, not 1 or 5.** 1s sometimes wasn't enough on cold Studio boots in casual testing. 5s is visibly long — the player stares at an empty map. 2s is the smallest value that hasn't reproduced the race so far. Tunable via `Config.PRE_WAVE_DELAY` if more headroom needed later.

- **Three earlier fixes were treating symptoms.** Em-dash swap, label widening, immediate broadcast — none addressed the actual race. Kept the broadcast (cheap, defensive) and the label width (cheap, harmless), reverted the em-dash (it works). Lesson logged.

### What's intentionally not built yet

- **"Current wave state" RemoteFunction for late-joiners.** A new player joining mid-wave-3 wouldn't get `WaveStarted` or `EnemyCountChanged` until wave 4. Not building until multiplayer is in scope (Phase 4+).
- **Client-ready handshake.** A `ClientReady:FireServer()` from `ClientMain` after all listeners are connected, with the server collecting readies before starting waves. Cleaner pattern for multiplayer but overengineered for a single-player Studio playtest.

### Hooks for the post

Pick one. Not all.

- **"Server scripts boot before client scripts. Your wave 1 events are firing into the void."** — the actual gotcha. Most Roblox tutorials don't teach this; you find out the first time you ship a UI that renders perfectly on wave 2 and never on wave 1. Concrete, niche, devs will save it.
- **"Three fixes that didn't work, one screenshot that did."** — the diagnostic story. Em-dash, label width, broadcast timing — all wrong theories. Wave 5 working is what reframed the problem. Lesson: when your fix doesn't fix it, the model is wrong, not the implementation.
- **"Don't trust the model.json default text — if your renderer never runs, that's what your users see."** — a UI lesson, broader than this bug. Default text in a `.model.json` is a silent fallback that masks "my code never ran" as "my code ran with stale data." Empty string defaults force the bug to surface.

---

## 2026-04-25 — Day 11: UI polish v1 (health bar, live wave count, cooldown panel)

> Backfilled from commit `6e50c6c` after the Day 9–11 gap was caught during the 2026-04-25 content-planning sprint (lives in `content-engine/DEVLOG-NOTES.md`).

### What got built

- **`HealthLabel` rebuilt as a Frame**, not a TextLabel — has named `Fill` and `Label` children. Fill width tweens with health %, color crosses green / yellow / red at 60% / 30% thresholds. ClientMain drives the tween from `HealthChanged` events.
- **Wave label combines `WaveStarted` + `EnemyCountChanged`** into "Wave X / Y — N left", driven by a small ClientMain state machine. EnemySpawner broadcasts active count once per heartbeat tick when it changes, so spawn / destroy / zone-damage all surface live without per-event remote traffic.
- **`EnemyCountChanged` RemoteEvent** — new, single-value payload (the new count). Replaces what would have been three separate events (spawned / destroyed / damaged-out).
- **Cooldown panel (`MainUI/CooldownPanel`)** — new `Frame` with 4 slots (Ban / Mute / Kick / Timeout, in hotbar order) at bottom-center. Each slot has named `Letter` and `Timer` TextLabel children. ClientMain reads `<Tool>ReadyAt` attributes off `LocalPlayer` per-frame to dim slots on cooldown and surface decimal seconds remaining.
- **Tool client scripts standardized on `<Tool>ReadyAt`** — `BanHammerScript`, `MuteGunScript`, `KickBootScript`, `TimeoutCardScript` each set `Players.LocalPlayer:SetAttribute("<Tool>ReadyAt", tick() + cooldown)` immediately after a successful activation. Client-only attributes — don't replicate to server, which has its own cooldown gating where needed.
- **`ClientMain.client.lua` major refactor** (~140 lines added/changed) — consumes `WaveStarted`, `EnemyCountChanged`, `WaveBreak`, `HealthChanged`, `GameOver`, `GameWon`. Per-frame loop reads `<Tool>ReadyAt` attributes to update the cooldown panel.

### Decisions made (and why)

- **One `EnemyCountChanged` event with the count, not three events for spawn / destroy / damaged-out.** All three sites need the same downstream UI update ("N left" text). Funneling through one event with the new count keeps ClientMain's handler shape uniform — no event-type branching for UX that doesn't differentiate. Server fires once per heartbeat tick (debounced), not once per delta.

- **Cooldown state via client-set Player attributes, not RemoteEvents.** Each tool's LocalScript writes `<Tool>ReadyAt = tick() + cooldown` on the LocalPlayer. ClientMain reads per-frame. No replication, no server traffic — server already enforces its own cooldown gate. Same shape as Day 4's "Player attributes replace RemoteEvents for client-rendered state" decision, applied to a new domain.

- **Cooldown panel is a Frame with named slot children, not 4 ImageLabels.** Each slot is `Letter` + `Timer` TextLabels under a slot Frame, fully Rojo-owned. Future work (icons, sweep animation, custom hotbar replacement) layers on top without rewriting the structure. Pick one structure now → next iteration is additive, not a rewrite.

- **HealthLabel rebuilt in place, not as a parallel HealthBar element.** The old HealthLabel was already at top-center with the right anchor — replacing its content (text → frame with Fill/Label children) preserved the layout and the `HealthChanged` wiring. Z-order, anchoring, and naming all stayed put.

- **Health bar color thresholds at 60% / 30%, not 66% / 33%.** Most damage in DMS comes in late-wave bursts; 60% is "you're getting hit, pay attention," 30% is "panic." Even thirds put the panic line too late. Tuned by feel, not theory.

### What's intentionally not built yet

- **Cooldown slot icons.** Currently shows letters (`B / M / K / T`). The 1024×1024 PNGs from Day 8+9 belong here too — deferred to next UI session.
- **Cooldown sweep animation.** Slots dim flat, no rotating sweep. Common in MOBA-style cooldown UIs. Two-line tween change once icons land.
- **Custom hotbar replacement.** Default Roblox `CoreGui` backpack still owns the top hotbar. Disabling `Enum.CoreGuiType.Backpack` and rendering a custom one is Phase 5 (Days 23–24, "UI cleanup").

### Blockers for next session

- None. UI v1 is stable; cooldown panel works against all four tools; wave + health labels are live.

### Hooks for the post

Pick one. Not all.

- **"`Player:SetAttribute` is the right way to wire a cooldown UI"** — client-only attributes for client-rendered state. Why a `<Tool>ReadyAt` attribute beats a `CooldownChanged` RemoteEvent. Same lesson as Day 4's currency wiring, applied to a new domain.
- **"One enemy-count event with the count, not three events for spawn / destroy / damage"** — debounced single-event design. Uniform handler shape, cheap server, no event-type branching.
- **"Health bar color thresholds at 60 and 30, not 66 and 33"** — feel-driven UX numbers. The argument for tuning thresholds against actual damage rhythm, not theoretical even thirds.
- **"Frame with named children > TextLabel for any UI that might grow"** — the HealthLabel rebuild. Why a `Fill` + `Label` structure preserved every wire-up while making the bar extensible.

---

## 2026-04-25 — Day 10: Splitter enemy

> Backfilled from commit `a6c3229` after the Day 9–11 gap was caught during the 2026-04-25 content-planning sprint (lives in `content-engine/DEVLOG-NOTES.md`).

### What got built

- **Splitter enemy** — new type, hot pink, wave 4+, 15% per-slot probability (`Config.SPLITTER_CHANCE = 0.15`). Speed between Troll and Spammer (14 studs/s), HP 20, slightly bigger than Troll (`Vector3.new(3.2, 4.2, 3.2)`) so it visually reads as "the parent." Reward: 30 coins (highest non-child).
- **`SplitterChild` enemy** — distinct type spawned only by the Splitter ban hook. Carnation pink, smaller (size ratio 0.55), faster (speed ratio 1.35× the parent's *effective* speed, so wave multipliers carry through). RoundManager NEVER rolls SplitterChild → children can't recurse. Reward: 5 coins each (intentionally low — keeps Splitter from becoming a coin farm).
- **`spawnEnemy` extended** with optional `spawnPos`, `sizeOverride`, `speedOverride` for derived spawns. RoundManager only ever calls with `(typeName, speedMultiplier)`; the Splitter ban hook is the only caller using the override args.
- **Splitter ban hook** in `EnemySpawner.banEnemy.OnServerEvent` — runs BEFORE `Effects.HitFlash` and `Effects.BanEffect`, gated on `enemyPart.Name == "Splitter"`. Looks up the parent's data row to get `parentSpeed`, derives `childSpeed` and `childSize`, then spawns 2 children at angles `(0, π)` around the ban position (`SPLITTER_CHILD_OFFSET = 4` studs apart). `Effects.SplitEffect(banPos)` fires once per split, not per child.
- **`Effects.SplitEffect`** — pink particle puff (30 sparks, 1.8 → 0 size) plus the split sound (`rbxassetid://127599335301017`).
- **`CLAUDE.md` updated** to document the type-specific-ban-path-behavior pattern: keying off `enemyPart.Name`, override args for derived spawns, distinct child type that RoundManager never rolls.

### Decisions made (and why)

- **Children are a distinct type (`SplitterChild`), not "small Splitters."** RoundManager never picks SplitterChild from `pickEnemyType`. If children were Splitters, banning a child would spawn grandchildren — infinite recursion or a manual depth check. The type split makes recursion impossible by construction. Rejected: a `splitDepth` integer attribute on each enemy + a recursion limit — works but leaks the structural concern into runtime state.

- **Override args at the end of `spawnEnemy(typeName, speedMultiplier, spawnPos, sizeOverride, speedOverride)`.** RoundManager and the ban hook both call into the same function. Positional optionals at the end keep the common call (`spawnEnemy("Troll", 1.5)`) clean and the override case explicit. Rejected: a separate `spawnEnemyAt` for derived spawns — duplicates setup code that needs to stay in lockstep.

- **Child speed scales off `parentData.speed`, not `Config.SPLITTER_SPEED`.** When wave 6 hits and the parent is moving at `14 × 1.15^5 ≈ 28`, children should inherit that scaling. Reading the live data table preserves wave multipliers through the split. Hardcoding off Config would make late-wave splits feel weak.

- **Coin economy: parent 30, child 5.** Splitter is dangerous if left alive — the high reward justifies the risk. Children are 5 coins each (10 total per split), less than just letting the parent pay out (30). This means you get *more* coins by NOT splitting it (e.g., Mute → Timeout → ban after position is controlled). Coin design as gameplay design.

- **Hook fires before HitFlash / BanEffect, not after.** "One becomes many" reads cleanest when children appear in the same frame as the parent's flash. Fire-after would put a frame gap between disappearance and replacement; fire-before keeps the swap instant.

- **`Effects.SplitEffect` once per split, not per child.** Sound spam is ugly. The split is one event with two outcomes; one effect call matches the perception.

### What's intentionally not built yet

- **Variable child count.** Always 2. Could become a Config knob for a Phase 5 "Spam Storm" wave modifier, but defaulting to 2 is the cleanest version.
- **Inherited muted/frozen visuals on children.** A Splitter banned while Muted produces children whose speed already includes the slow (parent's effective speed × 1.35). The gameplay is correct; the children just don't *look* slowed. Cosmetic; deferred.

### Hooks for the post

Pick one. Not all.

- **"How to spawn enemies that can't recurse"** — distinct child type, RoundManager never picks it, the type split as a structural prevention instead of a depth counter. One enemy, one design pattern, evergreen.
- **"Inheriting speed across a split"** — children read speed from the parent's runtime `data.speed`, not from Config, so wave multipliers carry through. Five-line lesson on "use the live state, not the spec value."
- **"30 coins for the parent, 5 each for the kids: economy as a pacing tool"** — the math behind making the Splitter pay more if you DON'T split it. Concrete, specific, gameplay-design-flavored.
- **"One effect per event, not one per outcome"** — `SplitEffect` fires once per ban, not per child. The aesthetic argument for fewer-but-louder effect calls.

---

## 2026-04-25 — Day 9: Teleporter enemy + Kick aim fix

> Backfilled from commit `a419aca` after the Day 9–11 gap was caught during the 2026-04-25 content-planning sprint (lives in `content-engine/DEVLOG-NOTES.md`). The Day 8+9 entry below covers the toolkit/icons portion of Day 9; this entry covers the Teleporter and Kick aim fix that landed in the same commit but never made the previous entry.

### What got built

- **Teleporter enemy** — new type, bright violet, wave 3+, 20% per-slot probability (`Config.TELEPORTER_CHANCE = 0.2`). Slow on foot (10 studs/s, slower than Troll) but warps `TELEPORTER_DISTANCE = 22` studs toward the zone every 2.0s. Slightly bigger footprint than Troll (`Vector3.new(2.5, 3.5, 2.5)`).
- **`Effects.TeleportEffect(startPos, endPos)`** — two-anchor purple particle burst with a short PointLight glow at each end. Sound (`rbxassetid://133226202202712`) plays only at arrival; depart is silent. Sells the warp visually so players see what just happened instead of a silent jump.
- **EnemySpawner heartbeat** — Teleporter warp logic added. Per-enemy state (`typeName`, `nextTeleport`) lives on the `activeEnemies` data table next to `damageCooldown`, NOT on Roblox attributes. Frozen blocks the warp; Mute does NOT. `Effects.TeleportEffect` fires on every successful warp.
- **RoundManager `pickEnemyType`** — picks Teleporter first for wave ≥ 3 (20% roll), else Spammer (wave ≥ 2, 30%), else Troll. Order matters: highest-tier-eligible enemy gets first claim.
- **Coin reward** — `COIN_TELEPORTER = 25`, between Spammer (20) and the future Splitter (30). Harder to catch, pays a bit more.
- **Kick aim fix** — switched from server-side `HumanoidRootPart.CFrame.LookVector` to client-sent camera `LookVector`. Server now validates the received `Vector3` is roughly unit-length (`0.5 < magnitude < 1.5`) and horizontal (`abs(Y) < 0.5`); flattens it before using as the cone direction.
- **`KickBootScript.client.lua`** — reads `Workspace.CurrentCamera.CFrame.LookVector`, flattens to horizontal, normalizes, sends as `kickEnemies:FireServer(lookDir)`. Bails early if magnitude < 0.01 (player looking straight up/down — no horizontal aim).
- **`CLAUDE.md` updated** — documents the Kick aim exception to the server-authoritative rule, and the per-enemy-state-on-data-table-not-attributes pattern (Teleporter's `nextTeleport`).

### Decisions made (and why)

- **Per-enemy behavior state lives on the spawner's `activeEnemies` data table, not on attributes.** Attributes are reserved for status effects that need to be visible to handler scripts (Mute / Timeout / Kick). Teleporter's `nextTeleport` timer is a private spawner concern — exposing it as a Roblox attribute would invite handler scripts to read it, leak the implementation, and replicate to clients for no reason. Rule: attributes for cross-script-boundary state, data tables for private spawner state.

- **Frozen blocks the warp; Mute doesn't.** Timeout fully pauses an enemy — including its warp tick. Mute slows movement, but a muted user can still ghost-ping, so a slowed Teleporter should still warp. This makes Timeout the right counter to Teleporter and Mute deliberately weaker against this enemy type — adding gameplay differentiation without inventing a new mechanic.

- **Kick aim moves to a client-sent vector despite the server-authoritative rule.** Body rotation only updates when the player is moving — standing still + turning the camera leaves the body facing the previous direction. Cone aimed at stale facings; clicks did nothing; kick felt broken. The server can't read camera state, so the client has to send it. Server validates the vector is unit-length and horizontal; the kick is non-destructive (no damage, no rewards) so the worst-case spoof is "kicked enemies behind you" — a UX papercut, not an exploit. Documented the exception in `CLAUDE.md` so the rule's edges stay visible.

- **Two-anchor teleport burst with silent depart, audible arrive.** A symmetric audible burst would feel like one event. Silent vanish + audible arrive splits the perception of "where did they go?" / "oh — there." Reads as menacing instead of busy.

- **RoundManager picks Teleporter first, not last.** Picking from least-likely to most-likely (Teleporter 20% → Spammer 30% → Troll fallback) means the highest-tier-eligible enemy gets first claim. Order is the wave gating: that's what makes wave 3 feel different from wave 2.

### What's intentionally not built yet

- **Path variation.** Day 9–10's original scope mentioned path variation alongside enemy variety; Teleporter and Splitter shipped instead. Path variation deferred — possibly absorbed into the Phase 2 game-feel pass, or skipped if enemy variety alone is enough difference.
- **Teleport telegraph.** The warp is instant visually. A 0.2s pre-burst at the destination would let attentive players Timeout mid-windup. Filed but not shipped.

### Hooks for the post

Pick one. Not all.

- **"Why I broke the server-authoritative rule for one tool"** — the Kick aim fix story. Body-rotation aiming was UX-broken; client-camera vector with sanity validation is the working compromise. The threat model is the lesson: not every "send from client" is a vulnerability if the worst-case spoof is harmless.
- **"Per-enemy behavior state: when to use attributes and when to use a data table"** — the `nextTeleport` decision. Attributes for cross-script-boundary state, data tables for private spawner state. Concrete rule, concrete example.
- **"Timeout dominates, Mute slips through: differentiating counters via priority rules"** — Mute lets the warp fire, Timeout blocks it. One enemy type, two existing tools, a meaningful tactical difference. The status priority ladder rewarded the gameplay even though it was originally a refactor.
- **"Two-anchor teleport burst: vanish silent, arrive loud"** — small visual-design lesson. Symmetric effects feel like one event; asymmetric effects narrate the action.

---

## 2026-04-24 — Day 8 + 9: full moderation toolkit (Mute, Timeout, Kick) + hotbar icons

### What got built

- **Mute Gun (Day 8)** — slow status effect, end-to-end. New `Config.MUTE_*` block (range 20, cooldown 1.5s, slow factor 0.25, duration 5s, sound `rbxassetid://115994842117368`). New `MuteEnemy` RemoteEvent. New `Effects.MuteEffect(position)` — blue particle burst + sound. New `ServerScriptService/Enemies/MuteHandler.server.lua` validates `IsEnemy` attr, `IsDescendantOf(workspace)`, `Magnitude <= MUTE_RANGE * 1.5`, per-player cooldown, then sets `MutedUntil` (number) and `OriginalColor` (Color3) attributes on the enemy and recolors it to `Color3.fromRGB(70, 150, 255)`. New `StarterPack/MuteGun/` Tool — blue Part Handle, `MuteGunScript.client.lua` mirrors BanHammer's closest-target picker. `EnemySpawner.server.lua` heartbeat now reads `MutedUntil` and applies `MUTE_SLOW_FACTOR` while active, restores `OriginalColor` on expiry.
- **Timeout Card (Day 8.5)** — full freeze, copy of Mute Gun pattern with `speed = 0`. New `TimeoutEnemy` RemoteEvent. New `Effects.TimeoutEffect` (yellow burst, sound `rbxassetid://9119366743`). New `TimeoutHandler.server.lua` writes `FrozenUntil` + `OriginalColor`. New yellow flat-card Tool in `StarterPack/TimeoutCard/`. EnemySpawner status pass refactored to handle stacking: when Timeout expires with Mute still active, color drops back to mute blue, not OriginalColor. Frozen enemies also stall at the zone instead of ticking damage. Tuned post-build: `COOLDOWN` 3.0 → 2.5, `DURATION` 2.5 → 4.0 — freeze now saves more distance per cast (4.0s × 100%) than mute (5.0s × 75% = 3.75s effective), so the panic button beats the steady CC.
- **Kick Boot (Day 9)** — new pattern: AOE forward cone, instant impulse, non-destructive. New `KickEnemies` RemoteEvent (no payload — server re-derives cone from `HumanoidRootPart.CFrame.LookVector` so clients can't spoof angle). New `KickHandler.server.lua` filters enemies by `dir:Dot(LookVector) >= cos(30°)`, then writes `KickedUntil` (number) + `KickVelocity` (Vector3) per hit. Push direction is radial away from player so off-center enemies fan out, not bunch up. New `Effects.KickEffect` — green burst, sound `rbxassetid://140668097319606`. New `StarterPack/KickBoot/` Tool. EnemySpawner heartbeat got a priority ladder: **Kick > Timeout > Mute > seek**. Kicked enemies skip every other per-frame system, including zone damage, until the window expires. Tuned: `FORCE` 60 → 120 studs/s, `DURATION` 0.4 → 0.6s (≈72 studs of flight), particle burst bumped 20 → 40 sparks. Whiff fix shipped as separate commit: gate `Effects.KickEffect` on `hitCount > 0` so misses don't make sound.
- **Hotbar tool icons** — replaced default cube icons with custom 1024×1024 PNGs (Ban Hammer, Mute Gun, Timeout Card, Kick Boot). Generated via ChatGPT image gen, iterated on the prompt to fix three failure modes: (1) baked light/gray backgrounds → require transparent PNG explicitly, (2) text on icon ("BAN" word) → forbid letters because they become red mush at 64px, (3) all-purple-on-dark-hotbar Mute Gun → require one accent color contrasting the body. Final prompt enforces square canvas, transparent background, subject touches two opposite edges with ≤4% padding, no fine details, and explicit style continuity across the set. Cropped each PNG with Photopea's Image → Trim before upload to Roblox. `Tool.TextureId` set in Studio (CLAUDE.md already documents this is Studio-only — Rojo doesn't own it).

### Decisions made (and why)

**Attribute-as-timer pattern for status effects, not a central StatusEffects module.**
- Each handler writes one attribute pair: `<Name>Until` (number, for the timer) plus a snapshot for whatever it's about to mutate (`OriginalColor`, `KickVelocity`). EnemySpawner's heartbeat is the sole reader. One writer, one reader. Adding Stun or DoT later means: write a new attribute, add a branch in the heartbeat priority ladder. No central registry to keep in sync.
- Tradeoff: when statuses interact (Timeout-while-Muted, Kick-while-anything), EnemySpawner has to know the precedence rules. With three statuses that's manageable; if it grows past five, this approach starts to creak.

**Status priority ladder: Kick > Timeout > Mute > seek.**
- Kick is an impulse — gating it behind status checks defeats "knock them flying." Timeout strictly dominates Mute (freeze > slow), so the strong one drives both visual and speed when both timers run. When Timeout expires while Mute is still ticking, color drops to mute blue, not OriginalColor — preserves the "still affected" visual without a third state machine.

**Frozen enemies stall zone damage, not just movement.**
- Edge case: enemy reaches zone, gets timed-out at the last moment. Natural read is "they're paused" — including paused on damage ticks. Five-line change. Without it, Timeout feels half-applied.

**Kick payload is empty; server reads the player's facing direction.**
- Client just calls `kickEnemies:FireServer()`. Server reads `HumanoidRootPart.CFrame.LookVector` directly. Stops a malicious client from sending a 360° cone parameter. Same authority principle as range validation, applied to geometry instead of distance.

**Vector3 attribute for `KickVelocity`, not three numbers.**
- Per-enemy push direction varies (radial from player), so couldn't compress to a single magnitude. Roblox attributes support Vector3 natively, so this just works. Worth knowing for future "directional" status effects.

**Whiff fix: Kick effect only fires on hit, matching Ban / Mute / Timeout.**
- Original behavior fired sound + particles on every cast regardless of contact — felt off because whiffs made noise but accomplished nothing. Inconsistent with the other three tools, which all gate effects on validation success. Now gated on `hitCount > 0`. Open question: should whiffs get a *visual* burst (cast confirmation) without sound? Filed as polish option, not shipped.

**Tool icon prompt — explicit constraints beat aesthetic guidance.**
- "Make it look cool" produces beautiful 1024×1024 art that becomes unreadable at 64×64. The constraints that mattered: no text on icon, subject touches two opposite edges, one accent color contrasting the body, transparent background, square canvas. Style continuity is enforced as a separate rule because a 4-icon set with mismatched outline weights reads as four random tools, not "the moderator's loadout."

**Photopea trim before upload, not post-upload tweaking.**
- Image generators always pad. Trimming the transparent border on the source PNG (Image → Trim → Transparent Pixels) is faster than fighting it in Studio with `ImageRectOffset` (which doesn't apply to `Tool.TextureId` anyway). One step, repeatable per icon.

### What's intentionally not built yet

- **Custom hotbar UI with hover/animated states.** The default Roblox CoreGui backpack only renders `Tool.TextureId` — no hover, no equip animation, and the blue selection ring overlaps the slot number when a tool is equipped. The user's reference grid (idle / hover / animated) needs a custom `ScreenGui` that disables `Enum.CoreGuiType.Backpack`, watches `Player.Backpack`, draws ImageButtons per tool, and runs TweenService on hover/equip. Real chunk of work — scheduled Phase 5 (Days 23–24, "UI cleanup"). Default hotbar deferred until then.
- **Mute Gun → real aim-and-shoot.** Currently picks closest `IsEnemy` part in a 20-stud sphere. Doesn't feel like a gun. Already filed in `docs/plan.md` §9 backlog with three upgrade paths (mouse raycast / forward cone / projectile).
- **Kick whiff visual feedback.** Now silent on miss. A visual-only burst (no sound) would confirm the cast went through without re-introducing audio spam. Two-line change, deferred.
- **Kick Y-axis lift.** Enemy `BodyVelocity.MaxForce.Y = 0`, so any upward push gets ignored by the physics. Cartoon-y vertical pop would make Kick more dramatic but requires temporarily raising MaxForce.Y during the kick window. Current horizontal-only push already reads as chunky after the FORCE/DURATION tune.
- **Days 9–10 enemy variety.** Teleporter enemies that warp forward 10 studs every few seconds, splitter enemies that spawn two smaller ones when banned, path variation. Real Day 9–10 scope; this session shipped tools instead.

### Blockers for next session

- None. Toolkit + icons are stable. Days 9–10 enemy variety is fully unblocked.

### Hooks for the post

Pick one. Not all.

- **"One writer, one reader: status effects without a manager class"** — the attribute-as-timer pattern across Mute → Timeout → Kick. Why it stays clean without a central StatusEffects module, where it'll break (when two effects need to write the same attribute), and the precedence rules baked into EnemySpawner.
- **"Kick > Timeout > Mute: a status priority ladder in 30 lines"** — three different effect types (slow, freeze, impulse) coexist via one heartbeat with explicit precedence. The order matters: the impulse has to run first or it gets overwritten by the slow/freeze logic.
- **"Empty payload kick: never trust client geometry"** — why the Kick RemoteEvent sends nothing and the server reads the player's `LookVector` directly. Same principle as range validation, applied to angle. The vulnerability if you don't.
- **"Whiffs need feedback or they don't"** — the bug (sound on miss) and the half-fix (now totally silent on miss). Honest answer is visual-without-audio on whiff, but the half-fix matched the other three tools, so it shipped first.
- **"Why your Roblox tool icon looks tiny: it's not the asset, it's the padding"** — Photopea trim workflow + the prompt rule that AI image generators always pad. The 30-second fix that makes a 1024×1024 PNG actually fill a 60×60 hotbar slot.
- **"TextureId is Studio-only and that's fine"** — when to fight Rojo and when to live with one-click Studio steps. Tool icons are Studio-side because there's no clean Rojo path for image asset IDs.

---

## 2026-04-23 — Day 7: hit flash, camera shake, swing animation, visible hammer

### What got built

- **Hit flash** — new `Effects.HitFlash(part)` in `ReplicatedStorage/Shared/Effects.lua`. Flips `IsEnemy` off, anchors the part, makes it Neon white, kills its `BodyVelocity`, `Debris:AddItem` at 0.15s. Wired in `EnemySpawner.server.lua` ban handler — runs before `Effects.BanEffect(...)` so the frame sequence is flash → particles → popup → gone.
- **Camera shake** — client-side, in `StarterPack/BanHammer/BanHammerScript.client.lua`. `RunService.RenderStepped` drives `Humanoid.CameraOffset` with a falloff over 0.18s, magnitude 0.35, debounced with `shakeActive` so rapid bans don't stack. Only shakes when a target is actually hit, not on empty swings.
- **Swing animation** — loads on `Tool.Equipped` via `Humanoid:FindFirstChildOfClass("Animator"):LoadAnimation(anim)`, stopped/destroyed on `Unequipped`. `AnimationPriority.Action`. Plays on every `Activated` regardless of whether a target is in range (the swing itself is feedback). Asset ID `rbxassetid://522635514` (toolbox, confirmed working). Speed is `Config.BAN_SWING_SPEED = 1.5`.
- **Visible 3D hammer** — added `Handle.model.json` (wood shaft, `0.8 × 4 × 0.8`, dark brown) and `Head.model.json` (metal, `2.5 × 1.4 × 1.8`, red, `Massless = true`). `BanHammerSetup.server.lua` positions the head on top of the handle with a small overlap and parents a `WeldConstraint` to the handle. `init.meta.json` flipped `RequiresHandle` to `true`.
- **New Config values** — `BAN_SWING_ANIM_ID`, `BAN_SWING_SPEED`.
- **Rojo BrickColor fix** — Rojo 7.6 refuses `"BrickColor": "Really black"` for a Part's color property with "Wrong type of value for property Part.BrickColor. Expected BrickColor, got a string." Switched to `"Color": [0.12, 0.08, 0.05]` (Color3 array, 0–1 floats) everywhere in the hammer parts.

### Decisions made (and why)

**Use `Humanoid.CameraOffset` for shake, not direct `camera.CFrame` writes.**
- First draft tweened the camera CFrame directly. That fights Roblox's built-in camera controller (follow cam, zoom, first/third-person toggles) — the shake either gets overwritten or accumulates. `CameraOffset` is additive and the controller respects it. Zero integration work.

**Swing plays on every Activated, not just on hits.**
- The swing is player-side feedback. Gating it behind "hit a target" means whiffs feel dead. Camera shake stays gated to hits — that's impact feedback, different signal.

**Camera shake is client-local, not server-broadcast.**
- Shake belongs to the banning player. If I fired a shake event from the server, every client would shake on every other player's ban. Multiplayer footgun avoided early.

**Massless head + handle-driven weight.**
- `Massless = true` on the Head so the Tool's grip physics is driven entirely by the Handle. Avoids the tool flopping weirdly because the head outweighs the grip point.

**Color3 array in `.model.json`, not BrickColor string.**
- Rojo's `.model.json` resolver for Part.BrickColor expects a real BrickColor value and a string like "Really black" fails even though it's a valid BrickColor name. Color3 arrays with 0–1 floats work reliably. Rule: default to `Color` + Color3, skip `BrickColor` in `.model.json`.

### What's intentionally not built yet

- **Bulletproofed UI styling.** `HealthLabel`, `CurrencyLabel`, `WaveLabel`, `UpgradeButton` `.model.json` files still only own `Text`. Studio-side `UIPadding`/`UICorner` children got wiped mid-session when the place file was rebuilt. Need to rewrite these model.json files to own Size/Position/AnchorPoint/colors + nested `UIPadding`/`UICorner`. Deferred because it needs the user's preferred styling values.
- **Map polish.** Only `EnemyStart` and `ServerZone` parts exist. The default Roblox `SpawnLocation` sits in the middle of the lane and enemies sometimes collide with it. Full map work is scheduled Phase 5 (Days 23–24). Could do a 30-second spawn reposition earlier if needed.
- **New tools (Mute Gun, Timeout, Kick).** Day 8 scope.

### Blockers for next session

- Need user's preferred UI styling values before rewriting the MainUI `.model.json` files (option B from the UI discussion).
- Need decision on whether to move/hide the default `SpawnLocation` now or wait for Phase 5.

### Hooks for the post

Pick one. Not all.

- **"Humanoid.CameraOffset is the right way to shake a Roblox camera"** — why writing camera CFrames directly fights the built-in controller, and how one property avoids every edge case.
- **"The swing is feedback, the shake is impact"** — gating rules for tool effects. What happens on every activation vs what happens only on hits, and why conflating the two makes the whole tool feel dead.
- **"Color3 beat BrickColor: a Rojo .model.json gotcha that wastes 20 minutes"** — the exact error, why the BrickColor string doesn't resolve, and the one-line rule to avoid it.
- **"A visible hammer in five minutes: Part + Part + WeldConstraint"** — how minimal the bar is for "that tool looks like a hammer now," and why Massless on the head matters.
- **"When fix-the-small-thing becomes rewrite-the-tool: reading intent on Day 5"** — callback to the aborted Day 5 hammer rewrite. The small-diff discipline that saved Day 7.

---

## 2026-04-23 — Day 6: ban effects (particles + coin popup + sound)

### What got built

- `ReplicatedStorage/Shared/Effects.lua` — new module. Single public function `Effects.BanEffect(position, reward)` that fires particles + plays sound + spawns floating text. Self-cleans via `Debris:AddItem`.
- **Particle burst** — 25 red sparks in a full sphere around the ban point. Lifetime 0.4–0.8s, fades + shrinks.
- **Floating `+N` coin popup** — `BillboardGui` on an invisible anchor part, `GothamBold` gold text, tweens up 3 studs and fades over ~0.9s. Shows the reward where it was earned.
- **Ban sound** — toolbox bonk SFX wired via `Config.BAN_SOUND_ID` + `Config.BAN_SOUND_VOLUME`. Effects code plays silently if ID is an empty string.
- **Wired into `EnemySpawner.server.lua`** — captured `enemy.Position` before `:Destroy()` (destroyed parts have meaningless Position), then `Effects.BanEffect(banPos, reward)` fires after coin award.
- **Server-side effects** — instance creations in `workspace` replicate automatically. All players see and hear every ban.

### Decisions made (and why)

**One effect module, one public function per event.**
- Growth is linear, not quadratic. Day 7 adds `HitFlash`, Day 8 will add `MuteEffect`, etc. Same cleanup model, same file, same call signature pattern `(position, ...)`. No scattered `Instance.new("ParticleEmitter")` across systems.

**`Debris:AddItem` beats `task.delay(..., function() x:Destroy() end)`.**
- Fewer closures, reliable cleanup even if the script errors mid-effect, built into the API surface. Replaced the first-draft `task.delay` version after writing it.

**Config-driven asset IDs.**
- `Config.BAN_SOUND_ID` is one string. Swapping the bonk sound is a one-line diff with no Lua changes. Same pattern already worked for numeric tuning — no reason asset IDs should be different.

### Hooks for the post

Pick one. Not all.

- **"Game feel is a force multiplier on work you've already done"** — how one day of polish made five days of mechanics feel fresh. Nothing balance-wise changed. The game felt 10× better.
- **"One effect module, one public function per event"** — module design rule that keeps the effects layer linear as the tool count grows.
- **"Config-driven asset IDs: the one-line-diff principle"** — why asset IDs belong in Config alongside tunable numbers, not buried in effect code.
- **"`Debris:AddItem` vs `task.delay`: the cleanup primitive I kept writing by hand"** — small API-discovery story, single-commit refactor.

---

## 2026-04-21 — Day 5: win condition, wave banner, Phase 1 close

### What got built

- **Win condition** — `Config.WAVES_TO_WIN = 5`. `GameManager.Win()` fires a new `GameWon` RemoteEvent. Client shows `VICTORY` in green. Spawning halts.
- **`WaveLabel`** — one `TextLabel` under MainUI, four states: `Wave 2 / 5`, `Wave 3 / 5 in 7s`, `VICTORY`, `Run ended`. Driven entirely by the server.
- **Break countdown** — `RoundManager.server.lua` ticks `WaveBreak:FireAllClients(nextWave, total, secondsLeft)` every second. Dead air between waves became a "3…2…1…" moment.
- **`GameManager.IsGameOver()` covers both loss and win.** Every downstream guard (`if IsGameOver() then return end` in spawning, damage, ban validation) halts cleanly in both outcomes without a separate flag.
- **Hotbar icon polish** — uploaded a gavel image as `TextureId` on the `BanHammer` Tool. Fixed the "BanHamm er" wrapped-text gray-square hotbar slot.

### Decisions made (and why)

**`IsGameOver()` returns true for both loss and win.**
- Every existing check was "stop processing if the run is over." Loss and win are both "run over" as far as those guards care. One function, one predicate, zero new flags. Rejected adding a separate `IsGameWon()` gate to every check site.

**Single `WaveLabel` with multiple states, not four UI elements.**
- Wave counter / countdown / VICTORY / Run ended are mutually exclusive. One label reads cleanly, no Z-ordering puzzle, no "which label is currently visible" state.

**Tool `TextureId`, not a full 3D hammer rebuild.**
- The user asked to fix the hotbar icon. I misread it as a structural hammer request and built Handle + Head + weld before realizing. Reverted in two minutes. Rule: when someone says "fix the small square," don't rewrite the tool.

### What's intentionally not built yet

- **Visible 3D hammer** — aborted on Day 5, shipped on Day 7 when explicitly requested.

### Hooks for the post

Pick one. Not all.

- **"Phase 1 closed in five days and ~350 lines of Luau"** — what made the five days actually work, vertical slices over horizontal layers, testing every 5–10 minutes.
- **"One predicate, two end-states: the `IsGameOver` shortcut"** — why collapsing loss + win into the same "run over" guard saved a refactor.
- **"When 'fix the small square' doesn't mean 'rewrite the tool'"** — reading user intent at small-diff granularity. A postmortem on the aborted hammer build.

---

## 2026-04-21 — Day 4: currency, first upgrade, UI polish

### What got built

- **Coins per ban** — 10 for Trolls, 20 for Spammers. Reward lives on the enemy part as a `Reward` attribute so new enemy types just declare their bounty when they spawn.
- **Player attributes for replication** — `Coins`, `CooldownLevel`, `BanCooldown` stored as Player attributes. Roblox replicates attributes automatically. Client listens with `GetAttributeChangedSignal("Coins")` instead of a RemoteEvent.
- **`CurrencyManager` ModuleScript** in `ServerScriptService/Systems/`. Owns per-player economy state. Exposes `AddCoins`, `TryPurchaseCooldown`. Wires `PurchaseUpgrade.OnServerEvent`.
- **First upgrade: Faster Ban Hammer.** 3 levels, costs 50 / 100 / 150. Each level shaves 0.1s off `BanCooldown` (floor 0.1s). Level 3 hits `Ban Hammer: MAXED` and the button stops responding.
- **UI layout** — coins top-left (gold), health top-center, upgrade button top-right (anchored `{1, 0}`). `UIPadding` + `UICorner` added to both new elements.

### Decisions made (and why)

**Player attributes replace RemoteEvents for per-player state.**
- Coins, upgrade levels, cooldowns are "per-player state the client renders." Attributes replicate server→client automatically. I was about to wire a `CurrencyChanged` RemoteEvent before noticing this — pointless plumbing. Same pattern will cover future buffs / selected tool / etc.

**Upgrade button top-right, not bottom-center.**
- First placement was bottom-center. The player's own character kept occluding it in third-person. Anchoring to `{1, 0}` (top-right corner) fixed it in 30 seconds. `AnchorPoint` is underrated.

**Server-authoritative cooldown via attribute.**
- Client reads `player:GetAttribute("BanCooldown")` for instant feel. Server enforces the real cooldown against the same attribute. Buying the upgrade mutates one number — both sides pick it up without additional wiring.

### Hooks for the post

Pick one. Not all.

- **"Player attributes replace half your RemoteEvents"** — the discovery that killed a three-RemoteEvent scaffold before it shipped.
- **"`AnchorPoint` is underrated"** — 30-second fix for the "character keeps occluding my UI" problem.
- **"Shared state, one source of truth: the cooldown attribute"** — how client feel and server authority both read from the same Roblox attribute.

---

## 2026-04-21 — Day 3: second enemy type + real wave system

### What got built

- **`Spammer` enemy type** — orange, smaller, 2× Troll speed, glass-cannon health. Forces prioritization.
- **`RoundManager` wave system** — wave 1 = 5 enemies. Each wave adds 3 more and multiplies enemy speed by 1.15× (compounding). 8-second break between waves.
- **Spammer gated to wave 2+.** 30% chance per slot. Wave 1 stays pure Trolls as a Ban Hammer tutorial.
- **Refactored all enemy matching to `IsEnemy` attribute** instead of `Name == "Troll"`. Ban Hammer now works on every enemy type automatically, including ones not built yet.
- **`RoundManager` ↔ `EnemySpawner` handoff** — two narrow `BindableFunction`s. RoundManager says "spawn one Spammer at 1.3× base speed," EnemySpawner builds it. RoundManager polls `GetActiveCount` until wave clears, then starts the break timer.
- **Fixed invisible `HealthLabel`** — Rojo's `.model.json` creates a `TextLabel` at `Size = {0,0},{0,0}`. One Studio properties pass to visible, top-center.

### Decisions made (and why)

**Attribute-based enemy detection (`IsEnemy`), not name matching.**
- Every new enemy type would otherwise need a new name check in three places (ban handler, damage code, spawn tracking). An attribute is one line at spawn, zero lines at every matcher. Also carries `Reward` the same way — makes coin award data-driven (relevant for Day 4).

**Two-function BindableFunction API between Rounds and Enemies.**
- `RoundManager` decides **when** and **what** (waves, timing, enemy mix). `EnemySpawner` decides **how** (build, move, damage). Communication is two named calls. Changing wave pacing or adding a third enemy type touches one file.

**Wave 1 is pure Trolls.**
- A "learn the tool" wave before chaos arrives. Spammers would punish new players before they understand the Ban Hammer has a cooldown.

### Hooks for the post

Pick one. Not all.

- **"Attribute-based matching beats name matching"** — why hardcoded `Name == "Troll"` checks are a tax you don't have to pay, and the one-line refactor that paid it off.
- **"Separation of concerns pays off fast: adding an enemy type in under a minute"** — the `RoundManager` / `EnemySpawner` split and how the two-function handoff kept it clean.
- **"Rojo's zero-default TextLabel: a five-minute bug with a five-second fix"** — `.model.json` creates UI at zero size. Always check Size first.

---

## 2026-04-21 — Day 2: core loop + Rojo detour

### What got built

- **`Config.lua`** — every tunable number lives here. `ReplicatedStorage/Shared/Config`.
- **`GameManager.lua`** (ModuleScript) — owns server health. `TakeDamage()` is the only entrypoint. Fires `HealthChanged` / `GameOver` RemoteEvents.
- **`EnemySpawner.server.lua`** — spawns Trolls at `EnemyStart`, moves them toward `ServerZone` via `BodyVelocity`, damages server when they arrive.
- **`ClientMain.client.lua`** — listens for `HealthChanged` / `GameOver`, updates `HealthLabel`.
- **`BanHammerScript.client.lua`** — click fires `BanEnemy:FireServer(enemyPart)`. Server validates and destroys.
- **Rojo helpers** — `Remotes.model.json` (Remotes Folder + 3 RemoteEvents), `MainUI/init.meta.json` (ScreenGui, `ResetOnSpawn = false`), `HealthLabel.model.json`.

### Decisions made (and why)

**`Workspace` is removed from the Rojo tree.**
- Original `default.project.json` had `Workspace.Map → src/Workspace/Map`. `src/Workspace/Map/` was empty. On every reconnect, Rojo enforced the match — any Parts placed under `Workspace.Map` in Studio would be wiped. Didn't destroy Day 1 work (different file), but would have eaten any new map geometry. Map now lives Studio-only (not version-controlled). Scripts/UI/Remotes stay Rojo-managed.

**Runtime objects via `.model.json` / `.meta.json`, not "create it in Studio manually."**
- If the place file ever dies, `rojo serve` rebuilds the RemoteEvents, the ScreenGui, the HealthLabel automatically. Only map geometry (two Parts) is manual-rebuild territory.

**Server-authoritative ban.**
- Client picks a target and fires `BanEnemy:FireServer(enemyPart)`. Server validates name, parent, and player distance against `BAN_RANGE * 1.5` before destroying. Tolerance covers latency. Keep this pattern for every future destructive tool — never let the client `:Destroy()` enemies directly.

**`GameManager` is a ModuleScript, not a Script.**
- `EnemySpawner` needs to `require()` it. A `Script` can't be required. Silent class-mismatch footgun — the file suffix `.server.lua` vs `.lua` is the whole difference.

### What's intentionally not built yet

- **Wave system.** `RoundManager` exists only as a stub. Day 3 scope.
- **Second enemy type.** Day 3 scope.
- **Currency / upgrades.** Day 4 scope.

### Blockers for next session

- Map Parts (`EnemyStart`, `ServerZone`) must exist in `Workspace.Map` as anchored Parts, or `EnemySpawner` hangs forever on `WaitForChild`. Manual Studio step, one-time.

### Hooks for the post

Pick one. Not all.

- **"Rojo will wipe your map if you point it at an empty folder"** — the `Workspace.Map → src/Workspace/Map` bug, how empty-source-wipes-Studio works, and the rule that keeps map geometry safe.
- **"What Rojo owns vs what Studio owns: the split ownership model"** — scripts/UI/Remotes as version-controlled, map geometry as Studio-local, and why mixing the two rules breaks things.
- **"Never trust the client to delete enemies: server-authoritative destructive actions"** — the validation pattern in the ban handler and why the 1.5× range tolerance exists.
- **"ModuleScript vs Script: the `.lua` / `.server.lua` footgun"** — how one filename suffix caused a silent `require()` failure.

---

## 2026-04-20 — Day 1: project scaffold + Rojo setup

### What got built

- Repo at `E:\Roblox Development\discord-mod-simulator\`, git initialized.
- Rojo 7.6.x wired. `default.project.json` maps `src/ReplicatedStorage`, `src/ServerScriptService`, `src/StarterPlayer/StarterPlayerScripts`, `src/StarterGui`, `src/StarterPack` into their Studio counterparts.
- Initial folder structure: `ServerScriptService/{Systems, Enemies, Rounds}`, `ReplicatedStorage/Shared`, etc.
- Minimal Studio map placed directly in Roblox (`DiscordModSimulator.rbxl`, archived; no map data on disk).

### Decisions made (and why)

**Rojo-first workflow.**
- Source of truth lives on disk, not in Roblox's `.rbxl` binary. Future "I lost my place file" scares become `rojo serve` runs.

**Folder layout mirrors the system split.**
- `Systems/`, `Enemies/`, `Rounds/` under `ServerScriptService` so one-system-per-script scales to many scripts without a flat pile.

### Hooks for the post

Pick one. Not all.

- **"Day 1 of a 30-day Roblox build"** — scaffold recap, the Rojo setup, the folder layout decision, and what's intentionally deferred to Day 2.
- **"Why I put Roblox source in git, not just the .rbxl"** — the argument for Rojo on a solo project, and the one bug (day 2) that vindicated it.

---

## BACKLOG

Items deferred from a session for future reconception or reschedule. Not dated. Move back into a dated entry once they ship or are abandoned.

### Clip 08 — server trust boundary

- **Status:** Filed 2026-04-25, deferred from Sunday recording.
- **Original premise (false):** "Empty packet, server-derived geometry — the client says 'I kicked' and the server figures out the rest."
- **Why it's wrong:** Per `CLAUDE.md` and `KickHandler.server.lua`, kick aim is the *documented exception* to server-authoritative — the client sends a flattened `CFrame.LookVector` Vector3 payload because the server can't read camera state. `KickBootScript.client.lua:37` does `kickEnemies:FireServer(lookDir)`. Was never not the case in committed history.
- **Reconception paths:**
  - Pivot the clip to `BanEnemy` — actually server-validated (server checks `IsEnemy`, range ≤ `BAN_RANGE * 1.5`, server-side cooldown via `BanCooldown` attribute before destroying).
  - Or: write a "trust boundaries" clip that *names* the kick exception explicitly — "the one place I let the client win, and why."
- **Block before re-pitch:** decide which framing first; don't film without a clear angle.

### Clip 10 — milestone recap / line count animation

- **Status:** Filed 2026-04-25, rescheduled to end of Phase 2 (around Day 12 close).
- **Why deferred:** Animated milestone-table is editor-heavy with no committed scaffold-only state for the "Day 1" frame. Recap clips work better with an established audience to recap *for*.
- **Numbers cached (2026-04-25):** 1,691 Lua LOC across 15 `.lua` files in `src/`. Re-tally on the day.
- **Re-pitch shape:** "Phase 2 in N days" companion piece — concrete deliverables list (8-tool toolkit, 4 enemy types, wave system, currency, upgrades v0, run-end states) over the line-count animation. Phase boundary, not arbitrary day boundary.
