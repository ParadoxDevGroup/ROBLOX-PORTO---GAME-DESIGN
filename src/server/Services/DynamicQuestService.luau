--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigFolder = Shared:WaitForChild("Config")
local RemotesConfig = require(ConfigFolder:WaitForChild("Remotes"))
local DynamicQuestConfig = require(ConfigFolder:WaitForChild("DynamicQuestConfig"))

local DynamicQuestService = {}
DynamicQuestService.__index = DynamicQuestService

type QuestState = {
	questActive: boolean,
	zoneIndex: number,
	questExpiresAt: number,
	foundPet: boolean,
	titleTag: string,
	titleExpiresAt: number,
	contextualPromptAvailable: boolean,
	promptZoneIndex: number,
	statusText: string,
	completedCount: number,
	nextPromptAt: number,
}

local function getOrCreateChild(parent: Instance, className: string, name: string): Instance
	local child = parent:FindFirstChild(name)
	if child then
		return child
	end

	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local function createInitialState(): QuestState
	return {
		questActive = false,
		zoneIndex = 1,
		questExpiresAt = 0,
		foundPet = false,
		titleTag = "None",
		titleExpiresAt = 0,
		contextualPromptAvailable = false,
		promptZoneIndex = 1,
		statusText = "Start a quest when the player enters a supported zone.",
		completedCount = 0,
		nextPromptAt = 0,
	}
end

local function getCharacterRootPart(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		return rootPart
	end

	return nil
end

local function getNearestZoneIndex(position: Vector3, maxDistance: number): number?
	-- Use horizontal (XZ) distance so vertical offsets (player height) don't prevent
	-- zone triggers when the player is within the planar radius.
	local nearestIndex = nil
	local nearestDistance = maxDistance

	for index, zone in ipairs(DynamicQuestConfig.Zones) do
		local dx = zone.position.X - position.X
		local dz = zone.position.Z - position.Z
		local planarDistance = math.sqrt(dx * dx + dz * dz)
		if planarDistance <= nearestDistance then
			nearestDistance = planarDistance
			nearestIndex = index
		end
	end

	return nearestIndex
end

function DynamicQuestService.new()
	local sharedFolder = getOrCreateChild(Shared, "Folder", RemotesConfig.FolderName)
	local actionRequest = getOrCreateChild(sharedFolder, "RemoteEvent", RemotesConfig.DynamicQuestActionRequest)
	local snapshotRequest = getOrCreateChild(sharedFolder, "RemoteFunction", RemotesConfig.DynamicQuestSnapshotRequest)
	local stateUpdated = getOrCreateChild(sharedFolder, "RemoteEvent", RemotesConfig.DynamicQuestStateUpdated)

	return setmetatable({
		sharedFolder = sharedFolder,
		actionRequest = actionRequest,
		snapshotRequest = snapshotRequest,
		stateUpdated = stateUpdated,
		connections = {},
		playerStates = {},
		started = false,
		questAnchor = nil,
		catPrompt = nil,
		zoneVisuals = nil,
		heartbeatAccumulator = 0,
	}, DynamicQuestService)
end

function DynamicQuestService:_ensureZoneVisuals()
	if self.zoneVisuals and self.zoneVisuals.Parent then
		return
	end

	local zoneAccentColors = {
		Color3.fromRGB(112, 122, 224),
		Color3.fromRGB(84, 232, 204),
		Color3.fromRGB(222, 146, 68),
	}

	local container = Instance.new("Folder")
	container.Name = "DynamicQuestZoneVisuals"
	container.Parent = Workspace

	for zoneIndex, zone in ipairs(DynamicQuestConfig.Zones) do
		local accentColor = zoneAccentColors[zoneIndex] or Color3.fromRGB(180, 190, 210)
		local zoneModel = Instance.new("Model")
		zoneModel.Name = string.format("Zone_%d_%s", zoneIndex, zone.name:gsub("%s+", ""))
		zoneModel.Parent = container

		local basePlate = Instance.new("Part")
		basePlate.Name = "ZoneBase"
		basePlate.Anchored = true
		basePlate.CanCollide = true
		basePlate.Material = Enum.Material.Concrete
		basePlate.Color = Color3.fromRGB(52, 56, 64)
		basePlate.Size = Vector3.new(38, 1, 38)
		basePlate.CFrame = CFrame.new(zone.position + Vector3.new(0, -0.5, 0))
		basePlate.Parent = zoneModel

		local beacon = Instance.new("Part")
		beacon.Name = "ZoneBeacon"
		beacon.Anchored = true
		beacon.CanCollide = false
		beacon.Material = Enum.Material.Neon
		beacon.Color = accentColor
		beacon.Transparency = 0.35
		beacon.Size = Vector3.new(2.5, 18, 2.5)
		beacon.CFrame = CFrame.new(zone.position + Vector3.new(0, 8.5, 0))
		beacon.Parent = zoneModel

		local beaconGlow = Instance.new("Part")
		beaconGlow.Name = "BeaconGlow"
		beaconGlow.Anchored = true
		beaconGlow.CanCollide = false
		beaconGlow.Material = Enum.Material.Neon
		beaconGlow.Color = accentColor
		beaconGlow.Transparency = 0.6
		beaconGlow.Size = Vector3.new(4.5, 20, 4.5)
		beaconGlow.CFrame = CFrame.new(zone.position + Vector3.new(0, 8.5, 0))
		beaconGlow.Parent = zoneModel

		local titleAnchor = Instance.new("Part")
		titleAnchor.Name = "ZoneTitleAnchor"
		titleAnchor.Anchored = true
		titleAnchor.CanCollide = false
		titleAnchor.Transparency = 1
		titleAnchor.Size = Vector3.new(1, 1, 1)
		titleAnchor.CFrame = CFrame.new(zone.position + Vector3.new(0, 12, 0))
		titleAnchor.Parent = zoneModel

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "ZoneTitle"
		billboard.AlwaysOnTop = true
		billboard.LightInfluence = 0
		billboard.Size = UDim2.fromOffset(240, 70)
		billboard.StudsOffset = Vector3.new(0, 0, 0)
		billboard.Parent = titleAnchor

		local titleLabel = Instance.new("TextLabel")
		titleLabel.BackgroundTransparency = 1
		titleLabel.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		titleLabel.Size = UDim2.fromScale(1, 1)
		titleLabel.Text = zone.name
		titleLabel.TextColor3 = accentColor
		titleLabel.TextScaled = true
		titleLabel.TextStrokeTransparency = 0.5
		titleLabel.TextYAlignment = Enum.TextYAlignment.Center
		titleLabel.Parent = billboard

		local buildingSpecs = {
			{
				size = Vector3.new(9, 10, 9),
				offset = Vector3.new(-11, 5, -10),
				color = Color3.fromRGB(73, 83, 97),
			},
			{
				size = Vector3.new(8, 14, 8),
				offset = Vector3.new(12, 7, -6),
				color = Color3.fromRGB(64, 73, 86),
			},
			{
				size = Vector3.new(7, 9, 7),
				offset = Vector3.new(-4, 4.5, 12),
				color = Color3.fromRGB(86, 95, 108),
			},
		}

		for buildingIndex, spec in ipairs(buildingSpecs) do
			local building = Instance.new("Part")
			building.Name = string.format("GreyboxBuilding_%d", buildingIndex)
			building.Anchored = true
			building.CanCollide = true
			building.Material = Enum.Material.SmoothPlastic
			building.Color = spec.color
			building.Size = spec.size
			building.CFrame = CFrame.new(zone.position + spec.offset)
			building.Parent = zoneModel
		end

		local streetLight = Instance.new("Part")
		streetLight.Name = "StreetLight"
		streetLight.Anchored = true
		streetLight.CanCollide = false
		streetLight.Material = Enum.Material.SmoothPlastic
		streetLight.Color = Color3.fromRGB(40, 40, 50)
		streetLight.Size = Vector3.new(0.5, 6, 0.5)
		streetLight.CFrame = CFrame.new(zone.position + Vector3.new(-14, 2.5, 8))
		streetLight.Parent = zoneModel

		local lightBulb = Instance.new("Part")
		lightBulb.Name = "LightBulb"
		lightBulb.Anchored = true
		lightBulb.CanCollide = false
		lightBulb.Material = Enum.Material.Neon
		lightBulb.Color = accentColor
		lightBulb.Transparency = 0.2
		lightBulb.Size = Vector3.new(1.2, 1.2, 1.2)
		lightBulb.CFrame = CFrame.new(zone.position + Vector3.new(-14, 6, 8))
		lightBulb.Parent = zoneModel

		local bench = Instance.new("Part")
		bench.Name = "Bench"
		bench.Anchored = true
		bench.CanCollide = true
		bench.Material = Enum.Material.Wood
		bench.Color = Color3.fromRGB(101, 67, 33)
		bench.Size = Vector3.new(5, 0.8, 1.5)
		bench.CFrame = CFrame.new(zone.position + Vector3.new(16, 0.4, 10))
		bench.Parent = zoneModel
	end

	self.zoneVisuals = container
end

function DynamicQuestService:_getState(player: Player): QuestState
	local playerState = self.playerStates[player.UserId]
	if playerState then
		return playerState
	end

	playerState = createInitialState()
	self.playerStates[player.UserId] = playerState
	return playerState
end

function DynamicQuestService:_getZoneName(zoneIndex: number): string
	local zone = DynamicQuestConfig.Zones[zoneIndex]
	if zone then
		return zone.name
	end
	return DynamicQuestConfig.Zones[1].name
end

function DynamicQuestService:_buildState(player: Player)
	local playerState = self:_getState(player)
	return {
		questActive = playerState.questActive,
		zoneIndex = playerState.zoneIndex,
		zoneName = self:_getZoneName(playerState.zoneIndex),
		questExpiresAt = playerState.questExpiresAt,
		foundPet = playerState.foundPet,
		titleTag = playerState.titleTag,
		titleExpiresAt = playerState.titleExpiresAt,
		contextualPromptAvailable = playerState.contextualPromptAvailable,
		promptZoneIndex = playerState.promptZoneIndex,
		promptZoneName = self:_getZoneName(playerState.promptZoneIndex),
		statusText = playerState.statusText,
		completedCount = playerState.completedCount,
		rewardTitle = DynamicQuestConfig.RewardTitle,
		questDurationSeconds = DynamicQuestConfig.QuestDurationSeconds,
		titleDurationSeconds = DynamicQuestConfig.TitleDurationSeconds,
	}
end

function DynamicQuestService:_broadcastState(player: Player)
	self.stateUpdated:FireClient(player, self:_buildState(player))
end

function DynamicQuestService:_ensureCatProp()
	if self.questAnchor and self.questAnchor.Parent and self.catPrompt and self.catPrompt.Parent then
		return
	end

	local model = Instance.new("Model")
	model.Name = "LostPetCat"
	model.Parent = Workspace

	local body = Instance.new("Part")
	body.Name = "CatBody"
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.SmoothPlastic
	body.Color = Color3.fromRGB(233, 156, 86)
	body.Size = Vector3.new(1.4, 1.1, 1.8)
	body.Parent = model

	local ears = Instance.new("Part")
	ears.Name = "CatEars"
	ears.Anchored = true
	ears.CanCollide = false
	ears.Material = Enum.Material.SmoothPlastic
	ears.Color = Color3.fromRGB(244, 176, 110)
	ears.Size = Vector3.new(1.0, 0.35, 0.8)
	ears.Parent = model

	model.PrimaryPart = body
	body.CFrame = CFrame.new(0, -8.4, -45)
	ears.CFrame = body.CFrame * CFrame.new(0, 0.72, 0)

	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 0.75, 0)
	attachment.Parent = body

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Rescue Lost Cat"
	prompt.ObjectText = "Lost Pet"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = attachment

	self.questAnchor = model
	self.catPrompt = prompt

	self.connections.catPrompt = prompt.Triggered:Connect(function(player)
		self:_onCatPromptTriggered(player)
	end)
end

function DynamicQuestService:_positionCatAtZone(zoneIndex: number)
	if not self.questAnchor or not self.questAnchor.PrimaryPart then
		return
	end

	local zone = DynamicQuestConfig.Zones[zoneIndex] or DynamicQuestConfig.Zones[1]
	self.questAnchor:PivotTo(CFrame.new(zone.position))
end

function DynamicQuestService:_startQuest(player: Player, forcedZoneIndex: number?)
	local playerState = self:_getState(player)
	local randomZone = math.random(1, #DynamicQuestConfig.Zones)
	local selectedZone = forcedZoneIndex or randomZone

	if selectedZone < 1 or selectedZone > #DynamicQuestConfig.Zones then
		selectedZone = randomZone
	end

	playerState.questActive = true
	playerState.contextualPromptAvailable = false
	playerState.promptZoneIndex = selectedZone
	playerState.zoneIndex = selectedZone
	playerState.questExpiresAt = os.clock() + DynamicQuestConfig.QuestDurationSeconds
	playerState.foundPet = false
	playerState.nextPromptAt = os.clock() + DynamicQuestConfig.ZonePromptCooldownSeconds
	playerState.statusText =
		string.format("Quest live in %s. Find the cat before the timer expires.", self:_getZoneName(selectedZone))

	self:_positionCatAtZone(selectedZone)
	self:_broadcastState(player)
end

function DynamicQuestService:_acceptContextualPrompt(player: Player)
	local playerState = self:_getState(player)
	if playerState.questActive then
		playerState.statusText = "Quest already active. Rescue the cat before accepting another prompt."
		self:_broadcastState(player)
		return
	end

	if not playerState.contextualPromptAvailable then
		playerState.statusText = "No contextual quest prompt is available in your current zone yet."
		self:_broadcastState(player)
		return
	end

	self:_startQuest(player, playerState.promptZoneIndex)
end

function DynamicQuestService:_cycleZoneHint(player: Player)
	local playerState = self:_getState(player)
	if playerState.questActive then
		playerState.statusText = "Zone hint cannot be cycled while a timed quest is active."
		self:_broadcastState(player)
		return
	end

	local nextIndex = playerState.zoneIndex + 1
	if nextIndex > #DynamicQuestConfig.Zones then
		nextIndex = 1
	end

	playerState.zoneIndex = nextIndex
	playerState.statusText = string.format("Quest hint moved to %s.", self:_getZoneName(nextIndex))
	self:_positionCatAtZone(nextIndex)
	self:_broadcastState(player)
end

function DynamicQuestService:_searchAttempt(player: Player)
	local playerState = self:_getState(player)
	if not playerState.questActive then
		playerState.statusText = "Start the quest first to search the zone."
		self:_broadcastState(player)
		return
	end

	local remaining = playerState.questExpiresAt - os.clock()
	if remaining <= 0 then
		playerState.questActive = false
		playerState.statusText = "The cat ran out of time. Start another scan to retry the hunt."
		self:_broadcastState(player)
		return
	end

	playerState.statusText = "Use the world prompt on the Lost Pet prop to complete this quest."
	self:_broadcastState(player)
end

function DynamicQuestService:_onCatPromptTriggered(player: Player)
	local playerState = self:_getState(player)
	if not playerState.questActive then
		playerState.statusText = "Start a timed quest before rescuing the cat."
		self:_broadcastState(player)
		return
	end

	local remaining = playerState.questExpiresAt - os.clock()
	if remaining <= 0 then
		playerState.questActive = false
		playerState.statusText = "Too late. The timed quest expired before rescue."
		self:_broadcastState(player)
		return
	end

	playerState.questActive = false
	playerState.foundPet = true
	playerState.completedCount += 1
	playerState.titleTag = DynamicQuestConfig.RewardTitle
	playerState.titleExpiresAt = os.clock() + DynamicQuestConfig.TitleDurationSeconds
	playerState.statusText = "Cat found. Temporary social title tag granted."
	player:SetAttribute("DynamicQuestTitleTag", DynamicQuestConfig.RewardTitle)
	player:SetAttribute("DynamicQuestTitleExpiresAt", playerState.titleExpiresAt)
	self:_broadcastState(player)
end

function DynamicQuestService:_updateContextualPrompt(player: Player, now: number)
	local playerState = self:_getState(player)
	if playerState.questActive then
		return
	end

	local rootPart = getCharacterRootPart(player)
	if not rootPart then
		return
	end

	local nearbyZoneIndex = getNearestZoneIndex(rootPart.Position, DynamicQuestConfig.ZoneTriggerRadius)
	if not nearbyZoneIndex then
		if playerState.contextualPromptAvailable then
			playerState.contextualPromptAvailable = false
			playerState.statusText = "Walk near a zone to trigger a quest prompt."
			self:_broadcastState(player)
		end
		return
	end

	if playerState.contextualPromptAvailable and playerState.promptZoneIndex == nearbyZoneIndex then
		return
	end

	playerState.contextualPromptAvailable = true
	playerState.promptZoneIndex = nearbyZoneIndex
	playerState.zoneIndex = nearbyZoneIndex
	playerState.statusText = string.format(
		"Quest available in %s! Click Accept Prompt to start the hunt.",
		self:_getZoneName(nearbyZoneIndex)
	)
	self:_positionCatAtZone(nearbyZoneIndex)
	self:_broadcastState(player)
end

function DynamicQuestService:_tickPlayerState(player: Player, now: number)
	local playerState = self:_getState(player)
	local stateChanged = false

	if playerState.questActive and now >= playerState.questExpiresAt then
		playerState.questActive = false
		playerState.statusText = "The cat ran out of time. Start another scan to retry the hunt."
		playerState.nextPromptAt = now + DynamicQuestConfig.ZonePromptCooldownSeconds
		stateChanged = true
	end

	if playerState.titleTag ~= "None" and playerState.titleExpiresAt > 0 and now >= playerState.titleExpiresAt then
		playerState.titleTag = "None"
		playerState.titleExpiresAt = 0
		if not playerState.questActive then
			playerState.statusText = "Temporary title tag expired. Enter a zone to trigger another quest prompt."
		end
		player:SetAttribute("DynamicQuestTitleTag", nil)
		player:SetAttribute("DynamicQuestTitleExpiresAt", nil)
		stateChanged = true
	end

	if stateChanged then
		self:_broadcastState(player)
	end

	self:_updateContextualPrompt(player, now)
end

function DynamicQuestService:_handleAction(player: Player, action: string)
	if action == "acceptPrompt" then
		self:_acceptContextualPrompt(player)
		return
	end

	if action == "startQuest" then
		self:_startQuest(player)
		return
	end

	if action == "searchForCat" then
		self:_searchAttempt(player)
		return
	end

	if action == "cycleZone" then
		self:_cycleZoneHint(player)
		return
	end

	local playerState = self:_getState(player)
	playerState.statusText = "Unknown quest action requested."
	self:_broadcastState(player)
end

function DynamicQuestService:start()
	if self.started then
		return
	end

	self.started = true
	self:_ensureCatProp()
	self:_ensureZoneVisuals()

	self.connections.action = self.actionRequest.OnServerEvent:Connect(function(player, action)
		if type(action) ~= "string" then
			return
		end

		self:_handleAction(player, action)
	end)

	self.snapshotRequest.OnServerInvoke = function(player)
		return self:_buildState(player)
	end

	self.connections.playerAdded = Players.PlayerAdded:Connect(function(player)
		self.playerStates[player.UserId] = createInitialState()
		player:SetAttribute("DynamicQuestTitleTag", nil)
		player:SetAttribute("DynamicQuestTitleExpiresAt", nil)
		self:_broadcastState(player)
	end)

	self.connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
		self.playerStates[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self.playerStates[player.UserId] = createInitialState()
		player:SetAttribute("DynamicQuestTitleTag", nil)
		player:SetAttribute("DynamicQuestTitleExpiresAt", nil)
		self:_broadcastState(player)
	end

	self.connections.heartbeat = RunService.Heartbeat:Connect(function(deltaTime)
		self.heartbeatAccumulator += deltaTime
		if self.heartbeatAccumulator < 1 then
			return
		end

		self.heartbeatAccumulator = 0
		local now = os.clock()
		for _, player in ipairs(Players:GetPlayers()) do
			self:_tickPlayerState(player, now)
		end
	end)
end

function DynamicQuestService:stop()
	if not self.started then
		return
	end

	self.started = false

	for name, connection in pairs(self.connections) do
		if typeof(connection) == "RBXScriptConnection" and connection.Connected then
			connection:Disconnect()
		end
		self.connections[name] = nil
	end

	self.snapshotRequest.OnServerInvoke = nil
	table.clear(self.playerStates)

	if self.questAnchor then
		self.questAnchor:Destroy()
		self.questAnchor = nil
	end

	if self.zoneVisuals then
		self.zoneVisuals:Destroy()
		self.zoneVisuals = nil
	end

	self.catPrompt = nil
end

return DynamicQuestService
