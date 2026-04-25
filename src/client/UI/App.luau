--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local State = script.Parent.Parent:WaitForChild("State")
local HubContext = require(State:WaitForChild("HubContext"))

local HubMenu = require(script.Parent:WaitForChild("HubMenu"))
local DebugOverlay = require(script.Parent:WaitForChild("DebugOverlay"))

local function calculateUiScale(viewportSize)
	local widthScale = viewportSize.X / 1440
	local heightScale = viewportSize.Y / 900
	return math.clamp(math.min(widthScale, heightScale), 0.8, 1.25)
end

local function App()
	local uiScale, setUiScale = React.useState(1)

	React.useEffect(function()
		local camera = Workspace.CurrentCamera
		local viewportConnection = nil
		local cameraConnection = nil

		local function updateScale()
			local activeCamera = Workspace.CurrentCamera
			if activeCamera then
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
		Backdrop = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(8, 10, 13),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, {
			Gradient = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(11, 13, 18)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 7, 10)),
				}),
				Rotation = 25,
			}),
			MainLayer = React.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
			}, {
				Scale = React.createElement("UIScale", {
					Scale = uiScale,
				}),
				Hub = React.createElement(HubMenu),
			}),
			Debug = React.createElement(DebugOverlay),
		}),
	})
end

return App
