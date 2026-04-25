# Recording session runbook — DMS side

Hand-off doc for a separate session to drive the Sunday clip-recording session for Discord Mod Simulator. Covers the **DMS-repo mechanics** only — branch swaps, debug-script setup, in-Studio verification, post-recording cleanup. Captions, edit decisions, and posting live in the `content-engine` repo and are out of scope here.

---

## State at handoff (2026-04-25)

- **Branch:** currently `clip-recording-bad-shake` (dirty — `src/StarterPack/BanHammer/BanHammerScript.client.lua` modified, NOT committed). This is intentional. See **Clip 03** below.
- **Main:** clean. Last main commits, top to bottom: `968cb50` DEVLOG decisions, `ac6e0d2` FlashOverlay, `4b2956b` KickBoot ToolTip, `e9d4b1f` Wave label + coin floater.
- **FlashOverlay:** built, committed to main, **NOT yet tested in Studio.** Verify Sunday morning before relying on it for Clips 04 / 07.
- **Audit reference:** `git show b68a82a:docs/clips.md` — full audit lives there (deleted from working tree, only in history).
- **Clip captions, full per-clip spec:** live in the `content-engine` repo at `docs/clips.md`. This runbook references clips by number — pull captions from there.
- **Cuts confirmed:** Clip 08 OUT (filed in `DEVLOG-NOTES.md` BACKLOG). Clip 10 OUT (deferred to Phase 2 close). **8 clips to record:** 01, 02, 03, 04, 05, 06, 07, 09.

---

## Sunday morning pre-flight (~15 min, before any recording)

### 1. Verify FlashOverlay (5 min)

Switch to main first (the dirty branch has the bad shake — don't test on it):

```bash
git checkout main          # if on clip-recording-bad-shake, stash or discard the dirty file first
rojo serve
```

In Studio: play a losing run (let server hit 0 HP), confirm **red** flash. Then a winning run (or set health high and let waves clear), confirm **green** flash. Both should: fade in over 0.15s to half-opacity, hold 0.3s, fade out over 0.4s. UpgradeButton must still click through (Active=false).

If it doesn't fire: check `MainUI/FlashOverlay` exists in PlayerGui at runtime and `ClientMain` connected the `gameOver`/`gameWon` handlers (look for `[ClientMain] Game over received` / `[ClientMain] Victory received` print).

### 2. Verify Tool TextureIds in Studio (5 min)

Per `CLAUDE.md`: Tool icons (`TextureId`) are Studio-only — Rojo doesn't sync them. Any fresh place file has blank icons.

In Studio Explorer, click each Tool in `StarterPack`:
- `BanHammer` → confirm TextureId set
- `MuteGun` → confirm TextureId set
- `TimeoutCard` → confirm TextureId set
- `KickBoot` → confirm TextureId set

If any are blank, re-paste the asset IDs from your icon backup. Recording Clip 01 with a blank icon is a hard fail.

### 3. Build SoloSpawn debug script (5 min)

Required for Clip 02 (need a single isolated Spammer, no other enemies). Path matters — Rojo only syncs covered paths.

```bash
# Add gitignore patterns first
echo '
# Recording debug scripts (ignored — never committed)
**/SoloSpawn*
**/RecordMode*
' >> .gitignore
```

Then create `src/ServerScriptService/Tools/SoloSpawn.server.lua`:

```lua
-- Recording debug only — disables RoundManager spawns and exposes
-- a chat command "/spammer" that spawns one Spammer at the start.
-- Hot-loads next to RoundManager. Delete after recording.

local ServerScriptService = game:GetService("ServerScriptService")
local Players             = game:GetService("Players")

local spawner    = ServerScriptService:WaitForChild("Enemies"):WaitForChild("EnemySpawner")
local spawnFunc  = spawner:WaitForChild("Spawn")

Players.PlayerAdded:Connect(function(p)
	p.Chatted:Connect(function(msg)
		local cmd, arg = msg:match("^/(%w+)%s*(%w*)$")
		if cmd == "spammer" then
			spawnFunc:Invoke(arg ~= "" and arg or "Spammer", 1)
		end
	end)
end)
print("[SoloSpawn] Debug spawn ready: /spammer, /troll, /teleporter, /splitter")
```

To suppress the round flow during recording, either comment out the `task.spawn` block at the bottom of `RoundManager.server.lua` for the session OR just hand-clear waves manually. The user's call.

Optional `RecordMode.client.lua` at `src/StarterPlayer/StarterPlayerScripts/RecordMode.client.lua` to hide chat / leaderboard for clean shots — only if needed:

```lua
local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
```

---

## Per-clip Studio mechanics

**Captions, voiceover scripts, and editing instructions live in `content-engine/docs/clips.md`.** This section is just the DMS-repo prep per clip.

### Clip 01 — The loadout

- **Branch:** main
- **Setup:** All four tools equipped (default StarterPack already does this). Empty map — kill `RoundManager` for the recording or use `SoloSpawn` and don't trigger any.
- **Capture:** 4 tools × 5 takes × 30s. Solo cast each.
- **Watch for:** Effect colors per audit — Kick (`Color3.fromRGB(180, 255, 200)`) reads near-white on camera; verify it's green-enough on screen.

### Clip 02 — All three at once

- **Branch:** main
- **Setup:** SoloSpawn debug script loaded. Run `/spammer` in chat to get one isolated Spammer. Single-target Spammer walks toward zone.
- **Capture:** Mute → Timeout → Kick chain. End on Kick.
- **Caption note (per audit + decision log):** the rewritten caption is "Three statuses, one Spammer, one launch into the void." — does NOT claim a priority order, does NOT promise a coin payoff. Don't end the chain on Ban for the +20 popup unless explicitly re-deciding the framing.
- **Common failure:** kicking before mute lands → no visible mute color. 5–10 takes to land cast rhythm.

### Clip 03 — Don't tween the camera

**Two captures, two branches.**

#### Bad version (capture first, branch is already prepared):

```bash
git checkout clip-recording-bad-shake   # branch already exists, file already dirty
rojo serve
```

Capture ~30s of banning enemies. The shake is deliberately broken — fights the default camera controller, jitters/snaps. **DO NOT commit anything on this branch.**

#### Good version:

```bash
# Discard the dirty file and switch back
git checkout -- src/StarterPack/BanHammer/BanHammerScript.client.lua
git checkout main
rojo serve
```

Capture ~10s of banning with the proper `Humanoid.CameraOffset` shake.

#### After both captures complete:

```bash
git branch -D clip-recording-bad-shake   # nuke the throwaway branch
```

### Clip 04 — SERVER DEAD

- **Branch:** main
- **Setup:** No SoloSpawn — let RoundManager run normally. Recording a genuine fail.
- **Capture:** Mid-wave-3 chaos. Play badly, let HP tick to 0. **Verify FlashOverlay fires red** (this is the new visual the audit asked for — don't capture without it).
- **Takes:** 3–4. Genuine fails can't be faked easily.

### Clip 05 — The whiff bug

- **Branch:** main
- **Setup:** Need to capture the **old** "sound on whiff" behavior. Per audit: hand-edit, do NOT git-checkout an old commit (parent commit `71a4b62` predates the lookDir param and would break Kick aim).
- **Edit before capture:** in `src/ServerScriptService/Enemies/KickHandler.server.lua`, find the `if hitCount > 0 then` gate around the `Effects.KickEffect(...)` call and **temporarily remove the gate**. (~2 lines.) **Do NOT commit.**
- **Capture:** 2 whiff casts (no enemies in cone) — sound fires on miss.
- **After capture:** `git checkout -- src/ServerScriptService/Enemies/KickHandler.server.lua`.
- **Then capture current behavior:** 2 whiff casts, silent.
- **Code overlay shot:** `if hitCount > 0 then` line in editor.

### Clip 06 — Three failed icons

- **Branch:** none (no Studio capture)
- **Setup:** AI image gen (ChatGPT) — re-generate three intentionally-bad icons (text on icon, baked background, all-purple) per spec.
- **Studio shot only at the end:** four-icon hotbar at 64×64. Keep StarterPack default loadout, equip nothing, screenshot the bottom-bar.

### Clip 07 — VICTORY

- **Branch:** main
- **Setup:** Genuine 5-wave clear. No SoloSpawn — full waves.
- **Capture:** Full successful run (~3–5 min). **Verify FlashOverlay fires green** on the wave-5-cleared moment.
- **Takes:** 30+ minutes of attempts. You have to actually win.
- **Edit later:** compress to ~3s per wave + the win moment.

### Clip 09 — Wave 3 is when you start sweating

- **Branch:** main
- **Setup:** Normal wave flow. Disable SoloSpawn for this clip — RoundManager runs normally.
- **Capture:** Waves 1 → 2 → 3 with intentional rapid tool-swapping in wave 3. 3–4 takes.
- **Side-check:** confirm wave label renders "Wave 1 / 5  —  N left" from frame 1 (this was the bug fixed in `e9d4b1f` — should be solid now). If it doesn't render, the clip can fall back to spec's "Wave 1 / 5" appearance — no harm, but flag it.

---

## Post-recording cleanup (~5 min, before next dev day)

```bash
# 1. Confirm on main, working tree clean
git checkout main
git status                               # should be clean

# 2. Delete the throwaway branch (if not already done after Clip 03)
git branch -D clip-recording-bad-shake   # silent if already gone

# 3. Delete the debug scripts (gitignored — won't show in status anyway)
rm src/ServerScriptService/Tools/SoloSpawn.server.lua
rm src/StarterPlayer/StarterPlayerScripts/RecordMode.client.lua  # if created
rmdir src/ServerScriptService/Tools 2>/dev/null

# 4. Confirm any per-clip hand-edits (Clip 05's whiff gate) were reverted
git status                               # still clean
git diff                                 # empty
```

---

## What this runbook does NOT cover

- **Captions, hashtags, voiceover scripts.** Live in `content-engine/docs/clips.md`.
- **Editing.** CapCut/Resolve. Done in a separate editing pass during the week.
- **Posting cadence.** Mon / Wed / Fri × ~3.3 weeks per the original plan. Posting workflow is `content-engine` `clip add` + per-platform formatters.
- **Status tracking.** Update Status column in `content-engine/docs/clips.md` (`Planned` → `Recorded`) after Sunday.

---

## After the session

When the recording session is fully done and tree is clean, hand back to the main DMS dev session for Day 12 work. The DMS dev session does NOT need to know about clips beyond "Sunday recording happened, runbook says clean, ready to resume Phase 2 close."
