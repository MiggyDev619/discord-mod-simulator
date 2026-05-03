-- ReplicatedStorage/Shared/Config
-- All tunable values in one place. Change numbers here only.

local Config = {}

-- Server
Config.SERVER_MAX_HEALTH     = 100
Config.SERVER_DAMAGE         = 10    -- per enemy that reaches ServerZone

-- Troll enemy (slow, tanky)
Config.ENEMY_SPEED           = 12
Config.ENEMY_HEALTH          = 30
Config.ENEMY_DAMAGE_INTERVAL = 1     -- seconds between damage ticks at zone

-- Spammer enemy (fast, weak)
Config.SPAMMER_SPEED         = 24
Config.SPAMMER_HEALTH        = 10

-- Teleporter enemy (medium-slow walk, but warps forward periodically — annoying to track)
Config.TELEPORTER_SPEED      = 10    -- slower than troll on foot, but warps make up for it
Config.TELEPORTER_HEALTH     = 25
Config.TELEPORTER_INTERVAL   = 2.0   -- seconds between warps (more frequent — players need to react fast)
Config.TELEPORTER_DISTANCE   = 22    -- studs jumped per warp; big enough to feel like teleport, not a hop
Config.TELEPORTER_SOUND_ID       = "rbxassetid://133226202202712"
Config.TELEPORTER_SOUND_VOLUME   = 0.7

-- Meme enemies (Day 25 polish) — pure flavor variants with chat-bubble speech.
-- Stats are intentionally distinct from the base 4 (Troll/Spammer/Teleporter/
-- Splitter) so they read as "different category" not "more of the same."

-- Karen: slow, high HP — the "Karen who won't leave the channel" enemy.
Config.KAREN_SPEED   = 10
Config.KAREN_HEALTH  = 40
Config.KAREN_CHANCE  = 0.10  -- wave 2+
Config.COIN_KAREN    = 25

-- Furry: fast, fragile — chaos energy, slips through normal lines.
Config.FURRY_SPEED   = 28
Config.FURRY_HEALTH  = 8
Config.FURRY_CHANCE  = 0.15  -- wave 3+
Config.COIN_FURRY    = 22

-- Discord Mod: medium speed + HP — power-tripping rule-enforcer.
Config.DISCORD_MOD_SPEED  = 15
Config.DISCORD_MOD_HEALTH = 25
Config.DISCORD_MOD_CHANCE = 0.10  -- wave 4+
Config.COIN_DISCORD_MOD   = 28

-- Splitter enemy (banning it spawns smaller, faster children — "one spam account, two more appear")
Config.SPLITTER_SPEED            = 14    -- between Troll and Spammer
Config.SPLITTER_HEALTH           = 20
Config.SPLITTER_CHILD_COUNT      = 2     -- children spawned per ban
Config.SPLITTER_CHILD_SPEED_RATIO = 1.35 -- child speed = parent's effective speed * this (preserves wave scaling)
Config.SPLITTER_CHILD_SIZE_RATIO  = 0.55 -- visual: children are clearly smaller
Config.SPLITTER_CHILD_OFFSET      = 4    -- studs apart when children appear (so they don't overlap)
Config.SPLITTER_SOUND_ID          = "rbxassetid://127599335301017"
Config.SPLITTER_SOUND_VOLUME      = 0.7

-- Spawning
Config.SPAWN_INTERVAL        = 2.5   -- seconds between each spawn within a wave

-- Ban Hammer
Config.BAN_DAMAGE            = 999
Config.BAN_RANGE             = 15
Config.BAN_COOLDOWN          = 0.5

-- Mute Gun (hitscan freeze gun — first hit freezes, second hit destroys)
-- Reworked from a slow-utility into a gun: distinguishes from Timeout Card by
-- requiring two hits but rewarding coins on the kill. Combo'd with Timeout
-- (already-frozen target) destroys in one shot.
Config.MUTE_RANGE            = 50    -- gun-feel — much longer than ban/timeout
Config.MUTE_COOLDOWN         = 1.5   -- slower than ban; takes 2 shots to kill
Config.MUTE_FREEZE_DURATION  = 3.0   -- first-hit freeze window before it wears off
Config.MUTE_SOUND_ID         = "rbxassetid://115994842117368"
Config.MUTE_SOUND_VOLUME     = 0.7

-- Timeout Card (full freeze; panic button — more saved-distance than mute per cast)
Config.TIMEOUT_RANGE         = 18    -- between ban and mute
Config.TIMEOUT_COOLDOWN      = 2.5   -- slower than mute, faster than the old 3.0 to stay useable
Config.TIMEOUT_DURATION      = 4.0   -- > mute's effective 3.75s of saved distance, so freeze > slow
Config.TIMEOUT_SOUND_ID      = "rbxassetid://9119366743"
Config.TIMEOUT_SOUND_VOLUME  = 0.7

-- Kick Boot (AOE pushback in a forward cone; non-destructive crowd control)
Config.KICK_RANGE            = 12    -- short — melee-ish
Config.KICK_CONE_ANGLE       = 60    -- degrees, full cone (30° to either side of LookVector)
Config.KICK_COOLDOWN         = 1.0   -- aggressive button, fast reuse
Config.KICK_FORCE            = 120   -- studs/sec pushback speed (≈72 studs distance over the window)
Config.KICK_DURATION         = 0.6   -- seconds BodyVelocity is overridden before normal walk resumes
Config.KICK_SOUND_ID         = "rbxassetid://140668097319606"
Config.KICK_SOUND_VOLUME     = 0.8

-- Wave system
Config.PRE_WAVE_DELAY        = 2     -- seconds before wave 1 starts; covers client boot + remote connect
Config.WAVE_ENEMY_BASE       = 5     -- enemies in wave 1
Config.WAVE_ENEMY_SCALE      = 3     -- additional enemies added each wave
Config.WAVE_SPEED_SCALE      = 1.15  -- multiply enemy speed each wave (compounding)
Config.WAVE_BREAK_DURATION   = 8     -- seconds of break between waves
Config.SPAMMER_CHANCE        = 0.3   -- probability (0–1) an enemy is a Spammer (wave 2+)
Config.TELEPORTER_CHANCE     = 0.2   -- probability (0–1) an enemy is a Teleporter (wave 3+)
Config.SPLITTER_CHANCE       = 0.15  -- probability (0–1) an enemy is a Splitter (wave 4+)
Config.WAVES_TO_WIN          = 5     -- survive this many waves and the game declares victory

-- Wave modifiers (chaos events). Rolled at wave start with MODIFIER_CHANCE
-- probability for waves >= 3. forceType overrides RoundManager's normal type
-- picker for the whole wave; enemyCountMult / speedMult stack onto the wave's
-- normal scaling. label is shown in the wave UI.
Config.MODIFIER_CHANCE = 0.30
Config.WAVE_MODIFIERS = {
	{
		key            = "SpamStorm",
		label          = "SPAM STORM",
		minWave        = 3,
		enemyCountMult = 1.5,   -- 50% more enemies
		speedMult      = 1.0,
		forceType      = "Spammer",
	},
	{
		key            = "ToxicWave",
		label          = "TOXIC WAVE",
		minWave        = 3,
		enemyCountMult = 1.0,
		speedMult      = 1.3,   -- 30% faster on top of normal scaling
		forceType      = nil,   -- normal type mix
	},
	{
		key            = "SplitterSurge",
		label          = "SPLITTER SURGE",
		minWave        = 4,     -- gated like Splitter spawning
		enemyCountMult = 1.0,   -- splitters already produce children — don't bump count
		speedMult      = 1.0,
		forceType      = "Splitter",
	},
}

-- Currency (awarded on ban)
Config.COIN_TROLL            = 10
Config.COIN_SPAMMER          = 20
Config.COIN_TELEPORTER       = 25   -- harder to catch — pays a bit more than spammer
Config.COIN_SPLITTER         = 30   -- dangerous if left alive — biggest non-child reward
Config.COIN_SPLITTER_CHILD   = 5    -- low — keeps splitter from being a coin farm
-- Meme enemy coin rewards live with their stats blocks above.
Config.COIN_KICK_PER_HIT     = 5    -- per enemy in the kick cone; small so it doesn't replace banning

-- Combo bonus: destroying an enemy with FrozenUntil OR MuteFrozenUntil active
-- multiplies the kill reward. Encourages setup plays (timeout → ban,
-- mute-shot → mute-shot, timeout → kick).
Config.COMBO_MULTIPLIER      = 2

-- Tool unlocks: Mute Gun, Timeout Card, Kick Boot are locked at start. Players
-- buy them from the upgrade panel. Ban Hammer is always granted via StarterPack.
-- toolName matches the folder name in ReplicatedStorage/Tools/.
-- Costs bumped 50% in Day 21-22 balance pass to give the Starter Pack
-- gamepass (499 R$ for all 3 + 500 coins) a meaningful coin-grind alternative.
-- Old: 100/150/200. New: 150/225/300. Total all 3: 675 (was 450).
Config.TOOL_UNLOCKS = {
	{ key = "MuteGun",     toolName = "MuteGun",     label = "Unlock Mute Gun",     cost = 150 },
	{ key = "KickBoot",    toolName = "KickBoot",    label = "Unlock Kick Boot",    cost = 225 },
	{ key = "TimeoutCard", toolName = "TimeoutCard", label = "Unlock Timeout Card", cost = 300 },
}

-- Upgrades (per-tool cooldown reductions). Each tool's LocalScript reads its
-- `<Tool>Cooldown` Player attribute (set by CurrencyManager to base − reduction*level).
-- Cost scales linearly: cost = baseCost * (level + 1).
-- One table drives server purchase logic AND client upgrade-panel UI rows — adding
-- a new upgrade is one entry here, no other code change.
Config.COOLDOWN_UPGRADES = {
	{
		key       = "Ban",
		label     = "Faster Ban Hammer",
		baseAttr  = "BanCooldown",
		levelAttr = "BanCooldownLevel",
		base      = Config.BAN_COOLDOWN,
		reduction = 0.1,
		minValue  = 0.1,
		maxLevel  = 3,
		baseCost  = 50,
	},
	{
		key       = "Mute",
		unlockKey = "MuteGun",  -- cooldown upgrade row stays hidden until tool unlocked
		label     = "Faster Mute Gun",
		baseAttr  = "MuteCooldown",
		levelAttr = "MuteCooldownLevel",
		base      = Config.MUTE_COOLDOWN,
		reduction = 0.25,
		minValue  = 0.5,
		maxLevel  = 3,
		baseCost  = 75,
	},
	{
		key       = "Timeout",
		unlockKey = "TimeoutCard",
		label     = "Faster Timeout Card",
		baseAttr  = "TimeoutCooldown",
		levelAttr = "TimeoutCooldownLevel",
		base      = Config.TIMEOUT_COOLDOWN,
		reduction = 0.4,
		minValue  = 1.0,
		maxLevel  = 3,
		baseCost  = 100,
	},
	{
		key       = "Kick",
		unlockKey = "KickBoot",
		label     = "Faster Kick Boot",
		baseAttr  = "KickCooldown",
		levelAttr = "KickCooldownLevel",
		base      = Config.KICK_COOLDOWN,
		reduction = 0.2,
		minValue  = 0.3,
		maxLevel  = 3,
		baseCost  = 50,
	},
}

-- Persistence (DataStore)
Config.PERSISTENCE_AUTOSAVE_INTERVAL = 60  -- seconds between dirty-player autosaves; PlayerRemoving + BindToClose also save

-- XP / player level. XP earned per kill = enemy's base coin Reward (combo
-- bonus does NOT inflate XP — combos reward you in coins, not progression).
-- Per-level requirement: level * XP_PER_LEVEL_BASE (lv 1→2 = 100, lv 2→3 = 200,
-- etc.). XP carries over on level-up, no XP wasted.
Config.XP_PER_LEVEL_BASE = 100
Config.XP_MAX_LEVEL      = 25

-- Gamepasses (one-time R$ purchases). `id` placeholders are 0 — replace with
-- real IDs from create.roblox.com. See docs/USER-ACTIONS.md §B.
-- effectAttr: name of the Player attribute set to true when ownership is detected.
Config.GAMEPASSES = {
	{
		key         = "DoubleCoins",
		id          = 1821265152,
		label       = "Double Coins",
		description = "Earn 2× coins from every kill, forever.",
		price       = 199,
		effectAttr  = "DoubleCoinsOwned",
	},
	{
		key         = "FasterCooldowns",
		id          = 1821712677,
		label       = "Faster Cooldowns",
		description = "All tools cool down 30% faster. Stacks with cooldown upgrades.",
		price       = 299,
		effectAttr  = "FasterCooldownsOwned",
	},
	{
		key         = "StarterPack",
		id          = 1821424911,
		label       = "Starter Pack",
		description = "Skip the early grind: all tool unlocks + 500 coins.",
		price       = 499,
		effectAttr  = "StarterPackOwned",
	},
}

-- Effect tunables for gamepasses
Config.DOUBLE_COINS_MULT       = 2     -- multiplier for AddCoins when DoubleCoinsOwned
Config.FASTER_COOLDOWNS_MULT   = 0.7   -- cooldown multiplier when FasterCooldownsOwned
Config.STARTER_PACK_COIN_GRANT = 500   -- one-time coin grant on first claim

-- Dev Products (consumable R$ purchases). Same placeholder pattern as gamepasses.
-- handler is the function key in ProductHandler that runs on grant.
Config.DEV_PRODUCTS = {
	{
		key         = "InstantRevive",
		id          = 3585511453,
		label       = "Instant Revive",
		description = "Restore your server's health to full mid-run.",
		price       = 99,
	},
	{
		key         = "CoinPackSmall",
		id          = 3585512509,
		label       = "Coin Pack — Small",
		description = "+100 coins instantly.",
		price       = 49,
		coinAmount  = 100,
	},
	{
		key         = "CoinPackLarge",
		id          = 3585516007,
		label       = "Coin Pack — Large",
		description = "+500 coins instantly.",
		price       = 199,
		coinAmount  = 500,
	},
	{
		key         = "XpBoost",
		id          = 3585516209,
		label       = "XP Boost (10 min)",
		description = "Earn 2× XP for the next 10 minutes.",
		price       = 99,
		durationSec = 600,
	},
}

Config.XP_BOOST_MULT = 2  -- multiplier for AddXp when XpBoostUntil > tick()

-- Effects
-- Drop a Roblox sound asset ID here (e.g. "rbxassetid://9125657040"). Empty string = silent ban.
-- In Studio: View → Toolbox → search "impact" / "whoosh" / "punch", right-click → Copy Asset ID.
Config.BAN_SOUND_ID                 = "rbxassetid://137041944943141"
Config.BAN_SOUND_VOLUME             = 0.8

-- Swing animation asset ID (e.g. "rbxassetid://507771019"). Empty string = no animation.
-- Either create your own via Avatar → Animation Editor, or grab one from View → Toolbox.
-- Must be published to Roblox (Save to Roblox, not local save) so it has an asset ID.
Config.BAN_SWING_ANIM_ID            = "rbxassetid://522635514"
Config.BAN_SWING_SPEED              = 1.5  -- anim playback multiplier; higher = snappier

return Config
