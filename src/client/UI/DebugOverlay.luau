--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ModuleIds = require(Shared:WaitForChild("Config"):WaitForChild("ModuleIds"))

local State = script.Parent.Parent:WaitForChild("State")
local HubContext = require(State:WaitForChild("HubContext"))

local function toModuleLabel(moduleId)
	if moduleId == ModuleIds.SocialProp then
		return "Module 1: Social Prop"
	end

	if moduleId == ModuleIds.MicroEconomy then
		return "Module 2: Micro-Economy"
	end

	if moduleId == ModuleIds.DynamicQuest then
		return "Module 3: Dynamic Quest"
	end

	return "Hub"
end

local function formatElapsedSeconds(totalSeconds)
	local safe = math.max(0, math.floor(totalSeconds))
	local minutes = math.floor(safe / 60)
	local seconds = safe % 60
	return string.format("%02d:%02d", minutes, seconds)
end

local function DebugOverlay(props)
	local hub = HubContext.useHubContext()
	local nowTick, setNowTick = React.useState(os.clock())

	local uiScaleProp = (props and props.uiScale) or 1
	local setUiScale = (props and props.setUiScale) or function() end

	React.useEffect(function()
		local alive = true

		task.spawn(function()
			while alive do
				task.wait(1)
				setNowTick(os.clock())
			end
		end)

		return function()
			alive = false
		end
	end, {})

	local elapsed = 0
	if hub.sessionStartedAt ~= nil and hub.activeModule ~= nil then
		elapsed = nowTick - hub.sessionStartedAt
	end

	local moduleLabel = toModuleLabel(hub.activeModule)
	local statusText = hub.activeModule and "Sandbox Active" or "Waiting In Hub"

	local function increaseScale()
		local v = uiScaleProp + 0.02
		v = math.max(v, 0.6)
		v = math.min(v, 1.5)
		setUiScale(v)
	end

	local function decreaseScale()
		local v = uiScaleProp - 0.02
		v = math.max(v, 0.6)
		v = math.min(v, 1.5)
		setUiScale(v)
	end

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Color3.fromRGB(7, 9, 12),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.fromOffset(220, 92),
		ZIndex = 40,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		Stroke = React.createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(54, 59, 68),
			Thickness = 1,
		}),
		Padding = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
		Title = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.fromEnum(Enum.Font.GothamBold),
			Size = UDim2.new(1, 0, 0, 16),
			Text = "Debug Overlay",
			TextColor3 = Color3.fromRGB(233, 239, 247),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 21,
		}),
		Status = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.fromEnum(Enum.Font.Gotham),
			Position = UDim2.fromOffset(0, 20),
			Size = UDim2.new(1, 0, 0, 16),
			Text = string.format("State: %s", statusText),
			TextColor3 = Color3.fromRGB(165, 178, 199),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 21,
		}),
		Module = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.fromEnum(Enum.Font.GothamMedium),
			Position = UDim2.fromOffset(0, 38),
			Size = UDim2.new(1, 0, 0, 16),
			Text = string.format("Active: %s", moduleLabel),
			TextColor3 = Color3.fromRGB(210, 218, 231),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 21,
		}),
		Timer = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.fromEnum(Enum.Font.GothamBold),
			Position = UDim2.fromOffset(0, 56),
			Size = UDim2.new(1, 0, 0, 20),
			Text = string.format("Session: %s", formatElapsedSeconds(elapsed)),
			TextColor3 = Color3.fromRGB(238, 242, 249),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 21,
		}),
		ScaleLabel = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 78),
			Size = UDim2.fromOffset(220, 16),
		}, {
			ScaleText = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.fromEnum(Enum.Font.Gotham),
				Size = UDim2.fromScale(0.6, 1),
				Text = string.format("UI Scale: %.2f", uiScaleProp),
				TextColor3 = Color3.fromRGB(210, 218, 231),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Minus = React.createElement("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0.78, 0, 0.5, 0),
				Size = UDim2.fromOffset(36, 16),
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(40, 44, 52),
				Text = "−",
				TextColor3 = Color3.fromRGB(238, 242, 249),
				TextSize = 14,
				[React.Event.Activated] = decreaseScale,
			}),
			Plus = React.createElement("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0.95, 0, 0.5, 0),
				Size = UDim2.fromOffset(36, 16),
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(40, 44, 52),
				Text = "+",
				TextColor3 = Color3.fromRGB(238, 242, 249),
				TextSize = 14,
				[React.Event.Activated] = increaseScale,
			}),
		}),
	})
end

return DebugOverlay
