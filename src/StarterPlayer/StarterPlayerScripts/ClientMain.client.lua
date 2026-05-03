-- StarterPlayer/StarterPlayerScripts/ClientMain
-- Wires up MainUI: health, currency, wave status, and the upgrade button.
-- Reads currency/cooldown state from Player attributes (replicated by CurrencyManager).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

-- Touch-only client: drives shorter currency label format + the per-element
-- HUD repositioning block at the bottom of this file. Set ONCE at startup.
local IS_TOUCH = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local CURRENCY_FORMAT = IS_TOUCH and "Lv %d  ·  %d" or "Lv %d  ·  Coins: %d"

local Shared             = ReplicatedStorage:WaitForChild("Shared")
local Config             = require(Shared:WaitForChild("Config"))
local Theme              = require(Shared:WaitForChild("Theme"))
local Effects            = require(Shared:WaitForChild("Effects"))
local remotes            = Shared:WaitForChild("Remotes")
local healthChanged      = remotes:WaitForChild("HealthChanged")
local gameOver           = remotes:WaitForChild("GameOver")
local gameWon            = remotes:WaitForChild("GameWon")
local waveStarted        = remotes:WaitForChild("WaveStarted")
local waveBreak          = remotes:WaitForChild("WaveBreak")
local purchaseUpgrade    = remotes:WaitForChild("PurchaseUpgrade")
local enemyCountChanged  = remotes:WaitForChild("EnemyCountChanged")
local retryRun           = remotes:WaitForChild("RetryRun")
local muteShotFx         = remotes:WaitForChild("MuteShotFx")
local cosmeticAction     = remotes:WaitForChild("CosmeticAction")

local player        = Players.LocalPlayer
local playerGui     = player:WaitForChild("PlayerGui")
local mainUI        = playerGui:WaitForChild("MainUI")
local healthBar     = mainUI:WaitForChild("HealthLabel")
local healthFill    = healthBar:WaitForChild("Fill")
local healthText    = healthBar:WaitForChild("Label")
local currencyLabel = mainUI:WaitForChild("CurrencyLabel")
local waveLabel     = mainUI:WaitForChild("WaveLabel")
-- Strict child lookup with a clear error if Rojo failed to sync something.
-- The default WaitForChild times out silently after 5s and returns nil — every
-- subsequent index then crashes with "attempt to index nil," which doesn't
-- point at the missing child. This wraps that.
local function strictChild(parent, childName)
	local child = parent:WaitForChild(childName, 5)
	if not child then
		error(string.format(
			"[ClientMain] Missing child %q under %s — likely Rojo sync issue. Try `rojo build -o discord-mod-simulator.rbxlx` and reopen the place.",
			childName, parent:GetFullName()
		))
	end
	return child
end

local upgradeButton    = strictChild(mainUI, "UpgradeButton")
local upgradePanel     = strictChild(mainUI, "UpgradePanel")
local shopButton       = strictChild(mainUI, "ShopButton")
local shopPanel        = strictChild(mainUI, "ShopPanel")
local cosmeticsButton  = strictChild(mainUI, "CosmeticsButton")
local cosmeticsPanel   = strictChild(mainUI, "CosmeticsPanel")
local cooldownPanel = strictChild(mainUI, "CooldownPanel")
local flashOverlay  = strictChild(mainUI, "FlashOverlay")
local gameOverPanel = strictChild(mainUI, "GameOverPanel")
local goHeadline    = strictChild(gameOverPanel, "Headline")
local goWavesStat   = strictChild(gameOverPanel, "WavesStat")
local goCoinsStat   = strictChild(gameOverPanel, "CoinsStat")
local goLevelStat   = strictChild(gameOverPanel, "LevelStat")
local retryButton   = strictChild(gameOverPanel, "RetryButton")

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

-- Wave-state tracker. Hoisted ABOVE the gameOver/gameWon handlers so those
-- closures bind to it as an upvalue (Lua closures capture at definition time;
-- locals declared later are resolved as globals → nil). Mutated by the
-- waveStarted/waveBreak/enemyCountChanged handlers below.
local waveState = {
	mode         = "idle",   -- "idle" | "wave" | "break"
	wave         = 0,
	total        = 0,
	secondsLeft  = 0,
	enemyCount   = 0,
	modifier     = nil,      -- string | nil — set on wave start, cleared on next wave
}

local function showGameOverPanel(headlineText, headlineColor, wavesSurvived)
	goHeadline.Text       = headlineText
	goHeadline.TextColor3 = headlineColor
	goWavesStat.Text      = string.format("Waves Survived: %d", wavesSurvived)
	goCoinsStat.Text      = string.format("Coins This Run: %d", player:GetAttribute("RunCoinsEarned") or 0)
	goLevelStat.Text      = string.format("Level: %d", player:GetAttribute("Level") or 1)
	gameOverPanel.Visible = true
	-- Defensive: ensure FlashOverlay isn't stuck opaque hiding the panel.
	-- (Tween should always fade it back to 1 — this is belt-and-suspenders
	-- against any race where the panel shows before the flash completes its
	-- fade-out and somehow stays visible.)
	task.delay(1.0, function()
		if flashOverlay.BackgroundTransparency < 0.99 then
			flashOverlay.BackgroundTransparency = 1
			print("[ClientMain] Forced FlashOverlay clear after game-over panel show")
		end
	end)
	print(string.format("[ClientMain] GameOverPanel shown (%s) — Visible=%s, RetryButton present=%s",
		headlineText, tostring(gameOverPanel.Visible), tostring(retryButton ~= nil)))
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

-- Multiplayer: render Mute Gun tracers fired by OTHER players. The shooter's
-- own client already drew the tracer locally; we skip our own bounce so we
-- don't double-render.
muteShotFx.OnClientEvent:Connect(function(shooter, muzzle, endPoint)
	if shooter == player then return end
	Effects.MuteTracer(muzzle, endPoint)
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
-- EnemyCountChanged (live remaining-enemy count). waveState was hoisted above
-- the gameOver/gameWon handlers so this comment is the only documentation that
-- still lives down here.

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
	currencyLabel.Text = string.format(CURRENCY_FORMAT, level, coins)
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

-- Mutex toggle: only one of (UpgradePanel, ShopPanel, CosmeticsPanel) visible
-- at a time so they don't overlap (Upgrade + Shop anchor at y=108; Cosmetics
-- at y=156). v2 Week 2 added Cosmetics into the rotation.
local function closeAllPanels()
	upgradePanel.Visible   = false
	shopPanel.Visible      = false
	cosmeticsPanel.Visible = false
end

upgradeButton.MouseButton1Click:Connect(function()
	local wasVisible = upgradePanel.Visible
	closeAllPanels()
	upgradePanel.Visible = not wasVisible
end)

shopButton.MouseButton1Click:Connect(function()
	local wasVisible = shopPanel.Visible
	closeAllPanels()
	shopPanel.Visible = not wasVisible
end)

cosmeticsButton.MouseButton1Click:Connect(function()
	local wasVisible = cosmeticsPanel.Visible
	closeAllPanels()
	cosmeticsPanel.Visible = not wasVisible
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

-- v2 Week 2: Cosmetics panel rows. One row per cosmetic in Config.COSMETICS,
-- with category headers between sections. Equip button is enabled when player
-- owns the cosmetic (CurrencyManager auto-grants on level up). Locked items
-- show "Lv N" requirement. Equipped item shows "EQUIPPED".
local function isOwned(cosmId)
	local owned = player:GetAttribute("OwnedCosmetics") or ""
	if owned == "" then return false end
	return string.find("," .. owned .. ",", "," .. cosmId .. ",", 1, true) ~= nil
end

local function isDefault(cosmId)
	for _, defaultId in pairs(Config.DEFAULT_COSMETICS) do
		if defaultId == cosmId then return true end
	end
	return false
end

local cosmeticRows = {}  -- [cosm.id] = { row, button, cosm }

for catIndex, category in ipairs(Config.COSMETIC_CATEGORIES) do
	-- Category header row
	local header = Instance.new("TextLabel")
	header.Name                   = category .. "Header"
	header.Size                   = UDim2.new(1, 0, 0, 28)
	header.BackgroundTransparency = 1
	header.Text                   = string.upper(category) .. "S"
	header.TextColor3             = Color3.fromRGB(180, 140, 220)
	header.Font                   = Enum.Font.GothamBold
	header.TextSize               = 14
	header.TextXAlignment         = Enum.TextXAlignment.Left
	header.LayoutOrder            = catIndex * 100
	header.ZIndex                 = 51
	header.Parent                 = cosmeticsPanel

	for i, cosm in ipairs(Config.COSMETICS) do
		if cosm.category == category then
			local row, button = makeRow(catIndex * 100 + i, cosm.label, cosm.id .. "Row")
			row.Parent = cosmeticsPanel
			cosmeticRows[cosm.id] = { row = row, button = button, cosm = cosm }

			button.MouseButton1Click:Connect(function()
				cosmeticAction:FireServer("Equip", cosm.id)
			end)
		end
	end
end

local function refreshAllCosmeticRows()
	for cosmId, entry in pairs(cosmeticRows) do
		local cosm   = entry.cosm
		local button = entry.button
		local equippedAttr = player:GetAttribute("Equipped" .. cosm.category)
		local owned        = isOwned(cosmId) or isDefault(cosmId)
		local passLocked   = cosm.requirePass and not player:GetAttribute(cosm.requirePass .. "Owned")
		local levelLocked  = cosm.requireLevel and (cosm.requireLevel > (player:GetAttribute("Level") or 1))

		if equippedAttr == cosmId then
			button.Text             = "EQUIPPED"
			button.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
			button.TextColor3       = Color3.fromRGB(9, 9, 11)
			button.AutoButtonColor  = false
		elseif owned and not passLocked then
			button.Text             = "Equip"
			button.BackgroundColor3 = Color3.fromRGB(180, 140, 220)
			button.TextColor3       = Color3.fromRGB(9, 9, 11)
			button.AutoButtonColor  = true
		elseif passLocked then
			button.Text             = "DONATOR ONLY"
			button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			button.TextColor3       = Color3.fromRGB(250, 250, 250)
			button.AutoButtonColor  = false
		else
			button.Text             = string.format("Lv %d", cosm.requireLevel or 0)
			button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			button.TextColor3       = Color3.fromRGB(250, 250, 250)
			button.AutoButtonColor  = false
		end
	end
end

refreshAllCosmeticRows()
player:GetAttributeChangedSignal("OwnedCosmetics"):Connect(refreshAllCosmeticRows)
player:GetAttributeChangedSignal("Level"):Connect(refreshAllCosmeticRows)
for _, category in ipairs(Config.COSMETIC_CATEGORIES) do
	player:GetAttributeChangedSignal("Equipped" .. category):Connect(refreshAllCosmeticRows)
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
local kickEnemiesRemote = remotes:WaitForChild("KickEnemies")

if IS_TOUCH then
	-- Touch HUD layout. Designed for phone (375×667+) and tablet (768+ wide).
	-- Roblox CoreGui (chat icon, menu icon) sits in the inset above ScreenGui's
	-- (0,0). On phone with a notch, IgnoreGuiInset=false (default) puts our
	-- (0,0) ~40-60px below screen top. So even small y-offsets like 8 should
	-- clear the Roblox icons.
	--
	-- Strategy: cluster ALL HUD at the top edges (left, center, right) so the
	-- bottom of the screen is reserved for cooldown panel + KICK button + the
	-- default Roblox tool hotbar. PC layout is 100% untouched — these
	-- overrides only run when IS_TOUCH is true.

	-- Top-left: compact "Lv N · N" (CURRENCY_FORMAT was set short for touch)
	currencyLabel.Size     = UDim2.new(0, 130, 0, 32)
	currencyLabel.Position = UDim2.new(0, 8, 0, 8)

	-- Top-center: health bar (compact)
	healthBar.Size     = UDim2.new(0, 200, 0, 32)
	healthBar.Position = UDim2.new(0.5, 0, 0, 8)

	-- Wave label: row below health, slightly wider for the modifier text
	waveLabel.Size     = UDim2.new(0, 260, 0, 24)
	waveLabel.Position = UDim2.new(0.5, 0, 0, 46)

	-- Top-right: Upgrades + Shop in vertical column (joins the rest of the
	-- HUD at the top instead of floating mid-right). Player list opens
	-- on-demand on phone (tap leaderboard icon) so this corner is usually free.
	upgradeButton.Size        = UDim2.new(0, 100, 0, 32)
	upgradeButton.Position    = UDim2.new(1, -8, 0, 8)
	upgradeButton.AnchorPoint = Vector2.new(1, 0)

	shopButton.Size        = UDim2.new(0, 100, 0, 32)
	shopButton.Position    = UDim2.new(1, -8, 0, 46)
	shopButton.AnchorPoint = Vector2.new(1, 0)

	-- Panels open below the buttons (top-right area).
	upgradePanel.Size        = UDim2.new(0, 280, 0, 0)
	upgradePanel.Position    = UDim2.new(1, -8, 0, 84)
	upgradePanel.AnchorPoint = Vector2.new(1, 0)

	shopPanel.Size        = UDim2.new(0, 280, 0, 0)
	shopPanel.Position    = UDim2.new(1, -8, 0, 84)
	shopPanel.AnchorPoint = Vector2.new(1, 0)

	-- Cooldown panel: bottom-center, lifted ~140px to clear the Roblox tool
	-- hotbar (~80px tall) plus iOS home indicator (~34px) plus a margin.
	cooldownPanel.Position    = UDim2.new(0.5, 0, 1, -140)
	cooldownPanel.AnchorPoint = Vector2.new(0.5, 1)

	-- Virtual KICK button: bottom-right, above the tool hotbar. Larger than
	-- desktop equivalent (none) since touch needs bigger tap targets.
	local virtualKick = Instance.new("TextButton")
	virtualKick.Name                   = "VirtualKickButton"
	virtualKick.Size                   = UDim2.new(0, 88, 0, 88)
	virtualKick.Position               = UDim2.new(1, -16, 1, -150)
	virtualKick.AnchorPoint            = Vector2.new(1, 1)
	virtualKick.BackgroundColor3       = Color3.fromRGB(34, 197, 94)
	virtualKick.BackgroundTransparency = 0.1
	virtualKick.BorderSizePixel        = 0
	virtualKick.Text                   = "KICK"
	virtualKick.TextColor3             = Color3.fromRGB(9, 9, 11)
	virtualKick.Font                   = Enum.Font.GothamBold
	virtualKick.TextSize               = 22
	virtualKick.AutoButtonColor        = true
	virtualKick.ZIndex                 = 60
	virtualKick.Parent                 = mainUI
	local vkCorner = Instance.new("UICorner")
	vkCorner.CornerRadius = UDim.new(1, 0)  -- circular
	vkCorner.Parent       = virtualKick
	local function refreshVk()
		virtualKick.Visible = player:GetAttribute("KickBootUnlocked") == true
	end
	refreshVk()
	player:GetAttributeChangedSignal("KickBootUnlocked"):Connect(refreshVk)

	local Workspace = game:GetService("Workspace")
	virtualKick.MouseButton1Click:Connect(function()
		local cam     = Workspace.CurrentCamera
		local look    = cam.CFrame.LookVector
		local flat    = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude < 0.01 then return end
		kickEnemiesRemote:FireServer(flat.Unit)
	end)

	print("[ClientMain] Touch HUD layout applied — top-clustered + bottom KICK + compact Lv/Coins format")
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
