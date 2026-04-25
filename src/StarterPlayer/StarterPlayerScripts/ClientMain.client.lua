-- StarterPlayer/StarterPlayerScripts/ClientMain
-- Wires up MainUI: health, currency, wave status, and the upgrade button.
-- Reads currency/cooldown state from Player attributes (replicated by CurrencyManager).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local Shared             = ReplicatedStorage:WaitForChild("Shared")
local Config             = require(Shared:WaitForChild("Config"))
local remotes            = Shared:WaitForChild("Remotes")
local healthChanged      = remotes:WaitForChild("HealthChanged")
local gameOver           = remotes:WaitForChild("GameOver")
local gameWon            = remotes:WaitForChild("GameWon")
local waveStarted        = remotes:WaitForChild("WaveStarted")
local waveBreak          = remotes:WaitForChild("WaveBreak")
local purchaseUpgrade    = remotes:WaitForChild("PurchaseUpgrade")
local enemyCountChanged  = remotes:WaitForChild("EnemyCountChanged")

local player        = Players.LocalPlayer
local playerGui     = player:WaitForChild("PlayerGui")
local mainUI        = playerGui:WaitForChild("MainUI")
local healthBar     = mainUI:WaitForChild("HealthLabel")
local healthFill    = healthBar:WaitForChild("Fill")
local healthText    = healthBar:WaitForChild("Label")
local currencyLabel = mainUI:WaitForChild("CurrencyLabel")
local waveLabel     = mainUI:WaitForChild("WaveLabel")
local upgradeButton = mainUI:WaitForChild("UpgradeButton")
local cooldownPanel = mainUI:WaitForChild("CooldownPanel")
local flashOverlay  = mainUI:WaitForChild("FlashOverlay")

local runEnded = false  -- set true once either GameOver or GameWon fires

-- Health bar: width tweens with health %, color crosses green→yellow→red.
-- Tweening Size and BackgroundColor3 in one TweenService call keeps them in sync.
local HEALTH_TWEEN  = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HEALTH_GREEN  = Color3.fromRGB(60, 200, 80)
local HEALTH_YELLOW = Color3.fromRGB(240, 210, 50)
local HEALTH_RED    = Color3.fromRGB(220, 60, 60)

local function healthColor(pct)
	if pct > 0.6 then
		return HEALTH_GREEN
	elseif pct > 0.3 then
		return HEALTH_YELLOW
	else
		return HEALTH_RED
	end
end

-- Full-screen flash on run end. Shape: fade to half-opacity, hold, fade out.
-- Frame is Active=false + ZIndex=100 in model.json so the overlay sits above
-- other MainUI elements without sinking input clicks.
local FLASH_FADE_IN  = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FLASH_FADE_OUT = TweenInfo.new(0.40, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local FLASH_HOLD     = 0.30
local FLASH_RED      = Color3.fromRGB(255, 70, 70)
local FLASH_GREEN    = Color3.fromRGB(80, 255, 140)

local function playFlash(color)
	flashOverlay.BackgroundColor3       = color
	flashOverlay.BackgroundTransparency = 1
	TweenService:Create(flashOverlay, FLASH_FADE_IN, {BackgroundTransparency = 0.5}):Play()
	task.delay(FLASH_FADE_IN.Time + FLASH_HOLD, function()
		TweenService:Create(flashOverlay, FLASH_FADE_OUT, {BackgroundTransparency = 1}):Play()
	end)
end

healthChanged.OnClientEvent:Connect(function(current, max)
	if runEnded then return end
	local pct = math.clamp(current / max, 0, 1)
	TweenService:Create(healthFill, HEALTH_TWEEN, {
		Size             = UDim2.new(pct, 0, 1, 0),
		BackgroundColor3 = healthColor(pct),
	}):Play()
	healthText.Text = current .. " / " .. max
end)

gameOver.OnClientEvent:Connect(function()
	runEnded = true
	healthText.Text       = "SERVER DEAD"
	healthText.TextColor3 = Color3.fromRGB(255, 50, 50)
	TweenService:Create(healthFill, HEALTH_TWEEN, {
		Size             = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = HEALTH_RED,
	}):Play()
	waveLabel.Text = "Run ended"
	waveLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
	playFlash(FLASH_RED)
	print("[ClientMain] Game over received")
end)

gameWon.OnClientEvent:Connect(function()
	runEnded = true
	waveLabel.Text       = "VICTORY"
	waveLabel.TextColor3 = Color3.fromRGB(80, 255, 140)
	healthText.TextColor3 = Color3.fromRGB(80, 255, 140)
	playFlash(FLASH_GREEN)
	print("[ClientMain] Victory received")
end)

-- Wave label is rendered from a tiny state machine because we combine inputs
-- from three sources: WaveStarted (wave+total), WaveBreak (countdown), and
-- EnemyCountChanged (live remaining-enemy count). Render whenever any input updates.
local waveState = {
	mode         = "idle",   -- "idle" | "wave" | "break"
	wave         = 0,
	total        = 0,
	secondsLeft  = 0,
	enemyCount   = 0,
}

local function renderWaveLabel()
	if runEnded then return end
	if waveState.mode == "wave" then
		waveLabel.Text = string.format("Wave %d / %d  —  %d left",
			waveState.wave, waveState.total, waveState.enemyCount)
		waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif waveState.mode == "break" then
		waveLabel.Text = string.format("Wave %d / %d in %ds",
			waveState.wave, waveState.total, waveState.secondsLeft)
		waveLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	end
end

waveStarted.OnClientEvent:Connect(function(wave, total)
	if runEnded then return end
	waveState.mode  = "wave"
	waveState.wave  = wave
	waveState.total = total
	renderWaveLabel()
end)

waveBreak.OnClientEvent:Connect(function(nextWave, total, secondsLeft)
	if runEnded then return end
	waveState.mode        = "break"
	waveState.wave        = nextWave
	waveState.total       = total
	waveState.secondsLeft = secondsLeft
	renderWaveLabel()
end)

enemyCountChanged.OnClientEvent:Connect(function(count)
	waveState.enemyCount = count
	renderWaveLabel()
end)

-- Currency + upgrade button
local CURRENCY_GOLD       = Color3.fromRGB(255, 215, 0)
local CURRENCY_FLASH      = Color3.fromRGB(255, 255, 180)
local CURRENCY_PULSE_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
local FLOATER_INFO        = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local lastCoins = 0

local function spawnCoinFloater(delta)
	-- Floater is parented to the currency label so it follows if the label moves.
	-- Anchored top-right of the label, drifts up while fading.
	local floater = Instance.new("TextLabel")
	floater.Name                   = "Floater"
	floater.Size                   = UDim2.new(0, 80, 0, 28)
	floater.Position               = UDim2.new(1, 4, 0, 6)
	floater.AnchorPoint            = Vector2.new(0, 0)
	floater.BackgroundTransparency = 1
	floater.Text                   = "+" .. delta
	floater.TextColor3             = CURRENCY_GOLD
	floater.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
	floater.TextStrokeTransparency = 0.3
	floater.Font                   = Enum.Font.GothamBold
	floater.TextScaled             = true
	floater.TextXAlignment         = Enum.TextXAlignment.Left
	floater.Parent                 = currencyLabel

	TweenService:Create(floater, FLOATER_INFO, {
		Position               = UDim2.new(1, 4, 0, -28),
		TextTransparency       = 1,
		TextStrokeTransparency = 1,
	}):Play()

	task.delay(FLOATER_INFO.Time, function()
		floater:Destroy()
	end)
end

local function updateCurrency()
	local coins = player:GetAttribute("Coins") or 0
	local delta = coins - lastCoins
	currencyLabel.Text = "Coins: " .. coins
	if delta > 0 then
		-- Brief color flash on the main label, plus a +N floater for the gain amount.
		TweenService:Create(currencyLabel, CURRENCY_PULSE_INFO, {
			TextColor3 = CURRENCY_FLASH,
		}):Play()
		spawnCoinFloater(delta)
	end
	lastCoins = coins
end

local function updateUpgradeButton()
	local level = player:GetAttribute("CooldownLevel") or 0
	if level >= Config.UPGRADE_COOLDOWN_MAX_LEVEL then
		upgradeButton.Text        = "Ban Hammer: MAXED"
		upgradeButton.AutoButtonColor = false
	else
		local cost = Config.UPGRADE_COOLDOWN_COST * (level + 1)
		upgradeButton.Text = string.format("Faster Ban Hammer  Lv %d → %d  (%d coins)", level, level + 1, cost)
		upgradeButton.AutoButtonColor = true
	end
end

upgradeButton.MouseButton1Click:Connect(function()
	purchaseUpgrade:FireServer("Cooldown")
end)

player:GetAttributeChangedSignal("Coins"):Connect(updateCurrency)
player:GetAttributeChangedSignal("CooldownLevel"):Connect(updateUpgradeButton)

-- Seed lastCoins to the current value so the initial render doesn't spawn a
-- "+N" floater for whatever amount the player loaded in with.
lastCoins = player:GetAttribute("Coins") or 0
updateCurrency()
updateUpgradeButton()

-- Cooldown panel: each tool LocalScript writes a `<Tool>ReadyAt` attribute on
-- the LocalPlayer when activated. Per frame we compute remaining seconds, dim
-- the slot while on cooldown, and surface the timer text. Writes are local-only
-- (client-set attributes don't replicate to server) — no remote traffic needed.
local COOLDOWN_DIM_TRANSPARENCY = 0.55  -- on cooldown
local COOLDOWN_LIT_TRANSPARENCY = 0     -- ready

local cooldownSlots = {
	{ name = "Ban",     attr = "BanReadyAt",     slot = cooldownPanel:WaitForChild("Ban") },
	{ name = "Mute",    attr = "MuteReadyAt",    slot = cooldownPanel:WaitForChild("Mute") },
	{ name = "Timeout", attr = "TimeoutReadyAt", slot = cooldownPanel:WaitForChild("Timeout") },
	{ name = "Kick",    attr = "KickReadyAt",    slot = cooldownPanel:WaitForChild("Kick") },
}
for _, s in ipairs(cooldownSlots) do
	s.timer = s.slot:WaitForChild("Timer")
end

RunService.Heartbeat:Connect(function()
	local now = tick()
	for _, s in ipairs(cooldownSlots) do
		local readyAt   = player:GetAttribute(s.attr)
		local remaining = readyAt and (readyAt - now) or 0
		if remaining > 0 then
			s.slot.BackgroundTransparency = COOLDOWN_DIM_TRANSPARENCY
			s.timer.Text                  = string.format("%.1f", remaining)
			s.timer.Visible               = true
		else
			s.slot.BackgroundTransparency = COOLDOWN_LIT_TRANSPARENCY
			s.timer.Visible               = false
		end
	end
end)

print("[ClientMain] UI connected")
