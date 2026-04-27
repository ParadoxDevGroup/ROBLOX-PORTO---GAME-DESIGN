--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigFolder = Shared:WaitForChild("Config")
local RemotesConfig = require(ConfigFolder:WaitForChild("Remotes"))
local MicroEconomyBalance = require(ConfigFolder:WaitForChild("MicroEconomyBalance"))

local MicroEconomyService = {}
MicroEconomyService.__index = MicroEconomyService

type PlayerState = {
	tokens: number,
	speedLevel: number,
	tipLevel: number,
	servedCount: number,
	statusText: string,
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

local function createInitialState(): PlayerState
	return {
		tokens = MicroEconomyBalance.InitialTokens,
		speedLevel = MicroEconomyBalance.InitialSpeedLevel,
		tipLevel = MicroEconomyBalance.InitialTipLevel,
		servedCount = MicroEconomyBalance.InitialServedCount,
		statusText = "Serve the first customer to begin the cafe loop.",
	}
end

function MicroEconomyService.new()
	local sharedFolder = getOrCreateChild(Shared, "Folder", RemotesConfig.FolderName)
	local actionRequest = getOrCreateChild(sharedFolder, "RemoteEvent", RemotesConfig.MicroEconomyActionRequest)
	local snapshotRequest = getOrCreateChild(sharedFolder, "RemoteFunction", RemotesConfig.MicroEconomySnapshotRequest)
	local stateUpdated = getOrCreateChild(sharedFolder, "RemoteEvent", RemotesConfig.MicroEconomyStateUpdated)

	return setmetatable({
		sharedFolder = sharedFolder,
		actionRequest = actionRequest,
		snapshotRequest = snapshotRequest,
		stateUpdated = stateUpdated,
		connections = {},
		playerStates = {},
		started = false,
	}, MicroEconomyService)
end

function MicroEconomyService:_getState(player: Player): PlayerState
	local playerState = self.playerStates[player.UserId]
	if playerState then
		return playerState
	end

	playerState = createInitialState()
	self.playerStates[player.UserId] = playerState
	return playerState
end

function MicroEconomyService:_buildState(player: Player)
	local playerState = self:_getState(player)
	local speedCost = MicroEconomyBalance.costForSpeed(playerState.speedLevel)
	local tipCost = MicroEconomyBalance.costForTips(playerState.tipLevel)
	local nextPayout = MicroEconomyBalance.payoutForServe(playerState.speedLevel, playerState.tipLevel)

	return {
		tokens = playerState.tokens,
		speedLevel = playerState.speedLevel,
		tipLevel = playerState.tipLevel,
		servedCount = playerState.servedCount,
		statusText = playerState.statusText,
		speedNextCost = speedCost,
		tipNextCost = tipCost,
		nextPayout = nextPayout,
	}
end

function MicroEconomyService:_broadcastState(player: Player)
	self.stateUpdated:FireClient(player, self:_buildState(player))
end

function MicroEconomyService:_playServeFeedback(player: Player, payout: number)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 2.5, 0)
	attachment.Parent = rootPart

	local coins = Instance.new("ParticleEmitter")
	coins.Name = "CafeCoinBurst"
	coins.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	coins.Color = ColorSequence.new(Color3.fromRGB(255, 212, 102))
	coins.LightEmission = 0.65
	coins.Lifetime = NumberRange.new(0.45, 0.75)
	coins.Rate = 0
	coins.Speed = NumberRange.new(4, 7)
	coins.SpreadAngle = Vector2.new(55, 55)
	coins.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.22),
		NumberSequenceKeypoint.new(0.65, 0.17),
		NumberSequenceKeypoint.new(1, 0),
	})
	coins.Parent = attachment
	coins:Emit(18)

	local tagPart = Instance.new("Part")
	tagPart.Name = "CafePayoutTag"
	tagPart.Anchored = true
	tagPart.CanCollide = false
	tagPart.Transparency = 1
	tagPart.Size = Vector3.new(0.2, 0.2, 0.2)
	tagPart.CFrame = rootPart.CFrame * CFrame.new(0, 3, 0)
	tagPart.Parent = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(110, 34)
	billboard.StudsOffset = Vector3.new(0, 0.7, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = tagPart
	billboard.Parent = tagPart

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	label.Text = string.format("+%d Tokens", payout)
	label.TextColor3 = Color3.fromRGB(255, 232, 176)
	label.TextStrokeTransparency = 0.6
	label.TextSize = 17
	label.Parent = billboard

	task.spawn(function()
		for _ = 1, 20 do
			if not tagPart.Parent then
				break
			end
			tagPart.CFrame = tagPart.CFrame * CFrame.new(0, 0.075, 0)
			task.wait(0.03)
		end
	end)

	Debris:AddItem(attachment, 1.6)
	Debris:AddItem(tagPart, 0.9)
end

function MicroEconomyService:_serve(player: Player, playerState: PlayerState)
	local payout = MicroEconomyBalance.payoutForServe(playerState.speedLevel, playerState.tipLevel)
	playerState.tokens += payout
	playerState.servedCount += 1
	playerState.statusText = string.format("Customer served for %d tokens. The shift keeps scaling.", payout)
	self:_playServeFeedback(player, payout)
	self:_broadcastState(player)
end

function MicroEconomyService:_upgradeSpeed(player: Player, playerState: PlayerState)
	local cost = MicroEconomyBalance.costForSpeed(playerState.speedLevel)
	if playerState.tokens < cost then
		playerState.statusText =
			string.format("Need %d tokens for serve speed level %d.", cost, playerState.speedLevel + 1)
		self:_broadcastState(player)
		return
	end

	playerState.tokens -= cost
	playerState.speedLevel += 1
	playerState.statusText = string.format("Serve speed upgraded to level %d.", playerState.speedLevel)
	self:_broadcastState(player)
end

function MicroEconomyService:_upgradeTips(player: Player, playerState: PlayerState)
	local cost = MicroEconomyBalance.costForTips(playerState.tipLevel)
	if playerState.tokens < cost then
		playerState.statusText =
			string.format("Need %d tokens for tip multiplier level %d.", cost, playerState.tipLevel + 1)
		self:_broadcastState(player)
		return
	end

	playerState.tokens -= cost
	playerState.tipLevel += 1
	playerState.statusText = string.format("Tip multiplier upgraded to level %d.", playerState.tipLevel)
	self:_broadcastState(player)
end

function MicroEconomyService:_handleAction(player: Player, action: string)
	local playerState = self:_getState(player)
	if action == "serve" then
		self:_serve(player, playerState)
		return
	end

	if action == "upgradeSpeed" then
		self:_upgradeSpeed(player, playerState)
		return
	end

	if action == "upgradeTips" then
		self:_upgradeTips(player, playerState)
		return
	end

	playerState.statusText = "Unknown cafe action requested."
	self:_broadcastState(player)
end

function MicroEconomyService:start()
	if self.started then
		return
	end

	self.started = true

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
		self:_broadcastState(player)
	end)

	self.connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
		self.playerStates[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self.playerStates[player.UserId] = createInitialState()
		self:_broadcastState(player)
	end
end

function MicroEconomyService:stop()
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
end

return MicroEconomyService
