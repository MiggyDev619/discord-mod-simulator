**MiggyDev — DMS Recording & Posting Plan**

*Saturday Apr 25 (pre-production complete) → Sunday Apr 26 recording → first post Mon Apr 27*

# **Status — Saturday night, 11pm**

| Pre-production: COMPLETE All §2.1 hard blockers landed. Three commits on main (4b2956b, ac6e0d2, 968cb50). One dirty branch (clip-recording-bad-shake) staged for tomorrow’s Clip 03 LEFT capture. Decisions logged in DEVLOG-NOTES. You are clear to sleep. |
| :---- |

## **What landed tonight**

### **Decisions logged in DEVLOG-NOTES.md**

☑  §2.1.1 Clip 02 caption finalized: "Three statuses, one Spammer, one launch into the void." Coin payoff dropped (Kick is non-destructive, no popup fires).

☑  §2.1.2 Clip 08 → BACKLOG with reconception notes. Premise was inverse of reality (kick aim is documented exception to server-auth).

☑  §2.1.3 Clip 10 → BACKLOG, reschedule to Phase 2 close. Better hook once you have a "Phase 2 in N days" companion piece.

☑  §2.2.1 Line count tallied: 1,691 Lua LOC across 15 files. Recorded for future Clip 10 reconception.

### **Commits on main**

| SHA | What | Why |
| :---- | :---- | :---- |
| 4b2956b | KickBoot ToolTip "Kick" → "Kick Boot" | Hotbar-spec consistency for Clip 01\. |
| ac6e0d2 | FlashOverlay (full-screen red/green flash on gameOver/gameWon, 0.15s in / 0.3s hold / 0.4s out, ZIndex 100, Active=false) | Real game improvement; double-duty for Clips 04 and 07\. Active=false means it doesn’t block UpgradeButton clicks. |
| 968cb50 | DEVLOG decisions \+ BACKLOG section | Records the four pre-production decisions and the two deferred clips. |

### **Dirty branch staged (NOT committed, NOT merged)**

clip-recording-bad-shake  
File modified: src/StarterPack/BanHammer/BanHammerScript.client.lua  
Change: shakeCamera() body replaced with the deliberately-bad CFrame loop that fights the default camera controller. Currently checked out. **You are on this branch right now.**

## **Updates discovered during execution**

**Two paths the original doc got wrong.** The Rojo project mapping audit caught both.

### **Path correction: RecordMode lives under StarterPlayer/**

Original §3.3 specified src/StarterPlayerScripts/RecordMode.client.lua — that path is NOT in the Rojo tree and would have silently never synced to Studio. Same trap as the Workspace pattern.  
**Correct path:** src/StarterPlayer/StarterPlayerScripts/RecordMode.debug.client.lua  
**SoloSpawn path is fine:** src/ServerScriptService/Tools/SoloSpawn.debug.server.lua — ServerScriptService maps the whole subtree, so Tools/ under it syncs automatically.

### **Naming convention: \*.debug suffix \+ pattern gitignore**

Instead of gitignoring debug scripts file-by-file, use a suffix convention. Two-line addition to .gitignore:  
  \*.debug.client.lua  
  \*.debug.server.lua  
Rojo decides script type by trailing suffix, so RecordMode.debug.client.lua still syncs as a LocalScript correctly. Generalizes to any future debug-only file.

## **What’s next**

Two windows of work remain: tonight (sleep) and tomorrow (Sunday).

* **Tonight:** nothing. Pre-production is done. Don’t open Studio.  
* **Sunday morning prep:** §3 of this doc, \~30 min. Studio file open, TextureIds verified, FlashOverlay tested, debug scripts created (with the corrected paths), .gitignore updated, OBS scenes ready, mic levels checked.  
* **Sunday recording session:** §4, \~2 hours. 8 clips. Capture only, no editing.  
* **Sunday EOD cleanup:** §4.5, 5 min. Branch nuke, RoundManager re-enable, debug scripts confirmed gitignored.  
* **Mon–Sat next week:** §5. Edit one clip per day. First post Mon Apr 27 with Clip 01\.

# **How to use this doc**

Read top to bottom in order. The boxes (☐) are check-as-you-go items. Items already complete are marked ☑ in green.  
**Critical decisions made for you (now finalized):**

* Sunday records **8 clips, not 10**. Clip 08 (empty packet) and Clip 10 (Phase 1 recap) deferred to BACKLOG.  
* Clip 02 caption finalized; coin payoff frame dropped.  
* Clip 03 bad version pre-written on a throwaway branch (already done).  
* Full-screen flash overlay shipped to main — covers Clips 04 and 07\.  
* Debug scripts use \*.debug.client.lua / \*.debug.server.lua suffix. Pattern-gitignored.

# **1\. Software setup (one-time)**

If you haven’t done these yet, do them tonight or in the Sunday morning prep window.

## **1.1 OBS Studio**

Free screen recorder. Used for: Roblox gameplay, F9 network panel, code editor screencaps. Studio’s built-in record is fine for gameplay only, but you’ll want OBS for everything else.

☐  Download from obsproject.com → install for Windows.

☐  On first launch, run the Auto-Configuration Wizard. Pick "Optimize for recording" (not streaming).

☐  Settings → Output → Recording: format \= MP4, encoder \= NVIDIA NVENC H.264 (Nvidia GPU) or x264 otherwise. Quality \= "Indistinguishable Quality, Large File".

☐  Settings → Video: Base Resolution \= 1920×1080, Output Resolution \= 1920×1080, FPS \= 60\.

☐  \[object Object\],\[object Object\],\[object Object\]

☐  Create a Scene called "Roblox Gameplay" with a Display Capture or Game Capture source pointed at Roblox.

☐  Create a second Scene called "Code Editor" with a Window Capture pointed at VS Code.

## **1.2 CapCut Desktop**

Free editor. Built for short-form (TikTok native), lower learning curve than DaVinci Resolve.

☐  Download from capcut.com → install desktop version (not mobile).

☐  Project settings: 1080×1920 (vertical, 9:16) for TikTok/Shorts/Reels. Re-export horizontal versions for X later.

☐  Familiarize: Text tool (hooks), Split tool (cuts), Speed (Clip 07 montage), Stickers panel for chevron arrows.

## **1.3 Snowball mic config**

☐  Plug into USB. Switch on back: position 1 (cardioid), not position 3 (omni picks up too much room noise).

☐  Distance: 6–8 inches from mouth, slightly off-axis (talk past it, not into it). Reduces plosives without a pop filter.

☐  Windows Sound Settings → Input → Snowball: Levels \= 80%. Listen tab unchecked. Enhancements tab → disable all (especially "Noise Suppression" which causes artifacts).

☐  Test in Audacity: 10 seconds of normal speech. Levels should peak around \-12 dB to \-6 dB. Adjust Windows mic level if peaks are clipping (red).

☐  Audacity (free, audacityteam.org) is your VO recording tool. Easier to edit a clean WAV than to scrub VO out of an OBS recording.

## **1.4 Brand assets**

☐  MiggyDev mark: 200×200 transparent PNG. Open Photopea, paste your existing logo, export. Save to Brand/miggydev-mark-200.png.

☐  \[object Object\]

  cyan-400      \#22d3ee  
  violet-400    \#a78bfa  
  zinc-950      \#09090b   (dark background)  
  red-warn      \#ef4444   (SERVER DEAD overlay — already shipped)  
  green-win     \#22c55e   (VICTORY overlay — already shipped)

☐  Font for on-screen text: Inter (free, fonts.google.com) or JetBrains Mono if you want the dev-coded look. Install once, set as CapCut default.

## **1.5 Folder structure**

E:/Content/DMS/  (root)  
  ├── Brand/                miggydev-mark-200.png, colors.txt  
  ├── Raw/                  Sunday’s OBS captures land here  
  │   ├── studio/           gameplay clips  
  │   ├── code/             editor screencaps  
  │   └── vo/               Audacity WAVs  
  ├── Edits/                CapCut project files \+ exports  
  └── Posted/               final exports, organized by post date

☐  Folder tree created on disk. Brand/ populated.

# **2\. Pre-production — COMPLETE (archived for reference)**

*All hard blockers landed Saturday night. Section preserved for the record.*

## **2.1 Hard blockers — finished**

☑  §2.1.1 Clip 02 caption decision logged — commit 968cb50.

☑  §2.1.2 Clip 08 deferred to BACKLOG — commit 968cb50.

☑  §2.1.3 Clip 10 deferred to BACKLOG — commit 968cb50.

☑  §2.1.4 Bad CFrame shake pre-written on clip-recording-bad-shake branch (uncommitted, dirty file ready).

☑  §2.1.5 FlashOverlay shipped to main — commit ac6e0d2. Red/green full-screen flash, ZIndex 100, Active=false.

## **2.2 Optional items — status**

☑  §2.2.1 Lua line count: 1,691 LOC / 15 files. Recorded.

☑  §2.2.2 KickBoot ToolTip fixed — commit 4b2956b.

# **3\. Sunday morning prep (before recording)**

30 minutes before you hit record. Coffee, then this. You start the morning on the clip-recording-bad-shake branch from last night.

## **3.1 Studio file setup**

☐  \[object Object\]

☐  \[object Object\],\[object Object\]

☐  \[object Object\]

☐  \[object Object\]

## **3.2 Update .gitignore (if not done)**

Add these two lines to .gitignore:  
  \*.debug.client.lua  
  \*.debug.server.lua

☐  .gitignore updated and committed. (Trivial commit, can be rolled into a small "tooling" commit if you prefer.)

## **3.3 Add SoloSpawn debug script (Clip 02 isolation)**

**Path:** src/ServerScriptService/Tools/SoloSpawn.debug.server.lua  
Auto-gitignored by the \*.debug.server.lua pattern. Maps to ServerScriptService.Tools.SoloSpawn in Studio.

Could be a BindableFunction, a module export, or a direct require. The session can wire it correctly in 2 minutes once it sees the surface area. Don’t write from memory.  
Skeleton (let the session adapt to the real API):  
  \-- SoloSpawn.debug.server.lua  (DEBUG, gitignored via \*.debug.server.lua)  
  \-- Chat command: /spawn   spawns one Spammer near the zone.  
  local Players \= game:GetService("Players")  
  \-- adapt to real EnemySpawner API  
  Players.PlayerAdded:Connect(function(plr)  
    plr.Chatted:Connect(function(msg)  
      if msg \== "/spawn" then ... end  
    end)  
  end)

☐  Script created at correct path, tested with /spawn chat command, single Spammer appears.

☐  \[object Object\],\[object Object\],\[object Object\],\[object Object\],\[object Object\]

## **3.4 Add RecordMode debug script (hide CoreGui)**

**Path:** src/StarterPlayer/StarterPlayerScripts/RecordMode.debug.client.lua  
Note: **NOT** src/StarterPlayerScripts/ — that path is not in the Rojo tree. The Rojo audit caught this.  
Auto-gitignored by the \*.debug.client.lua pattern.  
Contents:  
  game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)  
Removes chat, leaderboard, backpack indicator. Re-enable after recording by deleting the file.

☐  RecordMode script in place at corrected path, gitignored.

☐  \[object Object\],\[object Object\],\[object Object\]

## **3.5 OBS prep**

☐  Open OBS. Verify "Roblox Gameplay" scene captures cleanly (no Studio chrome, no F9 dev console showing).

☐  \[object Object\]

☐  Verify Snowball is selected as Audio Input Capture. Levels visible.

☐  Do a 10-second test recording. Play it back. Confirm: clean visuals, sync'd audio, no glitches.

# **4\. Sunday recording session (\~2 hours)**

Capture only. No editing today. 8 clips. You start on clip-recording-bad-shake branch (already there from last night).

## **4.1 In Roblox Studio (\~70 min)**

| \# | Capture | Time | Notes |
| :---- | :---- | :---- | :---- |
| 1 | Clip mode setup: clear scene, RoundManager disabled, RecordMode active. | 5 min | Fresh server, all four tools equipped. |
| 2 | Clip 01: solo tool firings (4 tools × 5 takes × \~30s). | 15 min | One tool per scene. /spawn for targets. |
| 3 | Clip 02: Mute → Timeout → Kick chain on a single Spammer. End on void launch. | 10 min | No \+20 coins frame. Use /spawn for solo Spammer. |
| 4 | Clip 03 LEFT: bad CFrame shake. You're already on the branch — capture 30s of bans. | 8 min | Branch swap is the risk. See 4.1.1 below for the cleanup sequence BEFORE moving on. |
| 5 | Clip 03 RIGHT: good CameraOffset shake. Capture during normal banning. | 3 min | After branch cleanup. Verify shake feels right before recording. |
| 6 | Clip 05: whiff bug. Hand-edit the if hitCount \> 0 then gate out, capture 2 whiffs with sound, re-add gate. | 7 min | DO NOT git checkout — just delete the 2 lines and put them back. |
| 7 | Clip 04: SERVER DEAD. Wave 3 spam-rush, intentionally play badly. FlashOverlay should fire red. | 10 min | 3–4 attempts; keep the most chaotic loss. |
| 8 | Clip 07: VICTORY. Full 5-wave win run. FlashOverlay should fire green. Difficulty pre-tuned (see 4.4). | 20 min | Plan for 30+ min if needed. Have backup gameplay queued. |
| 9 | Clip 09: Wave 3 transition. Waves 1→2→3 with rapid tool-swapping. | 10 min | 3–4 takes. Goal is the chaos rhythm at wave 3\. |

### **4.1.1 Critical: branch cleanup AFTER Clip 03 LEFT, BEFORE Clip 03 RIGHT**

The risk window is between filming Clip 03 LEFT and Clip 03 RIGHT. You must discard the bad-shake change and switch to main before capturing the good version. Sequence:  
  \# After filming Clip 03 LEFT  
  git checkout \-- src/StarterPack/BanHammer/BanHammerScript.client.lua  
  git checkout main  
  \# Verify Studio reloads with the good CameraOffset shake  
  \# before continuing

| Do NOT git checkout main while the file is still dirty. It’ll either error out (good — forces you to deal with it) or carry the bad changes over to main (very bad if you don’t notice). The discard step has to come first. Use git checkout \-- file BEFORE git checkout main. |
| :---- |

☐  Branch cleanup completed. On main with clean working tree before recording Clip 03 RIGHT.

## **4.2 Outside Studio (\~30 min)**

| \# | Capture | Time | Notes |
| :---- | :---- | :---- | :---- |
| 10 | Clip 06: re-generate three failed icons in ChatGPT (text-baked, gray-baked, all-purple). | 5 min | Reuse original prompts. PNGs to Raw/code/. |
| 11 | Clip 06: screenshot final 4-icon hotbar at 64×64 in Studio. | 2 min | Snipping Tool. Save to Raw/code/. |
| 12 | Clip 03: code editor screencap of the diff. OBS "Code Editor" scene. | 3 min | Bad CFrame block side-by-side with current CameraOffset. |
| 13 | Clip 05: code editor screencap of if hitCount \> 0 then gate. | 3 min | 2-line gate, highlighted. |

## **4.3 Voiceover passes (\~15 min)**

Record in Audacity, separate from OBS. Quiet room. One take per clip plus one safety take. Save WAVs to Raw/vo/.

* Clip 05 (\~12s): **"I shipped a bug. Then half-fixed it. Sound on miss — felt wrong, every other tool gates effects on contact. Half-fixed: no sound on whiff. Open question: visual without audio?"**  
* Clip 07 (\~5s): **"Five waves. Four tools. One server."**

Clip 08 VO not needed (deferred to BACKLOG). Save 5 minutes.

## **4.4 Tuning Clip 07 to de-risk the win run**

The audit flagged this as the schedule risk. Two pre-emptive moves:

1. Temporarily lower wave 5 enemy count or spawn rate. Revert before EOD Sunday.  
2. Have backup footage. Any successful run captures from Phase 1 testing should be queued. Don’t hold the session hostage to a single clean run.

## **4.5 EOD Sunday cleanup (5 min — DO NOT SKIP)**

☐  \[object Object\],\[object Object\],\[object Object\],\[object Object\],\[object Object\]

☐  \[object Object\],\[object Object\]

☐  \[object Object\],\[object Object\],\[object Object\]

☐  Revert Clip 07 difficulty tuning if you applied it.

☐  \[object Object\],\[object Object\],\[object Object\],\[object Object\],\[object Object\],\[object Object\],\[object Object\]

☐  Run the game one normal session. Confirm everything works as expected. No surprise commits Monday.

# **5\. Edit week (Mon–Sat, after Sunday recording)**

Edit one clip per day. Don’t batch. The brain fatigue from editing is the silent killer of clip quality.

## **5.1 Universal edit rules (every clip)**

* Vertical 1080×1920 (TikTok native). Re-export 1080×1080 square for X if needed.  
* MiggyDev mark in upper-right corner, \~150px wide, 70% opacity.  
* On-screen text: Inter or JetBrains Mono. Cyan-400 (\#22d3ee) on dark backgrounds, violet-400 (\#a78bfa) for accent. Drop shadow at 60% opacity.  
* First frame must be the hook. Aim for "stop scrolling in 0.4 seconds."  
* No music for week 1\. Captions and gameplay sounds carry it.  
* Length: 15–25s for player clips, 20–30s for dev clips. Hard cap at 30s.

## **5.2 Editing schedule**

| Day | Clip | Edit time | Posts on |
| :---- | :---- | :---- | :---- |
| Mon Apr 27 | Clip 01 — Loadout | \~1 hr | Mon Apr 27 (same day, evening post) |
| Tue Apr 28 | Clip 02 — Combo | \~45 min | Wed Apr 29 |
| Wed Apr 29 | Clip 03 — Camera shake | \~1 hr (split-screen comp) | Fri May 1 |
| Thu Apr 30 | Clip 04 — SERVER DEAD | \~30 min | Mon May 4 |
| Fri May 1 | Clip 05 — Whiff bug | \~45 min (VO \+ code overlay) | Wed May 6 |
| Sat May 2 | Clip 06 — Failed icons | \~45 min (still \+ transitions) | Fri May 8 |
| Mon May 4 | Clip 07 — VICTORY | \~1.5 hr (heaviest edit) | Mon May 11 |
| Tue May 5 | Clip 09 — Wave 3 | \~30 min | Wed May 13 |

Mon Apr 27: tight turnaround on Clip 01\. If anything blocks, push first post to Wed Apr 29 with Clip 01\.

# **6\. Posting cadence**

Mon / Wed / Fri. Same time each day. Manual posting for week 1 — it forces you to learn each platform’s quirks.

## **6.1 Platforms**

* **TikTok** (@miggydev) — primary. Vertical 1080×1920. Caption \+ 3–5 hashtags. Cover image \= first frame.  
* **YouTube Shorts** — same vertical file. Caption shorter. Title is the hook line. Add \#Shorts in title.  
* **Instagram Reels** — same vertical file. Caption can be slightly longer. Hashtags in first comment, not caption.  
* **X (Twitter)** (@miggydev — verify handle availability) — repost as 1:1 square if possible. Caption is the whole story; hashtags optional.

## **6.2 Posting checklist (per clip, all 4 platforms \~15 min total)**

☐  TikTok: upload, paste caption, paste hashtags, set cover frame, post.

☐  YouTube Shorts: upload, title \= hook line \+ \#Shorts, description \= caption, post.

☐  Instagram Reels: upload, caption (no hashtags), post. Then comment hashtags on your own post.

☐  X: upload, caption, post. Square crop if needed.

☐  Log post: date, clip number, platform, post URL. Needed for content-engine analytics later.

## **6.3 What NOT to optimize for in week 1**

* Optimal posting time. Whatever time you can post consistently is the optimal time.  
* Trending audio. Use raw gameplay sound for now. Trends move faster than your edit pace.  
* Algorithm hacks. Specifics, brand consistency, and cadence beat tricks.  
* Engaging with comments aggressively. Reply to genuine questions; ignore everything else.

# **7\. Reference: 8 clip specs (final)**

The deferred clips (08, 10\) are listed at the end for tracking but not in Sunday’s capture plan.

### **Clip 01 — The loadout**

| Audience | Player |
| :---- | :---- |
| **Posts** | Mon Apr 27 |
| **Hook** | "When your Discord gets raided." (cyan on violet) |
| **Body** | Four tool icons drop in over 4s. Each followed by 2s of in-game firing (red ban / blue slow / yellow freeze / mint kick). Final frame: all four in hotbar, "Pick your main." |
| **Caption** | The full mod loadout. Which one do you actually need? |
| **Hashtags** | \#robloxdev \#robloxgame \#moderationsimulator |
| **Note** | Verify Tool TextureIds in Studio first. |

### **Clip 02 — All three at once**

| Audience | Player |
| :---- | :---- |
| **Posts** | Wed Apr 29 |
| **Hook** | "One Spammer. Three statuses. Fifteen seconds." |
| **Body** | Mute Gun (slow, blue) → Timeout Card (freeze, yellow) → Kick Boot (launch into void, mint flash). End on the void launch. NO \+20 coins frame (Kick is non-destructive, no popup fires). |
| **Caption** | Three statuses, one Spammer, one launch into the void. |
| **Hashtags** | \#robloxgame \#robloxdev \#gamefeel |
| **Note** | Caption finalized; original was inverse of priority ladder. Use /spawn for solo Spammer. |

### **Clip 03 — Don't tween the camera**

| Audience | Dev |
| :---- | :---- |
| **Posts** | Fri May 1 |
| **Hook** | "Roblox screen shake. Wrong way." (jittering text) |
| **Body** | Side-by-side, 12s. Left: bad CFrame tween (jitters, fights camera). Right: Humanoid.CameraOffset (smooth). 4s text overlay: "Don't tween Camera.CFrame. Use Humanoid.CameraOffset." |
| **Caption** | First time you try screen shake in Roblox you fight the camera controller for an hour. There is a one-property fix. |
| **Hashtags** | \#robloxdev \#gamefeel \#luau |
| **Note** | Bad version pre-written on clip-recording-bad-shake branch. Cleanup sequence in §4.1.1. |

### **Clip 04 — SERVER DEAD**

| Audience | Player |
| :---- | :---- |
| **Posts** | Mon May 4 |
| **Hook** | "Don’t blink." (over chaos, no music) |
| **Body** | Wave 3 chaos. Health label ticks 6→0. Camera shake on each hit. Health 0 → SERVER DEAD text \+ full-screen red flash overlay (commit ac6e0d2). Cut hard to black. |
| **Caption** | Letting trolls into your Discord, visualized. The server doesn't get a second chance. |
| **Hashtags** | \#robloxgame \#robloxdev \#moderationsimulator |
| **Note** | FlashOverlay shipped to main. Don’t skip the visual hit. |

### **Clip 05 — The whiff bug**

| Audience | Dev |
| :---- | :---- |
| **Posts** | Wed May 6 |
| **Hook** | VO over silent Kick Boot icon shot: "I shipped a bug. Then half-fixed it." |
| **Body** | Old behavior (sound on miss) → VO explains. Cut: same whiff, silent (current). 3s code overlay: if hitCount \> 0 then. Closing text: "Open question — visual without audio on miss?" |
| **Caption** | Yesterday's bug. Today's half-fix. Tomorrow's open question. Probably visuals on whiff, no sound. Filed for next week. |
| **Hashtags** | \#robloxdev \#gamedev \#buildinginpublic |
| **Note** | Hand-edit the 2-line gate during recording — DON'T checkout the whole file from history. |

### **Clip 06 — Three failed icons**

| Audience | Dev |
| :---- | :---- |
| **Posts** | Fri May 8 |
| **Hook** | "Three failed icons before this one worked." |
| **Body** | a) "BAN" baked text → "no text — letters become red mush at 64px"; b) Gray bg → "transparent PNG only"; c) All-purple Mute Gun → "one accent against the body or it disappears." Cut to four current icons in hotbar at 64×64. End text: "Constraints over aesthetics." |
| **Caption** | AI image gen always pads, always bakes backgrounds, always wants text on the icon. Three rules for surviving a 64×64 hotbar. |
| **Hashtags** | \#robloxdev \#aiart \#gameicons |
| **Note** | Pure editor-table work; no Studio gameplay needed. |

### **Clip 07 — VICTORY**

| Audience | Player |
| :---- | :---- |
| **Posts** | Mon May 11 |
| **Hook** | VO over wave-1 calm: "Five waves. Four tools. One server." |
| **Body** | Speedrun cuts: wave 1→2→3→4→5, \~3s per wave. Last enemy of wave 5 banned. Full-screen green flash overlay \+ VICTORY text. Cut on the moment. |
| **Caption** | Five waves of trolls. Cleared. The first time it felt like a real game. |
| **Hashtags** | \#robloxgame \#robloxdev \#moderationsimulator |
| **Note** | Pair with Clip 04 emotionally. Tune wave 5 difficulty if needed for clean win. |

### **Clip 09 — Wave 3 is when you start sweating**

| Audience | Player |
| :---- | :---- |
| **Posts** | Wed May 13 |
| **Hook** | "Wave 1 is the tutorial." (over calm wave 1\) |
| **Body** | Wave indicator ticks 1/5, 2/5 (\~8s). Wave 3 in 7s countdown. Cut: orange Spammer flood. Player swaps tools rapidly. Sound layers chaotically. End on cleared zone, breath out. |
| **Caption** | Wave 1 is the tutorial. Wave 3 is when you start sweating. |
| **Hashtags** | \#robloxgame \#robloxdev \#moderationsimulator |
| **Note** | Tension-escalation is universally readable, no game knowledge required. |

## **Deferred to BACKLOG (per commit 968cb50)**

* **Clip 08 — Empty packet.** Premise was inverse of reality (kick aim is the documented exception to server-auth). Reconceive as "the one packet I let the client own" or refocus on the Ban remote. Target week 4+.  
* **Clip 10 — Phase 1 in five days.** No checked-out scaffold state to film, animated milestone-table is editor-heavy, recap clips need an audience to recap for. Defer to Phase 2 close as a "Phase 2 in N days" companion. Real LOC available: 1,691 across 15 files for Phase 1\.

# **Appendix: command reference**

## **Branch handling for Sunday**

You start the morning on clip-recording-bad-shake (already there from last night). The branch has BanHammerScript.client.lua modified to the bad CFrame loop.

  \# Saturday night state — you are HERE  
  git status  \# → on clip-recording-bad-shake, file dirty

  \# During Clip 03 LEFT recording  
  \# rojo serve  → Studio gets the bad shake. Capture.

  \# IMMEDIATELY AFTER Clip 03 LEFT, BEFORE moving on  
  git checkout \-- src/StarterPack/BanHammer/BanHammerScript.client.lua  
  git checkout main  
  git status  \# → should be clean, on main

  \# EOD Sunday cleanup  
  git branch \-D clip-recording-bad-shake

## **VS Code shortcuts for code screencaps**

* Cmd/Ctrl \+ B: toggle sidebar (hide for cleaner frame)  
* Cmd/Ctrl \+ Shift \+ P → "Toggle Zen Mode": single-file fullscreen, distraction-free  
* Cmd/Ctrl \+ \+/-: zoom font for legibility on mobile screens

## **OBS hotkeys for the recording session**

* F8: Start/Stop Recording (NOT F9 — conflicts with Studio dev console)  
* Scene transitions: bind 1, 2, 3 to scenes for fast switching

## **Daily editing routine (1 clip)**

3. Open Raw/ folder. Pick the take. Move to Edits/clip-XX/.  
4. CapCut: new project, 1080×1920, drop in raw clip.  
5. Trim to length, add hook text, add MiggyDev mark, add captions if applicable.  
6. Export 1080×1920 H.264 high quality. Save to Posted/ folder with date prefix.  
7. Cross-post per §6.2.  
8. Log in spreadsheet.