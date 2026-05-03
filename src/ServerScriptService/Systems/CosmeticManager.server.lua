-- ServerScriptService/Systems/CosmeticManager (Script)
-- v2 Week 2 — applies equipped cosmetics (Trail / Pet / Skin) to the player's
-- character on every spawn. Reads Player attributes (set by CurrencyManager
-- and persisted in DataStore via schema v7).
--
-- Side-effect installer: no public API. Server creates the visuals; replication
-- to clients is automatic since everything is parented to workspace or character.
--
-- Pet system: a small primitive part hovers above the player and bobs slightly.
-- Updated per-frame by Heartbeat (cheap — one CFrame set per pet per frame).
-- No PathfindingService — pet just lerps to a point above the character.

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared          = ReplicatedStorage:WaitForChild("Shared")
local Config          = require(Shared:WaitForChild("Config"))
local CurrencyManager = require(ServerScriptService:WaitForChild("Systems"):WaitForChild("CurrencyManager"))
local cosmeticAction  = Shared:WaitForChild("Remotes"):WaitForChild("CosmeticAction")

local function cosmeticById(id)
	for _, c in ipairs(Config.COSMETICS) do
		if c.id == id then return c end
	end
	return nil
end

local activePets = {}  -- [player] = { part = Part, offset = Vector3, bobPhase = number }

-- TRAIL: attached to character via two Attachments + a Trail instance.
local function applyTrail(character, cosm)
	-- Clean up any prior trail
	for _, child in ipairs(character:GetChildren()) do
		if child.Name == "MoveTrail" then child:Destroy() end
	end
	if not cosm or not cosm.color then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local a0 = Instance.new("Attachment")
	a0.Name = "TrailAttach0"
	a0.Position = Vector3.new(-1, -2.5, 0)
	a0.Parent = rootPart

	local a1 = Instance.new("Attachment")
	a1.Name = "TrailAttach1"
	a1.Position = Vector3.new(1, -2.5, 0)
	a1.Parent = rootPart

	local trail = Instance.new("Trail")
	trail.Name = "MoveTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(cosm.color)
	trail.Lifetime = 0.6
	trail.MinLength = 0.1
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.LightEmission = 0.5
	trail.Texture = ""
	trail.Parent = character
end

-- SKIN: overrides character body colors via BodyColors instance.
local function applySkin(character, cosm)
	if not cosm or not cosm.color then return end  -- default skin = no override
	local bodyColors = character:FindFirstChild("Body Colors") or character:FindFirstChildOfClass("BodyColors")
	if not bodyColors then
		bodyColors = Instance.new("BodyColors")
		bodyColors.Parent = character
	end
	local brick = BrickColor.new(cosm.color)
	bodyColors.HeadColor    = brick
	bodyColors.TorsoColor   = brick
	bodyColors.LeftArmColor = brick
	bodyColors.RightArmColor = brick
	bodyColors.LeftLegColor = brick
	bodyColors.RightLegColor = brick
end

-- PET: small primitive part follows above the character. Updated by Heartbeat.
local function applyPet(player, character, cosm)
	-- Clean up any prior pet for this player
	if activePets[player] then
		if activePets[player].part and activePets[player].part.Parent then
			activePets[player].part:Destroy()
		end
		activePets[player] = nil
	end
	if not cosm or not cosm.color then return end  -- "no pet" entry has color=nil

	local pet = Instance.new("Part")
	pet.Name        = "Pet_" .. player.Name
	pet.Size        = Vector3.new(1.2, 1.2, 1.2)
	pet.Color       = cosm.color
	pet.Material    = Enum.Material.Neon
	pet.Anchored    = true
	pet.CanCollide  = false
	pet.CanQuery    = false
	pet.CastShadow  = false
	pet.Parent      = workspace
	if cosm.id == "pet_coin" then
		pet.Shape = Enum.PartType.Cylinder
		pet.Orientation = Vector3.new(0, 0, 90)
	elseif cosm.id == "pet_wumpus" or cosm.id == "pet_gold" then
		pet.Shape = Enum.PartType.Ball
	end
	activePets[player] = { part = pet, offset = Vector3.new(2.5, 4, 0), bobPhase = math.random() * 6.28 }
end

local function applyAllCosmetics(player, character)
	local trailId = player:GetAttribute("EquippedTrail") or Config.DEFAULT_COSMETICS.Trail
	local petId   = player:GetAttribute("EquippedPet")   or Config.DEFAULT_COSMETICS.Pet
	local skinId  = player:GetAttribute("EquippedSkin")  or Config.DEFAULT_COSMETICS.Skin
	applyTrail(character, cosmeticById(trailId))
	applyPet(player,    character, cosmeticById(petId))
	applySkin(character, cosmeticById(skinId))
end

local function setupPlayer(player)
	if player.Character then
		applyAllCosmetics(player, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 5)
		task.wait(0.1)  -- let character finish appearance loading
		applyAllCosmetics(player, character)
	end)

	-- Re-apply on equipment change (player swaps cosmetic in-game)
	for _, category in ipairs(Config.COSMETIC_CATEGORIES) do
		player:GetAttributeChangedSignal("Equipped" .. category):Connect(function()
			if player.Character then
				applyAllCosmetics(player, player.Character)
			end
		end)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end

Players.PlayerRemoving:Connect(function(player)
	if activePets[player] then
		if activePets[player].part and activePets[player].part.Parent then
			activePets[player].part:Destroy()
		end
		activePets[player] = nil
	end
end)

-- Client → server: equip cosmetic by id. Validates ownership via CurrencyManager.
cosmeticAction.OnServerEvent:Connect(function(player, action, id)
	if action == "Equip" and type(id) == "string" then
		CurrencyManager.TryEquipCosmetic(player, id)
	end
end)

-- Pet follow heartbeat — lerp to a point relative to the character + bob.
RunService.Heartbeat:Connect(function(dt)
	for player, data in pairs(activePets) do
		if not data.part or not data.part.Parent then
			activePets[player] = nil
			continue
		end
		local character = player.Character
		if not character then continue end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then continue end
		data.bobPhase = (data.bobPhase + dt * 3) % (2 * math.pi)
		local target = root.Position + data.offset + Vector3.new(0, math.sin(data.bobPhase) * 0.4, 0)
		-- Smooth lerp toward target (10% per frame is responsive but not snappy)
		data.part.CFrame = data.part.CFrame:Lerp(CFrame.new(target), 0.15)
	end
end)
