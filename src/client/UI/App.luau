--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local State = script.Parent.Parent:WaitForChild("State")
local HubContext = require(State:WaitForChild("HubContext"))

local HubMenu = require(script.Parent:WaitForChild("HubMenu"))
local DebugOverlay = require(script.Parent:WaitForChild("DebugOverlay"))

local function calculateUiScale(viewportSize)
	local widthScale = viewportSize.X / 1440
	local heightScale = viewportSize.Y / 900
	return math.clamp(math.min(widthScale, heightScale), 0.82, 1.02)
end

local function HubScreen(props)
	local hub = HubContext.useHubContext()

	React.useEffect(function()
		local connection = UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
			if gameProcessedEvent then
				return
			end

			if inputObject.KeyCode == Enum.KeyCode.Tab then
				hub.toggleUi()
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, { hub })

	local function renderToggleButton()
		local buttonText = hub.isUiVisible and "Hide UI [Tab]" or "Open UI [Tab]"

		return React.createElement("TextButton", {
			AnchorPoint = Vector2.new(0, 1),
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(19, 22, 28),
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
			FontFace = Font.fromEnum(Enum.Font.GothamMedium),
			Position = UDim2.new(0, 16, 1, -16),
			Size = UDim2.fromOffset(128, 36),
			Text = buttonText,
			TextColor3 = Color3.fromRGB(235, 238, 242),
			TextSize = 13,
			ZIndex = 60,
			[React.Event.Activated] = function()
				hub.toggleUi()
			end,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 10),
			}),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(60, 66, 76),
				Thickness = 1,
				Transparency = 0.25,
			}),
		})
	end

	if not hub.isUiVisible then
		return React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			Toggle = renderToggleButton(),
		})
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Toggle = renderToggleButton(),
		Backdrop = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(10, 12, 16),
			BackgroundTransparency = 0.84,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, {
			Gradient = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 22, 30)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 14)),
				}),
				Rotation = 8,
			}),
			MainLayer = React.createElement("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.01, 0.52),
				Size = UDim2.fromScale(0.48, 0.94),
			}, {
				Scale = React.createElement("UIScale", {
					Scale = props.uiScale,
				}),
				Hub = React.createElement(HubMenu, {
					viewportSize = props.viewportSize,
				}),
			}),
			Debug = React.createElement(DebugOverlay, {
				uiScale = props.uiScale,
				setUiScale = props.setUiScale,
				viewportSize = props.viewportSize,
			}),
		}),
	})
end

local function App()
	local uiScale, setUiScale = React.useState(1)
	local viewportSize, setViewportSize = React.useState(Vector2.new(1440, 900))
	React.useEffect(function()
		local camera = Workspace.CurrentCamera
		local viewportConnection = nil
		local cameraConnection = nil

		local function updateScale()
			local activeCamera = Workspace.CurrentCamera
			if activeCamera then
				setViewportSize(activeCamera.ViewportSize)
				setUiScale(calculateUiScale(activeCamera.ViewportSize))
			end
		end

		local function attachCamera(activeCamera)
			if viewportConnection then
				viewportConnection:Disconnect()
				viewportConnection = nil
			end

			if activeCamera then
				viewportConnection = activeCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
			end
		end

		if camera then
			attachCamera(camera)
			updateScale()
		end

		cameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			attachCamera(Workspace.CurrentCamera)
			updateScale()
		end)

		return function()
			if viewportConnection then
				viewportConnection:Disconnect()
				viewportConnection = nil
			end

			if cameraConnection then
				cameraConnection:Disconnect()
				cameraConnection = nil
			end
		end
	end, {})

	return React.createElement(HubContext.HubProvider, nil, {
		HubScreen = React.createElement(HubScreen, {
			uiScale = uiScale,
			setUiScale = setUiScale,
			viewportSize = viewportSize,
		}),
	})
end

return App
