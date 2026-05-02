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
local retryRun           = remotes:WaitForChild("RetryRun")

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
local shopButton    = mainUI:WaitForChild("ShopButton")
local shopPanel     = mainUI:WaitForChild("ShopPanel")
local cooldownPanel = mainUI:WaitForChild("CooldownPanel")
local flashOverlay  = mainUI:WaitForChild("FlashOverlay")
local gameOverPanel = mainUI:WaitForChild("GameOverPanel")
local goHeadline    = gameOverPanel:WaitForChild("Headline")
local goWavesStat   = gameOverPanel:WaitForChild("WavesStat")
local goCoinsStat   = gameOverPanel:WaitForChild("CoinsStat")
local goLevelStat   = gameOverPanel:WaitForChild("LevelStat")
local retryButton   = gameOverPanel:WaitForChild("RetryButton")

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

local function showGameOverPanel(headlineText, headlineColor, wavesSurvived)
	goHeadline.Text       = headlineText
	goHeadline.TextColor3 = headlineColor
	goWavesStat.Text      = string.format("Waves Survived: %d", wavesSurvived)
	goCoinsStat.Text      = string.format("Coins This Run: %d", player:GetAttribute("RunCoinsEarned") or 0)
	goLevelStat.Text      = string.format("Level: %d", player:GetAttribute("Level") or 1)
	gameOverPanel.Visible = true
end

local function hideGameOverPanel()
	gameOverPanel.Visible = false
end

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
	-- "Survived" = waves you fully cleared, NOT the wave you died on.
	showGameOverPanel("SERVER DEAD", Theme.RedWarn, math.max(0, waveState.wave - 1))
	print("[ClientMain] Game over received")
end)

gameWon.OnClientEvent:Connect(function()
	runEnded = true
	waveLabel.Text       = "VICTORY"
	waveLabel.TextColor3 = Theme.GreenWin
	healthText.TextColor3 = Theme.GreenWin
	playFlash(Theme.GreenWin)
	showGameOverPanel("VICTORY", Theme.GreenWin, waveState.wave)
	print("[ClientMain] Victory received")
end)

-- Retry button: clear local run-end state immediately so subsequent server
-- events (HealthChanged from Reset, then WaveStarted) render normally.
retryButton.MouseButton1Click:Connect(function()
	if not runEnded then return end
	hideGameOverPanel()
	runEnded              = false
	healthText.TextColor3 = Theme.Zinc50
	waveLabel.TextColor3  = Theme.Zinc50
	waveLabel.Text        = ""  -- next WaveStarted will populate
	retryRun:FireServer()
	print("[ClientMain] Retry requested")
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

-- Mutex toggle: only one of (UpgradePanel, ShopPanel) visible at a time so
-- they don't overlap (both anchor top-right at y=108).
upgradeButton.MouseButton1Click:Connect(function()
	shopPanel.Visible    = false
	upgradePanel.Visible = not upgradePanel.Visible
end)

shopButton.MouseButton1Click:Connect(function()
	upgradePanel.Visible = false
	shopPanel.Visible    = not shopPanel.Visible
end)

-- Shop rows: gamepasses + dev products. Each row has a label, a description
-- subline (smaller grey text), and a "BUY (NN R$)" button on the right that
-- triggers Roblox's purchase prompt. Owned gamepasses show "OWNED" instead.
local MarketplaceService = game:GetService("MarketplaceService")

local function makeShopRow(layoutOrder, label, description, rowName)
	local row = Instance.new("Frame")
	row.Name                   = rowName
	row.Size                   = UDim2.new(1, 0, 0, 60)
	row.BackgroundTransparency = 1
	row.LayoutOrder            = layoutOrder
	row.ZIndex                 = 51

	local title = Instance.new("TextLabel")
	title.Size                   = UDim2.new(0.6, -4, 0, 22)
	title.Position               = UDim2.new(0, 0, 0, 4)
	title.BackgroundTransparency = 1
	title.TextColor3             = Color3.fromRGB(250, 250, 250)
	title.Font                   = Enum.Font.GothamBold
	title.TextSize               = 15
	title.TextXAlignment         = Enum.TextXAlignment.Left
	title.TextYAlignment         = Enum.TextYAlignment.Center
	title.Text                   = label
	title.ZIndex                 = 52
	title.Parent                 = row

	local desc = Instance.new("TextLabel")
	desc.Size                   = UDim2.new(0.6, -4, 0, 30)
	desc.Position               = UDim2.new(0, 0, 0, 28)
	desc.BackgroundTransparency = 1
	desc.TextColor3             = Color3.fromRGB(170, 170, 170)
	desc.Font                   = Enum.Font.Gotham
	desc.TextSize               = 11
	desc.TextXAlignment         = Enum.TextXAlignment.Left
	desc.TextYAlignment         = Enum.TextYAlignment.Top
	desc.TextWrapped            = true
	desc.Text                   = description
	desc.ZIndex                 = 52
	desc.Parent                 = row

	local button = Instance.new("TextButton")
	button.Name                  = "Buy"
	button.Size                  = UDim2.new(0.4, 0, 0, 44)
	button.Position              = UDim2.new(0.6, 4, 0, 8)
	button.BackgroundColor3      = Color3.fromRGB(250, 204, 21)
	button.BackgroundTransparency = 0
	button.TextColor3            = Color3.fromRGB(9, 9, 11)
	button.Font                  = Enum.Font.GothamBold
	button.TextSize              = 14
	button.AutoButtonColor       = true
	button.BorderSizePixel       = 0
	button.Text                  = "Buy"
	button.ZIndex                = 52
	button.Parent                = row
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent       = button

	return row, button
end

-- Gamepass rows (LayoutOrder 1..N — show first)
for i, gp in ipairs(Config.GAMEPASSES) do
	local row, button = makeShopRow(i, gp.label, gp.description, gp.key .. "PassRow")
	row.Parent = shopPanel

	local function refresh()
		if player:GetAttribute(gp.effectAttr) then
			button.Text             = "OWNED"
			button.AutoButtonColor  = false
			button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			button.TextColor3       = Color3.fromRGB(250, 250, 250)
		else
			button.Text             = string.format("Buy (%d R$)", gp.price)
			button.AutoButtonColor  = true
			button.BackgroundColor3 = Color3.fromRGB(250, 204, 21)
			button.TextColor3       = Color3.fromRGB(9, 9, 11)
		end
	end
	refresh()
	player:GetAttributeChangedSignal(gp.effectAttr):Connect(refresh)

	button.MouseButton1Click:Connect(function()
		if player:GetAttribute(gp.effectAttr) then return end
		if gp.id == 0 then
			print("[ClientMain] Gamepass id placeholder — set real id in Config first")
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, gp.id)
	end)
end

-- Dev product rows (LayoutOrder 100..N — show after gamepasses)
for i, dp in ipairs(Config.DEV_PRODUCTS) do
	local row, button = makeShopRow(100 + i, dp.label, dp.description, dp.key .. "ProductRow")
	row.Parent = shopPanel

	button.Text = string.format("Buy (%d R$)", dp.price)
	button.MouseButton1Click:Connect(function()
		if dp.id == 0 then
			print("[ClientMain] Product id placeholder — set real id in Config first")
			return
		end
		MarketplaceService:PromptProductPurchase(player, dp.id)
	end)
end

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
	-- Sweep gradient: a transparency wedge on the slot that rotates while on
	-- cooldown. Reads as a "spinning sweep" indicator — same idiom as MOBA
	-- cooldown UIs. Disabled when slot is ready (so the slot looks flat).
	local sweep = Instance.new("UIGradient")
	sweep.Color        = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	sweep.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,    0.6),
		NumberSequenceKeypoint.new(0.45, 0.6),
		NumberSequenceKeypoint.new(0.5,  0.0),
		NumberSequenceKeypoint.new(0.55, 0.6),
		NumberSequenceKeypoint.new(1,    0.6),
	})
	sweep.Enabled = false
	sweep.Parent  = s.slot
	s.sweep       = sweep
	if s.unlockKey then
		local function refreshSlotVisible()
			s.slot.Visible = player:GetAttribute(s.unlockKey .. "Unlocked") == true
		end
		refreshSlotVisible()
		player:GetAttributeChangedSignal(s.unlockKey .. "Unlocked"):Connect(refreshSlotVisible)
	end
end

-- Purchase confirmation toast: top-center pill that fades in/out when a
-- gamepass or dev product purchase succeeds. Handles BOTH gamepass and product
-- prompts since the user-facing experience is identical.
local toast = Instance.new("Frame")
toast.Name                   = "PurchaseToast"
toast.Size                   = UDim2.new(0, 320, 0, 44)
toast.Position               = UDim2.new(0.5, 0, 0, 76)
toast.AnchorPoint            = Vector2.new(0.5, 0)
toast.BackgroundColor3       = Color3.fromRGB(34, 197, 94)
toast.BackgroundTransparency = 1
toast.BorderSizePixel        = 0
toast.ZIndex                 = 95
toast.Visible                = false
toast.Parent                 = mainUI
local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 8)
toastCorner.Parent       = toast
local toastLabel = Instance.new("TextLabel")
toastLabel.Size                   = UDim2.new(1, -16, 1, 0)
toastLabel.Position               = UDim2.new(0, 8, 0, 0)
toastLabel.BackgroundTransparency = 1
toastLabel.Font                   = Enum.Font.GothamBold
toastLabel.TextSize               = 16
toastLabel.TextColor3             = Color3.fromRGB(9, 9, 11)
toastLabel.TextXAlignment         = Enum.TextXAlignment.Center
toastLabel.TextYAlignment         = Enum.TextYAlignment.Center
toastLabel.TextTransparency       = 1
toastLabel.Text                   = ""
toastLabel.ZIndex                 = 96
toastLabel.Parent                 = toast

local TOAST_FADE_IN  = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TOAST_FADE_OUT = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local TOAST_HOLD     = 2.5

local function showToast(msg)
	toastLabel.Text = msg
	toast.Visible   = true
	TweenService:Create(toast,      TOAST_FADE_IN, { BackgroundTransparency = 0.1 }):Play()
	TweenService:Create(toastLabel, TOAST_FADE_IN, { TextTransparency       = 0   }):Play()
	task.delay(TOAST_FADE_IN.Time + TOAST_HOLD, function()
		TweenService:Create(toast,      TOAST_FADE_OUT, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(toastLabel, TOAST_FADE_OUT, { TextTransparency       = 1 }):Play()
		task.delay(TOAST_FADE_OUT.Time, function() toast.Visible = false end)
	end)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_player, passId, wasPurchased)
	if not wasPurchased then return end
	for _, gp in ipairs(Config.GAMEPASSES) do
		if gp.id == passId then
			showToast("Bought: " .. gp.label .. " — effect active!")
			return
		end
	end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(_userId, productId, wasPurchased)
	if not wasPurchased then return end
	for _, dp in ipairs(Config.DEV_PRODUCTS) do
		if dp.id == productId then
			showToast("Used: " .. dp.label)
			return
		end
	end
end)

-- Touch controls: detect touch-only devices and adapt. UIScale shrinks the
-- whole HUD to fit phone screens; virtual KICK button mirrors Tool.Activated
-- on Kick Boot since touch users won't have a clean way to fire AOE while
-- still aiming the camera.
local UserInputService = game:GetService("UserInputService")
local kickEnemiesRemote = remotes:WaitForChild("KickEnemies")

if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
	local hudScale = Instance.new("UIScale")
	hudScale.Scale  = 0.75
	hudScale.Parent = mainUI

	local virtualKick = Instance.new("TextButton")
	virtualKick.Name                  = "VirtualKickButton"
	virtualKick.Size                  = UDim2.new(0, 96, 0, 96)
	virtualKick.Position              = UDim2.new(1, -24, 1, -132)
	virtualKick.AnchorPoint           = Vector2.new(1, 1)
	virtualKick.BackgroundColor3      = Color3.fromRGB(34, 197, 94)
	virtualKick.BackgroundTransparency = 0.1
	virtualKick.BorderSizePixel       = 0
	virtualKick.Text                  = "KICK"
	virtualKick.TextColor3            = Color3.fromRGB(9, 9, 11)
	virtualKick.Font                  = Enum.Font.GothamBold
	virtualKick.TextSize              = 22
	virtualKick.AutoButtonColor       = true
	virtualKick.ZIndex                = 60
	virtualKick.Parent                = mainUI
	local vkCorner = Instance.new("UICorner")
	vkCorner.CornerRadius = UDim.new(1, 0)  -- circular
	vkCorner.Parent       = virtualKick
	-- Hide while no Kick Boot unlock — same gating as the cooldown slot.
	local function refreshVk()
		virtualKick.Visible = player:GetAttribute("KickBootUnlocked") == true
	end
	refreshVk()
	player:GetAttributeChangedSignal("KickBootUnlocked"):Connect(refreshVk)

	local Workspace = game:GetService("Workspace")
	virtualKick.MouseButton1Click:Connect(function()
		-- Mirror KickBootScript's send: camera-derived flat lookDir.
		local cam     = Workspace.CurrentCamera
		local look    = cam.CFrame.LookVector
		local flat    = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude < 0.01 then return end
		kickEnemiesRemote:FireServer(flat.Unit)
	end)

	print("[ClientMain] Touch device detected — HUD scaled 0.75 + virtual KICK button enabled")
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
			s.sweep.Enabled  = true
			s.sweep.Rotation = (now * 360) % 360  -- 1 rev/sec — readable, not nauseating
		else
			s.slot.BackgroundTransparency = COOLDOWN_LIT_TRANSPARENCY
			s.timer.Visible               = false
			s.sweep.Enabled               = false
		end
	end
end)

print("[ClientMain] UI connected")
