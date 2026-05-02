-- ReplicatedStorage/Shared/Effects
-- Small visual/audio effects triggered by gameplay events.
-- All effects are short-lived instances parented to workspace; they clean themselves up.

local TweenService = game:GetService("TweenService")
local Debris       = game:GetService("Debris")

local Config = require(script.Parent:WaitForChild("Config"))

local Effects = {}

-- Tunables kept local because they're not gameplay-tunable (change feel, not balance).
local PARTICLE_COUNT  = 50
local PARTICLE_COLOR  = Color3.fromRGB(255, 60, 60)
local POPUP_RISE      = 3         -- studs the +N text rises
local POPUP_DURATION  = 0.9
local EFFECT_LIFETIME = 1.5       -- seconds before cleanup
local FLASH_DURATION  = 0.08      -- seconds the enemy flashes white before despawn

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

	-- Expanding red shockwave sphere — punches through the white HitFlash so the
	-- ban reads as a destructive moment, not a quiet poof.
	local shockwave = Instance.new("Part")
	shockwave.Shape         = Enum.PartType.Ball
	shockwave.Size          = Vector3.new(1, 1, 1)
	shockwave.Position      = position
	shockwave.Anchored      = true
	shockwave.CanCollide    = false
	shockwave.CanQuery      = false
	shockwave.CanTouch      = false
	shockwave.Material      = Enum.Material.Neon
	shockwave.Color         = PARTICLE_COLOR
	shockwave.Transparency  = 0.2
	shockwave.Parent        = workspace
	TweenService:Create(shockwave, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(8, 8, 8),
		Transparency = 1,
	}):Play()
	Debris:AddItem(shockwave, 0.5)

	local light = Instance.new("PointLight")
	light.Color      = PARTICLE_COLOR
	light.Brightness = 5
	light.Range      = 14
	light.Parent     = anchor

	Debris:AddItem(anchor, EFFECT_LIFETIME)

	if reward and reward > 0 then
		spawnCoinPopup(position, reward)
	end

	spawnBanMemePopup(position)
end

-- Blue particle burst + shockwave + glow at the position of a muted enemy.
function Effects.MuteEffect(position)
	local anchor    = createAnchor(position)
	local muteColor = Color3.fromRGB(70, 150, 255)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture       = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color         = ColorSequence.new(muteColor)
	emitter.Size          = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency  = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime      = NumberRange.new(0.4, 0.8)
	emitter.Speed         = NumberRange.new(12, 20)
	emitter.SpreadAngle   = Vector2.new(180, 180)
	emitter.Rate          = 0
	emitter.LightEmission = 0.7
	emitter.Parent        = anchor
	emitter:Emit(40)

	-- Small expanding sphere — softer than Ban's (mute isn't destructive).
	local shockwave = Instance.new("Part")
	shockwave.Shape         = Enum.PartType.Ball
	shockwave.Size          = Vector3.new(1, 1, 1)
	shockwave.Position      = position
	shockwave.Anchored      = true
	shockwave.CanCollide    = false
	shockwave.CanQuery      = false
	shockwave.CanTouch      = false
	shockwave.Material      = Enum.Material.Neon
	shockwave.Color         = muteColor
	shockwave.Transparency  = 0.4
	shockwave.Parent        = workspace
	TweenService:Create(shockwave, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(5, 5, 5),
		Transparency = 1,
	}):Play()
	Debris:AddItem(shockwave, 0.5)

	local light = Instance.new("PointLight")
	light.Color      = muteColor
	light.Brightness = 4
	light.Range      = 12
	light.Parent     = anchor

	if Config.MUTE_SOUND_ID ~= "" then
		local sound   = Instance.new("Sound")
		sound.SoundId = Config.MUTE_SOUND_ID
		sound.Volume  = Config.MUTE_SOUND_VOLUME
		sound.Parent  = anchor
		sound:Play()
	end

	Debris:AddItem(anchor, EFFECT_LIFETIME)
end

-- Yellow particle burst + shockwave + glow at the position of a timed-out enemy.
function Effects.TimeoutEffect(position)
	local anchor       = createAnchor(position)
	local timeoutColor = Color3.fromRGB(255, 200, 50)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture       = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color         = ColorSequence.new(timeoutColor)
	emitter.Size          = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency  = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime      = NumberRange.new(0.4, 0.8)
	emitter.Speed         = NumberRange.new(10, 16)
	emitter.SpreadAngle   = Vector2.new(180, 180)
	emitter.Rate          = 0
	emitter.LightEmission = 0.7
	emitter.Parent        = anchor
	emitter:Emit(45)

	-- Small expanding sphere — same softer scale as Mute (status, not destructive).
	local shockwave = Instance.new("Part")
	shockwave.Shape         = Enum.PartType.Ball
	shockwave.Size          = Vector3.new(1, 1, 1)
	shockwave.Position      = position
	shockwave.Anchored      = true
	shockwave.CanCollide    = false
	shockwave.CanQuery      = false
	shockwave.CanTouch      = false
	shockwave.Material      = Enum.Material.Neon
	shockwave.Color         = timeoutColor
	shockwave.Transparency  = 0.4
	shockwave.Parent        = workspace
	TweenService:Create(shockwave, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(5, 5, 5),
		Transparency = 1,
	}):Play()
	Debris:AddItem(shockwave, 0.5)

	local light = Instance.new("PointLight")
	light.Color      = timeoutColor
	light.Brightness = 4
	light.Range      = 12
	light.Parent     = anchor

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
	local anchor    = createAnchor(position)
	local kickColor = Color3.fromRGB(120, 255, 160)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture       = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color         = ColorSequence.new(kickColor)
	emitter.Size          = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3.0),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency  = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime      = NumberRange.new(0.5, 0.9)
	emitter.Speed         = NumberRange.new(20, 35)
	emitter.SpreadAngle   = Vector2.new(180, 180)
	emitter.Rate          = 0
	emitter.LightEmission = 0.9
	emitter.Parent        = anchor
	emitter:Emit(70)

	-- Flat horizontal shockwave disc at ground level — sells the AOE cone visually.
	local shockwave = Instance.new("Part")
	shockwave.Shape         = Enum.PartType.Cylinder
	shockwave.Size          = Vector3.new(0.2, 1, 1)
	shockwave.CFrame        = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	shockwave.Anchored      = true
	shockwave.CanCollide    = false
	shockwave.CanQuery      = false
	shockwave.CanTouch      = false
	shockwave.Material      = Enum.Material.Neon
	shockwave.Color         = kickColor
	shockwave.Transparency  = 0.3
	shockwave.Parent        = workspace
	TweenService:Create(shockwave, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.2, 14, 14),
		Transparency = 1,
	}):Play()
	Debris:AddItem(shockwave, 0.5)

	local light = Instance.new("PointLight")
	light.Color      = kickColor
	light.Brightness = 5
	light.Range      = 14
	light.Parent     = anchor

	if Config.KICK_SOUND_ID ~= "" then
		local sound   = Instance.new("Sound")
		sound.SoundId = Config.KICK_SOUND_ID
		sound.Volume  = Config.KICK_SOUND_VOLUME
		sound.Parent  = anchor
		sound:Play()
	end

	Debris:AddItem(anchor, EFFECT_LIFETIME)
end

-- Pink particle puff + optional sound at the position of a banned Splitter.
-- Fires once per split (not per child) — sells the "one becomes many" beat.
function Effects.SplitEffect(position)
	local anchor = createAnchor(position)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture       = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color         = ColorSequence.new(Color3.fromRGB(255, 120, 200))
	emitter.Size          = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency  = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime      = NumberRange.new(0.3, 0.6)
	emitter.Speed         = NumberRange.new(16, 26)
	emitter.SpreadAngle   = Vector2.new(180, 180)
	emitter.Rate          = 0
	emitter.LightEmission = 0.6
	emitter.Parent        = anchor
	emitter:Emit(30)

	if Config.SPLITTER_SOUND_ID ~= "" then
		local sound   = Instance.new("Sound")
		sound.SoundId = Config.SPLITTER_SOUND_ID
		sound.Volume  = Config.SPLITTER_SOUND_VOLUME
		sound.Parent  = anchor
		sound:Play()
	end

	Debris:AddItem(anchor, EFFECT_LIFETIME)
end

-- Random "you got banned lol"-style popup that joins the BanEffect's coin
-- floater. Picks from a small pool of memey one-liners. Pure flavor.
local BAN_MEME_PHRASES = {
	"you got banned lol",
	"skill issue",
	"L + ratio",
	"imagine getting banned",
	"stay mad",
	"ratio'd",
	"go touch grass",
}

local function spawnBanMemePopup(position)
	local phrase = BAN_MEME_PHRASES[math.random(1, #BAN_MEME_PHRASES)]
	local anchor = createAnchor(position + Vector3.new(0, 4, 0))

	local billboard = Instance.new("BillboardGui")
	billboard.Size           = UDim2.new(0, 200, 0, 36)
	billboard.AlwaysOnTop    = true
	billboard.LightInfluence = 0
	billboard.Parent         = anchor

	local label = Instance.new("TextLabel")
	label.Size                   = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text                   = phrase
	label.TextColor3             = Color3.fromRGB(255, 80, 80)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
	label.Font                   = Enum.Font.GothamBold
	label.TextSize               = 22
	label.Parent                 = billboard

	local rise = TweenService:Create(
		anchor,
		TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = anchor.Position + Vector3.new(0, 4, 0) }
	)
	local fade = TweenService:Create(
		label,
		TweenInfo.new(1.4, Enum.EasingStyle.Linear),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }
	)
	rise:Play()
	fade:Play()
	Debris:AddItem(anchor, 1.6)
end

-- Speech bubble above an enemy (chat-bubble style). Used for meme enemies on
-- spawn. Anchored to the enemy's current position; doesn't follow if it moves
-- (cheap; lasts 3s, enemy will mostly still be near the spawn point).
function Effects.SpeechBubble(part, phrase)
	if not part or not part.Parent then return end
	local anchor = createAnchor(part.Position + Vector3.new(0, part.Size.Y / 2 + 2, 0))

	local billboard = Instance.new("BillboardGui")
	billboard.Size           = UDim2.new(0, 240, 0, 60)
	billboard.AlwaysOnTop    = true
	billboard.LightInfluence = 0
	billboard.Parent         = anchor

	local frame = Instance.new("Frame")
	frame.Size                   = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3       = Color3.fromRGB(20, 20, 24)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel        = 0
	frame.Parent                 = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent       = frame

	local label = Instance.new("TextLabel")
	label.Size                   = UDim2.new(1, -12, 1, -8)
	label.Position               = UDim2.new(0, 6, 0, 4)
	label.BackgroundTransparency = 1
	label.Text                   = phrase
	label.TextColor3             = Color3.fromRGB(250, 250, 250)
	label.Font                   = Enum.Font.Gotham
	label.TextSize               = 14
	label.TextWrapped            = true
	label.TextXAlignment         = Enum.TextXAlignment.Center
	label.TextYAlignment         = Enum.TextYAlignment.Center
	label.Parent                 = frame

	local rise = TweenService:Create(
		anchor,
		TweenInfo.new(2.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = anchor.Position + Vector3.new(0, 1.5, 0) }
	)
	local fade = TweenService:Create(frame, TweenInfo.new(2.8, Enum.EasingStyle.Linear), {
		BackgroundTransparency = 1,
	})
	local fadeText = TweenService:Create(label, TweenInfo.new(2.8, Enum.EasingStyle.Linear), {
		TextTransparency = 1,
	})
	rise:Play()
	fade:Play()
	fadeText:Play()
	Debris:AddItem(anchor, 3.0)
end

-- Hitscan tracer for the Mute Gun. Cyan/electric line stretched between gun
-- muzzle and hit point, plus a brief muzzle flash + light at the origin.
-- Fires every shot (hit or miss) so the gun feels alive even on whiffs.
function Effects.MuteTracer(fromPos, toPos)
	local diff     = toPos - fromPos
	local distance = diff.Magnitude
	if distance < 0.1 then return end

	local tracerColor = Color3.fromRGB(120, 200, 255)

	local tracer = Instance.new("Part")
	tracer.Anchored      = true
	tracer.CanCollide    = false
	tracer.CanQuery      = false
	tracer.CanTouch      = false
	tracer.CastShadow    = false
	tracer.Material      = Enum.Material.Neon
	tracer.Color         = tracerColor
	tracer.Size          = Vector3.new(0.15, 0.15, distance)
	tracer.CFrame        = CFrame.lookAt(fromPos, toPos) * CFrame.new(0, 0, -distance / 2)
	tracer.Transparency  = 0.1
	tracer.Parent        = workspace

	TweenService:Create(tracer, TweenInfo.new(0.18, Enum.EasingStyle.Linear), {
		Transparency = 1,
		Size         = Vector3.new(0.04, 0.04, distance),
	}):Play()
	Debris:AddItem(tracer, 0.3)

	-- Muzzle flash at gun tip — short particle burst + bright light.
	local flash = createAnchor(fromPos)

	local flashLight = Instance.new("PointLight")
	flashLight.Color      = tracerColor
	flashLight.Brightness = 8
	flashLight.Range      = 6
	flashLight.Parent     = flash

	local flashEmitter = Instance.new("ParticleEmitter")
	flashEmitter.Texture       = "rbxasset://textures/particles/sparkles_main.dds"
	flashEmitter.Color         = ColorSequence.new(Color3.fromRGB(180, 220, 255))
	flashEmitter.Size          = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	flashEmitter.Transparency  = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	flashEmitter.Lifetime      = NumberRange.new(0.1, 0.2)
	flashEmitter.Speed         = NumberRange.new(4, 8)
	flashEmitter.SpreadAngle   = Vector2.new(60, 60)
	flashEmitter.Rate          = 0
	flashEmitter.LightEmission = 0.9
	flashEmitter.Parent        = flash
	flashEmitter:Emit(8)

	Debris:AddItem(flash, 0.4)
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
