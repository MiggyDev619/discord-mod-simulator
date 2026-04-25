-- ReplicatedStorage/Shared/Effects
-- Small visual/audio effects triggered by gameplay events.
-- All effects are short-lived instances parented to workspace; they clean themselves up.

local TweenService = game:GetService("TweenService")
local Debris       = game:GetService("Debris")

local Config = require(script.Parent:WaitForChild("Config"))

local Effects = {}

-- Tunables kept local because they're not gameplay-tunable (change feel, not balance).
local PARTICLE_COUNT  = 25
local PARTICLE_COLOR  = Color3.fromRGB(255, 60, 60)
local POPUP_RISE      = 3         -- studs the +N text rises
local POPUP_DURATION  = 0.9
local EFFECT_LIFETIME = 1.5       -- seconds before cleanup
local FLASH_DURATION  = 0.15      -- seconds the enemy flashes white before despawn

local function createAnchor(position)
	local p = Instance.new("Part")
	p.Size          = Vector3.new(0.2, 0.2, 0.2)
	p.Position      = position
	p.Anchored      = true
	p.CanCollide    = false
	p.CanQuery      = false
	p.CanTouch      = false
	p.Transparency  = 1
	p.Parent        = workspace
	return p
end

local function playParticleBurst(anchor)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture      = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color        = ColorSequence.new(PARTICLE_COLOR)
	emitter.Size         = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime     = NumberRange.new(0.4, 0.8)
	emitter.Speed        = NumberRange.new(14, 22)
	emitter.SpreadAngle  = Vector2.new(180, 180)
	emitter.Rate         = 0
	emitter.LightEmission = 0.5
	emitter.Parent       = anchor
	emitter:Emit(PARTICLE_COUNT)
end

local function playBanSound(anchor)
	if Config.BAN_SOUND_ID == "" then return end
	local sound    = Instance.new("Sound")
	sound.SoundId  = Config.BAN_SOUND_ID
	sound.Volume   = Config.BAN_SOUND_VOLUME
	sound.Parent   = anchor
	sound:Play()
end

local function spawnCoinPopup(position, reward)
	local anchor = createAnchor(position + Vector3.new(0, 2, 0))

	local billboard = Instance.new("BillboardGui")
	billboard.Size         = UDim2.new(0, 120, 0, 40)
	billboard.AlwaysOnTop  = true
	billboard.LightInfluence = 0
	billboard.Parent       = anchor

	local label = Instance.new("TextLabel")
	label.Size                   = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text                   = "+" .. reward
	label.TextColor3             = Color3.fromRGB(255, 215, 0)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
	label.Font                   = Enum.Font.GothamBold
	label.TextSize               = 32
	label.Parent                 = billboard

	local rise = TweenService:Create(
		anchor,
		TweenInfo.new(POPUP_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = anchor.Position + Vector3.new(0, POPUP_RISE, 0) }
	)
	local fade = TweenService:Create(
		label,
		TweenInfo.new(POPUP_DURATION, Enum.EasingStyle.Linear),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }
	)
	rise:Play()
	fade:Play()

	Debris:AddItem(anchor, EFFECT_LIFETIME)
end

function Effects.BanEffect(position, reward)
	local anchor = createAnchor(position)
	playParticleBurst(anchor)
	playBanSound(anchor)
	Debris:AddItem(anchor, EFFECT_LIFETIME)

	if reward and reward > 0 then
		spawnCoinPopup(position, reward)
	end
end

-- Blue particle burst + optional sound at the position of a muted enemy.
function Effects.MuteEffect(position)
	local anchor = createAnchor(position)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture       = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color         = ColorSequence.new(Color3.fromRGB(70, 150, 255))
	emitter.Size          = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.0),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency  = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime      = NumberRange.new(0.3, 0.6)
	emitter.Speed         = NumberRange.new(8, 14)
	emitter.SpreadAngle   = Vector2.new(180, 180)
	emitter.Rate          = 0
	emitter.LightEmission = 0.4
	emitter.Parent        = anchor
	emitter:Emit(15)

	if Config.MUTE_SOUND_ID ~= "" then
		local sound   = Instance.new("Sound")
		sound.SoundId = Config.MUTE_SOUND_ID
		sound.Volume  = Config.MUTE_SOUND_VOLUME
		sound.Parent  = anchor
		sound:Play()
	end

	Debris:AddItem(anchor, EFFECT_LIFETIME)
end

-- Yellow particle burst + optional sound at the position of a timed-out enemy.
function Effects.TimeoutEffect(position)
	local anchor = createAnchor(position)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture       = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color         = ColorSequence.new(Color3.fromRGB(255, 200, 50))
	emitter.Size          = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.0),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency  = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime      = NumberRange.new(0.3, 0.6)
	emitter.Speed         = NumberRange.new(6, 10)
	emitter.SpreadAngle   = Vector2.new(180, 180)
	emitter.Rate          = 0
	emitter.LightEmission = 0.4
	emitter.Parent        = anchor
	emitter:Emit(18)

	if Config.TIMEOUT_SOUND_ID ~= "" then
		local sound   = Instance.new("Sound")
		sound.SoundId = Config.TIMEOUT_SOUND_ID
		sound.Volume  = Config.TIMEOUT_SOUND_VOLUME
		sound.Parent  = anchor
		sound:Play()
	end

	Debris:AddItem(anchor, EFFECT_LIFETIME)
end

-- Two-anchor purple burst: a fade-out at the departure spot and a fade-in at arrival.
-- Sells the warp visually so players see what just happened instead of a silent jump.
-- Also drops a short-lived purple PointLight at each end so the warp briefly glows.
function Effects.TeleportEffect(startPos, endPos)
	local function burst(pos, withSound)
		local anchor  = createAnchor(pos)

		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture       = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color         = ColorSequence.new(Color3.fromRGB(200, 80, 255))
		emitter.Size          = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 2.6),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.Transparency  = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		emitter.Lifetime      = NumberRange.new(0.4, 0.8)
		emitter.Speed         = NumberRange.new(20, 32)
		emitter.SpreadAngle   = Vector2.new(180, 180)
		emitter.Rate          = 0
		emitter.LightEmission = 0.8
		emitter.Parent        = anchor
		emitter:Emit(45)

		local light = Instance.new("PointLight")
		light.Color      = Color3.fromRGB(200, 80, 255)
		light.Brightness = 4
		light.Range      = 10
		light.Parent     = anchor

		if withSound and Config.TELEPORTER_SOUND_ID ~= "" then
			local sound   = Instance.new("Sound")
			sound.SoundId = Config.TELEPORTER_SOUND_ID
			sound.Volume  = Config.TELEPORTER_SOUND_VOLUME
			sound.Parent  = anchor
			sound:Play()
		end

		Debris:AddItem(anchor, EFFECT_LIFETIME)
	end
	burst(startPos, false)
	burst(endPos, true)
end

-- White/green shockwave at the player's feet when a Kick fires.
-- Visualizes the AOE — fires once per cast regardless of how many enemies got hit.
function Effects.KickEffect(position)
	local anchor = createAnchor(position)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture       = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color         = ColorSequence.new(Color3.fromRGB(180, 255, 200))
	emitter.Size          = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency  = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime      = NumberRange.new(0.35, 0.7)
	emitter.Speed         = NumberRange.new(32, 52)
	emitter.SpreadAngle   = Vector2.new(180, 180)
	emitter.Rate          = 0
	emitter.LightEmission = 0.7
	emitter.Parent        = anchor
	emitter:Emit(40)

	if Config.KICK_SOUND_ID ~= "" then
		local sound   = Instance.new("Sound")
		sound.SoundId = Config.KICK_SOUND_ID
		sound.Volume  = Config.KICK_SOUND_VOLUME
		sound.Parent  = anchor
		sound:Play()
	end

	Debris:AddItem(anchor, EFFECT_LIFETIME)
end

-- Flashes an enemy part white/neon, freezes it in place, and schedules its destruction.
-- Clears IsEnemy so other systems stop seeing it as targetable mid-flash.
function Effects.HitFlash(part)
	if not part or not part.Parent then return end

	part:SetAttribute("IsEnemy", false)
	part.Anchored   = true
	part.CanCollide = false
	part.Material   = Enum.Material.Neon
	part.Color      = Color3.fromRGB(255, 255, 255)

	local bv = part:FindFirstChildOfClass("BodyVelocity")
	if bv then bv:Destroy() end

	Debris:AddItem(part, FLASH_DURATION)
end

return Effects
