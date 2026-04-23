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

-- Spawning
Config.SPAWN_INTERVAL        = 2.5   -- seconds between each spawn within a wave

-- Ban Hammer
Config.BAN_DAMAGE            = 999
Config.BAN_RANGE             = 15
Config.BAN_COOLDOWN          = 0.5

-- Wave system
Config.WAVE_ENEMY_BASE       = 5     -- enemies in wave 1
Config.WAVE_ENEMY_SCALE      = 3     -- additional enemies added each wave
Config.WAVE_SPEED_SCALE      = 1.15  -- multiply enemy speed each wave (compounding)
Config.WAVE_BREAK_DURATION   = 8     -- seconds of break between waves
Config.SPAMMER_CHANCE        = 0.3   -- probability (0–1) an enemy is a Spammer (wave 2+)
Config.WAVES_TO_WIN          = 5     -- survive this many waves and the game declares victory

-- Currency (awarded on ban)
Config.COIN_TROLL            = 10
Config.COIN_SPAMMER          = 20

-- Upgrades
Config.UPGRADE_COOLDOWN_COST        = 50   -- base cost; scales linearly per level (lvl 1 = 50, lvl 2 = 100, lvl 3 = 150)
Config.UPGRADE_COOLDOWN_REDUCTION   = 0.1  -- seconds shaved off BAN_COOLDOWN per level
Config.UPGRADE_COOLDOWN_MIN         = 0.1  -- floor — cooldown will never drop below this
Config.UPGRADE_COOLDOWN_MAX_LEVEL   = 3

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
