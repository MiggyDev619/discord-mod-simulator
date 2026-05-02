-- StarterPlayer/StarterPlayerScripts/ClientMain
-- Wires up MainUI: health, currency, wave status, and the upgrade button.
-- Reads currency/cooldown state from Player attributes (replicated by CurrencyManager).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local Shared             = ReplicatedStorage:WaitForChild("Shared")
local Config             = require(Shared:WaitForChild("Config"))
local Theme              = require(Shared:WaitForChild("Theme"))
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
local upgradePanel  = mainUI:WaitForChild("UpgradePanel")
local cooldownPanel = mainUI:WaitForChild("CooldownPanel")
local flashOverlay  = mainUI:WaitForChild("FlashOverlay")

local runEnded = false  -- set true once either GameOver or GameWon fires

-- Health bar: width tweens with health %, color crosses green→yellow→red.
-- Tweening Size and BackgroundColor3 in one TweenService call keeps them in sync.
local HEALTH_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function healthColor(pct)
	if pct > 0.6 then
		return Theme.HealthGreen
	elseif pct > 0.3 then
		return Theme.HealthYellow
	else
		return Theme.HealthRed
	end
end

-- Full-screen flash on run end. Shape: fade to half-opacity, hold, fade out.
-- Frame is Active=false + ZIndex=100 in model.json so the overlay sits above
-- other MainUI elements without sinking input clicks.
local FLASH_FADE_IN  = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FLASH_FADE_OUT = TweenInfo.new(0.40, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local FLASH_HOLD     = 0.30

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
	healthText.TextColor3 = Theme.RedWarn
	TweenService:Create(healthFill, HEALTH_TWEEN, {
		Size             = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.HealthRed,
	}):Play()
	waveLabel.Text = "Run ended"
	waveLabel.TextColor3 = Theme.RedWarn
	playFlash(Theme.RedWarn)
	print("[ClientMain] Game over received")
end)

gameWon.OnClientEvent:Connect(function()
	runEnded = true
	waveLabel.Text       = "VICTORY"
	waveLabel.TextColor3 = Theme.GreenWin
	healthText.TextColor3 = Theme.GreenWin
	playFlash(Theme.GreenWin)
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
	modifier     = nil,      -- string | nil — set on wave start, cleared on next wave
}

local function renderWaveLabel()
	if runEnded then return end
	if waveState.mode == "wave" then
		if waveState.modifier then
			waveLabel.Text = string.format("Wave %d / %d  —  %s  —  %d left",
				waveState.wave, waveState.total, waveState.modifier, waveState.enemyCount)
			waveLabel.TextColor3 = Theme.Yellow400
		else
			waveLabel.Text = string.format("Wave %d / %d  —  %d left",
				waveState.wave, waveState.total, waveState.enemyCount)
			waveLabel.TextColor3 = Theme.Zinc50
		end
	elseif waveState.mode == "break" then
		waveLabel.Text = string.format("Wave %d / %d in %ds",
			waveState.wave, waveState.total, waveState.secondsLeft)
		waveLabel.TextColor3 = Theme.Yellow400
	end
end

waveStarted.OnClientEvent:Connect(function(wave, total, modifierName)
	if runEnded then return end
	waveState.mode     = "wave"
	waveState.wave     = wave
	waveState.total    = total
	waveState.modifier = modifierName  -- nil for clean waves
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
	floater.TextColor3             = Theme.CurrencyGold
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
	local level = player:GetAttribute("Level") or 1
	local delta = coins - lastCoins
	currencyLabel.Text = string.format("Lv %d  ·  Coins: %d", level, coins)
	if delta > 0 then
		-- Brief color flash on the main label, plus a +N floater for the gain amount.
		TweenService:Create(currencyLabel, CURRENCY_PULSE_INFO, {
			TextColor3 = Theme.CurrencyFlash,
		}):Play()
		spawnCoinFloater(delta)
	end
	lastCoins = coins
end

local function flashLevelUp()
	-- Brief gold flash on the currency label whenever Level changes.
	TweenService:Create(currencyLabel, CURRENCY_PULSE_INFO, {
		TextColor3 = Theme.CurrencyFlash,
	}):Play()
end

player:GetAttributeChangedSignal("Coins"):Connect(updateCurrency)
player:GetAttributeChangedSignal("Level"):Connect(function()
	updateCurrency()
	flashLevelUp()
	print("[ClientMain] Level up →", player:GetAttribute("Level"))
end)

-- Seed lastCoins to the current value so the initial render doesn't spawn a
-- "+N" floater for whatever amount the player loaded in with.
lastCoins = player:GetAttribute("Coins") or 0
updateCurrency()

-- Upgrade panel: dynamic rows from Config. Two row types:
--  1. Unlock rows (TOOL_UNLOCKS) — one per locked tool, hides itself once owned.
--  2. Cooldown rows (COOLDOWN_UPGRADES) — visible only when the underlying tool
--     is unlocked (Ban Hammer is always visible; the others appear post-unlock).
-- UpgradeButton at top-right toggles the panel visible/hidden.

local function makeRow(layoutOrder, labelText, rowName)
	local row = Instance.new("Frame")
	row.Name                   = rowName
	row.Size                   = UDim2.new(1, 0, 0, 44)
	row.BackgroundTransparency = 1
	row.LayoutOrder            = layoutOrder
	row.ZIndex                 = 51

	local label = Instance.new("TextLabel")
	label.Size                   = UDim2.new(0.55, -4, 1, 0)
	label.Position               = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3             = Color3.fromRGB(250, 250, 250)
	label.Font                   = Enum.Font.GothamBold
	label.TextSize               = 16
	label.TextXAlignment         = Enum.TextXAlignment.Left
	label.TextYAlignment         = Enum.TextYAlignment.Center
	label.TextWrapped            = false
	label.Text                   = labelText
	label.ZIndex                 = 52
	label.Parent                 = row

	local button = Instance.new("TextButton")
	button.Name                   = "Buy"
	button.Size                   = UDim2.new(0.45, 0, 1, 0)
	button.Position               = UDim2.new(0.55, 4, 0, 0)
	button.BackgroundColor3       = Color3.fromRGB(250, 204, 21)
	button.BackgroundTransparency = 0
	button.TextColor3             = Color3.fromRGB(9, 9, 11)
	button.Font                   = Enum.Font.GothamBold
	button.TextSize               = 16
	button.AutoButtonColor        = true
	button.BorderSizePixel        = 0
	button.Text                   = "Buy"
	button.ZIndex                 = 52
	button.Parent                 = row
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent       = button

	return row, button
end

local function unlockedAttr(toolKey) return toolKey .. "Unlocked" end

-- Unlock rows (LayoutOrder 1..N — show first in panel)
local unlockRows = {}  -- [toolKey] = { ul = ul, row = row, button = button }
for i, ul in ipairs(Config.TOOL_UNLOCKS) do
	local row, button = makeRow(i, ul.label, ul.key .. "UnlockRow")
	row.Parent             = upgradePanel
	unlockRows[ul.key]     = { ul = ul, row = row, button = button }

	button.Text = string.format("Buy (%d)", ul.cost)

	button.MouseButton1Click:Connect(function()
		purchaseUpgrade:FireServer(ul.key)
	end)

	local function refresh()
		row.Visible = not (player:GetAttribute(unlockedAttr(ul.key)) == true)
	end
	refresh()
	player:GetAttributeChangedSignal(unlockedAttr(ul.key)):Connect(refresh)
end

-- Cooldown rows (LayoutOrder 100+ — show after unlocks)
local upgradeRows = {}  -- [key] = { upg = upg, row = row, button = button }

local function refreshCooldownRow(key)
	local entry = upgradeRows[key]
	if not entry then return end
	local upg    = entry.upg
	local button = entry.button
	local level  = player:GetAttribute(upg.levelAttr) or 0
	if level >= upg.maxLevel then
		button.Text             = "MAXED"
		button.AutoButtonColor  = false
		button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		button.TextColor3       = Color3.fromRGB(250, 250, 250)
	else
		local cost = upg.baseCost * (level + 1)
		button.Text             = string.format("Lv %d → %d (%d)", level, level + 1, cost)
		button.AutoButtonColor  = true
		button.BackgroundColor3 = Color3.fromRGB(250, 204, 21)
		button.TextColor3       = Color3.fromRGB(9, 9, 11)
	end
end

for i, upg in ipairs(Config.COOLDOWN_UPGRADES) do
	local row, button = makeRow(100 + i, upg.label, upg.key .. "Row")
	row.Parent           = upgradePanel
	upgradeRows[upg.key] = { upg = upg, row = row, button = button }

	button.MouseButton1Click:Connect(function()
		purchaseUpgrade:FireServer(upg.key)
	end)

	refreshCooldownRow(upg.key)
	player:GetAttributeChangedSignal(upg.levelAttr):Connect(function()
		refreshCooldownRow(upg.key)
	end)

	-- Cooldown rows for unlock-gated tools stay hidden until the tool is owned.
	-- Ban has no unlockKey (always available).
	if upg.unlockKey then
		local function refreshVisible()
			row.Visible = player:GetAttribute(unlockedAttr(upg.unlockKey)) == true
		end
		refreshVisible()
		player:GetAttributeChangedSignal(unlockedAttr(upg.unlockKey)):Connect(refreshVisible)
	end
end

upgradeButton.MouseButton1Click:Connect(function()
	upgradePanel.Visible = not upgradePanel.Visible
end)

-- Cooldown panel: each tool LocalScript writes a `<Tool>ReadyAt` attribute on
-- the LocalPlayer when activated. Per frame we compute remaining seconds, dim
-- the slot while on cooldown, and surface the timer text. Writes are local-only
-- (client-set attributes don't replicate to server) — no remote traffic needed.
local COOLDOWN_DIM_TRANSPARENCY = 0.55  -- on cooldown
local COOLDOWN_LIT_TRANSPARENCY = 0     -- ready

-- Cooldown slots tied to tool unlocks where applicable. Ban is always shown;
-- Mute/Timeout/Kick slots stay hidden until the corresponding tool is unlocked
-- (so a fresh player only sees the Ban slot at the bottom).
local cooldownSlots = {
	{ name = "Ban",     attr = "BanReadyAt",     slot = cooldownPanel:WaitForChild("Ban") },
	{ name = "Mute",    attr = "MuteReadyAt",    slot = cooldownPanel:WaitForChild("Mute"),    unlockKey = "MuteGun" },
	{ name = "Timeout", attr = "TimeoutReadyAt", slot = cooldownPanel:WaitForChild("Timeout"), unlockKey = "TimeoutCard" },
	{ name = "Kick",    attr = "KickReadyAt",    slot = cooldownPanel:WaitForChild("Kick"),    unlockKey = "KickBoot" },
}
for _, s in ipairs(cooldownSlots) do
	s.timer = s.slot:WaitForChild("Timer")
	if s.unlockKey then
		local function refreshSlotVisible()
			s.slot.Visible = player:GetAttribute(s.unlockKey .. "Unlocked") == true
		end
		refreshSlotVisible()
		player:GetAttributeChangedSignal(s.unlockKey .. "Unlocked"):Connect(refreshSlotVisible)
	end
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
