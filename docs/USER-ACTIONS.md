# USER-ACTIONS.md — Manual Steps Runbook

Tasks that Claude can't do for you (Roblox Studio interactions, Creator Hub website work, real-device testing, git pushes). Each section says **when**, **why**, **steps**, and **how to verify**.

Index — quick reference:

| Day / Phase | Action | Section |
|---|---|---|
| Each commit | Publish update to Roblox | [§A](#a-publishing-updates) |
| Day 19 (one-time) | Create 3 gamepasses on Creator Hub | [§B](#b-creating-gamepasses) |
| Day 20 (one-time) | Create 4 dev products on Creator Hub | [§C](#c-creating-dev-products) |
| Day 19–20 | Test R$ purchases in Studio | [§D](#d-testing-r-purchases-in-studio) |
| Day 23 | Build the new map in Studio | [§E](#e-building-the-map-in-studio) |
| Day 23 | Apply lighting recipe in Studio | [§F](#f-lighting-recipe) |
| Day 24 | Real-device touch testing (iPad/iPhone) | [§G](#g-real-device-touch-testing) |
| Day 26–27 | Multiplayer test (Studio Local Server) | [§H](#h-multiplayer-studio-testing) |
| Phase 5 close | Push commits to GitHub origin | [§I](#i-pushing-to-origin) |
| Phase 6 (later) | Save place to Roblox + ship | [§J](#j-launch-checklist) |

---

## §A — Publishing updates

**When:** after every commit that changes gameplay (almost every commit).

**Why:** the published place on Roblox runs the version *uploaded* to Roblox, NOT the version on your disk. `rojo serve` only syncs to your local Studio session. To make changes show up for players, you have to upload.

**Steps:**

1. In VS Code or terminal, run `rojo build -o "discord-mod-simulator.rbxlx"` to produce a fresh place file from the latest `src/`.
2. Open `discord-mod-simulator.rbxlx` in Roblox Studio (double-click or File → Open).
3. **File → Publish to Roblox** (NOT "Save to Roblox" — that creates a new place; we already published Day 13).
4. Studio uploads the place file to your existing experience. You should see a "Published successfully" toast.

**Verify:** open the experience on the Roblox website (browser) and click Play. Confirm the new behavior appears.

**Common gotcha:** if you accidentally click "Save to Roblox As" instead of "Publish to Roblox", you'll create a NEW experience instead of updating the existing one. The placeId in the local file will silently change. If this happens, undo via File menu's "recent places" or re-open the original place from Roblox.

---

## §B — Creating gamepasses

**When:** Day 19, **before** you test gamepasses in Studio. One-time setup.

**Why:** Gamepass IDs come from the Roblox Creator Hub website. The code references them via `Config.GAMEPASSES`, but the IDs are placeholder zeros until you create them and paste the real IDs in.

**Steps:**

1. Go to [create.roblox.com](https://create.roblox.com).
2. Click your **Creations** → find **Discord Mod Simulator** → click it.
3. Left sidebar → **Monetization** → **Passes** → **Create a Pass**.
4. For each of the 3 gamepasses below, fill in:

| Pass | Name | Description | Price | Image |
|---|---|---|---|---|
| 1 | `Double Coins` | "Earn 2× coins from every kill, forever. Stacks with combo bonuses for up to 4× coins per frozen-target kill." | 199 R$ | (Optional — square 512×512 PNG, gold coin stack on yellow/black bg) |
| 2 | `Faster Cooldowns` | "All your moderation tools cool down 30% faster. Stacks with cooldown level upgrades." | 299 R$ | (Optional — clock icon on yellow/black bg) |
| 3 | `Starter Pack` | "Skip the early grind. Instantly unlock Mute Gun, Kick Boot, and Timeout Card, plus 500 coins. One-time bonus on first claim." | 499 R$ | (Optional — toolbox icon on yellow/black bg) |

5. After each pass is created, click it in the **Passes** list → copy the **ID** from the URL or the page (it's a number like `1234567890`).
6. Open `src/ReplicatedStorage/Shared/Config.lua`, find the `Config.GAMEPASSES` table, and **replace the `id = 0` placeholders with the real IDs**.

**Verify:** in Studio command bar, run:
```lua
print(game:GetService("MarketplaceService"):GetProductInfo(YOUR_PASS_ID, Enum.InfoType.GamePass))
```
Should print a table with the pass info. If it errors with "Asset not found", the ID is wrong.

**After IDs are pasted:** rojo build, publish (§A), then test (§D).

---

## §C — Creating dev products

**When:** Day 20, before testing dev products. One-time.

**Why:** Same as gamepasses — Creator Hub creates them, code references the IDs.

**Steps:**

1. [create.roblox.com](https://create.roblox.com) → Discord Mod Simulator → **Monetization** → **Developer Products** → **Create a Developer Product**.
2. For each of the 4 products below:

| Product | Name | Description | Price |
|---|---|---|---|
| 1 | `Instant Revive` | "Restore your server's health to full mid-run. Use it when you're about to lose to save your wave streak." | 99 R$ |
| 2 | `Coin Pack — Small` | "Get 100 coins instantly. Great for unlocking your first tool." | 49 R$ |
| 3 | `Coin Pack — Large` | "Get 500 coins instantly — a full wave-5 clear's worth." | 199 R$ |
| 4 | `XP Boost (10 min)` | "Earn 2× XP for the next 10 minutes. Level up faster." | 99 R$ |

3. Copy each product's **ID** (numeric, from the URL or product page).
4. Open `Config.lua`, find `Config.DEV_PRODUCTS`, replace placeholder IDs.

**Verify:** in Studio command bar:
```lua
print(game:GetService("MarketplaceService"):GetProductInfo(YOUR_PRODUCT_ID, Enum.InfoType.Product))
```

---

## §D — Testing R$ purchases in Studio

**When:** Day 19 (gamepasses), Day 20 (dev products), and any time you change purchase flows.

**Why:** R$ purchases work in Studio playtest BUT no real Robux are charged. Studio simulates the full purchase flow.

**Steps for gamepass test:**

1. Build + publish current code (§A).
2. Studio → Play.
3. Click your "Shop" button → click "Buy" on a gamepass row.
4. Roblox shows the standard purchase prompt with R$ price.
5. Click **Buy**. In Studio, this completes instantly (no real R$). `PromptGamePassPurchaseFinished` fires with `wasPurchased = true`.
6. Confirm: gamepass effect activates immediately (e.g., Double Coins → kill an enemy and watch coins double).
7. **Stop and Play again** — gamepass should still show OWNED (cached in DataStore via schema v5).

**Steps for dev product test:**

1. Same as above, but click "Buy" on a dev product row.
2. Confirm the effect (e.g., Coin Pack Small → +100 coins instantly).
3. Stop and Play — dev product effect is consumable, should NOT persist (revive, coin pack, XP boost are all one-shot).

**Common gotcha:** Studio playtest sometimes silently rejects purchases if the placeId doesn't match the gamepass's parent. If a purchase prompt says "This item is not for sale," verify you're playing in the published place (not a fresh `rojo build`'d local file with PlaceId=0).

---

## §E — Building the map in Studio

**When:** Day 23.

**Why:** `Workspace` is intentionally NOT in the Rojo tree (see `state.md` §2). Map geometry lives in Studio only. We don't version-control it but `docs/MAP-LAYOUT.md` (Claude will write this on Day 23) describes the exact parts so you can rebuild from notes if the place file is ever lost.

**Steps:**

1. Open `MAP-LAYOUT.md` (Day 23 deliverable). It lists each map element: name, position, size, color, material.
2. In Studio: Workspace → Map folder (already exists for `EnemyStart` and `ServerZone`).
3. For each new element in the spec:
   - Insert → Object → `Part`
   - Anchor it (Properties → Anchored = true)
   - Set Position, Size, Color, Material per spec
   - Rename to spec name
   - Move into Workspace → Map folder
4. Save the place file (Ctrl+S — saves locally) AND publish (§A) so the new map ships to players.

**Verify:** Play. Walk around. Map elements appear, enemies path correctly through them.

---

## §F — Lighting recipe

**When:** Day 23.

**Why:** Lighting properties aren't in the Rojo tree; they're set on the `Lighting` service in Studio Properties panel.

**Steps:**

1. Studio → Explorer → click `Lighting` service.
2. In Properties panel, set:
   - **Ambient**: `[26, 26, 30]` (RGB) — slight blue-grey ambient
   - **OutdoorAmbient**: `[40, 36, 26]` — warm yellow tint
   - **Brightness**: `1.5`
   - **ClockTime**: `15` (afternoon — softer shadows)
   - **GlobalShadows**: `true`
   - **Technology**: `Future` (best lighting; if perf is an issue on mobile, switch to `ShadowMap`)
   - **EnvironmentDiffuseScale**: `0.4`
   - **EnvironmentSpecularScale**: `0.5`
3. Add a child to Lighting:
   - Insert → Object → `ColorCorrectionEffect`
   - Saturation: `0.15`
   - Contrast: `0.1`
   - TintColor: `[255, 240, 200]` — slight warm yellow tint matching brand

4. Save + publish (§A).

**Verify:** Play. Map should feel warmer and slightly higher contrast. Yellow brand accents should pop more.

---

## §G — Real-device touch testing

**When:** Day 24, after the touch controls commit lands.

**Why:** Studio's Test → Device emulator approximates layout but doesn't reproduce real touch input. The only way to know if touch actually feels good is to play on an actual device.

**Steps:**

1. Build + publish (§A).
2. On your iPad/iPhone, open the Roblox mobile app.
3. Search for "Discord Mod Simulator" (your published experience). Or use the URL on your phone — Roblox app prompts to open.
4. Play a full round. Test:
   - **Tap-to-target**: tap directly on an enemy with Ban Hammer / Mute Gun / Timeout Card equipped. Should fire the tool.
   - **Virtual KICK button**: should appear bottom-right when on touch device. Tapping it should kick.
   - **HUD scaling**: cooldown panel should fit on screen without cutting off. Wave label readable. Coins/Level visible.
   - **Upgrades panel**: tap Upgrades button → panel opens → buttons are tappable without misfires.

**Verify:** If any of the above feel broken, tell Claude with specifics ("Kick button doesn't fire", "Mute Gun aim is too floaty on touch", etc.) and we'll fix.

**After it feels good:** in Creator Hub → your experience → Settings → Devices → check **Tablet** and **Phone**. Save. Publish update (§A). Touch users can now find your game in mobile search.

**Until then:** leave Devices = Computer only. Bad touch UX = 1-star reviews.

---

## §H — Multiplayer Studio testing

**When:** Day 26-27, after multiplayer polish lands.

**Why:** Solo testing doesn't exercise leaderstats visibility, server-side tracer replication, or "two players hitting the same enemy" race conditions.

**Steps:**

1. Studio → **Test** ribbon → click the dropdown next to **Play** → choose **Local Server** (or "Local Server with 2 Players" / N players).
2. Studio opens 2 windows: one is the SERVER, the others are CLIENT instances (you'll see them labeled).
3. In each client window, control a different player (each has its own camera + character).
4. Test:
   - **Leaderstats**: Roblox player list (Tab key) should show Coins + Level columns for both players.
   - **Server-side tracers**: have player 1 fire Mute Gun. Player 2 should see the tracer line.
   - **Shared server health**: both players see the same health bar. If one player dies (server health = 0), both see SERVER DEAD + GameOverPanel.
   - **Concurrent kills**: both players ban the same enemy at near the same instant. Server should accept exactly one ban (whoever the cooldown allows first); the other gets nothing. No crash, no double-coin.

**Verify:** if anything misbehaves, capture the Output panel from the server window and tell Claude.

---

## §I — Pushing to origin

**When:** Phase 5 close (after the Phase 5 close commit lands), or any time you want a remote backup.

**Why:** Claude doesn't push autonomously. All commits live locally on `main` until you push. As of Phase 3 close you have 18 commits ahead of `origin/main`, never pushed.

**Steps:**

1. Open terminal in the project root (`E:\Roblox Development\discord-mod-simulator`).
2. Run `git status` — should be clean (no uncommitted changes).
3. Run `git log origin/main..HEAD --oneline` to see exactly what will be pushed.
4. Run `git push origin main`.
5. If GitHub asks for credentials, log in via your usual method (browser auth, PAT, etc.).

**Verify:** check GitHub web — your repo's `main` branch should show all the commits.

**After first push:** subsequent pushes are just `git push` (no `origin main` argument needed; tracking is set up).

---

## §J — Launch checklist (Phase 6 — Days 28-30, future)

**Not part of Phase 4-5 work.** When you're ready to launch publicly:

1. **Icon** — square 512×512 PNG. Upload via Creator Hub → your experience → Configuration → Icons.
2. **Thumbnails** — up to 10 images, 1920×1080. Should show gameplay (banning, the upgrade panel, a chaotic Spam Storm wave).
3. **Description** — write the kid-friendly hook (Claude already drafted one for Day 13 publish; Phase 6 will revisit).
4. **Public release** — Creator Hub → Settings → Permissions → set to **Public**.
5. **First players** — share to TikTok / Discord / Reddit per `plan.md` §7 Phase 6.

Detailed Phase 6 launch checklist will land in this doc when we get there.

---

## When in doubt

- Tell Claude what you're trying to do, what step you're on, and what's failing.
- Studio Output panel + game `print` lines are the best signal — paste them in.
- If a section here is wrong or unclear, tell Claude and we'll edit.
