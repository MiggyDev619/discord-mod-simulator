# Discord Mod Simulator — clip plan

Week-one content for the MiggyDev faceless gamedev brand. Ten 15–30s short-form clips for cross-posting via the `content-engine` tool. Strategy and rationale captured in `DEVLOG-NOTES.md` (2026-04-25 entry).

**Status:** plan locked, **audit complete** (2026-04-25), recording pending.
**Recording target:** Sunday batch session, ~2 hours.
**Posting cadence:** Mon / Wed / Fri × ~3.3 weeks.
**Start date:** TBD (fill in once you've confirmed the Sunday recording lands clean).

> **Audit notice (2026-04-25):** Reality-check pass against current source code complete. **4 hard blockers** before recording (see Audit section at bottom for the pre-recording checklist). **Clip 02** caption is wrong as written. **Clip 08** premise is structurally false — recommend deferring to week 4+. **Clip 10** also recommended for deferral. Per-clip details, the corrected cut-to-6, and the recommended Sunday drops are all in the Audit section.

## Hard constraints (locked)

- Faceless. Hands + screen + voiceover OR on-screen text only. Voice OK; face never.
- 15–30 seconds. Sweet spot for TikTok / YouTube Shorts / Instagram Reels. Works on the most restrictive platform first.
- One specific observation per clip. Not "look at my game" — a thing the viewer learns or laughs at in 20 seconds.
- Cyan/violet HUD aesthetic carried into overlay text. MiggyDev mark in a corner of every clip.
- Captions stay platform-agnostic in this file. Per-platform rewrites (hashtag count, length, link rules) are the `content-engine` `caption draft` command's job.

## Mix targets (locked)

- 5 player-audience / 5 dev-audience.
- ≥2 broken-or-fixed or before-and-after framings (currently: camera shake, whiff bug, icon iteration — three).
- ≥1 honestly-imperfect (whiff bug, slot 5).
- ≥1 recap (Phase 1 in 5 days, slot 10).
- ≤2 code-on-screen as the primary visual (camera shake, empty packet — at the cap).

## Posting schedule

| # | Title | Audience | Status | Posting target |
|---|---|---|---|---|
| 01 | The loadout | Player | Planned | Week 1 Mon |
| 02 | All three at once | Player | Planned | Week 1 Wed |
| 03 | Don't tween the camera | Dev | Planned | Week 1 Fri |
| 04 | SERVER DEAD | Player | Planned | Week 2 Mon |
| 05 | The whiff bug | Dev | Planned | Week 2 Wed |
| 06 | Three failed icons | Dev | Planned | Week 2 Fri |
| 07 | VICTORY | Player | Planned | Week 3 Mon |
| 08 | Empty packet | Dev | Planned | Week 3 Wed |
| 09 | Wave 3 is when you start sweating | Player | Planned | Week 3 Fri |
| 10 | Phase 1 in five days | Both | Planned | Week 4 Mon |

Status legend: `Planned` → `Recorded` → `Edited` → `Posted`.

---

## Clip 01 — The loadout

- **Audience:** Player
- **Hook (first 2 seconds):** ON-SCREEN TEXT (cyan-on-violet, MiggyDev mark in corner): *"When your Discord gets raided."*
- **Body:** Four tool icons drop in one at a time over 4 seconds — Ban Hammer, Mute Gun, Timeout Card, Kick Boot. Each is followed by a 2-second clip of it firing in-game (red explosion / blue slow / yellow freeze / green knockback). Final frame: all four icons in the hotbar at actual 64×64 size with text *"Pick your main."*
- **Caption shape:** "The full mod loadout. Which one do you actually need?" Hashtags: `#robloxdev #robloxgame #moderationsimulator`
- **Why it'll work:** Brand-introduction clip without "follow my journey" filler. Stranger sees four tools in 25 seconds and knows what the account is about. The closing question invites a comment.
- **Recording requirements:** Studio capture — four solo tool-firing clips (5 takes each, ~10 min). Editor work for the drop-in animation and text overlay. Reuse the existing 1024×1024 transparent-PNG icons.

## Clip 02 — All three at once

- **Audience:** Player
- **Hook:** ON-SCREEN TEXT: *"One Spammer. Three statuses. Fifteen seconds."* (timer counts down on screen)
- **Body:** A Spammer walks toward the zone. Player hits with Mute Gun (turns blue, slows). Timeout Card (turns yellow, frozen). Kick Boot (green burst, launches into the void). Final frame: `+20 coins` floating popup.
- **Caption shape:** "Slow it. Freeze it. Kick it. In that order — anything else and the kick gets eaten by the slow." Hashtags: `#robloxgame #robloxdev #gamefeel`
- **Why it'll work:** Visceral chain of three distinct effects with a clean payoff. Caption smuggles in a small dev brag (the priority-ladder rule) without explaining it. Re-watchable — different effects pop on different passes.
- **Recording requirements:** Single Studio take, 20 seconds. 5–10 takes to nail the cast rhythm. Tools loadout already configured.

## Clip 03 — Don't tween the camera

- **Audience:** Dev
- **Hook:** ON-SCREEN TEXT (jittering): *"Roblox screen shake. Wrong way."*
- **Body:** Side-by-side, ~12s. Left: tweened `Camera.CFrame` — fights the follow cam, visible snap-back, jitter. Right: `Humanoid.CameraOffset` — smooth shake that respects the controller. Center text overlay for 4s: *"Don't tween Camera.CFrame. Use `Humanoid.CameraOffset`. One property, every edge case."*
- **Caption shape:** "First time you try screen shake in Roblox you fight the camera controller for an hour. There is a one-property fix." Hashtags: `#robloxdev #gamefeel #luau`
- **Why it'll work:** Bad version in the first 2 seconds is visibly broken — that's the stop-scroll moment. SEO-friendly ("roblox camera shake" is a real search). Devs who've hit this exact bug will share it.
- **Recording requirements:** Two Studio captures — temporarily restore the bad CFrame tween code (5 minutes, then revert), then capture current. Brief code overlay (3-line diff). One of two allowed code-on-screen slots.

## Clip 04 — SERVER DEAD

- **Audience:** Player
- **Hook:** ON-SCREEN TEXT (over chaos, no music yet): *"Don't blink."*
- **Body:** Mid-wave-3 chaos. Health label visibly tickdown from ~6 to 0. Camera shake on each hit. Health hits 0, screen flips to red overlay with `SERVER DEAD` in the wave label slot. Cut hard to black.
- **Caption shape:** "Letting trolls into your Discord, visualized. The server doesn't get a second chance." Hashtags: `#robloxgame #robloxdev #moderationsimulator`
- **Why it'll work:** Stakes-establishing clip — viewers learn "you can lose this game" without being told. The "don't blink" hook is a small dare that holds attention. Pairs emotionally with clip 07 (VICTORY).
- **Recording requirements:** Studio capture during a losing run — wave 3 spam-rush, intentionally play badly. Genuine fail recording, can't be faked. Need 3–4 attempts.

## Clip 05 — The whiff bug

- **Audience:** Dev
- **Hook:** VOICEOVER (over a silent product shot of the Kick Boot icon): *"I shipped a bug. Then half-fixed it."*
- **Body:** Cut to in-game: a Kick whiff playing the sound (old behavior) — VO: *"Sound on miss. Felt wrong — every other tool gates effects on contact."* Cut: same whiff, silent (current). Brief code overlay: `if hitCount > 0 then`. Closing text: *"Open question — visual without audio on miss?"*
- **Caption shape:** "Yesterday's bug. Today's half-fix. Tomorrow's open question. The honest sequence — visuals on whiff, no sound, is probably the right answer. Filed for next week." Hashtags: `#robloxdev #gamedev #buildinginpublic`
- **Why it'll work:** Authenticity hook. Faceless dev accounts that show only polished wins lose trust fast. A "here's what's still broken" clip mid-rotation (slot 5 of 10) buys credibility for the wins around it. Open question is real, not bait.
- **Recording requirements:** Two Studio whiff captures — temporarily restore the old `Effects.KickEffect` call site (5 minutes), then revert. Code editor screencap of the gating line. Voiceover ~12 seconds, recorded separately.

## Clip 06 — Three failed icons

- **Audience:** Dev
- **Hook:** ON-SCREEN TEXT: *"Three failed icons before this one worked."* (with the four current icons hovering as silhouettes in the background)
- **Body:** Show each failure with its lesson:
  1. *"BAN" word baked in* → "no text on icon — letters become red mush at 64px"
  2. *Gray baked background* → "transparent PNG only — backgrounds clash with every UI"
  3. *All-purple Mute Gun* → "one accent color contrasting the body, or it disappears on the dark hotbar"
  Cut to the four current icons in the actual hotbar at 64×64. Final text: *"Constraints over aesthetics. Always."*
- **Caption shape:** "AI image gen always pads, always bakes backgrounds, always wants text on the icon. Three rules for surviving a 64×64 hotbar." Hashtags: `#robloxdev #aiart #gameicons`
- **Why it'll work:** Concrete useful lesson with visual proof. Before-after-after-after structure is universally readable. Other devs and creators hit these exact failure modes — searchable and shareable.
- **Recording requirements:** Re-generate the three failed icons in ChatGPT (cheap, ~5 min). Final hotbar screenshot. Optional 5-second clip of the Photopea trim workflow. All editor-table work, no Studio gameplay.

## Clip 07 — VICTORY

- **Audience:** Player
- **Hook:** VOICEOVER (over wave-1 calm gameplay): *"Five waves. Four tools. One server."*
- **Body:** Speedrun-style cuts: wave 1 → 2 → 3 → 4 → 5, ~3 seconds per wave. Last enemy of wave 5 banned, screen flashes green `VICTORY`. Cut on the moment.
- **Caption shape:** "Five waves of trolls. Cleared. The first time it felt like a real game." Hashtags: `#robloxgame #robloxdev #moderationsimulator`
- **Why it'll work:** Resolution moment, emotional pair to clip 04 (SERVER DEAD). "You can win this game" message. Compressed five-wave montage feels like a full run in 25 seconds — high information density.
- **Recording requirements:** Most labor-intensive. One full successful run (~3–5 min), then heavy edit down to 25s with the best 4-second moment from each wave. Plan for 30+ minutes of takes — you have to actually win.

## Clip 08 — Empty packet

- **Audience:** Dev
- **Hook:** ON-SCREEN TEXT (over a blurred network panel): *"What's in this packet? Nothing."*
- **Body:** Network panel sharpens — `KickEnemies:FireServer()` payload: 0 bytes. VO: *"Client sends nothing. Server reads its own facing direction. Why? Because if the client sent the cone angle, anyone could spoof a 360° kick."* Cut to 3-line server snippet: `local cameraLook = root.CFrame.LookVector` followed by the dot-product cone filter. Closes on text: *"Same principle as range validation. Different geometry."*
- **Caption shape:** "Server-authoritative kick. Empty packet, server-derived geometry. The thing every Roblox tutorial leaves out." Hashtags: `#robloxdev #gamedev #serverauth`
- **Why it'll work:** Counter-intuitive opener (an empty packet *is* the hook — most are full). Specific security lesson with one concrete example. Devs interested in multiplayer integrity will save this rather than just like it.
- **Recording requirements:** OBS capture with Roblox network/F9 panel visible during a kick cast. Code editor screencap of the 3-line server-side LookVector read. Voiceover ~15 seconds. Second code-on-screen slot.

## Clip 09 — Wave 3 is when you start sweating

- **Audience:** Player
- **Hook:** ON-SCREEN TEXT: *"Wave 1 is the tutorial."* (over calm wave 1 gameplay)
- **Body:** Wave indicator ticks: `Wave 1 / 5`, `Wave 2 / 5` (8 seconds, increasing pace). `Wave 3 / 5 in 7s` countdown. Cut: orange Spammers flood in. Player swaps tools rapidly — Mute, Timeout, Kick, Ban, Mute, Kick. Sound layers chaotically. Closes on a one-second wide shot of the cleared zone, breath out.
- **Caption shape:** "Wave 1 is the tutorial. Wave 3 is when you start sweating." Hashtags: `#robloxgame #robloxdev #moderationsimulator`
- **Why it'll work:** Tension-escalation structure is universally readable — you don't need to know the game to feel the difficulty curve. Wave 3 is the "you can lose" inflection point identified in DEVLOG Day 3. Two-sentence caption matches the devlog voice.
- **Recording requirements:** Studio capture, waves 1–3 with intentional rapid tool-swapping. Need a clean 3–4 minute take, then heavy edit down to 25s. 3–5 takes to land the chaos rhythm.

## Clip 10 — Phase 1 in five days

- **Audience:** Both (dev-leaning)
- **Hook:** ON-SCREEN TEXT (over a dark, MiggyDev-marked card): *"Phase 1 of a 30-day Roblox build. In five days."*
- **Body:** A milestones table animates in row by row, each paired with a 1-second clip of that milestone running in-game:
  - Day 1 — Rojo + scaffold
  - Day 2 — core loop, first enemy
  - Day 3 — second enemy + waves
  - Day 4 — currency + first upgrade
  - Day 5 — win condition + Phase 1 close

  Closing text: *"~350 lines of Luau. Phase 2 is polish."*
- **Caption shape:** "Five days. Six milestones. ~350 lines of Luau. Phase 2 starts now — the part where it actually feels good to play." Hashtags: `#robloxdev #gamedev #buildinginpublic`
- **Why it'll work:** Recap clip creates "what's next" anticipation that pulls viewers back for clip 11+. Concrete numbers (5 days, 6 milestones, 350 lines) build dev-audience credibility. Player audience sees the game evolving, which builds trust in continued development.
- **Recording requirements:** Five quick game-state captures (~1s each: empty scaffold, first ban, wave UI, currency UI, victory screen). Animated milestone-table overlay = editor work in CapCut/Resolve. Hardest part is the table animation, not the captures.

---

## Sunday batch capture session (~2 hours, single batch)

### In Roblox Studio (~75 min)

1. Set up a "clip mode" save — disable spawn distractions, all four tools equipped, controlled enemy spawn scenario.
2. **Solo tool firings** — 4 tools × 5 takes × 30s each. (~15 min) → clip 01.
3. **Three-status combo** on one Spammer — mute → timeout → kick chain. 5–10 takes. (~10 min) → clip 02.
4. **Camera shake — bad version**: temporarily restore CFrame tween, capture 30s, revert immediately. (~10 min) → clip 03 left.
5. **Camera shake — good version**: capture during normal banning. (~3 min) → clip 03 right.
6. **Whiff bug — old behavior**: temporarily restore unconditional `Effects.KickEffect`, capture 2 whiffs with sound, revert. (~5 min) → clip 05.
7. **Losing run** — let the server die wave 3 spam-rush. 3–4 attempts, keep the most chaotic. (~10 min) → clip 04.
8. **Winning run** — full 5-wave clear. 3–5 attempts, keep the cleanest. (~20 min) → clip 07.
9. **Wave 3 transition** — capture wave 1→2→3 with intentional rapid tool-swapping. 3–4 takes. (~10 min) → clip 09.
10. **Milestone snapshots** — 5 quick state captures (scaffold, first ban, wave UI, currency UI, victory). (~5 min) → clip 10.

### Outside Studio (~30 min)

11. **Re-generate three failed icons** in ChatGPT (text on icon, baked background, all-purple). (~5 min) → clip 06.
12. **Network panel screencap** during kick cast — Roblox F9 panel visible. (~5 min) → clip 08.
13. **Code editor screencaps** (~10 min):
    - `Humanoid.CameraOffset` lines (clip 03)
    - `if hitCount > 0 then` whiff gate (clip 05)
    - Server-side `LookVector` read + cone dot-product (clip 08)
14. **Voiceover passes** (~10 min, separate quiet recording):
    - Clip 05 whiff bug (~12s)
    - Clip 07 victory (~5s)
    - Clip 08 empty packet (~15s)

Editing happens later in the week. Sunday is **capture only** — don't try to edit on the same day, you'll burn out and the editing decisions will be worse.

### Code-revert overhead

Two captures need temporarily-reverted code, ~5 min round-trip each:

- Clip 03 (camera shake bad version): restore CFrame tween from pre-Day-7 code.
- Clip 05 (whiff bug old behavior): restore unconditional `Effects.KickEffect` from pre-Day-9 fix.

Use `git stash` after capture to keep the working tree clean for the next dev day.

---

## Editing checklist (per clip, post-capture)

Run through this for every clip individually. None of these are skippable.

- [ ] Trim raw capture to ≤30s
- [ ] Cyan/violet color treatment on overlay text
- [ ] MiggyDev mark in a corner (consistent placement across all 10)
- [ ] Hook text in the first 2 seconds
- [ ] Voiceover layered (clips 05, 07, 08 only)
- [ ] Export 9:16 master at 1080×1920 (TikTok / YouTube Shorts / Instagram Reels)
- [ ] Export 16:9 master at 1920×1080 (X) — only if the 9:16 version doesn't translate
- [ ] Register in `content-engine`: `python main.py clip add <path> --title "<clip title>" --duration <s>`
- [ ] Update Status column in this file: `Planned` → `Recorded` → `Edited` → `Posted`

---

## Cut list — drop to 6 if reality eats four

If the schedule forces a smaller batch, the survivors are:

1. **Clip 01** — The loadout (brand opener; non-negotiable)
2. **Clip 02** — All three at once (visceral payoff, only ~15 min to record)
3. **Clip 03** — Don't tween the camera (broken-vs-fixed; SEO; the dev tier-1)
4. **Clip 04** — SERVER DEAD (player tier-1 — establishes stakes)
5. **Clip 05** — The whiff bug (honestly-imperfect anchor; non-negotiable)
6. **Clip 07** — VICTORY (resolution clip, pairs with #04)

Cuts in priority order: clip 09 (overlap with #04 as "tension" coverage), clip 10 (recap is lower-leverage for week-one), clip 08 (most niche dev clip — security audience is small), clip 06 (strong but not the strongest dev clip in rotation).

Each cut clip is worth bringing back later when the schedule is steady and there's an actual audience for niche dev content.

> Note: the audit below supersedes parts of this cut list. See **Updated cut-to-6 (post-audit)** for the corrected version.

---

## Audit — 2026-04-25 post-plan reality check

> Reality-check pass: spec read against current source code. Findings supersede per-clip "Recording requirements" above where they conflict. Order of authority: code → audit → original spec.

### Five things you should know

1. **The one caption that'll embarrass you if posted as-written:** Clip 02. Status priority is the inverse of what the caption claims.
2. **The one clip that's structurally false:** Clip 08. Not a fix-the-caption issue — the whole premise is wrong.
3. **The one "before" version you can't `git revert`:** Clip 03. The CFrame-tween version was never in repo.
4. **The one Studio-state risk you can't see in code:** Tool TextureIds (icons). Verify in Studio Sunday morning before the camera rolls.
5. **The two visual hooks that oversell:** Clips 04 and 07 say "screen flash" but only the label changes color. Either accept the smaller visuals or add a 20-min overlay (does double duty).

### Per-clip findings

#### Clip 01 — The loadout · Doable

- **Effect color verification** (`src/ReplicatedStorage/Shared/Effects.lua`):
  - Ban: `Color3.fromRGB(255, 60, 60)` (red, line 14) ✓
  - Mute: `Color3.fromRGB(70, 150, 255)` (blue, line 116) ✓
  - Timeout: `Color3.fromRGB(255, 200, 50)` (yellow, line 150) ✓
  - Kick: `Color3.fromRGB(180, 255, 200)` (mint / very light green, line 225) — may read as white on camera. Verify on screen before relying on the green description.
- **Risk:** Tool TextureIds are Studio-only per CLAUDE.md, not in the repo. Confirm the four icons are still assigned to the four Tools in your current place file before recording. A fresh place file would have blank icons.
- **Capture time delta:** matches plan.

#### Clip 02 — All three at once · Doable, **caption rewrite required**

- **Issue 1 — caption is backwards.** Status priority in `EnemySpawner.server.lua:181-195` is **Kick > Timeout > Mute > seek** (CLAUDE.md confirms). Kicking a muted/frozen enemy works fine — Kick OVERRIDES Mute. The current caption's "in that order — anything else and the kick gets eaten by the slow" assertion is **false**.
- **Issue 2 — coin payoff doesn't fire on Kick.** Coins are awarded only inside `banEnemy.OnServerEvent` (`EnemySpawner.server.lua:315`). Kick is non-destructive and awards nothing. If the chain ends on Kick Boot launching the Spammer, the "+20 coins" floater never appears.
- **Issue 3 — single-Spammer isolation needs setup.** No test/freeze mode exists. Need either a temp single-spawn debug script, or hand-clear other enemies until one Spammer remains.
- **Caption alternatives:**
  - "Slow it. Freeze it. Boot it. Kick wins every priority duel — but it's funnier with all three on screen."
  - Or end the chain on **Ban** (not Kick) for a real +20 coin floater.
- **Capture time delta:** +10 min (need temp solo-spawn debug script).

#### Clip 03 — Don't tween the camera · Doable, **bad version must be written, not restored**

- **Issue:** `git log --follow src/StarterPack/BanHammer/BanHammerScript.client.lua` shows the initial Days-1-7 commit already used `Humanoid.CameraOffset`. The CFrame-tween version was **never in repo**. The original "temporarily restore the bad code" step is impossible — there's nothing to restore.
- **Recording approach:** Write a deliberately-bad CFrame-tween shake from scratch on a throwaway branch (`clip03-bad-shake`), capture, then `git checkout main && git branch -D clip03-bad-shake`. Frame the clip honestly as "common mistake → here's the fix" instead of "here's the bug I shipped."
- **Capture time delta:** +15 min (writing the bad version is more involved than a git revert).

#### Clip 04 — SERVER DEAD · Doable, visual smaller than spec

- **Issue:** No full-screen red overlay exists. Actual behavior at `ClientMain.client.lua:61-72`:
  - "SERVER DEAD" lands in the **HealthLabel inner Label** (the bar's own text), not the wave label.
  - Wave label says "Run ended" in light red.
  - Health fill tweens to width 0, color red.
  - The "screen flips to red" line in the spec **oversells the visual**.
- **Recording approach options:**
  - Accept the smaller visual (text in health bar slot, color change).
  - Add a `Frame` overlay in `MainUI` that tweens `BackgroundTransparency` from 1 → 0.5 → 1 on `gameOver`. ~20 min addition; does double duty for clip 07.
- **Capture time delta:** matches plan if accepting current visual; +20 min shared with clip 07 if adding overlay.

#### Clip 05 — The whiff bug · Doable. **Most reliable clip in the rotation**

- **Verification:** Commit `966d9c6` ("Kick: only play effect on contact") cleanly added the `if hitCount > 0 then` gate. Diff is 4 lines.
- **Recording approach:** **Hand-edit the 2-line gate** — do NOT `git checkout 966d9c6^ -- KickHandler.server.lua` because that commit's parent (`71a4b62`) doesn't yet take the `lookDir` param, which would break clip 02's Kick aim.
- **Capture time delta:** matches plan.

#### Clip 06 — Three failed icons · Doable, Studio-state dependent

- **Issue:** The four current icons live as `Tool.TextureId` in Studio only — not in the repo. Verify they're still assigned in your current place file before recording the final-hotbar shot.
- **Capture time delta:** matches plan.

#### Clip 07 — VICTORY · Doable, visual smaller than spec

- **Issue:** `ClientMain.client.lua:74-80` sets wave label to exactly `"VICTORY"` in `Color3.fromRGB(80, 255, 140)` (mint green) ✓ — but there's **no full-screen green flash**. Just label color change + health text turns green. Same shortfall as clip 04.
- **Recording approach options:** Same as clip 04 — accept current visual or add the overlay (which would do double duty across both clips).
- **Capture time delta:** matches plan; +20 min shared with clip 04 if adding overlay.

#### Clip 08 — Empty packet · **Reconceive — premise is structurally false**

- **Issue:** Current code (`KickBootScript.client.lua:37`) sends `kickEnemies:FireServer(lookDir)` with a Vector3 payload (12 bytes, **not empty**). Server (`KickHandler.server.lua:38`) reads the **client-sent vector**, not its own facing. Commit `a419aca` (Day 9) explicitly switched FROM server-derived TO client-derived as the documented exception to server-authoritative. CLAUDE.md spells this out. The whole "empty packet, server-derived geometry" hook is the **inverse** of reality.
- **Two truthful angles available:**
  1. **"The one packet I let the client own."** The kick aim as the documented exception, with the trade-off (UX vs. spoof risk) as the lesson. CLAUDE.md already has the rationale.
  2. **Pivot to the BAN remote.** `BanEnemy:FireServer(closest)` is genuinely "client picks target, server validates everything else (range, cooldown, IsEnemy)." Cleaner story for "server-authoritative destructive actions."
- **Recommended action:** Drop from this rotation; reconceive deliberately for week 4+. The clip needs its own thinking, not a Sunday rush.
- **Capture time delta:** unchanged once reconceived; saves ~25 min Sunday if dropped.

#### Clip 09 — Wave 3 is when you start sweating · Doable, minor cosmetic discrepancy

- **Issue:** Wave label format is `"Wave %d / %d  -  %d left"` (`ClientMain.client.lua:96`). Spec says `"Wave X / 5"` — substring matches but spec didn't anticipate the `"  -  N left"` suffix.
- **Side issue (paused, separate work):** Wave 1 was not rendering the "N left" suffix per earlier observation. Three fixes landed; verify Sunday morning. If still misfires, the clip falls back to spec's "Wave 1 / 5" appearance — no harm.
- **Capture time delta:** matches plan.

#### Clip 10 — Phase 1 in five days · Doable but lower-leverage. **Recommend deferring to week 4+**

- **Issue 1:** No checked-out scaffold-only state to film for "Day 1: Rojo + scaffold." A `git stash`-of-everything is impractical. Substitute: VS Code shot of the empty `default.project.json` view.
- **Issue 2:** Caption claims "~350 lines of Luau." Verify with `wc -l src/**/*.lua` before locking — number could be off after Days 9–11.
- **Recommended action:** Drop from week-one rotation; queue for week 4+ alongside a Phase 2 recap.
- **Capture time delta:** matches plan if recorded; saves ~10 min capture + heavier editor lift if dropped.

### Pre-recording checklist

Ordered by what blocks recording, then by lift.

| # | Task | File(s) | Estimate | Blocks recording? | When |
|---|---|---|---|---|---|
| 1 | Reconceive Clip 08 premise (or swap to BAN remote story). | (planning only) | 15 min | **Y** | Tonight |
| 2 | Rewrite Clip 02 caption to drop the false priority claim; decide whether to end chain on Kick (no payoff) or Ban (real +20 popup). | `docs/clips.md` | 10 min | **Y** | Tonight |
| 3 | Add temp single-spawn debug for Clip 02 isolated Spammer. ~5 lines, gitignored. | new `Tools/SoloSpawn.server.lua` | 15 min | **Y** | Sunday morning |
| 4 | Verify all four Tool TextureIds (BanHammer / MuteGun / TimeoutCard / KickBoot) exist in your current Studio place file. | Studio only | 5 min | **Y** | Sunday morning, first thing |
| 5 | Decide on full-screen flash overlay for Clips 04 + 07. Accept current visual OR add overlay (does both clips). | new `MainUI/FlashOverlay.model.json` + 10 lines in ClientMain | 20 min | N | Tonight if doing it |
| 6 | Tally line count for Clip 10 caption (`wc -l src/**/*.lua`). Update or drop if dropping clip 10. | none | 2 min | N | Tonight |
| 7 | Fix KickBoot ToolTip from "Kick" → "Kick Boot" if you want clip / hotbar consistency. | `src/StarterPack/KickBoot/init.meta.json` | 1 min | N | Tonight (trivial) |
| 8 | Optional: hide CoreGui (chat, leaderboard) for clean recording. 1-line `RecordMode.client.lua`, gitignored. | new file | 5 min | N | Sunday morning |
| 9 | Pre-write the bad CFrame-tween shake for Clip 03 on `clip03-bad-shake` branch. | `BanHammerScript.client.lua` | 15 min | N | Tonight |
| 10 | Verify Wave 1 "N left" rendering after the recent fixes. If still broken, dig before Sunday. | (testing) | 5 min | N | Tonight |

**Hard blockers** (must-fix before camera rolls): items **1, 2, 3, 4**. Everything else is polish.

### Updated cut-to-6 (post-audit)

The original cut-to-6 was: 01, 02, 03, 04, 05, 07. After audit, **Clip 08 was already excluded** from the cut-to-6, so the list survives intact:

1. **Clip 01** — The loadout (intact; verify Studio icons)
2. **Clip 02** — All three at once (intact mechanically; **caption rewrite required**, payoff decision required)
3. **Clip 03** — Don't tween the camera (intact lesson; **bad version must be written, not restored**)
4. **Clip 04** — SERVER DEAD (intact text; visual smaller than spec — accept or add overlay)
5. **Clip 05** — The whiff bug (intact; **most reliable** of the six — straight 2-line edit works)
6. **Clip 07** — VICTORY (intact text; same overlay decision as clip 04)

**Order shift:** None. The original spec front-loaded the strongest hooks correctly. Clip 05 (whiff bug) is now the **most reliable** because its before/after is bulletproof.

**Drop-priority if schedule eats further:** Clip 03 first (bad-version writing eats 15 extra min), then Clip 04 (visual underdelivers without the overlay). Clip 05 should be among the last to cut.

### Pure pre-production cuts (drop for Sunday, queue for later)

**Drop:**

- **Clip 08 — Empty packet.** Reconceive deliberately for week 4+ ("the one packet I let the client own" angle). Saves ~25 min Sunday.
- **Clip 10 — Phase 1 in five days.** Push to week 4+ as a "Phase 2 in N days" companion piece. Saves ~10 min capture + heavy editor lift later.

**Don't cut, even if tempting:**

- Clip 06 (failed icons) — all editor-table, doesn't compete for Studio time.
- Clip 09 (wave 3) — natural-feeling chaos take, only blocks on you nailing the rhythm.

If you cut both Clip 08 and Clip 10, the Sunday session goes from 10 → 8 clips, ~15–20 min back in the budget. Useful for the temp single-spawn debug script (item 3) and an extra losing/winning run for Clips 04 / 07.
