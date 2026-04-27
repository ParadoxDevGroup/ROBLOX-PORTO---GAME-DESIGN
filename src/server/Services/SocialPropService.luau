--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemotesConfig = require(Shared:WaitForChild("Config"):WaitForChild("Remotes"))
local SocialPropVariants = require(Shared:WaitForChild("Config"):WaitForChild("SocialPropVariants"))

local SocialPropService = {}
SocialPropService.__index = SocialPropService

local function getOrCreateChild(parent, className, name)
	local child = parent:FindFirstChild(name)
	if child then
		return child
	end

	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local function getVariant(variantIndex)
	local index = math.clamp(math.floor(variantIndex or 1), 1, #SocialPropVariants)
	return index, SocialPropVariants[index]
end

function SocialPropService.new()
	local sharedFolder = getOrCreateChild(Shared, "Folder", RemotesConfig.FolderName)
	local deployRequest = getOrCreateChild(sharedFolder, "RemoteEvent", RemotesConfig.SocialPropDeployRequest)
	local actionRequest = getOrCreateChild(sharedFolder, "RemoteEvent", RemotesConfig.SocialPropActionRequest)
	local snapshotRequest = getOrCreateChild(sharedFolder, "RemoteFunction", RemotesConfig.SocialPropSnapshotRequest)
	local stateUpdated = getOrCreateChild(sharedFolder, "RemoteEvent", RemotesConfig.SocialPropStateUpdated)

	return setmetatable({
		sharedFolder = sharedFolder,
		deployRequest = deployRequest,
		actionRequest = actionRequest,
		snapshotRequest = snapshotRequest,
		stateUpdated = stateUpdated,
		connections = {},
		activeBasket = nil,
		activePrompt = nil,
		activeBasketOwnerUserId = nil,
		interactionCount = 0,
		activeVariantIndex = 1,
		lastInteractorName = nil,
		stateMessage = "Deploy a basket to begin the shared loop.",
		buffTokens = {},
		activeBuffs = {},
	}, SocialPropService)
end

function SocialPropService:_playBasketPulseAnimation(basketModel)
	if not basketModel or not basketModel.PrimaryPart then
		return
	end

	task.spawn(function()
		local startingPivot = basketModel:GetPivot()
		for frame = 1, 10 do
			if not basketModel.Parent then
				return
			end

			local offsetY = math.sin((frame / 10) * math.pi) * 0.35
			basketModel:PivotTo(startingPivot * CFrame.new(0, offsetY, 0))
			task.wait(0.025)
		end

		if basketModel.Parent then
			basketModel:PivotTo(startingPivot)
		end
	end)
end

function SocialPropService:_buildState()
	local ownerPlayer = self.activeBasketOwnerUserId and Players:GetPlayerByUserId(self.activeBasketOwnerUserId) or nil
	local variantIndex, variant = getVariant(self.activeVariantIndex)

	return {
		deployed = self.activeBasket ~= nil,
		variantIndex = variantIndex,
		variantName = variant.name,
		interactionCount = self.interactionCount,
		ownerUserId = self.activeBasketOwnerUserId,
		ownerName = ownerPlayer and ownerPlayer.DisplayName or nil,
		lastInteractorName = self.lastInteractorName,
		statusText = self.stateMessage,
	}
end

function SocialPropService:_broadcastState(stateMessage)
	self.stateMessage = stateMessage or self.stateMessage
	self.stateUpdated:FireAllClients(self:_buildState())
end

function SocialPropService:_clearBasket()
	if self.activePrompt then
		self.activePrompt:Destroy()
		self.activePrompt = nil
	end

	if self.activeBasket then
		self.activeBasket:Destroy()
		self.activeBasket = nil
	end

	self.activeBasketOwnerUserId = nil
	self.lastInteractorName = nil
end

function SocialPropService:_createSharedEffects(basketModel, accentColor)
	local primaryPart = basketModel.PrimaryPart
	if not primaryPart then
		return
	end

	local accentAttachment = primaryPart:FindFirstChild("AccentAttachment")
	if not accentAttachment then
		accentAttachment = Instance.new("Attachment")
		accentAttachment.Name = "AccentAttachment"
		accentAttachment.Position = Vector3.new(0, 1.25, 0)
		accentAttachment.Parent = primaryPart
	end

	local sparkleEmitter = Instance.new("ParticleEmitter")
	sparkleEmitter.Name = "SharedSparkles"
	sparkleEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkleEmitter.Color = ColorSequence.new(accentColor)
	sparkleEmitter.LightEmission = 0.6
	sparkleEmitter.Lifetime = NumberRange.new(0.5, 0.8)
	sparkleEmitter.Rate = 0
	sparkleEmitter.Speed = NumberRange.new(1, 2)
	sparkleEmitter.SpreadAngle = Vector2.new(180, 180)
	sparkleEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkleEmitter.Parent = accentAttachment
	sparkleEmitter:Emit(24)

	local highlight = Instance.new("Highlight")
	highlight.Name = "SharedHighlight"
	highlight.FillColor = accentColor
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = basketModel
	highlight.Parent = basketModel

	task.delay(1.4, function()
		if highlight.Parent then
			highlight:Destroy()
		end
	end)
end

function SocialPropService:_applyVariantToActiveBasket(variantIndex)
	local selectedIndex, variant = getVariant(variantIndex)
	self.activeVariantIndex = selectedIndex

	if not self.activeBasket then
		return selectedIndex, variant
	end

	local basketBase = self.activeBasket:FindFirstChild("BasketBase")
	if basketBase and basketBase:IsA("BasePart") then
		basketBase.Color = variant.baseColor
	end

	local basketLid = self.activeBasket:FindFirstChild("BasketLid")
	if basketLid and basketLid:IsA("BasePart") then
		basketLid.Color = variant.lidColor
	end

	if self.activePrompt then
		self.activePrompt.ObjectText = variant.name
	end

	if self.activeBasket then
		self.activeBasket:SetAttribute("VariantIndex", selectedIndex)
	end

	return selectedIndex, variant
end

function SocialPropService:_triggerSharedInteraction(triggeringPlayer, allowOwner)
	if not self.activeBasket then
		self:_broadcastState("Deploy a basket first before triggering a shared interaction.")
		return
	end

	if (not allowOwner) and triggeringPlayer.UserId == self.activeBasketOwnerUserId then
		local ownerPlayer = Players:GetPlayerByUserId(self.activeBasketOwnerUserId)
		local ownerName = ownerPlayer and ownerPlayer.DisplayName or "Owner"
		self:_broadcastState(string.format("%s needs a different player to share the basket.", ownerName))
		return
	end

	local _, variant = getVariant(self.activeVariantIndex)
	self.interactionCount += 1
	self.lastInteractorName = triggeringPlayer.DisplayName
	self:_applyBuff(triggeringPlayer, variant.buffBonus, variant.buffDuration, variant.buffLabel, variant.accentColor)
	self:_playBasketPulseAnimation(self.activeBasket)
	self:_createSharedEffects(self.activeBasket, variant.accentColor)
	self:_broadcastState(
		string.format("%s shared the basket and received %s.", triggeringPlayer.DisplayName, variant.buffLabel)
	)
end

function SocialPropService:_applyBuff(player, buffBonus, buffDuration, buffLabel, accentColor)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local userId = player.UserId
	local buffState = self.activeBuffs[userId]
	if not buffState then
		buffState = {
			originalWalkSpeed = humanoid.WalkSpeed,
			token = 0,
		}
		self.activeBuffs[userId] = buffState
	end

	buffState.token += 1
	local token = buffState.token

	if not buffState.applied then
		buffState.applied = true
		humanoid.WalkSpeed = math.max(buffState.originalWalkSpeed, 16) + buffBonus
	else
		humanoid.WalkSpeed = math.max(humanoid.WalkSpeed, buffState.originalWalkSpeed + buffBonus)
	end

	player:SetAttribute("SocialPropBuffActive", true)
	player:SetAttribute("SocialPropBuffLabel", buffLabel)
	player:SetAttribute("SocialPropBuffExpiresAt", os.clock() + buffDuration)

	local characterHighlight = Instance.new("Highlight")
	characterHighlight.Name = "SocialPropBuffHighlight"
	characterHighlight.FillColor = accentColor
	characterHighlight.FillTransparency = 0.55
	characterHighlight.OutlineTransparency = 1
	characterHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	characterHighlight.Adornee = character
	characterHighlight.Parent = character

	task.delay(1.5, function()
		if characterHighlight.Parent then
			characterHighlight:Destroy()
		end
	end)

	task.delay(buffDuration, function()
		local currentBuffState = self.activeBuffs[userId]
		if not currentBuffState or currentBuffState ~= buffState or currentBuffState.token ~= token then
			return
		end

		local currentCharacter = player.Character
		local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
		if currentHumanoid then
			currentHumanoid.WalkSpeed = currentBuffState.originalWalkSpeed
		end

		player:SetAttribute("SocialPropBuffActive", false)
		player:SetAttribute("SocialPropBuffLabel", nil)
		player:SetAttribute("SocialPropBuffExpiresAt", nil)
		self.activeBuffs[userId] = nil
	end)
end

function SocialPropService:_deployBasket(player, variantIndex)
	local character = player.Character
	if not character then
		return false, "Wait for your character to load before deploying the basket."
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false, "Your character is missing a root part."
	end

	local selectedIndex, variant = getVariant(variantIndex)
	self:_clearBasket()

	local basketModel = Instance.new("Model")
	basketModel.Name = "SocialPropBasket"
	basketModel:SetAttribute("OwnerUserId", player.UserId)
	basketModel:SetAttribute("VariantIndex", selectedIndex)
	basketModel.Parent = Workspace

	local basketBase = Instance.new("Part")
	basketBase.Name = "BasketBase"
	basketBase.Anchored = true
	basketBase.CanCollide = true
	basketBase.Material = Enum.Material.Wood
	basketBase.Color = variant.baseColor
	basketBase.Size = Vector3.new(4, 1.1, 3)
	basketBase.TopSurface = Enum.SurfaceType.Smooth
	basketBase.BottomSurface = Enum.SurfaceType.Smooth
	basketBase.Parent = basketModel

	local basketLid = Instance.new("Part")
	basketLid.Name = "BasketLid"
	basketLid.Anchored = true
	basketLid.CanCollide = false
	basketLid.Material = Enum.Material.Fabric
	basketLid.Color = variant.lidColor
	basketLid.Size = Vector3.new(4.15, 0.22, 3.15)
	basketLid.Parent = basketModel

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Anchored = true
	handle.CanCollide = false
	handle.Material = Enum.Material.SmoothPlastic
	handle.Color = Color3.fromRGB(37, 31, 24)
	handle.Size = Vector3.new(0.18, 2.2, 0.18)
	handle.Parent = basketModel

	basketModel.PrimaryPart = basketBase
	basketModel:PivotTo(rootPart.CFrame * CFrame.new(0, -1, -6))

	basketLid.CFrame = basketBase.CFrame * CFrame.new(0, 0.72, 0)
	handle.CFrame = basketBase.CFrame * CFrame.new(0, 1.55, 0)

	local promptAttachment = Instance.new("Attachment")
	promptAttachment.Name = "PromptAttachment"
	promptAttachment.Position = Vector3.new(0, 0.8, 0)
	promptAttachment.Parent = basketBase

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SharedPrompt"
	prompt.ActionText = "Share Snack"
	prompt.ObjectText = variant.name
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptAttachment

	self.activeBasket = basketModel
	self.activePrompt = prompt
	self.activeBasketOwnerUserId = player.UserId
	self.activeVariantIndex = selectedIndex
	self.interactionCount = 0
	self.lastInteractorName = nil

	local promptConnection
	promptConnection = prompt.Triggered:Connect(function(triggeringPlayer)
		self:_triggerSharedInteraction(triggeringPlayer, false)
	end)

	table.insert(self.connections, promptConnection)
	basketModel.AncestryChanged:Connect(function(_, parent)
		if parent == nil and promptConnection.Connected then
			promptConnection:Disconnect()
		end
	end)

	self:_broadcastState(
		string.format("%s deployed %s. Another player can trigger the shared buff.", player.DisplayName, variant.name)
	)
	return true
end

function SocialPropService:start()
	if self.started then
		return
	end

	self.started = true

	self.connections.deploy = self.deployRequest.OnServerEvent:Connect(function(player, variantIndex)
		local success, message = self:_deployBasket(player, variantIndex)
		if not success and message then
			self:_broadcastState(message)
		end
	end)

	self.connections.action = self.actionRequest.OnServerEvent:Connect(function(player, action, payload)
		if type(action) ~= "string" then
			return
		end

		if action == "cycleVariant" then
			local requestedIndex = (type(payload) == "number" and payload) or self.activeVariantIndex
			local selectedIndex, variant = self:_applyVariantToActiveBasket(requestedIndex)
			self:_playBasketPulseAnimation(self.activeBasket)
			if self.activeBasket then
				self:_createSharedEffects(self.activeBasket, variant.accentColor)
			end
			self:_broadcastState(string.format("Variant switched to %s.", variant.name))
			self.activeVariantIndex = selectedIndex
			return
		end

		if action == "shareTest" then
			self:_triggerSharedInteraction(player, true)
			return
		end

		self:_broadcastState("Unknown social prop action requested.")
	end)

	self.snapshotRequest.OnServerInvoke = function()
		return self:_buildState()
	end

	self.connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
		if player.UserId == self.activeBasketOwnerUserId then
			self:_clearBasket()
			self:_broadcastState("The basket owner left. Deploy a new basket to continue.")
		end

		self.activeBuffs[player.UserId] = nil
	end)

	self:_broadcastState("Deploy a basket to begin the shared loop.")
end

function SocialPropService:stop()
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
	self:_clearBasket()
end

return SocialPropService
